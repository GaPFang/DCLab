`timescale 1ns/1ps
`define CYCLE       20.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define I2C_CYCLE   200.0
`define I2C_HCYCLE  (`I2C_CYCLE/2)
`define I2S_CYCLE   83.3333
`define I2S_HCYCLE  (`I2S_CYCLE/2)
`define MAX_CYCLE   100000000
`define RST_DELAY   2
`define INFILE      "tb/keys.txt"

module testbed;

logic         clk, rst_n, clk_100k, bclk;
logic keys[4];

logic  [ 3:0] indata_mem [0:9];

initial begin
    $dumpfile("top.vcd");
    $dumpvars();
end

Top uut (
	.i_rst_n(rst_n),
	.i_clk(clk),
    .i_clk_100k(clk_100k),
    .i_AUD_BCLK(bclk),
	.i_key_0(keys[0]),
	.i_key_1(keys[1]),
	.i_key_2(keys[2]),
    .i_key_3(keys[3])
);

initial $readmemb(`INFILE, indata_mem);

initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

initial clk_100k = 1'b0;
always begin #(`I2C_HCYCLE) clk_100k = ~clk_100k; end

initial bclk = 1'b0;
always begin #(`I2S_HCYCLE) bclk = ~bclk; end

initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

integer i;
logic [3:0] cnt;

initial begin
    wait(rst_n == 0);
    cnt = 0;
    for (i = 0; i < 4; i = i + 1) begin
        keys[i] = 0;
    end
    wait(rst_n == 1);
    $display("Start simulation");
    # (3200 * `CYCLE);
    while (1) begin
        @(negedge clk);
        if (indata_mem[cnt] === 4'bxxxx) begin
            $display("End simulation");
            $finish;
        end
        # (49 * `CYCLE);
        for (i = 0; i < 4; i = i + 1) begin
            keys[i] = indata_mem[cnt][i];
        end
        # (7 * `CYCLE);
        for (i = 0; i < 4; i = i + 1) begin
            keys[i] = 0;
        end
        cnt = cnt + 1;
    end
end

endmodule
