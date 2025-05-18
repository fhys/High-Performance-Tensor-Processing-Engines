module sparse_encoder (
        input              clk,
        input              rst_n,
        input        [7:0] en_multiplicand,
        input        [3:0] sign_en_multiplicand,
        input              encode_valid,
        output reg   [1:0] partial_product_index, // to sparse_pe generate partial product
        output reg   [1:0] position_0,            // to prefetch operand b
        output       [2:0] cal_cycle              // to prefetch operand a    
);

wire a ;
wire b ;
wire c ;
wire d ;

reg [7:0] cal_en_multiplicand;
reg [1:0] position_1 ;
reg [1:0] position_2 ;
reg [1:0] position_3 ;

assign a  =  en_multiplicand[0] | en_multiplicand[1];
assign b  =  en_multiplicand[2] | en_multiplicand[3];
assign c  =  en_multiplicand[4] | en_multiplicand[5];
assign d  =  en_multiplicand[6] | en_multiplicand[7];

assign cal_cycle = {(a) & (b) & (c) & (d),
                               ((~a) & (c) & (d)) | ((~a) & (b) & (d)) | ((~a) & (b) & (c)) | (
                                           (a) & (~b) & (d)) | ((a) & (c) & (~d)) | (
                                           (a) & (b) & (~c)),
                               ((~a) & (~b) & (~c) & (d)) | ((~a) & (~b) & (c) & (~d)) | (
                                           (~a) & (b) & (~c) & (~d)) | ((~a) & (b) & (c) & (d)) | (
                                           (a) & (~b) & (~c) & (~d)) | ((a) & (~b) & (c) & (d)) | (
                                           (a) & (b) & (~c) & (d)) | ((a) & (b) & (c) & (~d))};

/**********************************************/
/********  00  |  01  |  10  |  11  | *********/
/******** -2B  |  B   |  2B  |  -B  | *********/
/**********************************************/
genvar i;
generate
   for (i = 0 ; i < 4 ; i = i + 1) begin : gen_cal_encoder
        always @(posedge clk or negedge rst_n) begin
	   if (!rst_n) begin
                cal_en_multiplicand[2*(i+1)-1:2*i] <= 0;
	   end
	   else begin
            if(encode_valid) begin
               if(sign_en_multiplicand[i]) begin
                   cal_en_multiplicand[2*(i+1)-1:2*i] <= {~en_multiplicand[2*(i+1)-1],en_multiplicand[2*i]};
               end
               else
                   cal_en_multiplicand[2*(i+1)-1:2*i] <= en_multiplicand[2*(i+1)-1:2*i];
            end else
                   cal_en_multiplicand[2*(i+1)-1:2*i] <= cal_en_multiplicand[2*(i+1)-1:2*i] ;
	   end
        end
   end
endgenerate
 


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
            position_0   <= 2'b0 ;    
            position_1   <= 2'b0 ;        
            position_2   <= 2'b0 ;          
            position_3   <= 2'b0 ;
    end
    else begin
          if(encode_valid) begin
              position_0   <= {(~a)&(~b), (~a & (b | ~c))};
              position_1   <= {( (a ^ b) & (c | d)) | ( (~a)&(c)&(d) ),
                                    ( (~a)&(~b)&(c)&(d) ) | ( (b)&(~c)&(d) ) | ( (a)&(~c)&(d) ) | ( (a)&(b) )};
              position_2   <= {( (b)&(c)&(d) ) | ( (a)&(c)&(d) ) | ( (a)&(b)&(d) ) | ( (a)&(b)&(c) ),
                                    ( (~a)&(b)&(c)&(d) ) | ( (a)&(~b)&(c)&(d) ) | ( (a)&(b)&(~c)&(d) )};
              position_3   <= {(a)&(b)&(c)&(d),(a)&(b)&(c)&(d)};
          end
          else begin
              position_0 <= position_1;
              position_1 <= position_2;
              position_2 <= position_3;
              position_3 <= 0;
          end
        end
end


always @(posedge clk) begin
  case(position_0) 
  2'b00: partial_product_index <= cal_en_multiplicand[1:0];
  2'b01: partial_product_index <= cal_en_multiplicand[3:2];
  2'b10: partial_product_index <= cal_en_multiplicand[5:4];
  2'b11: partial_product_index <= cal_en_multiplicand[7:6];
  endcase
end

endmodule


























