module tb_Block_Movement2Motor;

  // Inputs
  reg i_en;
  reg [4:0] i_Start_Block;
  reg [4:0] i_End_Block;
  reg i_Clk, i_rst_n;

  // Outputs
  wire o_step_control_x, o_step_control_y;
  wire o_direction_x, o_direction_y;
  wire o_magnet;
  wire o_done;

  // Instantiate the module
  Block_Movement2Motor uut(
    .i_Clk(i_Clk),
    .i_rst_n(i_rst_n),
    .i_Start_Block(i_Start_Block),
    .i_End_Block(i_End_Block),
    .i_en(i_en),
    .o_step_control_x(o_step_control_x),
    .o_direction_x(o_direction_x),
    .o_step_control_y(o_step_control_y),
    .o_direction_y(o_direction_y),
    .o_magnet(o_magnet),
    .o_done(o_done)
);

  // Clock generation (50 MHz clock)
  always begin
    #10 i_Clk = ~i_Clk; // 50 MHz clock period is 20ns
  end

  // Initial block for initializing signals and driving the test
  initial begin
    // Initialize signals
    i_Clk = 0;
    i_rst_n = 0;
    i_en = 0;
    i_Start_Block = 0;
    i_End_Block = 0;
    
    // Set up FSDB dumping
    $fsdbDumpfile("block_movement2motor_wave.fsdb");  // Specify FSDB output file name
    $fsdbDumpvars(0, uut);                // Dump all signals from the uut (Read_VGA module)
    
    // Apply reset
    #50;
    i_rst_n = 1; // Release reset
    
    // Start signal pulse
    #20;
    i_en = 1; // Assert start signal
    i_Start_Block = 0;
    i_End_Block = 1;
    #20;
    i_en = 0; // Deassert start signal
    
    
    // Check if the o_done signal is asserted
    wait(o_done == 1);

    #20;
    i_en = 1; // Assert start signal
    i_Start_Block = 6;
    i_End_Block = 10;
    #20;
    i_en = 0; // Deassert start signal

    // Check if the o_done signal is asserted
    wait(o_done == 1);

    #20;
    i_en = 1; // Assert start signal
    i_Start_Block = 7;
    i_End_Block = 6;
    #20;
    i_en = 0; // Deassert start signal

    // Check if the o_done signal is asserted
    wait(o_done == 1);
    
    // End of simulation
    $finish;
  end

endmodule
