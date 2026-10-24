`timescale 1ns/1ps
module tb_vending_top;
    logic clk_12mhz = 0;
    always #5 clk_12mhz = ~clk_12mhz;
    logic [3:0] sw = 4'b1000;
    logic [3:0] key = 4'b1111;
    wire [7:0] led;
    wire [2:0] rgb1, rgb2;
    wire [6:0] seg_tens, seg_ones;
    wire dp_tens, dp_ones, digit_tens, digit_ones;
    integer checks = 0;
    vending_top #(.DEBOUNCE_CYCLES(4), .HOLD_CYCLES(40)) dut (.*);

    task automatic cycles(input integer n);
        repeat (n) @(negedge clk_12mhz);
    endtask
    task automatic verify(input bit ok, input string message);
        checks++;
        if (!ok) $fatal(1, "FAIL: %s", message);
    endtask
    task automatic reset_board;
        @(negedge clk_12mhz); key = 4'b0111;
        cycles(4); key = 4'b1111;
        cycles(12);
    endtask
    task automatic press_key(input integer index);
        key[index] = 0;
        cycles(12);
        key[index] = 1;
        cycles(12);
    endtask

    initial begin
        reset_board();
        verify(!led[3] && led[7], "idle indicators active low");
        verify(seg_tens == 7'b1111110 && seg_ones == 7'b1111110, "display 00 active high segments");
        verify(!dp_tens && !dp_ones && !digit_tens && !digit_ones, "active low commons, decimal points off");

        // Short contact bounces must not add any money.
        key[0] = 0; cycles(1);
        key[0] = 1; cycles(1);
        key[0] = 0; cycles(2);
        key[0] = 1; cycles(12);
        verify(dut.credit == 0, "reject short button bounces");
        key[0] = 0; cycles(30);
        verify(dut.credit == 5, "holding button deposits once");
        cycles(30);
        verify(dut.credit == 5, "no automatic repeat while held");
        key[0] = 1; cycles(12);
        verify(seg_tens == 7'b1111110 && seg_ones == 7'b1011011, "display 05");

        press_key(0);
        verify(dut.credit == 10, "release and repress creates a second event");
        verify(seg_tens == 7'b0110000 && seg_ones == 7'b1111110, "display 10");
        sw[1:0] = 1; cycles(8);
        verify(rgb2 == 3'b101, "switches select B, RGB active low");
        key[1] = 0; cycles(12);
        verify(!led[4] && !led[1] && !led[7] && rgb1 == 3'b101, "buy B through physical key interface");
        reset_board();
        verify(dut.credit == 0 && led[4] && led[7], "physical reset aborts dispense");

        // Invalid product selection reaches the error indicators.
        sw = 4'b1011; cycles(8);
        key[1] = 0; cycles(12);
        verify(!led[6] && led[2:0] == 3'b110 && rgb1 == 3'b011, "invalid selection error output");
        key[1] = 1; cycles(50);
        verify(!led[3] && led[6], "error recovers automatically");
        $display("PASS tb_vending_top: %0d checks", checks);
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "watchdog timeout");
    end
endmodule
