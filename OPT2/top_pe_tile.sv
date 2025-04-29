module top_pe_tile #(
      localparam RESULT_WIDTH = 20
)(
      input                                 clk,
      input                                 weight_wen,
      input       [7:0]                     weight_din,
      input       [3:0]                     bit_enable [0:15],
      input       [7:0]                     partial_product_select [0:15],
      output  reg signed [RESULT_WIDTH-1:0] result,
      output  reg [3:0]                     bit_enable_pip [0:15],
      output  reg [7:0]                     partial_product_select_pip [0:15]
);

localparam REDUCE_WIDTH = 13;

//*********range of partial_product in same bit-weight********/
//** 9bit:       -256 ≤ partial_product ≤ 254                 /
//** 13bit:    -4096 ≤ 16 * partial_product ≤ 4064            /
//************************************************************/
wire        [7:0]                      weight            [0:15];
wire signed [9:0]                      partial_product   [0:15][0:3];  
wire signed [REDUCE_WIDTH-1:0]         csa_extend        [0:15][0:3];
wire        [16*REDUCE_WIDTH-1:0]      csa_input         [0:3];
wire        [4*REDUCE_WIDTH-1:0]       mid_result        [0:3];
wire signed [REDUCE_WIDTH-1:0]         result_bw [0:3];
wire signed [RESULT_WIDTH-1:0]         bw_0;
wire signed [RESULT_WIDTH-1:0]         bw_1;
wire signed [RESULT_WIDTH-1:0]         bw_2;
wire signed [RESULT_WIDTH-1:0]         bw_3;


weight_rf weight_buffer(
  .clk(clk),
  .wen(weight_wen),
  .din(weight_din),
  .weight(weight)      
);

genvar i,j;
generate
    for (i=0;i<16;i=i+1) begin
      partial_product_select pps (
        .clk(clk),
        .weight(weight[i]),
        .bit_enable(bit_enable_pip[i]),
        .partial_product_select(partial_product_select_pip[i]),
        .partial_product(partial_product[i])
        );
    end
endgenerate

generate
    for (i=0;i<16;i=i+1) begin
      for (j=0;j<4;j=j+1) begin
          assign csa_extend[i][j] = $signed(partial_product[i][j]);
      end
    end
endgenerate

generate
    for (i=0;i<4;i=i+1) begin
      for (j=0;j<16;j=j+1) begin
          assign csa_input[i][(j+1)*REDUCE_WIDTH-1:j*REDUCE_WIDTH] = csa_extend[j][i];
      end
    end
endgenerate


generate
    for (i=0;i<4;i=i+1) begin

          tree_full_sum #(
                  .K(4),
                  .WIDTH(REDUCE_WIDTH)
          ) tree_stage_1_0 (
                  .clk(clk),
                  .csa_input({csa_input[i][1*REDUCE_WIDTH-1:0],
                              csa_input[i][2*REDUCE_WIDTH-1:1*REDUCE_WIDTH],
                              csa_input[i][3*REDUCE_WIDTH-1:2*REDUCE_WIDTH],
                              csa_input[i][4*REDUCE_WIDTH-1:3*REDUCE_WIDTH]}),
                  .full_sum(mid_result[i][1*REDUCE_WIDTH-1:0*REDUCE_WIDTH])
          );
          tree_full_sum #(
                  .K(4),
                  .WIDTH(REDUCE_WIDTH)
          ) tree_stage_1_1 (
                  .clk(clk),
                  .csa_input({csa_input[i][5*REDUCE_WIDTH-1:4*REDUCE_WIDTH],
                              csa_input[i][6*REDUCE_WIDTH-1:5*REDUCE_WIDTH],
                              csa_input[i][7*REDUCE_WIDTH-1:6*REDUCE_WIDTH],
                              csa_input[i][8*REDUCE_WIDTH-1:7*REDUCE_WIDTH]}),
                  .full_sum(mid_result[i][2*REDUCE_WIDTH-1:1*REDUCE_WIDTH])
          );
          tree_full_sum #(
                  .K(4),
                  .WIDTH(REDUCE_WIDTH)
          ) tree_stage_1_2 (
                  .clk(clk),
                  .csa_input({csa_input[i][9*REDUCE_WIDTH-1:8*REDUCE_WIDTH],
                              csa_input[i][10*REDUCE_WIDTH-1:9*REDUCE_WIDTH],
                              csa_input[i][11*REDUCE_WIDTH-1:10*REDUCE_WIDTH],
                              csa_input[i][12*REDUCE_WIDTH-1:11*REDUCE_WIDTH]}),
                  .full_sum(mid_result[i][3*REDUCE_WIDTH-1:2*REDUCE_WIDTH])
          );
          tree_full_sum #(
                  .K(4),
                  .WIDTH(REDUCE_WIDTH)
          ) tree_stage_1_3 (
                  .clk(clk),
                  .csa_input({csa_input[i][13*REDUCE_WIDTH-1:12*REDUCE_WIDTH],
                              csa_input[i][14*REDUCE_WIDTH-1:13*REDUCE_WIDTH],
                              csa_input[i][15*REDUCE_WIDTH-1:14*REDUCE_WIDTH],
                              csa_input[i][16*REDUCE_WIDTH-1:15*REDUCE_WIDTH]}),
                  .full_sum(mid_result[i][4*REDUCE_WIDTH-1:3*REDUCE_WIDTH])
          );
    end
endgenerate


generate
    for (i=0;i<4;i=i+1) begin
      tree_full_sum #(
               .K(4),
               .WIDTH(REDUCE_WIDTH)
       ) tree_stage_2 (
               .clk(clk),
               .csa_input({mid_result[i][1*REDUCE_WIDTH-1:0],
                           mid_result[i][2*REDUCE_WIDTH-1:1*REDUCE_WIDTH],
                           mid_result[i][3*REDUCE_WIDTH-1:2*REDUCE_WIDTH],
                           mid_result[i][4*REDUCE_WIDTH-1:3*REDUCE_WIDTH]}),
               .full_sum(result_bw[i])
       );
    end
endgenerate


assign bw_0 = $signed(result_bw[0]);
assign bw_1 = $signed({result_bw[1],2'b0});
assign bw_2 = $signed({result_bw[2],4'b0});
assign bw_3 = $signed({result_bw[3],6'b0});

tree_full_sum #(
               .K(4),
               .WIDTH(RESULT_WIDTH)
) tree_stage_3 (
               .clk(clk),
               .csa_input({bw_0,bw_1,bw_2,bw_3}),
               .full_sum(result)
       );

// pipeline the bit_enable and partial_product_select
always @(posedge clk) begin
        bit_enable_pip             <= bit_enable;
        partial_product_select_pip <= partial_product_select;
end

endmodule





