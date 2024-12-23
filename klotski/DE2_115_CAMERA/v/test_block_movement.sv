module test_block_movement(
    input i_Clk,
    input i_rst_n,
    input i_en,
    output o_step_x,
    output o_direction_x,
    output o_step_y,
    output o_direction_y,
    output o_magnet,
    output o_done

);

localparam START_BLOCK1 = 1;
localparam END_BLOCK1 = 2;
localparam START_BLOCK2 = 12;
localparam END_BLOCK2 = 13;

localparam TOTAL_BLOCK_MOVEMENT = 2;


const int start_block[2] = '{START_BLOCK1, START_BLOCK2};
const int end_block[2] = '{END_BLOCK1, END_BLOCK2};

logic [4:0] send_cnt_r, send_cnt_w;
logic [4:0] wait_motor_cnt_r, wait_motor_cnt_w;
logic block_movement_done;
logic [4:0] start_block_r, start_block_w;
logic [4:0] end_block_r, end_block_w;
logic block_movement_en_r, block_movement_en_w;
logic done_r, done_w;
logic step_x, step_y;
logic direction_x, direction_y;
logic magnet;

assign o_done = done_r;
assign o_step_x = step_x;
assign o_direction_x = direction_x;
assign o_step_y = step_y;
assign o_direction_y = direction_y;
assign o_magnet = magnet;

typedef enum logic [2:0] {
    S_IDLE = 3'b000,
    S_SEND = 3'b001,
    S_DONE = 3'b010
} state_t;

state_t state_r, state_w;

always_comb begin
    state_w = state_r;
    case(state_r)
    S_IDLE: begin
        if (i_en) begin
            state_w = S_SEND;
        end
    end

    S_SEND: begin
        if ((send_cnt_r >= TOTAL_BLOCK_MOVEMENT) && (block_movement_done)) begin
            state_w = S_DONE;
        end
    end

    S_DONE: begin
        state_w = S_IDLE;
    end
    endcase
end


always_comb begin
    send_cnt_w = send_cnt_r;
    wait_motor_cnt_w = wait_motor_cnt_r;
    start_block_w = start_block_r;
    end_block_w = end_block_r;
    block_movement_en_w = 0;
    done_w = 0;
    case(state_r)
        S_IDLE: begin
            if (i_en) begin
                block_movement_en_w = 1;
                start_block_w = start_block[0][4:0];
                end_block_w = end_block[0][4:0];
                send_cnt_w = send_cnt_r + 1;
            end
        end

        S_SEND: begin
            wait_motor_cnt_w = 1;
            
            if (block_movement_done) begin
                wait_motor_cnt_w = 0;
                send_cnt_w = send_cnt_r + 1;
                if (send_cnt_r < TOTAL_BLOCK_MOVEMENT) begin
                    block_movement_en_w = 1;
                    start_block_w = start_block[send_cnt_r];
                    end_block_w = end_block[send_cnt_r];
                end
            end
        end

        S_DONE: begin
            done_w = 1;
            send_cnt_w = 0;
            wait_motor_cnt_w = 0;
        end
    endcase
end

always_ff @(posedge i_Clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        state_r <= S_IDLE;
        send_cnt_r <= 0;
        wait_motor_cnt_r <= 0;
        start_block_r <= 4'b0;
        end_block_r <= 4'b0;
        block_movement_en_r <= 0;
        done_r <= 0;
    end
    else begin
        state_r <= state_w;
        send_cnt_r <= send_cnt_w;
        wait_motor_cnt_r <= wait_motor_cnt_w;
        start_block_r <= start_block_w;
        end_block_r <= end_block_w;
        block_movement_en_r <= block_movement_en_w;
        done_r <= done_w;

    end


end

Block_Movement2Motor bm2m(
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_Start_Block(start_block_r),
    .i_End_Block(end_block_r),
    .i_en(block_movement_en_r),
    .o_step_control_x(step_x),
    .o_direction_x(direction_x),
    .o_step_control_y(step_y),
    .o_direction_y(direction_y),
    .o_magnet(magnet),
    .o_done(block_movement_done)
);

endmodule