package calc_types;
    typedef enum logic [2:0] {
        INPUT_A, SELECT_OP, INPUT_B, EVALUATE, SHOW_RESULT, ERROR
    } state_t;
    localparam logic [1:0] ADD = 2'b00, SUB = 2'b01, MUL = 2'b10, DIV = 2'b11;
endpackage
