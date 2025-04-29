module booth_pp_gen(
        input  wire [7:0]   operand_a, 
        input  wire [7:0]   operand_b, 
        output wire [9:0]   pp1,
        output wire [9:0]   pp2,
        output wire [9:0]   pp3,
        output wire [9:0]   pp4     
    );

    wire [1:0]  operand_slice_a1 ;
    wire [2:0]  operand_slice_a2 ;
    wire [2:0]  operand_slice_a3 ;
    wire [2:0]  operand_slice_a4 ;
    wire [8:0]  operand_b_neg  ;
    
    inv_converter_8 inv_converter_8_inst(
        .data_i (operand_b),
        .inv_o  (operand_b_neg) 
    );
    
    assign operand_slice_a1 = operand_a[1:0]         ;
    assign operand_slice_a2 = operand_a[3:1]         ;
    assign operand_slice_a3 = operand_a[5:3]         ;
    assign operand_slice_a4 = operand_a[7:5]         ;

    booth_partial_product_generator_pp1 ppg_1 (
        .operand_slice_a (operand_slice_a1),  
        .operand_b       (operand_b), 
        .operand_b_neg   (operand_b_neg), 
        .pp_out          (pp1)  
    );

    booth_partial_product_generator ppg_2 (
        .operand_slice_a (operand_slice_a2),  
        .operand_b       (operand_b), 
        .operand_b_neg   (operand_b_neg), 
        .pp_out          (pp2)  
    );

    booth_partial_product_generator ppg_3 (
        .operand_slice_a (operand_slice_a3),  
        .operand_b       (operand_b), 
        .operand_b_neg   (operand_b_neg), 
        .pp_out          (pp3)  
    );

    booth_partial_product_generator ppg_4 (
        .operand_slice_a (operand_slice_a4),  
        .operand_b       (operand_b), 
        .operand_b_neg   (operand_b_neg), 
        .pp_out          (pp4)  
    );

endmodule
