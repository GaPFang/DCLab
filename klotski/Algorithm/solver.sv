module Solver (
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_ready,
    
    output [4:0] o_pos [0:1];
    output [1:0] o_direction;
    output o_en;
);

    typedef enum logic [2:0] { 
        IDLE = 3'b000,
        INIT = 3'b001,
        SEARCH = 3'b010,
        MOVE = 3'b011,
        FINISH = 3'b100
    } state_t;

    logic [4:0] klotski_r [1:0][1:0], klotski_w [1:0][1:0];
    assign o_klotski = klotski_r;

    logic [5:0] cnt_r, cnt_w;
    state_t state_r, state_w;

    always_comb begin
        klotski_w = klotski_r;
        cnt_w = cnt_r;
    end

    

endmodule