`timescale 1ns/1ps
module tb_calculator_top;
    logic clk_12mhz = 0;
    logic [3:0] sw = 0, key = 4'b1111;
    wire [7:0] led;
    wire [2:0] rgb1, rgb2;
    wire [6:0] seg_tens, seg_ones;
    wire dp_tens, dp_ones, digit_tens, digit_ones;
    calculator_top #(.DEBOUNCE_CYCLES(3)) dut (.*);
    always #5 clk_12mhz = ~clk_12mhz;
    task automatic cycles(input integer count);
        repeat (count) @(negedge clk_12mhz);
    endtask
    task automatic press(input integer index);
        key[index] = 0; cycles(12);
        key[index] = 1; cycles(12);
    endtask
    task automatic choose(input logic [3:0] data);
        sw = data; cycles(5); press(0);
    endtask
    localparam logic [6:0] ZERO = 7'b1111110, ONE = 7'b0110000, TWO = 7'b1101101,
                           FOUR = 7'b0110011, LETTER_E = 7'b1001111;
    initial begin
        cycles(1); press(3);
        if (led !== 8'hef || {seg_tens,seg_ones} !== {ZERO,ZERO} ||
            {dp_tens,dp_ones,digit_tens,digit_ones} !== 0)
            $fatal(1, "reset display / INPUT_A");
        // A short bounce does not enter OP. A held key advances once.
        sw = 3; cycles(5);
        key[0] = 0; cycles(1); key[0] = 1; cycles(10);
        if (led[4] !== 0) $fatal(1, "bounce accepted");
        key[0] = 0; cycles(60);
        if (led[5] !== 0) $fatal(1, "held key skipped operation");
        key[0] = 1; cycles(10);
        choose(1); choose(5); // 3 - 5 = -2
        if ({seg_tens,seg_ones} !== {ZERO,TWO} || led[7] !== 0 ||
            led[1] !== 0 || rgb1 !== 3'b101 || rgb2 !== 3'b011)
            $fatal(1, "negative result or operation LED");
        sw = 7; cycles(6);
        if (seg_ones !== TWO) $fatal(1, "result changed with sw");
        press(1);
        choose(4'b1110); choose(3); choose(4'b1000); // -6 / negative zero
        if ({seg_tens,seg_ones} !== {LETTER_E,ONE} || rgb1 !== 3'b011)
            $fatal(1, "division by zero indicator");
        press(2); // back from ERROR preserves -6 and division
        if (led[6] !== 0) $fatal(1, "did not return to B");
        choose(4'b1011); // -6 / -3 = +2
        if ({seg_tens,seg_ones} !== {ZERO,TWO} || led[7] !== 1 ||
            rgb1 !== 3'b101 || rgb2 !== 3'b101) $fatal(1, "retry after error");
        press(0); choose(7); choose(2); choose(7); // largest result
        if (seg_tens !== FOUR || seg_ones !== 7'b1111011) $fatal(1, "display 49");
        press(3);
        if (led[4] !== 0 || rgb1 !== 3'b110) $fatal(1, "board reset");
        $display("PASS tb_calculator_top: board interaction and physical outputs");
        $finish;
    end
    initial begin #100000; $fatal(1, "Timeout"); end
endmodule
