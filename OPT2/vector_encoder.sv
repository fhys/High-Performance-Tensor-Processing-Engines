module vector_encoder(
    input                    clk,
    input   [127:0]          operand_a,
    output  reg [3:0]        bit_enable [0:15],
    output  reg [7:0]        partial_product_select [0:15]
);

wire    [3:0]    bit_valid     [0:15];
wire    [7:0]    encoder_nub   [0:15];
reg     [127:0]  sync_operand        ;

genvar i;
generate
  for(i = 0; i < 16; i = i + 1) begin
      en_t_encoder en_t_preencoder(
          .clk(clk),
          .multiplicand(sync_operand[8*(i+1)-1:8*i]),
          .cal_encode_nub(encoder_nub[i]),
          .bit_enable(bit_valid[i])
      );
  end 
endgenerate

always @(posedge clk) begin
    sync_operand <= operand_a;
    bit_enable <= bit_valid;
    partial_product_select <= encoder_nub;
end

endmodule



module en_t_encoder(
    input                             clk,
    input          [7:0]              multiplicand,   
    output  reg    [7:0]              cal_encode_nub,
    output  reg    [3:0]              bit_enable
    );

wire [7:0]   encode_input;
wire [2:0]   c_out;
wire [7:0]   encode_nub;

// covert to bit_enable-Magnitude
assign encode_input = multiplicand[7] ? ((multiplicand[6:0] == 0) ? 8'b10000000 : {1'b0,~multiplicand[6:0] + 1'b1}) : {1'b0,multiplicand[6:0]};

genvar i;
generate for(i = 0; i < 4; i = i + 1)  begin: gen_encode_nub 
    if(i==0) begin
        assign encode_nub[1:0] = encode_input[1:0];
    end
    else if (i==1) begin
        encoder_1 en_t
        (.A(encode_input[2*i-1:2*i-2]),
         .B(encode_input[2*i+1:2*i]), 
         .c_out(c_out[i]), 
         .en_b(encode_nub[2*i+1:2*i])
        );
    end
    else if (i==3) begin
        encoder_3 en_t
        (.A(encode_input[2*i-1:2*i-2]),
         .c_in(c_out[i-1]), 
         .B(encode_input[2*i+1:2*i]), 
         .en_b(encode_nub[2*i+1:2*i])
        );
    end
    else begin
        encoder en_t
        (.A(encode_input[2*i-1:2*i-2]),
         .c_in(c_out[i-1]), 
         .B(encode_input[2*i+1:2*i]), 
         .c_out(c_out[i]), 
         .en_b(encode_nub[2*i+1:2*i])
        );
    end                
end                                                                     
endgenerate  


generate 
  for (i = 0 ; i < 4; i = i + 1) begin
    always @(posedge clk) begin
        if(encode_nub[2*i+1:2*i] == 2'b00) begin
            bit_enable[i] <= 0;
            cal_encode_nub[2*i+1:2*i] <= 0;
        end
        else begin
            bit_enable[i] <= 1;
            cal_encode_nub[2*i+1:2*i] <= {multiplicand[7]^encode_nub[2*i+1],encode_nub[2*i]};
        end
    end
  end
endgenerate

endmodule


module encoder_1(A, B, c_out, en_b);

input wire [1:0]   A;
input wire [1:0]   B;
 
output wire        c_out;
output wire [1:0]  en_b;

assign c_out = (A[0] & A[1]); 
assign en_b  = B + c_out;

endmodule

module encoder(A, c_in, B, c_out, en_b);

input wire [1:0]   A;
input wire         c_in;
input wire [1:0]   B;
 
output wire        c_out;
output wire [1:0]  en_b;

assign c_out = (A[0] & A[1]) | (A[1] & c_in); 
assign en_b  = B + c_out;

endmodule

module encoder_3(A, c_in, B, en_b);

input wire  [1:0]   A;
input wire          c_in;
input wire  [1:0]   B;
output wire [1:0]  en_b;

wire c_out;
assign c_out = (A[0] & A[1]) | (A[1] & c_in); 
assign en_b  = B + c_out;

endmodule