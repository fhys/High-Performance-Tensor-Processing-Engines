module top #
(
    parameter A_H   = 16, //CHANGE
    parameter B_W   = 16, //CHANGE
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 32 //CHANGE
)
(
    input   wire                                rst_n                           ,
    input   wire                                clk                             ,
    input   wire    [A_H*WIDTH-1    :0]         A                               ,
    input   wire    [B_W*WIDTH-1    :0]         B                               ,
    input   wire                                clc                             , // clean_result_cache
//    output  wire    [A_H*B_W*ACC_WIDTH-1  :0] result  
    output  wire    [2*A_H*B_W*ACC_WIDTH-1  :0] result  
);

reg [A_H*WIDTH-1    :0]       A_reg                               ;
reg [B_W*WIDTH-1    :0]       B_reg                               ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        A_reg<={(A_H*WIDTH){1'b0}};
        B_reg<={(B_W*WIDTH){1'b0}};
    end
    else begin
        A_reg<=A;
        B_reg<=B;
    end
end

wire signed [WIDTH-1:0] row [0:A_H-1][0:B_W-1];
wire signed [WIDTH-1:0] col [0:A_H-1][0:B_W-1];


    genvar i, j;
    generate
        for (i = 0; i < A_H; i = i + 1 ) begin
            for(j = 0; j < B_W; j = j + 1) begin
                if(i==0) begin
                    if(j==0) begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                            .rst_n  (rst_n                                                       ),
                            .clk    (clk                                                         ),
                            .a      (A_reg[WIDTH-1    :0]                                        ),
                            .b      (B_reg[WIDTH-1    :0]                                        ),
                            .clc    (clc                                                         ), // input   wire    clean_result_cache
                            .row    (row[i][j]                                                   ),
                            .col    (col[i][j]                                                   ),
//                            .result (result[(i*B_W+j+1)*ACC_WIDTH-1:(i*B_W+j)*ACC_WIDTH])
                            .result (result[(i*B_W+j+1)*2*ACC_WIDTH-1:(i*B_W+j)*2*ACC_WIDTH])
                        ); 
                    end
                    else begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                            .rst_n  (rst_n                                                       ),
                            .clk    (clk                                                         ),
                            .a      (row[i][j-1]                                                 ),
                            .b      (B_reg[WIDTH*(j+1)-1    :WIDTH*j]                            ),
                            .clc    (clc                                                         ), // input   wire    clean_result_cache
                            .row    (row[i][j]                                                   ),
                            .col    (col[i][j]                                                   ),
//                            .result (result[(i*B_W+j+1)*ACC_WIDTH-1:(i*B_W+j)*ACC_WIDTH])
                            .result (result[(i*B_W+j+1)*2*ACC_WIDTH-1:(i*B_W+j)*2*ACC_WIDTH])
                        );
                    end
                end
                else if (j==0) begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                            .rst_n  (rst_n                                                       ),
                            .clk    (clk                                                         ),
                            .a      (A_reg[WIDTH*(i+1)-1    :WIDTH*i]                            ),
                            .b      (col[i-1][j]                                                 ),
                            .clc    (clc                                                         ), // input   wire    clean_result_cache
                            .row    (row[i][j]                                                   ),
                            .col    (col[i][j]                                                   ),
//                            .result (result[(i*B_W+j+1)*ACC_WIDTH-1:(i*B_W+j)*ACC_WIDTH])
                            .result (result[(i*B_W+j+1)*2*ACC_WIDTH-1:(i*B_W+j)*2*ACC_WIDTH])
                        );
                end
                else begin
                    PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                    (
                        .rst_n  (rst_n                                                       ),
                        .clk    (clk                                                         ),
                        .a      (row[i][j-1]                                                 ),
                        .b      (col[i-1][j]                                                 ),
                        .clc    (clc                                                         ), // input   wire    clean_result_cache
                        .row    (row[i][j]                                                   ),
                        .col    (col[i][j]                                                   ),
//                        .result (result[(i*B_W+j+1)*ACC_WIDTH-1:(i*B_W+j)*ACC_WIDTH])
                        .result (result[(i*B_W+j+1)*2*ACC_WIDTH-1:(i*B_W+j)*2*ACC_WIDTH])
                    ); 
                                   
                end                  
            end
        end
    endgenerate

endmodule
