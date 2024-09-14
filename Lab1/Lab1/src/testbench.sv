`define CYCLE_TIME 50            

module TestBench;

reg                Clk;
reg                Reset;
integer            i, outfile, counter;
integer            array [0:10];
reg                output;

always #(`CYCLE_TIME/2) Clk = ~Clk;

Top Top(
    .i_clk(Clk),
    .i_rst_n(Reset),
    .i_start(output)
);
  
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;

    counter = 0;
    
    // // initialize instruction memory
    // for(i=0; i<256; i=i+1) begin
    //     CPU.Instruction_Memory.memory[i] = 32'b0;
    // end
    
    // // Load instructions into instruction memory
    // $readmemb("instruction.txt", CPU.Instruction_Memory.memory);
    for (i=0; i<10; i=i+1) begin
        array[i] = i % 2;
    end
    
    // Open output file
    outfile = $fopen("output.txt") | 1;

    Clk = 0;
    Reset = 0;
    
    #(`CYCLE_TIME/4) 
    Reset = 1;
    
end
  
always@(posedge Clk) begin
    if(counter == 10)    // stop after 30 cycles
        $finish;
        
    output <= array[counter];
    
    counter = counter + 1;
end

  
endmodule