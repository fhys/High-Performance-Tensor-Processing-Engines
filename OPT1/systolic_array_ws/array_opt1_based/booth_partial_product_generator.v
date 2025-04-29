module booth_partial_product_generator(
        input  wire  [2:0]      operand_slice_a, 
        input  wire  [7:0]      operand_b, 
        input  wire  [8:0]      operand_b_neg, 
        output wire  [9:0]      pp_out        
    );
    
    wire [8:0] pp_source ;
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
    //         0                  0                    1               |  operand_b             
    //         0                  1                    0               |  operand_b   
    //         0                  1                    1               |  2operand_b   
    //         1                  0                    0               |  -2operand_b   
    //         1                  0                    1               |  -operand_b   
    //         1                  1                    0               |  -operand_b  
    //         1                  1                    1               |  0  
    //----------------------------------------------------
    
    wire not_c2    ;  
    wire c1_and_c0 ;  
    wire c1_nor_c0 ;  
    wire nor_o2    ;  
    
    wire   flag_2x ;
    wire   flag_s1 ;
    wire   flag_s2 ;
    
    assign not_c2     = ~operand_slice_a[2] ;
    assign c1_and_c0  = operand_slice_a[1] & operand_slice_a[0]         ;
    assign c1_nor_c0  = ~(operand_slice_a[1] | operand_slice_a[0])      ;
    assign nor_o2     = ~(c1_and_c0 | c1_nor_c0)  ;
  
    assign flag_2x      = ~nor_o2                   ;
    assign flag_s1      = ~(not_c2 | c1_and_c0)     ;
    assign flag_s2      = ~(operand_slice_a[2] | c1_nor_c0)    ;
    
    wire    flag_not_2x = nor_o2; 
    assign pp_source = (({{operand_b[7]}, operand_b}  & {9{flag_s2}}) | (operand_b_neg & {9{flag_s1}}));
    assign pp_out[0] = (!flag_2x & pp_source[0]);
    assign pp_out[8:1] = (({8{flag_2x}} & pp_source[7:0]) | ({8{flag_not_2x}} & pp_source[8:1]));
    assign pp_out[9] = pp_source[8];
    
endmodule