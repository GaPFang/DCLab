module vga(
    input             i_clk,
    input             i_rst,
    
    // VGA port
    output reg [7:0]  VGA_R,
    output reg [7:0]  VGA_G,
    output reg [7:0]  VGA_B,
    output           VGA_HS,
    output           VGA_VS
);

    typedef enum logic [1:0] { 
        S_H_A,
        S_H_B,
        S_H_C,
        S_H_D
    } state_hor_t;

    typedef enum logic [1:0] { 
        S_V_A,
        S_V_B,
        S_V_C,
        S_V_D
    } state_ver_t;

    state_hor_t state_hor_r, state_hor_w;
    state_ver_t state_ver_r, state_ver_w;

    logic [10:0] h_cnt_r, h_cnt_w;
    logic [8:0] v_cnt_r, v_cnt_w;

    logic [10:0] color_cnt_r, color_cnt_w;
    
    assign VGA_HS = (state_hor_r == S_H_A) ? 1'b0 : 1'b1;
    assign VGA_VS = (state_ver_r == S_V_A) ? 1'b0 : 1'b1;

    always_comb begin
        state_hor_w = state_hor_r;
        state_ver_w = state_ver_r;
        h_cnt_w = h_cnt_r + 1;
        v_cnt_w = v_cnt_r;
        color_cnt_w = color_cnt_r;
        VGA_R = 4'b0000;
        VGA_G = 4'b0000;
        VGA_B = 4'b0000;
        case (state_hor_r)
            S_H_A: begin
                if (h_cnt_r == 10'd189) begin // 190
                    state_hor_w = S_H_B;
                    h_cnt_w = 8'd0;
                end
            end
            S_H_B: begin
                if (h_cnt_r == 10'd94) begin  // 95
                    state_hor_w = S_H_C;
                    h_cnt_w = 8'd0;
                end
            end
            S_H_C: begin
                if (state_ver_r == S_V_C) begin
                    // VGA_R = {4{color_cnt_r[10]}};
                    // VGA_G = {4{color_cnt_r[9]}};
                    // VGA_B = {4{color_cnt_r[8]}};
						  VGA_R = 8'hFF;
						  VGA_G = 0;
						  VGA_B = 0;
                    color_cnt_w = color_cnt_r + 1;
                end
                if (h_cnt_r == 11'd1269) begin // 1270
                    state_hor_w = S_H_D;
                    h_cnt_w = 8'd0;
                end
            end
            S_H_D: begin
                if (h_cnt_r == 10'd29) begin  // 30
                    state_hor_w = S_H_A;
                    h_cnt_w = 8'd0;
                    v_cnt_w = v_cnt_r + 1;
                    case (state_ver_r)
                        S_V_A: begin
                            if (v_cnt_r == 10'd1) begin
                                state_ver_w = S_V_B;
                                v_cnt_w = 9'd0;
                            end
                        end
                        S_V_B: begin
                            if (v_cnt_r == 10'd32) begin
                                state_ver_w = S_V_C;
                                v_cnt_w = 9'd0;
                            end
                        end
                        S_V_C: begin
                            if (v_cnt_r == 10'd479) begin
                                state_ver_w = S_V_D;
                                v_cnt_w = 9'd0;
                            end
                        end
                        S_V_D: begin
                            if (v_cnt_r == 10'd9) begin
                                state_ver_w = S_V_A;
                                v_cnt_w = 9'd0;
                            end
                        end
                    endcase
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (~i_rst) begin
            state_hor_r <= S_H_A;
            state_ver_r <= S_V_A;
            h_cnt_r <= 8'd0;
            v_cnt_r <= 9'd0;
            color_cnt_r <= 11'd0;
        end else begin
            state_hor_r <= state_hor_w;
            state_ver_r <= state_ver_w;
            h_cnt_r <= h_cnt_w;
            v_cnt_r <= v_cnt_w;
            color_cnt_r <= color_cnt_w;
        end
    end

endmodule
