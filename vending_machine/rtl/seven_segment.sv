module seven_segment #(
    parameter bit ACTIVE_LOW = 1'b1
) (
    input  logic [3:0] digit,
    output logic [6:0] segments // {a,b,c,d,e,f,g}
);
    logic [6:0] lit;
    always_comb begin
        case (digit)
            4'd0: lit = 7'b1111110;
            4'd1: lit = 7'b0110000;
            4'd2: lit = 7'b1101101;
            4'd3: lit = 7'b1111001;
            4'd4: lit = 7'b0110011;
            4'd5: lit = 7'b1011011;
            4'd6: lit = 7'b1011111;
            4'd7: lit = 7'b1110000;
            4'd8: lit = 7'b1111111;
            4'd9: lit = 7'b1111011;
            default: lit = 7'b0000000;
        endcase
        segments = ACTIVE_LOW ? ~lit : lit;
    end
endmodule
