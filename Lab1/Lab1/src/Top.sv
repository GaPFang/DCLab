module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);

LFSR LFSR0(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_start(LFSR_start),
	.o_random_out(o_random_out_LFSR)
);

// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

//Registers and Wires
//state
logic state_r, state_w;

//output
logic [3:0] o_random_out_r, o_random_out_w, o_random_out_LFSR;

//counter for output speed
logic [24:0] cnt, cnt_nxt;
logic [7:0] cnt_small, cnt_small_nxt;
logic LFSR_start, LFSR_start_nxt;

//counter
always_comb begin
	if(cnt == {25{1'b1}}) begin
		cnt_nxt = 25'b0;
		cnt_small_nxt = cnt_small + 1;
	end
	else 
		cnt_nxt = cnt + 1;
end

//FSM

always_comb begin
	//Default
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	LFSR_start_nxt = 1'b0
	 
	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			// key0 is pressed
			state_w = S_PROC;
			//o_random_out_w = 4'd00;
		end
	end

	S_PROC: begin
		if (i_start) begin
			state_w = (cnt_small == 8'd55) ? S_IDLE : state_r;
			o_random_out_w = o_random_out_LFSR;
			case (cnt_small)
				8'd01, 8'd03, 8'd06, 8'd10, 8'd15, 8'd21, 8'd28, 8'd36, 8'd45, 8'd55: LFSR_start_nxt = 1'b1;
				default: LFSR_start_nxt = 1'b0;
			endcase
		end
	end

	endcase
end

// please check out the working example in lab1 README (or Top_exmaple.sv) first
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		state_r <= S_IDLE;
		cnt <= 25'd0;
		cnt_small <= 8'd0;
		LFSR_start <= 1'b0;
	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
		cnt <= cnt_nxt;
		cnt_small <= cnt_small_nxt;
		LFSR_start <= LFSR_start_nxt;
	end
end
endmodule