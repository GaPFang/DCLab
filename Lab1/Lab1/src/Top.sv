module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);
// ===== States =====
parameter S_IDLE = 1'b0;
parameter S_PROC = 1'b1;

//Registers and Wires
//state
logic state_r, state_w;

//output
logic [3:0] o_random_out_r, o_random_out_w;

//counter for output speed
logic [24:0] cnt, cnt_nxt;
logic [3:0] cnt_small, cnt_small_nxt;

//counter
always_comb begin
	if(cnt == {25{1'b1}})
		cnt_nxt = 25'b0;
	else 
		cnt_nxt = cnt + 1;
	
end

//FSM

always_comb begin
	//Default
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	 
	// FSM
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			state_w = S_PROC;
			o_random_out_w = 4'd15;
		end
	end

	S_PROC: begin
		if (i_start) begin
			state_w = (cnt_small == 4'd15) ? S_IDLE : state_w;
			case (cnt_small)
			
			o_random_out_w = (o_random_out_r == 4'd10) ? 4'd1 : (o_random_out_r - 4'd1);
		end
	end

	endcase
end

// please check out the working example in lab1 README (or Top_exmaple.sv) first
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		state_r <= S_IDLE;
	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
	end
end
endmodule