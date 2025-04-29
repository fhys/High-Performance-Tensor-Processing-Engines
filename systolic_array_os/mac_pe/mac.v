module mac #
(
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 32
)
(
    input   wire                                rst_n,
    input   wire                                clk,
    input   wire  signed  [WIDTH-1    :0]       a,
    input   wire  signed  [WIDTH-1    :0]       b,
    output  reg   signed  [ACC_WIDTH-1  :0]     result
);

wire signed [15:0]  result_p;
reg  signed [7:0]   operand_a;
reg  signed [7:0]   operand_b;

assign result_p = $signed(operand_a) * $signed(operand_b) ;

always @(posedge clk) begin
    operand_a <= a;
    operand_b <= b;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result <= 0;
    end
    else begin
        result <= result + $signed(result_p);
    end
end


endmodule
