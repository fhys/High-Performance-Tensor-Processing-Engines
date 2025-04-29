module booth_partial_product_generator_pp1(
        input  wire  [1:0]      operand_slice_a, 
        input  wire  [7:0]      operand_b,  
        input  wire  [8:0]      operand_b_neg,  
        output wire  [9:0]      pp_out         
    );
    
    wire [8:0] pp_source;
    wire not_code0;
    //----------------------------------------------------
    //|  pp          |  flag_2x  | flag_s1   |  flag_s2  |
    //----------------------------------------------------
    //|  operand_b   |     0     |     0     |     1     |
    //|  -operand_b  |     0     |     1     |     0     |
    //|  2operand_b  |     1     |     0     |     1     |   
    //|  -2operand_b |     1     |     1     |     0     |
    //|  0           |     x     |     0     |     0     |    
    //----------------------------------------------------
    
    //----------------------------------------------------
    //operand_slice_a[1]    operand_slice_a[0]    operand_slice_a[-1]  |  pp   
    //----------------------------------------------------
    //         0                  0                    0               |  0             
    //         0                  1                    0               |  operand_b   
    //         1                  0                    0               |  2operand_b   
    //         1                  1                    0               |  -operand_b  
    //----------------------------------------------------
    
    wire    flag_2x;
    wire    flag_s1;
    wire    flag_s2;  
    assign  not_code0 = ~operand_slice_a[0];  
    assign  flag_2x = not_code0;  
    assign  flag_s1 = operand_slice_a[1]; // 取反
    assign  flag_s2 = ~(operand_slice_a[1] | not_code0);  // A
    wire    flag_not_2x = operand_slice_a[0];
    assign  pp_source = (({{operand_b[7]}, operand_b} & {9{flag_s2}}) | (operand_b_neg & {9{flag_s1}})); // A or ~A or 0
    assign  pp_out[0] = (!flag_2x & pp_source[0]);// x2 (<<1) pp_out[0]=0
    assign  pp_out[8:1] = (({8{flag_2x}} & pp_source[7:0]) | ({8{flag_not_2x}} & pp_source[8:1]));
    assign  pp_out[9] = pp_source[8];

endmodule