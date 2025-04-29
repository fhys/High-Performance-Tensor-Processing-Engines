// b = w * a
module PE #
(
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 24
)
(
    input   wire                                rst_n                           ,
    input   wire                                clk                             ,
    input   wire                                weight_wen                      ,
    input                 [WIDTH-1       :0]    weight_din                      ,
    input   wire  signed  [WIDTH-1       :0]    a                               ,
    input   wire  signed  [2*ACC_WIDTH-1 :0]    partial_result                  , 

    output  reg   signed  [WIDTH-1       :0]    col                             ,
    output  reg   signed  [2*ACC_WIDTH-1 :0]    row                             
);


reg  signed  [WIDTH-1    :0]  weight;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        weight <= 0;
    end
    else begin
        if(weight_wen) begin
            weight <= weight_din;   
        end
        else begin
            weight <= weight;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        col <= 0;
    end
    else begin
        if(weight_wen) begin
            col <= weight_din;   
        end
        else begin
            col <= a;
        end
    end
end

wire [ACC_WIDTH-1:0]  acc_sum;
wire [ACC_WIDTH-1:0]  acc_carry;
always @(*) begin
    if(!rst_n) begin
        row <= 0;
    end
    else begin
        row <= {acc_sum, acc_carry}; // partial_result + weight * a;
    end
end
opt1_mac #(
    .ACC_WIDTH(ACC_WIDTH),
    .INPUT_PIP(0)
) opt1_mac_test (
    .clk(clk),
    .rst_n(rst_n),
    .operand_a_in(a),  
    .operand_b_in(weight), 
    .partial_result(partial_result),
    .acc_sum(acc_sum),
    .acc_carry(acc_carry)
);


endmodule
