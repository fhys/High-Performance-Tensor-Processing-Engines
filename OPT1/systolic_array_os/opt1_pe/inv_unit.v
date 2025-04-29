module inv_unit(
        input wire  a       ,
        input wire  b       ,
        output wire xor_o   ,  
        output wire or_o       
    );
    
    wire aORb       ; 
    wire aNANDb     ; 
    
    assign aORb     = a | b;
    assign aNANDb   = ~(a & b);
    assign xor_o    = (aORb & aNANDb);
    assign or_o     = aORb;
    
endmodule