module partial_product_select(
      input                                 clk,
      input                [7:0]            weight,
      input                [3:0]            bit_enable,
      input                [7:0]            partial_product_select,
      output   signed      [9:0]            partial_product  [0:3]     
);

wire signed [8:0] inv_b;
wire signed [7:0] b;
wire signed [8:0] b_2;
wire signed [8:0] b_neg;
wire signed [9:0] b_2_neg;
wire        [1:0] cal_partial_product_select [0:3];
reg  signed [9:0] partial_product_bw  [0:3];   

assign cal_partial_product_select[0] = partial_product_select[1:0];
assign cal_partial_product_select[1] = partial_product_select[3:2];
assign cal_partial_product_select[2] = partial_product_select[5:4];
assign cal_partial_product_select[3] = partial_product_select[7:6];
assign partial_product               = partial_product_bw;
assign b                             = $signed(weight);
assign inv_b                         = $signed(~b);
assign b_2                           = {b,1'b0};
assign b_neg                         = inv_b + 1'b1;
assign b_2_neg                       = {b_neg,1'b0};

genvar i;
generate 
  for (i = 0 ; i < 4; i = i + 1) begin
    always @(posedge clk) begin
        if(bit_enable[i]) begin
          case(cal_partial_product_select[i])
            2'b00: partial_product_bw[i] <= $signed(b_2_neg);
            2'b01: partial_product_bw[i] <= $signed(b);
            2'b10: partial_product_bw[i] <= $signed(b_2);
            2'b11: partial_product_bw[i] <= $signed(b_neg);
          endcase
        end
        else
          partial_product_bw[i] <= 0;
      end
  end 
endgenerate

endmodule

