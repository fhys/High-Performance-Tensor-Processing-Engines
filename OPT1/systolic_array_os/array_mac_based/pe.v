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
    input   wire                                clc, // clean_result_cache,

    output  reg   signed  [WIDTH-1    :0]       row,
    output  reg   signed  [WIDTH-1    :0]       col,
    output  reg   signed  [ACC_WIDTH-1  :0]   result
);

always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            result <= 0;
        end
        else begin
            if(clc)
                result <= 0;
            else
                result <= result + a * b ;
        end
end

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
