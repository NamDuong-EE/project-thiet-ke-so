`timescale 1ns/1ps
module tb_primitives;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1, pressed_async = 0;
    wire press_pulse;
    logic [3:0] digit = 0;
    wire [6:0] active_low, active_high;
    logic [6:0] expected [0:9];
    integer i, pulses = 0;
    button_conditioner #(.DEBOUNCE_CYCLES(1)) button_minimum (.*);
    seven_segment #(.ACTIVE_LOW(1)) low_decoder (.digit(digit), .segments(active_low));
    seven_segment #(.ACTIVE_LOW(0)) high_decoder (.digit(digit), .segments(active_high));
    always @(negedge clk) if (!rst && press_pulse) pulses++;
    initial begin
        expected[0] = 7'b1111110; expected[1] = 7'b0110000;
        expected[2] = 7'b1101101; expected[3] = 7'b1111001;
        expected[4] = 7'b0110011; expected[5] = 7'b1011011;
        expected[6] = 7'b1011111; expected[7] = 7'b1110000;
        expected[8] = 7'b1111111; expected[9] = 7'b1111011;
        for (i = 0; i < 16; i++) begin
            digit = i; #1;
            if (i < 10) begin
                if (active_high !== expected[i] || active_low !== ~expected[i])
                    $fatal(1, "incorrect seven-segment digit %0d", i);
            end else if (active_high !== 0 || active_low !== 7'b1111111)
                $fatal(1, "invalid digit should blank display");
        end
        @(negedge clk); rst = 0;
        pressed_async = 1;
        repeat (10) @(negedge clk);
        #1;
        if (pulses != 1) $fatal(1, "minimum debounce generated %0d pulses", pulses);
        @(negedge clk); pressed_async = 0;
        repeat (6) @(negedge clk);
        pressed_async = 1;
        repeat (6) @(negedge clk);
        #1;
        if (pulses != 2) $fatal(1, "minimum debounce did not rearm");
        $display("PASS tb_primitives: 16 digits, both polarities, minimum debounce");
        $finish;
    end
    initial begin #10000; $fatal(1, "watchdog timeout"); end
endmodule
