module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0,
	input i_key_1,
	input i_key_2,
	input i_key_3,
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT

	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// design the FSM and states as you like

parameter S_START      = 0;
parameter S_START_I2C  = 1;
parameter S_WAIT_I2C   = 2;
parameter S_IDLE       = 3;
parameter S_RECD       = 4;
parameter S_RECD_PAUSE = 5;
parameter S_PLAY       = 6;
parameter S_PLAY_PAUSE = 7;

logic [2:0] state_r, state_w;
logic [3:0] cnt_r, cnt_w;

localparam I_LEFT_LINE_IN  = 4'b0000;
localparam I_RIGHT_LINE_IN = 4'b0001;
localparam I_LEFT_PHONE_OUT = 4'b0010;
localparam I_RIGHT_PHONE_OUT = 4'b0011;
localparam I_ANALOG_PATH = 4'b0100;
localparam I_DIGITAL_PATH = 4'b0101;
localparam I_POWER_DOWN = 4'b0110;
localparam I_DIGITAL_FORMAT = 4'b0111;
localparam I_SAMPLE = 4'b1000;
localparam I_ACTIVE = 4'b1001;

logic i2c_start, i2c_started, i2c_oen, i2c_sdat, i2c_finished;
logic [3:0] i2c_type;
logic [19:0] addr_record, addr_play;
logic recorder_start, recorder_pause, recorder_stop;
logic [15:0] data_record, data_play, dac_data;
logic [7:0]  speed = 8'b00001000;
logic player_en, player_start, player_pause, player_stop;
logic ack_Ply2Dsp;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_start),
	.i_type(i2c_type),
	.o_start(i2c_started),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(player_start),
	.i_pause(player_pause),
	.i_stop(player_stop),
	.i_speed(speed),
	.i_fast(1'b0),
	.i_slow_0(1'b1), // constant interpolation
	.i_slow_1(1'b0), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.i_player_ack(ack_Ply2Dsp),
	//.i_initial_addr(initial_addr),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play),
	.o_player_en(player_en)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
// player will handle the segmentation of the bits of the data
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_en), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_ack(ack_Ply2Dsp),
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(recorder_start),
	.i_pause(recorder_pause),
	.i_stop(recorder_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);

always_comb begin
	// design your control here
	state_w = state_r;
	cnt_w = cnt_r;
	i2c_start = 0;
	i2c_type = 0;
	recorder_start = 0;
	recorder_pause = 0;
	recorder_stop = 0;
	player_start = 0;
	player_pause = 0;
	player_stop = 0;
	case (state_r)
		S_START: begin
			state_w = S_START_I2C;
			cnt_w = 0;
		end
		S_START_I2C: begin
			if (~i2c_finished) begin
				i2c_start = 1;
				i2c_type = cnt_r;
				if (i2c_started) begin
					state_w = S_WAIT_I2C;
				end
			end
		end
		S_WAIT_I2C: begin
			if (i2c_finished) begin
				if (cnt_r >= 9) begin
					state_w = S_IDLE;
					cnt_w = 0;
				end else begin
					cnt_w = cnt_r + 1;
					state_w = S_START_I2C;
				end
			end
		end
		S_IDLE: begin
			if (i_key_0) begin
				state_w = S_RECD;
				recorder_start = 1;
			end else if (i_key_1) begin
				state_w = S_PLAY;
				player_start = 1;
			end
		end
		S_RECD: begin
			recorder_start = 1;
			if (i_key_2) begin
				state_w = S_RECD_PAUSE;
				recorder_pause = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				recorder_stop = 1;
			end
		end
		S_RECD_PAUSE: begin
			recorder_pause = 1;
			if (i_key_0) begin
				state_w = S_RECD;
				recorder_start = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				recorder_stop = 1;
			end
		end
		S_PLAY: begin
			if (i_key_2) begin
				state_w = S_PLAY_PAUSE;
				player_pause = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				player_stop = 1;
			end
		end
		S_PLAY_PAUSE: begin
			if (i_key_1) begin
				state_w = S_PLAY;
				player_start = 1;
			end else if (i_key_3) begin
				state_w = S_IDLE;
				player_stop = 1;
			end
		end
	endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_START;
		cnt_r <= 0;
	end else begin
		state_r <= state_w;
		cnt_r <= cnt_w;
	end
end

endmodule

