`timescale 1ns/1ns

module tb_vga;

reg         clock;
reg         reset;
wire [7:0]  VGA_R;
wire [7:0]  VGA_G;
wire [7:0]  VGA_B;
wire        VGA_HS;
wire        VGA_VS;

initial begin
    clock = 1'b0;
    reset = 1'b1;

    // Reset for 1us
    #5
    reset = 1'b0;
    #10
    reset = 1'b1;

end

// Generate 50MHz clock signal
always #10 clock <= ~clock;

vga vga_top(
    .i_clk     (clock),
    .i_rst     (reset),
    
    // VGA port
    .VGA_R   (VGA_R),
    .VGA_G   (VGA_G),
    .VGA_B   (VGA_B),
    .VGA_HS  (VGA_HS),
    .VGA_VS  (VGA_VS)
);

initial begin
    $dumpfile("vga.vcd");
    $dumpvars(0, tb_vga);
    $display("Start simulation");
    #20000000
    $display("End simulation");
    $finish;
end

endmodule
