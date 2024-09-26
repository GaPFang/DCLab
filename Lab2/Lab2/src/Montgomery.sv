module Montgomery (
    input          i_clk,
	input          i_rst,
	input          i_start,
    input  [255:0] i_N, i_a, i_b,
    output [255:0] o_motgomery,
    output         o_finished

);
    localparam S_IDLE = 1'b0;
    localparam S_CALC = 1'b1;
    localparam m_size = 4;
    localparam cycles = 256 / m_size;

    logic state, state_nxt;
    logic [257:0] m_r [0:m_size-1];
    logic [257:0] m_w [0:m_size-1];
    logic [255:0] N, a, b;
    logic [255:0] o_motgomery_r;
    logic o_finished
    integer cycle;
    integer i;

    always_comb begin
        state_nxt = state;
        N_w = i_N;
        a_w = i_a;
        b_w = i_b;
        case(state)
            S_IDLE: begin
                if(i_start) begin
                    state_nxt = S_CALC;
                end
            end
            S_CALC: begin
                if(cycle < cycles) begin
                    state_nxt = S_CALC;
                end else begin
                    state_nxt = S_IDLE;
                end
            end
        endcase
        for (i = 0; i < m_size; i = i + 1) begin
            m_w[i] = m_r[i];
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            m <= 0;
            state <= S_IDLE;
        end else begin
            state <= state_nxt;
            if (state == S_IDLE) begin
                for (i = 0; i < arr_size; i = i + 1) begin
                    m[i] <= 0;
                end
            end else begin
                for (i = 0; i < arr_size; i = i + 1) begin
                    m[i] <= m_w[i];
                end
            end
        end
    end

    
    
endmodule