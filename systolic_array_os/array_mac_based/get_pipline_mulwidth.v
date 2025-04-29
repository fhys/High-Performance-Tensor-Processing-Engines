module get_pipeline_mulwidth #(
    parameter N = 4,
    parameter WIDTH = 8  
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] signal,
    output wire [WIDTH-1:0] pipeline_signal
);


    reg [WIDTH-1:0] pipeline_regs [N-1:0];


    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : pipeline_stage
            always @(posedge clk) begin
                if(~rst_n) 
                    pipeline_regs[i] <= 0;
                else begin
                    if (i == 0) begin
                        pipeline_regs[i] <= signal;  
                    end else begin
                        pipeline_regs[i] <= pipeline_regs[i-1];  
                    end
                end
            end
        end
    endgenerate


    assign pipeline_signal = pipeline_regs[N-1];

endmodule


// // 实例化 get_pipeline_mulwidth 模块
// get_pipeline_mulwidth #(
//     .N(4),       // 设置流水线深度为 4
//     .WIDTH(8)    // 设置信号宽度为 8 位
// ) pipeline_inst (
//     .clk(clk),                  // 连接时钟信号
//     .rst_n(rst_n),              // 连接复位信号
//     .signal(input_signal),      // 连接输入信号
//     .pipeline_signal(output_signal) // 连接输出信号
// );
