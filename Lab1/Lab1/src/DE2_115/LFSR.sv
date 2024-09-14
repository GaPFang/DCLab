module LFSR (
    input        i_clk,
    input        i_rst_n,
    input        i_start,
    output logic [3:0] o_random_out
);

always_ff @(posedge i_clk or negedge i_rst_n) begin
    // reset
    if (!i_rst_n) begin
        o_random_out <= 4'd0;
    end
    else begin
        if (i_start) begin
            o_random_out[0] <= o_random_out[3] ^ o_random_out[0];
            o_random_out[1] <= o_random_out[0];
            o_random_out[2] <= o_random_out[1];
            o_random_out[3] <= o_random_out[2];
        end
    end
end

endmodule