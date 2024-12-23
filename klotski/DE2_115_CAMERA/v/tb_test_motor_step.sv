module tb_test_motor_step;

  // Inputs
  reg i_en;
  reg i_Clk, i_rst_n;
  reg [14:0] i_total_steps_x;

  // Outputs
  wire o_step_x, o_direction_x;
  wire o_step_y, o_direction_y;
  wire o_done;

  // Instantiate the module
  test_motor_step uut(
        .i_Clk(i_Clk),
        .i_rst_n(i_rst_n),
        .i_en(i_en),
        .i_total_steps_x(i_total_steps_x),
        .o_step_x(o_step_x),
        .o_direction_x(o_direction_x),
        .o_step_y(),
        .o_direction_y(), 
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
    i_total_steps_x = 500;

    
    // Set up FSDB dumping
    $fsdbDumpfile("test_motor_step.fsdb");  // Specify FSDB output file name
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
