module opt1_mac #(
        parameter ACC_WIDTH = 32,
        parameter INPUT_PIP = 1
)(
        input  wire                           clk,
        input  wire                           rst_n,
        input  wire         [7:0]             operand_a_in,  
        input  wire         [7:0]             operand_b_in,  
        output reg          [ACC_WIDTH-1:0]   acc_sum,
        output reg          [ACC_WIDTH-1:0]   acc_carry
);

reg         [7:0]                operand_a;
reg         [7:0]                operand_b;

wire signed [9:0]                pp1;
wire signed [9:0]                pp2;
wire signed [9:0]                pp3;
wire signed [9:0]                pp4;
wire        [6*ACC_WIDTH-1 : 0]  mul_reduce_csa_input;
wire signed [ACC_WIDTH-1:0]      sign_extend_pp1;
wire signed [ACC_WIDTH-1:0]      sign_extend_pp2;
wire signed [ACC_WIDTH-1:0]      sign_extend_pp3;
wire signed [ACC_WIDTH-1:0]      sign_extend_pp4;
wire signed [ACC_WIDTH-1:0]      reduce_acc_sum;
wire signed [ACC_WIDTH-1:0]      reduce_acc_carry;

assign sign_extend_pp4        = $signed({pp4,6'b0});
assign sign_extend_pp3        = $signed({pp3,4'b0});
assign sign_extend_pp2        = $signed({pp2,2'b0});
assign sign_extend_pp1        = $signed(pp1);

assign mul_reduce_csa_input   = {sign_extend_pp4,sign_extend_pp3,sign_extend_pp2,sign_extend_pp1,acc_carry, acc_sum};

booth_pp_gen booth_pp_gen_inst(
        .operand_a(operand_a),  
        .operand_b(operand_b),  
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .pp4(pp4)
);

DW02_tree #(6, ACC_WIDTH, 1)
 U2 ( .INPUT(mul_reduce_csa_input), .OUT0(reduce_acc_sum), .OUT1(reduce_acc_carry) );

always @(posedge clk) begin
     if (!rst_n) begin
        acc_sum   <= 0;
        acc_carry <= 0;
     end
     else begin
        acc_sum   <= reduce_acc_sum;
        acc_carry <= reduce_acc_carry;
     end
end

generate
  if(INPUT_PIP == 1) begin
        always @(posedge clk) begin
            operand_a <= operand_a_in;
            operand_b <= operand_b_in;
        end
  end
  else begin
        always @(*) begin
           operand_a = operand_a_in;
           operand_b = operand_b_in;
        end
  end
endgenerate

//  dff_async #(
//     .WIDTH(ACC_WIDTH)) acc_sum_reg (
//     .clk(clk),
//     .rst_n(rst_n),
//     .d(reduce_acc_sum),
//     .q(acc_sum)
// );

//  dff_async #(
//     .WIDTH(ACC_WIDTH)) acc_carry_reg (
//     .clk(clk),
//     .rst_n(rst_n),
//     .d(reduce_acc_carry),
//     .q(acc_carry)
// );



    
endmodule



