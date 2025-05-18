module get_negedge(
                input                       clk,
                input                       signal,
                output                      negedge_signal
                );

reg save;

always @(posedge clk) begin
  save <= signal;
end

assign negedge_signal = ~signal & save;

endmodule

// get_negedge get_hit(
//   .clk(clk),
//   .signal(cache_hit),
//   .negedge_signal(negedge_cache_hit)
// );