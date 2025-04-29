module tree_full_sum #(
    parameter K = 16,
    parameter WIDTH = 13
)(
    input                               clk,
    input             [K*WIDTH-1:0]     csa_input,
    output reg signed [WIDTH-1:0]       full_sum
);

wire signed [WIDTH-1:0] acc_sum;
wire signed [WIDTH-1:0] acc_carry;

genvar i;
generate
  if(K == 4) begin
    always @(posedge clk) begin
      full_sum <= $signed(csa_input[1*WIDTH-1:0*WIDTH]) + $signed(csa_input[2*WIDTH-1:1*WIDTH]) + $signed(csa_input[3*WIDTH-1:2*WIDTH]) + $signed(csa_input[4*WIDTH-1:3*WIDTH]);
    end
  end
  else begin
    DW02_tree #(K, WIDTH, 1)
     ins_tree ( .INPUT(csa_input), .OUT0(acc_sum), .OUT1(acc_carry));
    always @(posedge clk) begin
      full_sum <= $signed(acc_sum) + $signed(acc_carry);
    end
  end
endgenerate




endmodule


