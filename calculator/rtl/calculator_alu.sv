module calculator_alu (
    input  logic signed [3:0] a, b,
    input  logic [1:0] operation,
    output logic signed [6:0] value,
    output logic divide_by_zero
);
    import calc_types::*;
    always_comb begin
        divide_by_zero = 1'b0;
        case (operation)
            ADD: value = a + b;
            SUB: value = a - b;
            MUL: value = a * b;
            DIV: begin
                divide_by_zero = (b == 0);
                if (divide_by_zero) value = '0;
                else value = a / b;
            end
            default: value = '0;
        endcase
    end
endmodule
