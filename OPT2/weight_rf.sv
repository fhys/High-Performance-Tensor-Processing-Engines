module weight_rf (
      input                  clk,
      input                  wen,
      input       [7:0]      din,
      output      [7:0]      weight [0:15]
);

reg [7:0] buffer [0:15];

assign weight = buffer;

genvar i;
generate
  for (i = 0; i < 16; i = i + 1) begin
    always @(posedge clk) begin
        if(wen) begin
          if (i==15)
            buffer[i] <= din;
          else 
            buffer[i] <= buffer[i+1];
        end
        else
            buffer[i] <= buffer[i];
      end
    end
endgenerate


endmodule