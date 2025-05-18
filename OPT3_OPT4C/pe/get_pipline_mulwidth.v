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
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    pipeline_regs[i] <= 0;  
                end else begin
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


