module AudRecorder(
  input i_rst_n,
  input i_clk,
  input i_lrc,  // left/right channel
  input i_start,
  input i_pause,
  input i_stop,
  input i_data,
  output [19:0] o_address,
  output [15:0] o_data
);
  // FSM states
  localparam S_IDLE = 2'd0;
  localparam S_RECORD = 2'd1;
  localparam S_PAUSE = 2'd2;
  localparam S_WAIT = 2'd3; // wait for the next lrc right channel (lrc = high)
  
  logic [3:0] cnt, cnt_nxt;
  logic [19:0] addr, addr_nxt;
  logic [15:0] data, data_nxt;
  logic [1:0] state, state_nxt;

  integer i;

  // FSM
  always_comb begin
    state_nxt = state;
    case(state) // Synopsys parallel_case
      S_IDLE: begin
        if (i_start) 
          state_nxt = S_RECORD;
      end
      S_RECORD: begin
        if (i_pause) 
          state_nxt = S_PAUSE;
        else if (i_stop) 
          state_nxt = S_IDLE;
        else if (cnt == 15) 
          state_nxt = S_WAIT;
      end
      S_WAIT: begin
        if (i_lrc) 
          state_nxt = S_RECORD;
        else if (i_stop) 
          state_nxt = S_IDLE;
      end
      S_PAUSE: begin
        if (i_start) 
          state_nxt = S_RECORD;
        else if (i_stop) 
          state_nxt = S_IDLE;
      end
    endcase
  end

  // Counter
  always_comb begin
    cnt_nxt = cnt;
    addr_nxt = addr;
    data_nxt = data;
    case(state) // Synopsys parallel_case
      S_IDLE: begin
        cnt_nxt = 0;
        data_nxt = 0;
      end
      S_RECORD: begin
        // store data from small address to large address
        for(i = 0; i < 16; i = i + 1) begin
          if(i == cnt)  
            data_nxt[i] = i_data;
          else
            data_nxt[i] = data[i];
        end
        if(cnt == 15) begin
          cnt_nxt = 0;
          addr_nxt = addr + 1;
        end else begin
          cnt_nxt = cnt + 1;
        end
      end
      S_PAUSE: begin
        cnt_nxt = 0;
        data_nxt = 0;
      end
      S_WAIT: begin
        cnt_nxt = 0;
        data_nxt = 0;
      end
    endcase
  end

  always_ff @(negedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      cnt <= 0;
      addr <= 0;
      data <= 0;
      state <= S_IDLE;
    end else begin
      cnt <= cnt_nxt;
      addr <= addr_nxt;
      data <= data_nxt;
      state <= state_nxt;
    end
  end

endmodule