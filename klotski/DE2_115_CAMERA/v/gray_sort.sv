module Read_VGA_Grey(
    input i_Start,
    input [7:0] i_Red,
    input [7:0] i_Green,
    input [7:0] i_Blue,
    input [12:0] i_H_Counter,
    input [12:0] i_V_Counter,

    input i_Clk,
    input i_rst_n,

    output [63:0] o_block_order,

    // output [23:0] o_block1_avg,
    // output [23:0] o_block2_avg,
    // output [23:0] o_block3_avg,
    // output [23:0] o_block4_avg,
    // output [23:0] o_block5_avg,
    // output [23:0] o_block6_avg,
    // output [23:0] o_block7_avg,
    // output [23:0] o_block8_avg,
    // output [23:0] o_block9_avg,
    // output [23:0] o_block10_avg,
    // output [23:0] o_block11_avg,
    // output [23:0] o_block12_avg,
    // output [23:0] o_block13_avg,
    // output [23:0] o_block14_avg,
    // output [23:0] o_block15_avg,
    // output [23:0] o_block16_avg,

    // output [7:0][7:0][3:0] o_red_avg,

    output o_done

);

//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;         //Peli
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;

//	Start Offset
parameter	X_START		=	36;
parameter	Y_START		=	37;

localparam START_H_POS = 120;
localparam START_V_POS = 10;

// localparam H_intra_block_width = 15;
// localparam H_inter_block_width = 140;

// localparam V_intra_block_width = 15;
// localparam V_inter_block_width = 145;

localparam H_intra_block_width = 5;
localparam H_inter_block_width = 68;

localparam V_intra_block_width = 5;
localparam V_inter_block_width = 67;

localparam LEFT_ORIGIN = X_START + START_H_POS;
localparam UP_ORIGIN = Y_START + START_V_POS;

localparam THRESHOLD = 2'd3;

const logic [9:0] BLOCK_H [0:7][0:1] = '{'{LEFT_ORIGIN, LEFT_ORIGIN + H_intra_block_width}, 
'{LEFT_ORIGIN + H_inter_block_width, LEFT_ORIGIN + H_inter_block_width + H_intra_block_width}, 
'{LEFT_ORIGIN + 2*H_inter_block_width, LEFT_ORIGIN + 2*H_inter_block_width + H_intra_block_width}, 
'{LEFT_ORIGIN + 3*H_inter_block_width, LEFT_ORIGIN + 3*H_inter_block_width + H_intra_block_width}, 
'{LEFT_ORIGIN + 4*H_inter_block_width, LEFT_ORIGIN + 4*H_inter_block_width + H_intra_block_width},
'{LEFT_ORIGIN + 5*H_inter_block_width, LEFT_ORIGIN + 5*H_inter_block_width + H_intra_block_width},
'{LEFT_ORIGIN + 6*H_inter_block_width, LEFT_ORIGIN + 6*H_inter_block_width + H_intra_block_width},
'{LEFT_ORIGIN + 7*H_inter_block_width, LEFT_ORIGIN + 7*H_inter_block_width + H_intra_block_width}};

const logic [9:0] BLOCK_V [0:7][0:1] = '{'{UP_ORIGIN, UP_ORIGIN + V_intra_block_width},
'{UP_ORIGIN + V_inter_block_width, UP_ORIGIN + V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 2*V_inter_block_width, UP_ORIGIN + 2*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 3*V_inter_block_width, UP_ORIGIN + 3*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 4*V_inter_block_width, UP_ORIGIN + 4*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 5*V_inter_block_width, UP_ORIGIN + 5*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 6*V_inter_block_width, UP_ORIGIN + 6*V_inter_block_width + V_intra_block_width},
'{UP_ORIGIN + 7*V_inter_block_width, UP_ORIGIN + 7*V_inter_block_width + V_intra_block_width}};


logic [7:0][7:0][3:0] block_Red_value_r;
logic [12:0] block_Green_value_r [0:63];
logic [12:0] block_Blue_value_r [0:63];
logic [7:0][7:0][3:0] block_Red_value_w;
logic [12:0] block_Green_value_w [0:63];
logic [12:0] block_Blue_value_w [0:63];

logic [12:0] Red_r, Green_r, Blue_r;
logic [12:0] H_Counter_r, V_Counter_r;

logic o_done_r, o_done_w;


integer i, j, k;

logic [63:0] block_order_r, block_order_w;
//assign
assign o_block_order = {block_Red_value_r[0][0], block_Red_value_r[0][1], block_Red_value_r[0][2], block_Red_value_r[0][3], block_Red_value_r[1][0], block_Red_value_r[1][1], block_Red_value_r[1][2], block_Red_value_r[1][3], block_Red_value_r[2][0], block_Red_value_r[2][1], block_Red_value_r[2][2], block_Red_value_r[2][3], block_Red_value_r[3][0], block_Red_value_r[3][1], block_Red_value_r[3][2], block_Red_value_r[3][3]};
assign o_done = o_done_r;


//

//state enumeration
typedef enum logic [2:0] {
    S_IDLE     = 3'b000,
    S_WAIT_V_CONT_0 = 3'b001,
    S_RECEIVE = 3'b010,
    S_AVG = 3'b011,
    S_DECODE = 3'b100,
    S_DONE = 3'b101
} state_t;

