`timescale 1ns/1ps
module tb_vending_core;
    localparam integer HOLD = 6;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1;
    logic [1:0] product_select = 0, coin_select = 0;
    logic insert_pulse = 0, buy_pulse = 0, cancel_pulse = 0;
    wire [6:0] credit, display_value;
    wire [2:0] dispense_led, error_code, state_debug;
    wire ready, busy;
    integer checks = 0;

    vending_core #(.HOLD_CYCLES(HOLD)) dut (.*);

    task automatic verify(input bit ok, input string message);
        checks++;
        if (!ok) $fatal(1, "FAIL: %s (state=%0d credit=%0d display=%0d)",
                        message, state_debug, credit, display_value);
    endtask
    task automatic reset_dut;
        @(negedge clk);
        rst = 1;
        insert_pulse = 0; buy_pulse = 0; cancel_pulse = 0;
        repeat (2) @(negedge clk);
        rst = 0;
        verify(state_debug === 3'd0 && credit === 0 && ready === 1,
               "reset returns to idle with zero credit");
    endtask
    // Inputs change on falling edges; the DUT samples on rising edges.
    task automatic event_pulse(input bit ins, input bit buy, input bit cancel);
        @(negedge clk);
        insert_pulse = ins; buy_pulse = buy; cancel_pulse = cancel;
        @(negedge clk);
        insert_pulse = 0; buy_pulse = 0; cancel_pulse = 0;
    endtask
    task automatic deposit(input logic [1:0] coin);
        coin_select = coin;
        event_pulse(1, 0, 0);
    endtask
    task automatic wait_state(input logic [2:0] wanted);
        integer count;
        count = 0;
        while (state_debug !== wanted && count < 100) begin
            @(negedge clk);
            count++;
        end
        verify(state_debug === wanted, $sformatf("reach state %0d", wanted));
    endtask

    // Invariants checked throughout every scenario, including timed states.
    always @(negedge clk) begin
        if (!rst) begin
            if (credit > 99 || display_value > 99) $fatal(1, "amount exceeds 99");
            if (ready === busy) $fatal(1, "ready and busy must be complementary");
            if (state_debug != 3 && dispense_led != 0)
                $fatal(1, "product output outside DISPENSE");
            if (dispense_led != 0 && dispense_led != 1 && dispense_led != 2 && dispense_led != 4)
                $fatal(1, "more than one product output active");
        end
    end

    initial begin
        reset_dut();
        // Exact payment: A costs 5, no refund phase.
        product_select = 0;
        deposit(2);
        verify(credit == 5 && display_value == 5, "deposit five");
        event_pulse(0, 1, 0);
        wait_state(3);
        verify(dispense_led == 1 && credit == 0 && display_value == 5, "exact-price A sale");
        repeat (HOLD-1) begin
            @(negedge clk);
            verify(state_debug == 3, "dispense lasts the complete interval");
        end
        @(negedge clk);
        verify(state_debug == 0, "exact payment skips refund");

        // B with insufficient funds, then total 12 and change 2.
        product_select = 1;
        deposit(2);
        event_pulse(0, 1, 0);
        wait_state(5);
        verify(error_code == 3 && credit == 5, "insufficient funds preserves credit");
        wait_state(1);
        verify(error_code == 0, "error clears after timeout");
        deposit(2); deposit(1);
        verify(credit == 12, "sum of multiple coins");
        event_pulse(0, 1, 0);
        product_select = 2; // Change switches after buy: B must still be dispensed.
        wait_state(3);
        verify(dispense_led == 2 && display_value == 10, "product latched at purchase");
        coin_select = 2;
        event_pulse(1, 1, 1);
        verify(credit == 0 && dispense_led == 2, "ignore events during dispense");
        wait_state(4);
        verify(display_value == 2, "return change two");
        repeat (HOLD-1) begin
            @(negedge clk);
            verify(state_debug == 4 && display_value == 2, "refund held for complete interval");
        end
        @(negedge clk);
        verify(state_debug == 0 && display_value == 0, "clear refund after timeout");

        product_select = 2;
        repeat (3) deposit(2);
        event_pulse(0, 1, 0);
        wait_state(3);
        verify(dispense_led == 4 && display_value == 15, "C sale for fifteen");
        wait_state(0);

        // Invalid coin and invalid selection cannot consume existing money.
        deposit(1);
        deposit(3);
        verify(state_debug == 5 && error_code == 2 && credit == 2, "invalid coin rejected");
        wait_state(1);
        product_select = 3;
        event_pulse(0, 1, 0);
        wait_state(5);
        verify(error_code == 1 && credit == 2, "invalid product rejected");
        wait_state(1);
        event_pulse(0, 0, 1);
        verify(state_debug == 4 && display_value == 2 && credit == 0, "cancel refunds all money");
        event_pulse(1, 1, 1);
        verify(state_debug == 4 && display_value == 2, "ignore events during refund");
        wait_state(0);
        event_pulse(0, 0, 1);
        verify(state_debug == 0, "cancel with zero money remains idle");

        // Boundaries: accept exactly 99, reject any addition over it.
        repeat (19) deposit(2);
        deposit(1); deposit(1);
        verify(credit == 99 && display_value == 99, "maximum balance accepted");
        deposit(0);
        verify(state_debug == 5 && error_code == 4 && credit == 99, "overflow rejected without wrap");
        event_pulse(0, 0, 1);
        verify(state_debug == 5 && credit == 99, "ignore cancel while displaying error");
        wait_state(1);
        event_pulse(1, 1, 1);
        verify(state_debug == 4 && display_value == 99, "cancel has highest priority");
        wait_state(0);

        // BUY beats INSERT; coin is not silently counted in simultaneous events.
        product_select = 0;
        deposit(2);
        event_pulse(1, 1, 0);
        wait_state(3);
        verify(dispense_led == 1, "buy beats insert");
        repeat (HOLD) @(negedge clk);
        verify(state_debug == 0, "simultaneous insert did not create change");

        // No-money purchase, reset during error, dispense and refund.
        event_pulse(0, 1, 0);
        wait_state(5);
        verify(error_code == 3 && credit == 0, "purchase with zero credit");
        wait_state(0);
        deposit(3);
        reset_dut();
        deposit(2);
        event_pulse(0, 1, 0);
        wait_state(3);
        reset_dut();
        verify(dispense_led == 0 && error_code == 0, "reset clears outputs");
        deposit(0);
        event_pulse(0, 0, 1);
        reset_dut();
        verify(display_value == 0, "reset clears pending refund");
        $display("PASS tb_vending_core: %0d checks", checks);
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "watchdog timeout");
    end
endmodule
