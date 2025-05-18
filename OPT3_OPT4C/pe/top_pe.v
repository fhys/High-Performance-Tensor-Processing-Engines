module top_pe(
    input          clk,
    input          rst_n,
    input          clr,
    input   [7:0]  en_multiplicand,   // operand a
    input   [3:0]  sign_en_multiplicand,
    input          encode_valid,
    input   [7:0]  operand_b, 
    output  [1:0]  position,          // to prefetch operand b            
    output  [2:0]  cal_cycle,         // to prefetch operand a                 
    output  [51:0] pe_result  
);

wire [1:0] partial_product_index;

sparse_encoder sp_encoder(
        .clk(clk),
        .rst_n(rst_n),
        .en_multiplicand(en_multiplicand),
        .sign_en_multiplicand(sign_en_multiplicand),
        .encode_valid(encode_valid),
        .partial_product_index(partial_product_index), // to sparse_pe generate partial product
        .position_0(position),                        // to prefetch operand b
        .cal_cycle(cal_cycle)                         // to prefetch operand a    
);


pe #(
    .ACC_WIDTH(26)
) sparse_pe (
    .clk(clk),
    .rst_n(rst_n),
    .clr(clr),
    .encoder_position_ins(partial_product_index),
    .operand_b_ins(operand_b),
    .result(pe_result)
);




endmodule