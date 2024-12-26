module Top_Control(
    input i_Clk,
    input i_rst_n,
    input i_en,
    input i_alg_done,
    input [3:0][3:0][3:0] i_klotski,
    output [3:0][3:0][3:0] o_klotski,
    output o_start_alg,
    output o_done
);

logic [3:0][3:0][3:0] klotski_r, klotski_w;

logic done_r, done_w;
logic start_alg_r, start_alg_w;

assign o_klotski = klotski_r;
assign o_start_alg = start_alg_r;
assign o_done = done_r;

typedef enum logic [2:0] {
    S_IDLE = 3'b000,
    S_SEND = 3'b001,
    S_DONE = 3'b010
} state_t;

state_t state_r, state_w;

always_comb begin
    state_w = state_r;
    case (state_r)
        S_IDLE: begin
            if (i_en) begin
                state_w = S_SEND;
            end
        end

        S_SEND: begin
            if (i_alg_done) begin
                state_w = S_DONE;
            end
        end

        S_DONE: begin
            state_w = S_IDLE;
        end
    endcase
end

always_comb begin
    done_w = 0;
    start_alg_w = 0;
    klotski_w = klotski_r;
    case(state_r)
        S_IDLE: begin
            if (i_en) begin
                start_alg_w = 1;
                klotski_w = i_klotski;
            end
        end

        S_SEND: begin

        end

        S_DONE: begin
            done_w = 1;
        end
    endcase
end

always_ff @(posedge i_Clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        done_r <= 0;
        start_alg_r <= 0;
        state_r <= S_IDLE;
        klotski_r <= 0;
    end
    else begin
        done_r <= done_w;
        start_alg_r <= start_alg_w;
        state_r <= state_w;
        klotski_r <= klotski_w;
    end
end
endmodule
