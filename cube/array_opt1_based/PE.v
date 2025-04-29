`timescale 1ns / 1ps

// b = w * a
module PE #
(
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 24
)
(
    input   wire                                rst_n,
    input   wire                                clk,
    input   wire  signed  [WIDTH-1    :0]       i_z_a,
    input   wire  signed  [WIDTH-1    :0]       i_x_b,
    input   wire  signed  [2*ACC_WIDTH-1    :0]   i_y_p,

    output  reg   signed  [WIDTH-1    :0]       o_z_a,
    output  reg   signed  [WIDTH-1    :0]       o_x_b,
    output  reg   signed  [2*ACC_WIDTH-1  :0]     o_y_p
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        o_z_a <= 0;
        o_x_b <= 0;
    end
    else begin
        o_z_a <= i_z_a; 
        o_x_b <= i_x_b; 
    end
end

wire [ACC_WIDTH-1:0]  acc_sum;
wire [ACC_WIDTH-1:0]  acc_carry;
always @(*) begin
    if(!rst_n) begin
        o_y_p = 0;
    end
    else begin
        o_y_p = {acc_sum, acc_carry}; // partial_result + weight * a;
    end
end
opt1_mac #(
    .ACC_WIDTH(ACC_WIDTH),
    .INPUT_PIP(0)
) opt1_mac_test (
    .clk(clk),
    .rst_n(rst_n),
    .operand_a_in(i_z_a),  
    .operand_b_in(i_x_b), 
    .partial_result(i_y_p),
    .acc_sum(acc_sum),
    .acc_carry(acc_carry)
);

endmodule
