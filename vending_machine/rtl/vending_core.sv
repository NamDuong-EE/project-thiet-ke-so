// Transaction controller. All inputs are synchronous; events last one clock.
module vending_core #(
    parameter integer HOLD_CYCLES = 24_000_000
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] product_select, // 00=A (5), 01=B (10), 10=C (15)
    input  logic [1:0] coin_select,    // 00=1, 01=2, 10=5, 11=invalid
    input  logic       insert_pulse,
    input  logic       buy_pulse,
    input  logic       cancel_pulse,
    output logic [6:0] credit,
    output logic [6:0] display_value,
    output logic [2:0] dispense_led,
    output logic [2:0] error_code,
    output logic       ready,
    output logic       busy,
    output logic [2:0] state_debug
);
    typedef enum logic [2:0] {
        IDLE = 3'd0, ACCEPT_MONEY = 3'd1, CHECK = 3'd2,
        DISPENSE = 3'd3, REFUND = 3'd4, ERROR = 3'd5
    } state_t;
    localparam integer TIMER_WIDTH = (HOLD_CYCLES > 1) ? $clog2(HOLD_CYCLES) : 1;
    localparam logic [2:0] ERR_NONE = 3'd0, ERR_PRODUCT = 3'd1,
        ERR_COIN = 3'd2, ERR_FUNDS = 3'd3, ERR_OVERFLOW = 3'd4;

    state_t state, next_state;
    logic [TIMER_WIDTH-1:0] hold_count;
    logic timed_state, hold_done;
    logic [1:0] selected_product;
    logic [6:0] price, refund_amount;
    logic [2:0] coin_value;
    logic [7:0] added_credit;

    // Combinational datapath: price lookup, coin decoder, adder, comparator.
    always_comb begin
        case (selected_product)
            2'b00: price = 7'd5;
            2'b01: price = 7'd10;
            2'b10: price = 7'd15;
            default: price = 7'd0;
        endcase
        case (coin_select)
            2'b00: coin_value = 3'd1;
            2'b01: coin_value = 3'd2;
            2'b10: coin_value = 3'd5;
            default: coin_value = 3'd0;
        endcase
    end
    assign added_credit = {1'b0, credit} + {5'b0, coin_value};
    assign timed_state = (state == DISPENSE || state == REFUND || state == ERROR);
    assign hold_done = (hold_count == HOLD_CYCLES - 1);

    // Event priority when ready: cancel > buy > insert.
    always_comb begin
        next_state = state;
        case (state)
            IDLE, ACCEPT_MONEY: begin
                if (cancel_pulse) begin
                    if (credit != 0) next_state = REFUND;
                    else next_state = IDLE;
                end else if (buy_pulse)
                    next_state = CHECK;
                else if (insert_pulse) begin
                    if (coin_select == 2'b11 || added_credit > 8'd99) next_state = ERROR;
                    else next_state = ACCEPT_MONEY;
                end
            end
            CHECK: begin
                if (selected_product == 2'b11 || credit < price)
                    next_state = ERROR;
                else
                    next_state = DISPENSE;
            end
            DISPENSE: if (hold_done) begin
                if (refund_amount != 0) next_state = REFUND;
                else next_state = IDLE;
            end
            REFUND: if (hold_done) next_state = IDLE;
            ERROR: if (hold_done) begin
                if (credit != 0) next_state = ACCEPT_MONEY;
                else next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // State register and transaction registers.
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            hold_count <= '0;
            credit <= 7'd0;
            refund_amount <= 7'd0;
            selected_product <= 2'b00;
            error_code <= ERR_NONE;
        end else begin
            state <= next_state;
            if (state != next_state || !timed_state)
                hold_count <= '0;
            else if (!hold_done)
                hold_count <= hold_count + 1'b1;

            case (state)
                IDLE, ACCEPT_MONEY: begin
                    error_code <= ERR_NONE;
                    if (cancel_pulse) begin
                        refund_amount <= credit;
                        credit <= 7'd0;
                    end else if (buy_pulse) begin
                        // Freeze the product for the complete transaction.
                        selected_product <= product_select;
                    end else if (insert_pulse) begin
                        if (coin_select == 2'b11)
                            error_code <= ERR_COIN;
                        else if (added_credit > 8'd99)
                            error_code <= ERR_OVERFLOW;
                        else
                            credit <= added_credit[6:0];
                    end
                end
                CHECK: begin
                    if (selected_product == 2'b11)
                        error_code <= ERR_PRODUCT;
                    else if (credit < price)
                        error_code <= ERR_FUNDS;
                    else begin
                        refund_amount <= credit - price;
                        credit <= 7'd0;
                    end
                end
                REFUND: if (hold_done) refund_amount <= 7'd0;
                ERROR: if (hold_done) error_code <= ERR_NONE;
                default: begin end
            endcase
        end
    end

    always_comb begin
        ready = (state == IDLE || state == ACCEPT_MONEY);
        busy = !ready;
        state_debug = state;
        display_value = credit;
        dispense_led = 3'b000;
        if (state == DISPENSE) begin
            display_value = price;
            case (selected_product)
                2'b00: dispense_led = 3'b001;
                2'b01: dispense_led = 3'b010;
                2'b10: dispense_led = 3'b100;
                default: dispense_led = 3'b000;
            endcase
        end else if (state == REFUND)
            display_value = refund_amount;
    end
endmodule
