 `timescale 1ns/1ps
module tb_calculator_core;
    import calc_types::*;
    logic clk = 0, rst = 1, confirm = 0, clear_entry = 0, back = 0;
    logic [3:0] switches = 0;
    state_t state;
    logic [1:0] display_op;
    logic [5:0] magnitude;
    logic negative;
    integer cases = 0;
    calculator_core dut (.*);
    always #5 clk = ~clk;

    function automatic logic [3:0] encode(input integer number);
        return (number < 0) ? (8 - number) : number;
    endfunction

    task automatic enter(input logic [3:0] data);
        switches = data;
        confirm = 1;
        @(negedge clk);
        confirm = 0;
    endtask

    task automatic check_state(input state_t expected);
        if (state !== expected) $fatal(1, "Expected state %0d, got %0d", expected, state);
    endtask

    initial begin
        integer a, b, op, expected;
        @(negedge clk);
        rst = 0;
        for (a = -7; a <= 7; a++)
            for (b = -7; b <= 7; b++)
                for (op = 0; op < 4; op++) begin
                    check_state(INPUT_A);
                    enter(encode(a));
                    check_state(SELECT_OP);
                    enter(op);
                    check_state(INPUT_B);
                    if (display_op !== op[1:0]) $fatal(1, "operation not latched");
                    enter(encode(b));
                    check_state(EVALUATE);
                    switches = ~switches; // A completed operation uses the latched operands.
                    @(negedge clk);
                    if (op == DIV && b == 0) begin
                        check_state(ERROR);
                    end else begin
                        check_state(SHOW_RESULT);
                        case (op)
                            ADD: expected = a + b;
                            SUB: expected = a - b;
                            MUL: expected = a * b;
                            DIV: expected = a / b;
                        endcase
                        if (negative !== (expected < 0) ||
                            magnitude !== ((expected < 0) ? -expected : expected))
                            $fatal(1, "a=%0d op=%0d b=%0d expected %0d got sign=%b mag=%0d",
                                   a, op, b, expected, negative, magnitude);
                    end
                    cases++;
                    enter(0); // From result/error, return to INPUT_A.
                end
        switches = 4'b1000; #1;
        if (negative !== 0 || magnitude !== 0) $fatal(1, "negative zero");
        enter(5);
        back = 1; confirm = 1; @(negedge clk);
        check_state(INPUT_A); // back beats confirm
        back = 0; confirm = 0;
        enter(4); enter(MUL);
        back = 1; @(negedge clk); back = 0;
        check_state(SELECT_OP);
        enter(SUB);
        clear_entry = 1; confirm = 1; back = 1; @(negedge clk);
        check_state(INPUT_A); // clear beats both
        $display("PASS tb_calculator_core: %0d exhaustive transactions", cases);
        $finish;
    end
    initial begin #100000; $fatal(1, "Timeout"); end
endmodule
