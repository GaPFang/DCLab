module test_motor_step(
    input i_Clk,
    input i_rst_n,
    input i_en,
    input [14:0] i_total_steps_x,
    input [14:0] i_total_steps_y,
    input i_dir_x,
    input i_dir_y,
    output o_step_x,
    output o_direction_x,
    output o_step_y,
    output o_direction_y, 
    output o_done
);

localparam X_STEPS = 100;
localparam Y_STEPS = 100;

logic x_motor_done, y_motor_done;
logic x_en_r, x_en_w, y_en_r, y_en_w;
logic x_dir_r, x_dir_w, y_dir_r, y_dir_w;
logic [31:0] x_steps_r, x_steps_w, y_steps_r, y_steps_w;
logic step_control_x, step_control_y;
logic direction_x, direction_y;
logic done_r, done_w;
logic [31:0] total_steps_x, total_steps_y;
logic dir_x, dir_y;
//logic [14:0] total_steps_r, total_steps_w;

assign o_direction_x = direction_x;
assign o_step_x = step_control_x;
assign o_done = done_r;
assign total_steps_x = (i_total_steps_x);
assign dir_x = i_dir_x;

assign o_direction_y = direction_y;
assign o_step_y = step_control_y;
assign o_done = done_r;
assign total_steps_y = (i_total_steps_y);
assign dir_y = i_dir_y;

//state enumeration
typedef enum logic [1:0] {
    S_IDLE = 2'b00,
    S_RUN = 2'b01
} state_t;

state_t state_r, state_w;
//

always_comb begin
    state_w = state_r;
    case(state_r)
        S_IDLE: begin
            if (i_en) begin
                state_w = S_RUN;
            end
        end
        S_RUN: begin
            if (x_motor_done) begin
                state_w = S_IDLE;
            end
        end
    endcase
end


always_comb begin
    x_en_w = 0;
    y_en_w = 0;
    x_steps_w = x_steps_r;
    x_dir_w = 1;
    done_w = 0;
    //total_steps_w = total_steps_r;
    case(state_r)
        S_IDLE: begin
            x_steps_w = X_STEPS;
            x_dir_w = 1;
            if (i_en && i_rst_n) begin
                x_en_w = 1;
                y_en_w = 1;
            end
        end
        S_RUN: begin
            x_steps_w = 0;
            x_dir_w = x_dir_r;
            x_en_w = 0;
            y_en_w = 0;
            if (x_motor_done) begin
                done_w = 1;
            end
        end
    endcase
end

always_ff @(posedge i_Clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        x_en_r <= 0;
        y_en_r <= 0;
        x_dir_r <= 0;
        x_steps_r <= 0;
        done_r <= 0;
        state_r <= S_IDLE;
    end
    else begin
        x_en_r <= x_en_w;
        y_en_r <= y_en_w;
        x_dir_r <= x_dir_w;
        x_steps_r <= x_steps_w;
        done_r <= done_w;
        state_r <= state_w;
    end

end

Motor_Control x_motor(
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_en(x_en_r),
    .i_direction(dir_x),
    .i_total_steps(total_steps_x),
    .o_step_control(step_control_x),
    .o_direction(direction_x),
    .o_done(x_motor_done)
);

Motor_Control y_motor(
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_en(y_en_r),
    .i_direction(dir_y),
    .i_total_steps(total_steps_y),
    .o_step_control(step_control_y),
    .o_direction(direction_y),
    .o_done(y_motor_done)
);
endmodule