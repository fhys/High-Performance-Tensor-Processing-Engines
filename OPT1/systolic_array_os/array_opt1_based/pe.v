module PE #
(
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 32
)
(
    input   wire                                rst_n,
    input   wire                                clk,
    input   wire  signed  [WIDTH-1    :0]       a,
    input   wire  signed  [WIDTH-1    :0]       b,
    input   wire                                clc, // clean_result_cache

    output  reg   signed  [WIDTH-1    :0]       row,
    output  reg   signed  [WIDTH-1    :0]       col,
    output        signed  [2*ACC_WIDTH-1  :0]   result
);


wire [ACC_WIDTH-1:0]  acc_sum;
wire [ACC_WIDTH-1:0]  acc_carry;
opt1_mac #(
    .ACC_WIDTH(ACC_WIDTH),
    .INPUT_PIP(0)
) opt1_mac_test (
    .clk(clk),
    .rst_n(rst_n),
    .operand_a_in(a),  
    .operand_b_in(b), 
    .clc(clc), // input   wire    clean_result_cache
    .acc_sum(acc_sum),
    .acc_carry(acc_carry)
);
assign result = {acc_sum, acc_carry};

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        row <= 0;
        col <= 0;
    end
    else begin
        row <= a;
        col <= b;
    end
end

endmodule
