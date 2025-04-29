module inv_unit_nor_out(
        input wire  a       ,
        input wire  b       ,
        
        output wire xor_o   ,  
        output wire nor_o      
    );
    

    wire    a_AND_b     ; 
    wire    a_NOR_b     ; 
    
  
    assign  a_AND_b = a & b;
    
 
    assign  a_NOR_b = ~(a | b);
    

    assign  xor_o   = ~(a_AND_b | a_NOR_b);
    assign  nor_o   = a_NOR_b;
    
endmodule