state_t state_r, state_w;
//

///////////////////combinational part///////////////////

//FSM
always_comb begin
    state_w = state_r;
    block_order_w = 0;
    case (state_r)
        S_IDLE: begin
            if (i_Start) begin
                state_w = S_WAIT_V_CONT_0;
            end
            else begin
                state_w = S_IDLE;
            end
        end

        S_WAIT_V_CONT_0: begin
            if (V_Counter_r == 0) begin
                state_w = S_RECEIVE;
            end
            else begin
                state_w = S_WAIT_V_CONT_0;
            end
        end

        S_RECEIVE: begin
            if ((H_Counter_r >= 742) && (V_Counter_r >= 542)) begin
                state_w = S_AVG;
            end
        end

        S_AVG: begin
            state_w = S_DECODE;
        end

        S_DECODE: begin
            state_w = S_DONE;
        end

        S_DONE: begin
            state_w = S_IDLE;
        end
    endcase
end
//

//state_behavior
always_comb begin
    o_done_w = 0;
    j = 0;
    k = 0;
    // for (j = 0; j < 16; j = j + 1) begin
    //     block_Red_value_w[j] = block_Red_value_r[j];
    //     block_Green_value_w[j] = block_Green_value_r[j];
    //     block_Blue_value_w[j] = block_Blue_value_r[j];
    // end
    block_Red_value_w = block_Red_value_r;
    case (state_r)
        S_IDLE: begin
            if (i_Start) begin
                block_Red_value_w = 0;
            end
        end

        S_WAIT_V_CONT_0: begin
            
        end

        S_RECEIVE: begin
            for (j=0; j<8; j=j+1) begin
                for (k=0; k<8; k=k+1) begin
                    if (((H_Counter_r == BLOCK_H[j][0]) || // block1
                    (H_Counter_r == BLOCK_H[j][1])) &&
                    ((V_Counter_r == BLOCK_V[k][0]) || (V_Counter_r == BLOCK_V[k][1]))) begin
                        block_Red_value_w[k][j] = block_Red_value_r[k][j] + Red_r;
                    end
                end
            end
        end

        
        S_AVG: begin
            for (j = 0; j < 8; j = j + 1) begin
                for (k = 0; k < 8; k+=1) begin
                    block_Red_value_w[k][j] = block_Red_value_r[k][j] > THRESHOLD ? 1'b1:1'b0;
                    // block_Red_value_w[j][k] = (block_Red_value_r[j][k] >> 2);
                    // block_Green_value_w[j] = block_Green_value_r[j] >> 2;
                    // block_Blue_value_w[j] = block_Blue_value_r[j] >> 2;
                end
            end
        end

        S_DECODE: begin
            for (j=0; j<4; j=j+1) begin
                for (k=0; k<4; k=k+1) begin
                    // block_Red_value_w[j][k] = {block_Red_value_r[16*j+2*k][0], block_Red_value_r[16*j+2*k+1][0], block_Red_value_r[16*j+8+2*k][0], block_Red_value_r[16*j+8+2*k+1][0]};
                    block_Red_value_w[j][k] = {block_Red_value_r[2*j][2*k][0], block_Red_value_r[2*j][2*k+1][0], block_Red_value_r[2*j+1][2*k][0], block_Red_value_r[2*j+1][2*k+1][0]};
                    // block_Red_value_w[4*j+k] = {{block_order_r[8*j+2*k]}, {block_order_r[8*j+2*k+1]}, {block_order_r[8*j+2*k+2]}, {block_order_r[8*j+2*k+3]}};
                end
            end
        end

        S_DONE: begin
            o_done_w = 1;
        end
        // default: begin
        //     for (j = 0; j < 16; j = j + 1) begin
        //         block_Red_value_w[j] = block_Red_value_r[j];
        //         block_Green_value_w[j] = block_Green_value_r[j];
        //         block_Blue_value_w[j] = block_Blue_value_r[j];
        //     end
        // end
    endcase
end
//

////////////////////////////////////////////////////////

///////////////////sequential part///////////////////
always_ff @(posedge i_Clk or negedge i_rst_n) begin 
    if(!i_rst_n) begin
        state_r <= S_IDLE;
        // for (i = 0; i < 16; i = i + 1) begin
        //     block_Red_value_r[i] <= 13'b0;
        //     block_Green_value_r[i] <= 13'b0;
        //     block_Blue_value_r[i] <= 13'b0;
        // end
        block_Red_value_r <= 0;
        o_done_r <= 0;
        Red_r <= 0;
        Green_r <= 0;
        Blue_r <= 0;
        H_Counter_r <= 0;
        V_Counter_r <= 0;
    end
    else begin
        state_r <= state_w;
        // for (i = 0; i < 16; i = i + 1) begin
        //     block_Red_value_r[i] <= block_Red_value_w[i];
        //     block_Green_value_r[i] <= block_Green_value_w[i];
        //     block_Blue_value_r[i] <= block_Blue_value_w[i]; 
        // end
        block_Red_value_r <= block_Red_value_w;
        o_done_r <= o_done_w;
        Red_r <= i_Green[7:6];
        Green_r <= i_Green;
        Blue_r <= i_Blue;
        H_Counter_r <= i_H_Counter;
        V_Counter_r <= i_V_Counter;
    end
    
end

/////////////////////////////////////////////////////
endmodule