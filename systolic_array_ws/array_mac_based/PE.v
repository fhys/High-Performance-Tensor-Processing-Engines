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
    input                 [WIDTH-1      :0]     weight_din                      ,
    input   wire  signed  [WIDTH-1      :0]     a                               ,
    input   wire  signed  [ACC_WIDTH-1  :0]     partial_result                  , 

    output  reg   signed  [WIDTH-1      :0]     col                             ,
    output  reg   signed  [ACC_WIDTH-1  :0]     row                             
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

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        row <= 0;
    end
    else begin
        row <= partial_result + weight * a;
    end
end

endmodule
