module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

	// operations for RSA256 decryption
	// namely, the Montgomery algorithm

	localparam S_IDLE = 2'd0;
	localparam S_PREP = 2'd1;
	localparam S_MONT = 2'd2;
	localparam S_CALC = 2'd3;

	logic [1:0] state, state_nxt;
	logic [8:0] cnt, cnt_nxt;
	logic [255:0] o_a_pow_d_r, o_a_pow_d_o_finished_r;
	logic [255:0] m_w, t_w;
	logic [255:0] m_r, t_r;
	logic [255:0] N, d, a;
	logic Mont_finish, Mont_fin_m, Mont_fin_t;
	logic Mont_ready, Prep_ready, Prep_finish;
	
	Montgomery Montgomery_m(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(Mont_ready),
		.o_motgomery(m_w),
		.N(N),
		.a(m_r),
		.b(t_r),
		.o_finished(Mont_finish_m)
	);
	Montgomery Montgonery_t(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_ready(Mont_ready),
		.o_motgomery(t_w),
		.N(N),
		.a(t_r),
		.b(t_r),
		.o_finished(Mont_finish_t)
	);

	ModuloProduct ModuloProduct0(
		
		.done(Prep_finish)
	);

	assign Mont_finish = Mont_fin_t && Mont_fin_m;
	assign Mont_ready = (state == S_CALC)

	// Counter
	always_comb begin
		cnt_nxt = cnt;
		if(state == S_CALC) begin
			if(cnt != 257)	cnt_nxt = cnt + 1;
			else	cnt_nxt = 0;
		end
	end

	// FSM
	always_comb begin
		state_nxt = state;
		case(state)
			S_IDLE: begin
				if(i_start)	state_nxt = S_PREP;
			end
			S_PREP: begin
				if(Prep_ready) state_nxt = S_CAL;
			end
			S_MONT: begin
				if(Mont_finish)	state_nxt = S_CALC;
			end
			S_CALC: begin
				if(cnt != 257)
					state_nxt = S_MONT;
				else state_nxt = S_IDLE;
			end
		endcase
	end

	assign o_a_pow_d = o_a_pow_d_r;
	assign o_finished = o_finished_r;

	function [255:0] montgomery;
		input [255:0] N, a, b;
		logic   [257:0] m;
		integer i;
		begin
			m = 0;
			for (i = 0; i < 256; i = i + 1) begin
				if (a[0] == 1) begin
					m = m + b;
				end
				if (m[0] == 1) begin
					m = m + N;
				end
				m = m >> 1;
				a = a >> 1;
			end
			if (m >= N) begin
				m = m - N;
			end
			montgomery = m;
		end

	endfunction

	function [255:0] RSA256;
		input [255:0] N, y, d;
		logic [255:0] t, m;
		integer i;
		begin
			for (i = 0; i < 256; i = i + 1) begin
				if (d[i] == 1) begin
					m = montgomery(N, m, t);
				end
				t = montgomery(N, t, t);
			end
			RSA256 = m;
		end
		
	endfunction
	
/*
	function [255:0] ModuloProduct;
		input [255:0] N, a, b, k;
		logic [255:0] t, m;
		integer i;

		t = b;
		m = 0;

		begin
			for (i = 0; i <= k; i = i + 1) begin
				if (a[i]) begin
					if ((m + t) >= N) m = m + t - N;
					else m = m + t;
				end

				if ((t << 2) >= N) begin
					t = t << 2;
					t = t - N;
				end
				else begin
					t = t << 2;
				end
			end
			ModuloProduct = m;
		end
		
	endfunction
	*/	
	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			o_a_pow_d <= 0;
			o_finished <= 0;
			cnt <= 0;
			state <= S_IDLE;
			m_r <= 0;
			t_r <= 0;
		end else begin
			o_finished <= 0;
			if (state == S_IDLE && i_start) begin
				o_a_pow_d_r <= RSA256(i_n, i_a, i_d);
				o_finished_r <= 1;
			end
			cnt <= cnt_nxt;
			state <= state_nxt;
			if(Mont_finish) begin
				m_r <= m_w;
				t_r <= t_w;
			end
			if(Prep_finish) begin
				m_r <= 1;
				t_r <= 
			end
		end
	end

endmodule



module ModuloProduct (
    input logic clk,               // 時鐘
    input logic rst_n,             // 重置訊號（低電位有效）
    input logic start,             // 啟動信號
    input [255:0] N,               // 輸入參數 N
    input [255:0] a,               // 輸入參數 a
    input [255:0] b,               // 輸入參數 b
    input integer k,               // 迴圈次數 k
    output logic [255:0] result,   // 結果輸出
    output logic done              // 完成信號
);
    logic [255:0] t, m;
    integer i;
    logic [1:0] state;             // 狀態變數
    logic [255:0] temp_m, temp_t;  // 用於暫存每次迴圈中的 m 和 t 更新
	logic start_flag = 0;

	always_comb begin
		if (start) begin
			start_flag = 1;
		end
		else if (state == 2) begin
			start_flag = 0;
		end
		else begin
			start_flag = start_flag + 0;
		end
	end

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            t = 0;
            m = 0;
            i = 0;
            state = 0;
            done = 0;
			temp_m = 0;
			temp_t = 0;
        end 
		else begin
			if (start_flag) begin
				case (state)
					0: begin
						// 初始化
						t = b;
						m = 0;
						i = 0;
						state = 1;

					end
					1: begin
						// 每個時鐘週期處理 4 次迴圈運算
						if (i <= k - 4) begin
							temp_m = m;
							temp_t = t;

							// 處理 i, i+1, i+2, i+3
							for (int j = 0; j < 4; j = j + 1) begin
								if (a[i + j]) begin
									if ((temp_m + temp_t) >= N) 
										temp_m = temp_m + temp_t - N;
									else 
										temp_m = temp_m + temp_t;
								end

								if ((temp_t << 2) >= N) begin
									temp_t = (temp_t << 2) - N;
								end else begin
									temp_t = temp_t << 2;
								end
							end

							// 更新 m 和 t
							m = temp_m;
							t = temp_t;

							// 更新迴圈變數
							i = i + 4;
						end else begin
							m = m + 0;
							i = i + 0;
							state = 2;
						end
					end
					2: begin
						// 完成運算
						result = m;
						done = 1;
						state = 0;
						start_flag = 0;
					end
				endcase
			end
			else begin
				result = m;
				done = 0;
				start = 0;
				start_flag = 0;
				i = 0;
				temp_m = 0;
				temp_t = 0;
				t = 0;
			end
        end
    end
endmodule
