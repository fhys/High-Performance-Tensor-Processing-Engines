// Calculate matrix (A*B)
// Size of A is (M*K), size of B is (K*N), and A_H = K, B_W = N, B is weight
// Size of output matirx A*B is (M*N)

module top #
(
    parameter A_H   = 16, //CHANGE
    parameter B_W   = 16, //CHANGE
    parameter WIDTH = 8,
    parameter ACC_WIDTH = 2*WIDTH + $clog2(A_H)
)
(
    input   wire                              clk                             ,
    input   wire                              rst_n                           ,
    input                                     weight_wen                      ,
    input           [A_H*WIDTH-1      :0]     weight_din                      ,
    input   wire    [A_H*WIDTH-1      :0]     A                               ,
    output  wire    [2*B_W*ACC_WIDTH-1  :0]   result  
);

reg  [A_H*WIDTH-1    :0]       A_reg   ;
reg  [A_H*WIDTH-1    :0]       weight_din_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        A_reg<={(A_H*WIDTH){1'b0}};
        weight_din_reg <= {(B_W*WIDTH){1'b0}};
    end
    else begin
        A_reg<=A;
        weight_din_reg <= weight_din;
    end
end


wire signed [2*ACC_WIDTH-1:0] row [0:B_W-1][0:A_H-1];
wire signed [WIDTH-1:0]     col [0:B_W-1][0:A_H-1];


    genvar i, j;
    generate
        for (i = 0; i < B_W; i = i + 1 ) begin
            for(j = 0; j < A_H; j = j + 1) begin
                if(j==0) begin
                    if(i==0) begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                        .rst_n               (rst_n                                                       ),
                        .clk                 (clk                                                         ),
                        .weight_wen          (weight_wen                                                  ),
                        .weight_din          (weight_din_reg[(j+1)*WIDTH-1:j*WIDTH]                       ),
                        .a                   (A_reg[(j+1)*WIDTH-1:j*WIDTH]                                ),
                        .partial_result      ({2*ACC_WIDTH{1'b0}}                                           ),
                        .row                 (row[i][j]                                                   ),
                        .col                 (col[i][j]                                                   )
                        ); 
                    end
                    else begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                        .rst_n               (rst_n                                                       ),
                        .clk                 (clk                                                         ),
                        .weight_wen          (weight_wen                                                  ),
                        .weight_din          (col[i-1][j]                                                 ),
                        .a                   (col[i-1][j]                                                 ),
                        .partial_result      ({2*ACC_WIDTH{1'b0}}                                           ),
                        .row                 (row[i][j]                                                   ),
                        .col                 (col[i][j]                                                   )
                        ); 
                    end
                end
                else if (i==0) begin
                    if(j==A_H-1) begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                        .rst_n               (rst_n                                                       ),
                        .clk                 (clk                                                         ),
                        .weight_wen          (weight_wen                                                  ),
                        .weight_din          (weight_din_reg[(j+1)*WIDTH-1:j*WIDTH]                       ),
                        .a                   (A_reg[(j+1)*WIDTH-1:j*WIDTH]                                ),
                        .partial_result      (row[i][j-1]                                                 ),
                        .row                 (result[(i+1)*2*ACC_WIDTH-1  :i*2*ACC_WIDTH]                     ),
                        .col                 (col[i][j]                                                   )
                        ); 
                    end
                    else begin
                        PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                        (
                        .rst_n               (rst_n                                                       ),
                        .clk                 (clk                                                         ),
                        .weight_wen          (weight_wen                                                  ),
                        .weight_din          (weight_din_reg[(j+1)*WIDTH-1:j*WIDTH]                       ),
                        .a                   (A_reg[(j+1)*WIDTH-1:j*WIDTH]                                ),
                        .partial_result      (row[i][j-1]                                                 ),
                        .row                 (row[i][j]                                                   ),
                        .col                 (col[i][j]                                                   )
                        ); 
                    end
                end
                else if (j==A_H-1) begin
                    PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                    (
                    .rst_n               (rst_n                                                       ),
                    .clk                 (clk                                                         ),
                    .weight_wen          (weight_wen                                                  ),
                    .weight_din          (col[i-1][j]                                                 ),
                    .a                   (col[i-1][j]                                                 ),
                    .partial_result      (row[i][j-1]                                                 ),
                    .row                 (result[(i+1)*2*ACC_WIDTH-1  :i*2*ACC_WIDTH]                     ),
                    .col                 (col[i][j]                                                   )
                    ); 
                end
                else begin
                    PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE
                    (
                    .rst_n               (rst_n                                                       ),
                    .clk                 (clk                                                         ),
                    .weight_wen          (weight_wen                                                  ),
                    .weight_din          (col[i-1][j]                                                 ),
                    .a                   (col[i-1][j]                                                 ),
                    .partial_result      (row[i][j-1]                                                 ),
                    .row                 (row[i][j]                                                   ),
                    .col                 (col[i][j]                                                   )
                    );   
                end
            end
        end
endgenerate

endmodule
