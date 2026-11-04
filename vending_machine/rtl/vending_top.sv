// STEP-MAX10 wrapper: four switches, four keys, two independent 7-seg digits.
module vending_top #(
    parameter integer CLK_HZ = 12_000_000,
    parameter integer DEBOUNCE_CYCLES = CLK_HZ / 50, // 20 ms
    parameter integer HOLD_CYCLES = CLK_HZ * 2,     // 2 seconds per timed state
    parameter bit KEY_ACTIVE_LOW = 1'b1,
    parameter bit SEG_ACTIVE_LOW = 1'b0,
    parameter bit DIGIT_ACTIVE_LOW = 1'b1,
    parameter bit LED_ACTIVE_LOW = 1'b1,
    parameter bit RGB_ACTIVE_LOW = 1'b1
) (
    input  logic       clk_12mhz,
    input  logic [3:0] sw,
    input  logic [3:0] key,
    output logic [7:0] led,
    output logic [2:0] rgb1, rgb2, // {red,green,blue}
    output logic [6:0] seg_tens, seg_ones,
    output logic       dp_tens, dp_ones,
    output logic       digit_tens, digit_ones
);
    logic [3:0] pressed;
    logic reset_request, rst;
    (* preserve *) logic [1:0] reset_pipe;
    (* preserve *) logic [3:0] sw_meta, sw_sync;
    logic insert_pulse, buy_pulse, cancel_pulse;
    logic [6:0] credit, display_value;
    logic [3:0] tens, ones;
    logic [2:0] dispense_led, error_code, state_debug;
    logic ready, busy;
    logic [7:0] led_lit;
    logic [2:0] rgb1_lit, rgb2_lit;

    assign pressed = KEY_ACTIVE_LOW ? ~key : key;
    assign reset_request = pressed[3];
    // Asynchronous assertion, synchronous deassertion of reset.
    // Press KEY4 once after programming; reset deliberately clears all credit.
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

    button_conditioner #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) insert_key (
        .clk(clk_12mhz), .rst(rst), .pressed_async(pressed[0]), .press_pulse(insert_pulse));
    button_conditioner #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) buy_key (
        .clk(clk_12mhz), .rst(rst), .pressed_async(pressed[1]), .press_pulse(buy_pulse));
    button_conditioner #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) cancel_key (
        .clk(clk_12mhz), .rst(rst), .pressed_async(pressed[2]), .press_pulse(cancel_pulse));

    vending_core #(.HOLD_CYCLES(HOLD_CYCLES)) core (
        .clk(clk_12mhz), .rst(rst),
        .product_select(sw_sync[1:0]), .coin_select(sw_sync[3:2]),
        .insert_pulse(insert_pulse), .buy_pulse(buy_pulse), .cancel_pulse(cancel_pulse),
        .credit(credit), .display_value(display_value), .dispense_led(dispense_led),
        .error_code(error_code), .ready(ready), .busy(busy), .state_debug(state_debug));

    // Constant division/modulo synthesize into combinational decimal conversion.
    // Values are bounded to 0..99, so each decimal digit fits in four bits.
    assign tens = 4'(display_value / 7'd10);
    assign ones = 4'(display_value % 7'd10);
    seven_segment #(.ACTIVE_LOW(SEG_ACTIVE_LOW)) tens_decoder (.digit(tens), .segments(seg_tens));
    seven_segment #(.ACTIVE_LOW(SEG_ACTIVE_LOW)) ones_decoder (.digit(ones), .segments(seg_ones));
    assign dp_tens = SEG_ACTIVE_LOW ? 1'b1 : 1'b0;
    assign dp_ones = SEG_ACTIVE_LOW ? 1'b1 : 1'b0;
    assign digit_tens = DIGIT_ACTIVE_LOW ? 1'b0 : 1'b1;
    assign digit_ones = DIGIT_ACTIVE_LOW ? 1'b0 : 1'b1;

    always_comb begin
        led_lit = '0;
        led_lit[2:0] = (state_debug == 3'd5) ? error_code : dispense_led;
        led_lit[3] = ready;
        led_lit[4] = (state_debug == 3'd3);
        led_lit[5] = (state_debug == 3'd4);
        led_lit[6] = (state_debug == 3'd5);
        led_lit[7] = busy;
        case (state_debug)
            3'd3: rgb1_lit = 3'b010; // Green: dispense
            3'd4: rgb1_lit = 3'b011; // Cyan: refund
            3'd5: rgb1_lit = 3'b100; // Red: error
            default: rgb1_lit = 3'b001; // Blue: waiting/checking
        endcase
        case (sw_sync[1:0])
            2'b00: rgb2_lit = 3'b100; // Selection A
            2'b01: rgb2_lit = 3'b010; // Selection B
            2'b10: rgb2_lit = 3'b001; // Selection C
            default: rgb2_lit = 3'b000;
        endcase
        led = LED_ACTIVE_LOW ? ~led_lit : led_lit;
        rgb1 = RGB_ACTIVE_LOW ? ~rgb1_lit : rgb1_lit;
        rgb2 = RGB_ACTIVE_LOW ? ~rgb2_lit : rgb2_lit;
    end
endmodule
