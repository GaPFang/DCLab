module AudDSP(
	input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,
	input [7:0] i_speed,
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	inout i_daclrck,
	input i_sram_data,
	//input [19:0] i_initial_addr,
	output [15:0] o_dac_data,
	output [19:0] o_sram_addr
);

//parameters

//speed definition
localparam x8 =     8'b01000000;
localparam x4 =     8'b00100000;
localparam x2 =     8'b00010000;
localparam x1 =     8'b00001000;
localparam x0_5 =   8'b00000100;
localparam x0_25 =  8'b00000010;
localparam x0_125 = 8'b00000001;
//

//address
localparam START_ADDR = 20'b0;
//
//

//state enumeration
typedef enum logic [2:0] {
    S_IDLE     = 3'b000,
    S_READMEM_AND_PLAY = 3'b001,
    S_PAUSE = 3'b011;
    S_STOP = 3'b100;
} state_t;

state_t state_r, state_w;
//

//any register and wire
logic signed [15:0] o_processed_data_r, o_processed_data_w;
logic signed [19:0] temp_data1, temp_data2;
logic signed [15:0] old_data_r, old_data_w;
logic [19:0] o_sram_addr_r, o_sram_addr_w;
logic daclrck_prev;
logic transmission_en_r, transmission_en_w;
logic [7:0] speed_r, speed_w;
logic [5:0] cnt, cnt_nxt;
//

//assign
assign o_dac_data = o_processed_data_r;
assign o_sram_addr = o_sram_addr_r;
//

//combinational part

//FSM Behavior
always_comb begin
    state_w = state_r;
    o_sram_addr_w = o_sram_addr_r;
    transmission_en_w = 0; 
    speed_w = speed_r;
    cnt_nxt = 0;
    old_data_w = old_data_r;
    o_processed_data_w = o_processed_data_r;
    case (state_r)
        S_IDLE: begin
            if (i_start) begin
                state_w = S_READMEM_AND_PLAY;
            end
            //TODO: reset address 
            o_sram_addr_w = START_ADDR;
        end

        S_READMEM_AND_PLAY:begin
            if (i_pause) begin
                state_w = S_PAUSE;
                //and the output address is still held
            end

            if (i_stop) begin
                state_w = S_STOP;
            end

            //wait until LRC transition
            //we choose the left channel for transmission
            if ((daclrck_prev == 1) && (i_daclrck == 0)) begin
                transmission_en_w = 1;
            end

            //start transmitting aud data
            if (transmission_en_r) begin
                //we handle the playspeed by sending address with different interval
                case(speed_r)
                    x8: begin
                        //address has been delivered to SRAM
                        o_processed_data_w = $signed(i_sram_data);//data will be segmented in player
                        o_sram_addr_w = o_sram_addr_r + 20'd8;
                        transmission_en_w = 0;
                    end

                    x4: begin
                        o_processed_data_w = $signed(i_sram_data);//data will be segmented in player
                        o_sram_addr_w = o_sram_addr_r + 20'd4;
                        transmission_en_w = 0;
                    end

                    x2: begin
                        o_processed_data_w = $signed(i_sram_data);//data will be segmented in player
                        o_sram_addr_w = o_sram_addr_r + 20'd2;
                        transmission_en_w = 0;
                    end

                    x1: begin
                        o_processed_data_w = $signed(i_sram_data);//data will be segmented in player
                        o_sram_addr_w = o_sram_addr_r + 20'd1;
                        transmission_en_w = 0;
                    end

                    x0_5: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 1) begin
                                cnt_nxt = 0;
                                o_sram_addr_w = o_sram_addr_r + 20'd1;
                            end else begin
                                cnt_nxt = 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                cnt_nxt = 0;
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data) + $signed(o_processed_data_r);// new data + old data
                                temp_data2 = $signed(temp_data1) >> 1;
                                o_processed_data_w = temp_data2[15:0];
                            end else begin
                                cnt_nxt = 1;
                                o_sram_addr_w = o_sram_addr_r + 20'd1;
                                o_processed_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end

                    x0_25: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 3) begin
                                cnt_nxt = 0;
                                o_sram_addr_w = o_sram_addr_r + 20'd1;
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 3) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(4'sd04 - cnt);// new data + old data
                                temp_data2 = $signed(temp_data1) >> 2;
                                o_processed_data_w = temp_data2[15:0];
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                o_sram_addr_w = o_sram_addr_r + 20'd1;
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end

                    x0_125: begin
                        if (i_slow_0 && !i_slow_1) begin //0 interpolation
                            o_processed_data_w = $signed(i_sram_data);
                            if (cnt >= 7) begin
                                cnt_nxt = 0;
                                o_sram_addr_w = o_sram_addr_r + 20'd1;
                            end else begin
                                cnt_nxt = cnt + 1;
                                o_sram_addr_w = o_sram_addr_r;
                            end
                        end
                        else if (!i_slow_0 && i_slow_1) begin //1 interpolation
                            if (cnt >= 1) begin
                                if (cnt >= 7) begin
                                    cnt_nxt = 0;
                                end else begin
                                    cnt_nxt = cnt + 1;
                                end
                                
                                o_sram_addr_w = o_sram_addr_r;
                                temp_data1 = $signed(i_sram_data)*$signed(cnt) + $signed(old_data_r)*(4'sd08 - cnt);// new data + old data
                                temp_data2 = $signed(temp_data1) >> 3;
                                o_processed_data_w = temp_data2[15:0];
                            end else begin //cnt == 0
                                cnt_nxt = 1;
                                o_sram_addr_w = o_sram_addr_r + 20'd1;
                                o_processed_data_w = $signed(i_sram_data);
                                old_data_w = $signed(i_sram_data);
                            end
                        end
                        transmission_en_w = 0;
                    end
                endcase
            end
        end

        S_PAUSE: begin
            state_w = S_READMEM_AND_PLAY;
            //start from the same address as before in the next cycle
        end

        S_STOP: begin
            state_w = S_IDLE;
            
        end
        //default: 
    endcase
end
//
//
//sequential part
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_processed_data_r <= 0;
        o_sram_addr_r <= 0;
        daclrck_prev <= 0;
        transmission_en_r <= 0;
        speed_r <= 0;
        cnt <= 0;
        old_data_r <= 0;
	end
	else begin
        o_processed_data_r <= o_processed_data_w;
		o_sram_addr_r <= o_sram_addr_w;
        daclrck_prev <= i_daclrck;
        transmission_en_r <= transmission_en_w;
        if(state_r == S_IDLE) begin
            speed_r <= i_speed;
        end else begin
            speed_r <= speed_w;
        end
        cnt <= cnt_nxt;
        old_data_r <= old_data_w;
	end
end
//
endmodule