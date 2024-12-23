module tb_test_block_movement;

  // Inputs
  reg i_en;
  reg i_Clk, i_rst_n;

  // Outputs
  wire o_step_x, o_direction_x;
  wire o_step_y, o_direction_y;
  wire o_magnet;
  wire o_done;

  // Instantiate the module
    test_block_movement uut(
        .i_Clk(i_Clk),
        .i_rst_n(i_rst_n),
        .i_en(i_en),
        .o_step_x(o_step_x),
        .o_direction_x(o_direction_x),
        .o_step_y(o_step_y),
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

    
    // Set up FSDB dumping
    $fsdbDumpfile("test_block_movement.fsdb");  // Specify FSDB output file name
    $fsdbDumpvars(0, uut);                // Dump all signals from the uut (Read_VGA module)
    
    // Apply reset
    #5;
    i_rst_n = 1; // Release reset
    
    // Start signal pulse
    #20;
    i_en = 1; // Assert start signal
    
    #20;
    i_en = 0; // Deassert start signal
    
    
    // Check if the o_done signal is asserted
    wait(o_done == 1);
    
    // End of simulation
    $finish;
  end

endmodule
