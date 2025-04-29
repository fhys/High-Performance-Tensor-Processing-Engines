module inv_converter_8(
        input wire [7:0]   data_i  ,
        output wire[8:0]   inv_o    
    );
    
    wire [5:0]      wire_cout       ;  
    wire            not_o           ;  

    assign inv_o[0] = data_i[0];
    
    inv_unit inv_unit_bit1(
        .a       (data_i[1]     ),
        .b       (data_i[0]     ),
        .xor_o   (inv_o[1]      ),  
        .or_o    (wire_cout[0]  )   
    );
    
    genvar i;
    generate 
        for(i=2;i<=5;i=i+1) begin
            inv_unit inv_unit_inst(
                .a       (data_i[i]       ),
                .b       (wire_cout[i-2]  ),
                .xor_o   (inv_o[i]        ),  
                .or_o    (wire_cout[i-1]  )   
            );
        end
    endgenerate
    
    inv_unit_nor_out inv_unit_nor_out_inst_6(
        .a       (data_i[6]     ),
        .b       (wire_cout[4]  ),
        .xor_o   (inv_o[6]      ),  
        .nor_o   (wire_cout[5]  )   
    );
    
    inv_unit_nor_out inv_unit_nor_out_inst_7(
        .a       (data_i[7]     ),
        .b       (not_o         ),  
        .xor_o   (inv_o[7]      ),  
        .nor_o   (              )   
    );
    
    

    assign not_o     = ~wire_cout[5]   ;
    

    assign inv_o[8] = ~(wire_cout[5] | data_i[7]);
    
endmodule