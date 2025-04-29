module top_tpe #(
    parameter  N = 32,
    localparam RESULT_WIDTH = 20
)(
  
    input                         clk,
    input   [127:0]               operand_a,
    input                         weight_wen,
    input   [8*N-1:0]             weight_din,
    output  [RESULT_WIDTH*N-1:0]  result

);

wire [3:0]  bit_enable [0:15];
wire [7:0]  partial_product_select [0:15];
wire [3:0]  bit_enable_pip [0:N-1][0:15];
wire [7:0]  partial_product_select_pip [0:N-1][0:15];

vector_encoder encoder(
    .clk(clk),
    .operand_a(operand_a),
    .bit_enable(bit_enable),
    .partial_product_select(partial_product_select)
);

genvar i;
generate 
  for (i = 0 ; i < N ; i = i + 1) begin
    if(i == 0) begin
      top_pe_tile pe_tile(
        .clk(clk),
        .weight_wen(weight_wen),
        .weight_din(weight_din[8*(i+1)-1:8*i]),
        .bit_enable(bit_enable),
        .partial_product_select(partial_product_select),
        .result(result[RESULT_WIDTH*(i+1)-1:RESULT_WIDTH*i]),
        .bit_enable_pip(bit_enable_pip[i]),
        .partial_product_select_pip(partial_product_select_pip[i])
        );
    end
    else begin
      top_pe_tile pe_tile(
        .clk(clk),
        .weight_wen(weight_wen),
        .weight_din(weight_din[8*(i+1)-1:8*i]),
        .bit_enable(bit_enable_pip[i-1]),
        .partial_product_select(partial_product_select_pip[i-1]),
        .result(result[RESULT_WIDTH*(i+1)-1:RESULT_WIDTH*i]),
        .bit_enable_pip(bit_enable_pip[i]),
        .partial_product_select_pip(partial_product_select_pip[i])
        );
    end
  end
endgenerate

endmodule