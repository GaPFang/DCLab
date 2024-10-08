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

	localparam S_IDLE = 3'd0;
	localparam S_PREP = 3'd1;
	localparam S_MONT = 3'd2;
	localparam S_CALC = 3'd3;
	localparam S_DONE = 3'd4;

	logic [2:0] state, state_nxt;
	logic [8:0] cnt, cnt_nxt;
	logic [255:0] o_a_pow_d_r, o_a_pow_d_o_finished_r;
	logic [255:0] m_w, t_w;
	logic [255:0] m_r, t_r;
	logic [255:0] m_mont, t_mont, t_prep;	// output of m, t from mont and prep
	logic [255:0] N, d, a;	// loaded data
	logic [255:0] N_nxt, d_nxt, a_nxt;
	logic Mont_finish, Mont_finish_m, Mont_finish_t, Prep_finish; // finished signal from mont and prep
	logic Mont_ready, Prep_ready;	// ready signal for mont and prep
	logic [7:0] i_d_index; // 
	logic start_flag, start_flag_nxt;
	
	
	Montgomery Montgomery_m(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(Mont_ready),
		.o_montgomery(m_mont),
		.i_N(N),
		.i_a(m_r),
		.i_b(t_r),
		.o_finished(Mont_finish_m)
	);
	Montgomery Montgonery_t(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.i_start(Mont_ready),
		.o_montgomery(t_mont),
		.i_N(N),
		.i_a(t_r),
		.i_b(t_r),
		.o_finished(Mont_finish_t)
	);

	ModuloProduct ModuloProduct0(
		.clk(i_clk),
		.rst_n(i_rst),
		.start(Prep_ready),
		.N({1'b0, N}),
		.a({1'b1, 256'b0}),
		.b({1'b0, a}),
		.k(11'd256),
		.result(t_prep),
		.done(Prep_finish)
	);

	assign Mont_finish = Mont_finish_t && Mont_finish_m;
	assign Mont_ready = (state == S_MONT && start_flag);
	assign Prep_ready = (state == S_PREP && start_flag);
	// assign i_d_index = (cnt > 0)? (256-cnt): 0;
	assign i_d_index = cnt>0? cnt-1: 0;
	assign o_a_pow_d = (state == S_DONE)? m_r: 0;
	assign o_finished = (state == S_DONE);

	// Counter
	always_comb begin
		cnt_nxt = cnt;
		if(state == S_CALC) begin
			if(cnt != 256)	cnt_nxt = cnt + 1;
			else	cnt_nxt = 0;
		end
	end

	// FSM
	always_comb begin
		state_nxt = state;
		start_flag_nxt = 0;
		case(state)
			S_IDLE: begin
				if(i_start)	begin
					state_nxt = S_PREP;
					start_flag_nxt = 1;
				end
			end
			S_PREP: begin
				if(Prep_finish) state_nxt = S_CALC;
			end
			S_MONT: begin
				if(Mont_finish)	state_nxt = S_CALC;
			end
			S_CALC: begin
				if(cnt != 256) begin
					state_nxt = S_MONT;
					start_flag_nxt = 1;
				end
					
				else state_nxt = S_DONE;
			end
			S_DONE: begin
				state_nxt = S_IDLE;
			end
		endcase
	end


	// load data
	always_comb begin
		N_nxt = N;
		a_nxt = a;
		d_nxt = d;
		if(i_start && state == S_IDLE) begin
			N_nxt = i_n;
			a_nxt = i_a;
			d_nxt = i_d;
		end
	end
	
	// update t, m
	always_comb begin
		m_w = m_r;
		t_w = t_r;
		if(state == S_PREP && Prep_finish) begin
			m_w = 1;
			t_w = t_prep;
		end
		else if(state == S_MONT && Mont_finish) begin
			if(d[i_d_index] == 1'b1)
				m_w = m_mont;
			t_w = t_mont;
		end
	end

	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			cnt <= 0;
			state <= S_IDLE;
			m_r <= 0;
			t_r <= 0;
			N <= 0;
			a <= 0;
			d <= 0;
			start_flag <= 0;
		end else begin
			cnt <= cnt_nxt;
			state <= state_nxt;
			N <= N_nxt;
			a <= a_nxt;
			d <= d_nxt;
			m_r <= m_w;
			t_r <= t_w;
			start_flag <= start_flag_nxt;
		end
	end

endmodule


/*
module ModuloProduct (
    input  clk,               // 時鐘
    input  rst_n,             // 重置訊號（低電位有效）
    input  start,             // 啟動信號
    input [255:0] N,               // 輸入參數 N
    input [255:0] a,               // 輸入參數 a
    input [255:0] b,               // 輸入參數 b
    input [10:0] k,               // 迴圈次數 k
    output [255:0] result,   // 結果輸出
    output done              // 完成信號
);
    logic [256:0] t, m;
    logic [10:0] i;
    logic [1:0] state, state_nxt;             // 狀態變數
    //logic [256:0] temp_m, temp_t;  // 用於暫存每次迴圈中的 m 和 t 更新
	logic start_flag = 0;
	logic [256:0] comp;

	localparam S_IDLE = 2'b00;
	localparam S_CALC = 2'b01;
	localparam S_DONE = 2'b10;

	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			start_flag <= 0;
		end
		else begin 
			if (start) begin
				start_flag <= 1;
			end
			else if ((state == 2) || (state == 0)) begin
				start_flag <= 0;
			end
			else begin
				start_flag <= 1;
			end
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= 0;
		end
		else begin 
			state <= state_nxt;
		end
	end


	always_comb begin
		state_nxt = state;
		if (state == S_CALC) begin
			//所有計算
			t = {1'b0,b};
			m = 257'b0;
			for (i = 0; i <= k; i = i + 1) begin
				if(a[i]) begin
					comp = m + t;
					if (comp >= N) begin
						m = m + t - N;
					end
					else begin
						m = m + t;
					end
				end
				else begin
					m = m + 0;
					comp = 0;
				end

				comp = t << 1;
				if (comp >= N) begin
					t = t + t - N
				end
				else begin
					t = t << 1;
				end
			end
			done = 0;
			state_nxt = S_DONE;
			result = m;
		end
		else if (state == S_DONE) begin
			//可以輸出結果
			done = 1;
			m = m + 0;
			t = 0;
			comp = 0;
			state_nxt = S_IDLE;
			result = m[255:0];
		end
		else begin // state == S_IDLE
			//全部設為0
			done = 0;
			m = 0;
			t = 0;
			comp = 0;
			result = 0;
			if (start_flag) begin
				state_nxt = S_CALC;
			end
			else begin
				state_nxt = S_IDLE;
			end
		end
	end
	
endmodule
*/

/*
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
	*/

/*
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
    integer i = 0;

endmodule
*/