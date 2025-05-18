module encoder_multi_bit #(
        localparam  WIDTH = 8,
        localparam  ENCODER_WIDTH = WIDTH + (WIDTH+1)%2,
        localparam  TIMES = (WIDTH-1)/2 + (WIDTH-1)%2
)(
        input                   clk,
        input                   rst_n,
        input  [WIDTH-1:0]      multiplicand,
        input                   multiplicand_valid,              
        output reg  [WIDTH:0]   en_multiplicand,      // native EN-T encoding is sent to tensorcore local memory or local rf.
        output                  en_multiplicand_valid
    );

wire [WIDTH-1:0]         encoder_input;
wire [ENCODER_WIDTH-1:0] en_multiplicand_ins;
wire [TIMES-1:0]         en_t_c_out;
reg  [WIDTH-1:0]         multiplicand_reg;

assign encoder_input = (multiplicand_reg != 8'b10000000) ? {1'b0,multiplicand_reg[WIDTH-2:0]} : 8'b10000000;
assign en_multiplicand_ins[ENCODER_WIDTH-1] = multiplicand_reg[WIDTH-1];

genvar i;
generate for(i = 0; i < TIMES; i = i + 1)  begin: gen_encoder  
    if(i==0) begin
        assign en_multiplicand_ins[1:0] = multiplicand_reg[1:0];
    end
    else if (i==1)begin
        encoder ins_encoder
         (.A(encoder_input[2*i-1:2*i-2]),
          .C_IN(1'b0), 
          .B(encoder_input[2*i+1:2*i]), 
          .en_t_c_out(en_t_c_out[i]), 
          .EN_B(en_multiplicand_ins[2*i+1:2*i]));
    end
    else begin
        encoder ins_encoder
            (.A(encoder_input[2*i-1:2*i-2]),
             .C_IN(en_t_c_out[i-1]), 
             .B(encoder_input[2*i+1:2*i]), 
             .en_t_c_out(en_t_c_out[i]), 
             .EN_B(en_multiplicand_ins[2*i+1:2*i]));
    end                
end                                                                     
endgenerate  


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
         en_multiplicand    <= 0;
         multiplicand_reg   <= 0;
    end
	else begin
         en_multiplicand  <= en_multiplicand_ins;  
         //multiplicand belongs to [-128,127] range and operand with complement representation use this logic:
         multiplicand_reg <= (multiplicand[WIDTH-1] & (multiplicand[WIDTH-2:0] != 0)) ? ({1'b1,~multiplicand[WIDTH-2:0] + 1'b1}) : multiplicand;   
         //multiplicand belongs to [-127,127] range and operand with sign-magnitude representation use this logic:
         //multiplicand_reg <= multiplicand;   
    end
end

get_pipeline_mulwidth #(
    .N(2),       
    .WIDTH(1)    
) pipeline_en_multiplicand_valid (
    .clk(clk), 
    .rst_n(rst_n),                
    .signal(multiplicand_valid),     
    .pipeline_signal(en_multiplicand_valid) 
);

endmodule


module encoder(A, C_IN, B, en_t_c_out, EN_B);

input wire [1:0] A;
input wire C_IN;
input wire [1:0] B;

output wire en_t_c_out;
output wire [1:0] EN_B;

assign en_t_c_out = (A[0] & A[1]) | (A[1] & C_IN); 
assign EN_B  = B + en_t_c_out;

endmodule