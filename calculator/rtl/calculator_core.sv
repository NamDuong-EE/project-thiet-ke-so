module calculator_core (
    input  logic clk, rst,
    input  logic [3:0] switches,
    input  logic confirm, clear_entry, back,
    output calc_types::state_t state,
    output logic [1:0] display_op,
    output logic [5:0] magnitude,
    output logic negative
);
    import calc_types::*;
    state_t next_state;
    logic signed [3:0] entry, a, b;
    logic signed [6:0] value, result, display_number;
    logic [1:0] operation;
    logic divide_by_zero;

    // The switches encode sign and magnitude; the datapath uses two's complement.
    assign entry = switches[3] ? -$signed({1'b0, switches[2:0]})
                               :  $signed({1'b0, switches[2:0]});
    calculator_alu alu (.a(a), .b(b), .operation(operation),
                        .value(value), .divide_by_zero(divide_by_zero));

    always_comb begin
        next_state = state;
        if (clear_entry) next_state = INPUT_A;
        else if (back) begin
            case (state)
                SELECT_OP: next_state = INPUT_A;
                INPUT_B: next_state = SELECT_OP;
                SHOW_RESULT, ERROR: next_state = INPUT_B;
                EVALUATE: next_state = divide_by_zero ? ERROR : SHOW_RESULT;
                default: next_state = state;
            endcase
        end else begin
            case (state)
                INPUT_A: if (confirm) next_state = SELECT_OP;
                SELECT_OP: if (confirm) next_state = INPUT_B;
                INPUT_B: if (confirm) next_state = EVALUATE;
                EVALUATE: next_state = divide_by_zero ? ERROR : SHOW_RESULT;
                SHOW_RESULT, ERROR: if (confirm) next_state = INPUT_A;
                default: next_state = INPUT_A;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (rst || clear_entry) begin
            state <= INPUT_A;
            a <= '0;
            b <= '0;
            operation <= ADD;
            result <= '0;
        end else begin
            state <= next_state;
            if (confirm && !back) begin
                case (state)
                    INPUT_A: a <= entry;
                    SELECT_OP: operation <= switches[1:0];
                    INPUT_B: b <= entry;
                    default: begin end
                endcase
            end
            if (state == EVALUATE && !divide_by_zero) result <= value;
        end
    end

    always_comb begin
        display_op = (state == SELECT_OP) ? switches[1:0] : operation;
        case (state)
            INPUT_A, INPUT_B: display_number = $signed(entry);
            SELECT_OP: display_number = $signed({5'b0, display_op});
            SHOW_RESULT: display_number = result;
            default: display_number = '0;
        endcase
        negative = display_number[6];
        magnitude = negative ? 6'(-display_number) : display_number[5:0];
    end
endmodule
