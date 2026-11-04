// Two-flop synchronizer + stable-level debounce + one pulse per press.
module button_conditioner #(
    parameter integer DEBOUNCE_CYCLES = 240_000
) (
    input  logic clk,
    input  logic rst,
    input  logic pressed_async, // Already normalized: 1 means pressed.
    output logic press_pulse
);
    localparam integer COUNT_WIDTH = (DEBOUNCE_CYCLES > 1)
                                    ? $clog2(DEBOUNCE_CYCLES) : 1;
    // Preserve the synchronizer stages when Quartus optimizes the netlist.
    (* preserve *) logic sync_meta, sync_level;
    logic stable_level;
    logic [COUNT_WIDTH-1:0] count;

    always_ff @(posedge clk) begin
        if (rst) begin
            sync_meta <= 1'b0;
            sync_level <= 1'b0;
            stable_level <= 1'b0;
            count <= '0;
            press_pulse <= 1'b0;
        end else begin
            sync_meta <= pressed_async;
            sync_level <= sync_meta;
            press_pulse <= 1'b0;
            if (sync_level == stable_level)
                count <= '0;
            else if (count == DEBOUNCE_CYCLES - 1) begin
                count <= '0;
                stable_level <= sync_level;
                press_pulse <= sync_level;
            end else
                count <= count + 1'b1;
        end
    end
endmodule
