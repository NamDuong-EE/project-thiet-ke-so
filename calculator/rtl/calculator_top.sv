module calculator_top #(
    parameter integer DEBOUNCE_CYCLES = 240_000
) (
    input  logic clk_12mhz,
    input  logic [3:0] sw, key,
    output logic [7:0] led,
    output logic [2:0] rgb1, rgb2,
    output logic [6:0] seg_tens, seg_ones,
    output logic dp_tens, dp_ones, digit_tens, digit_ones
);
    import calc_types::*;
    (* preserve *) logic [1:0] reset_pipe;
    (* preserve *) logic [3:0] sw_meta, sw_sync;
    logic rst, reset_request;
    logic [2:0] pulse;
    state_t state;
    logic [1:0] display_op;
    logic [5:0] magnitude;
    logic negative;
    logic [3:0] tens, ones;
    logic [6:0] tens_segments;
    logic [7:0] led_lit;
    logic [2:0] status_color, sign_color;

    assign reset_request = ~key[3];
    always_ff @(posedge clk_12mhz or posedge reset_request) begin
        if (reset_request) reset_pipe <= 2'b11;
        else reset_pipe <= {reset_pipe[0], 1'b0};
    end
    assign rst = reset_pipe[1];

    always_ff @(posedge clk_12mhz) begin
        if (rst) begin
            sw_meta <= '0;
            sw_sync <= '0;
        end else begin
            sw_meta <= sw;
            sw_sync <= sw_meta;
        end
    end
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : keys
            button_conditioner #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) button (
                .clk(clk_12mhz), .rst(rst), .pressed_async(~key[i]), .press_pulse(pulse[i]));
        end
    endgenerate
    calculator_core core (
        .clk(clk_12mhz), .rst(rst), .switches(sw_sync),
        .confirm(pulse[0]), .clear_entry(pulse[1]), .back(pulse[2]),
        .state(state), .display_op(display_op), .magnitude(magnitude), .negative(negative));

    // The two displays have independent buses. E1 means division by zero.
    assign tens = 4'(magnitude / 6'd10);
    assign ones = (state == ERROR) ? 4'd1 : 4'(magnitude % 6'd10);
    seven_segment #(.ACTIVE_LOW(0)) tens_decoder (.digit(tens), .segments(tens_segments));
    seven_segment #(.ACTIVE_LOW(0)) ones_decoder (.digit(ones), .segments(seg_ones));
    assign seg_tens = (state == ERROR) ? 7'b1001111 : tens_segments;
    assign {dp_tens, dp_ones, digit_tens, digit_ones} = 4'b0000;

    always_comb begin
        led_lit = '0;
        if (state != INPUT_A) led_lit[display_op] = 1'b1;
        led_lit[4] = (state == INPUT_A);
        led_lit[5] = (state == SELECT_OP);
        led_lit[6] = (state == INPUT_B);
        led_lit[7] = negative;
        case (state)
            ERROR: status_color = 3'b100;
            SHOW_RESULT: status_color = 3'b010;
            default: status_color = 3'b001;
        endcase
        sign_color = 3'b000;
        if (state == INPUT_A || state == INPUT_B || state == SHOW_RESULT)
            sign_color = negative ? 3'b100 : ((magnitude == 0) ? 3'b001 : 3'b010);
        led = ~led_lit;
        rgb1 = ~status_color;
        rgb2 = ~sign_color;
    end
endmodule
