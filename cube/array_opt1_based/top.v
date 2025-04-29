`timescale 1ns / 1ps

// Calculate matrix (A*B)
// Size of A is (A_H*A_W), size of B is (B_H*B_W), and A_W = B_H
// Size of output matirx A*B is (A_H*B_W)

module top #
(
    parameter N   = 8, //CHANGE
    parameter WIDTH = 8, 
    parameter ACC_WIDTH = 2*WIDTH + $clog2(N) 
)
(
    input   wire                              rst_n                           ,
    input   wire                              clk                             ,
    input   wire    [N*N*WIDTH-1    :0]       A                               ,
    input   wire    [N*N*WIDTH-1    :0]       B                               ,
    output  wire    [N*N*2*ACC_WIDTH-1  :0]     result  
);

reg  [N*N*WIDTH-1    :0]       A_reg    ;
reg  [N*N*WIDTH-1    :0]       B_reg    ;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        A_reg<={(N*N*WIDTH){1'b0}};
        B_reg<={(N*N*WIDTH){1'b0}};
    end
    else begin
        A_reg<=A;
        B_reg<=B;
    end
end


wire signed [WIDTH-1:0] d_x [0:N-1][0:N-1][0:N-1];
wire signed [2*ACC_WIDTH-1:0] d_y [0:N-1][0:N-1][0:N-1];
wire signed [WIDTH-1:0] d_z [0:N-1][0:N-1][0:N-1];


    genvar x, y, z;
    generate
        for (z = 0; z < N; z = z + 1 ) begin
            for(x = 0; x < N; x = x + 1) begin
                for (y = 0; y < N; y = y + 1 ) begin
                    if(z==0) begin
                        if(x==0) begin
                            if(y==0) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE //(1)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (A_reg[N*WIDTH*x+(y+1)*WIDTH-1 : WIDTH*N*x+y*WIDTH]              ),
                                    .i_x_b   (B_reg[N*WIDTH*z+(y+1)*WIDTH-1 : WIDTH*N*z+y*WIDTH]              ),
                                    .i_y_p   ({2*ACC_WIDTH{1'b0}}                                                           ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );                           
                            end
                            else if(y==N-1) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(3)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (A_reg[N*WIDTH*x+(y+1)*WIDTH-1 : WIDTH*N*x+y*WIDTH]              ),
                                    .i_x_b   (B_reg[N*WIDTH*z+(y+1)*WIDTH-1 : WIDTH*N*z+y*WIDTH]              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (result[N*2*ACC_WIDTH*z+(x+1)*2*ACC_WIDTH-1 : 2*ACC_WIDTH*N*z+x*2*ACC_WIDTH]         )
                                ); 
                            end
                            else begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(2)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (A_reg[N*WIDTH*x+(y+1)*WIDTH-1 : WIDTH*N*x+y*WIDTH]              ),
                                    .i_x_b   (B_reg[N*WIDTH*z+(y+1)*WIDTH-1 : WIDTH*N*z+y*WIDTH]              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );
                            end
                        end
                        else begin
                            if(y==0) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE //(6)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (A_reg[N*WIDTH*x+(y+1)*WIDTH-1 : WIDTH*N*x+y*WIDTH]              ),
                                    .i_x_b   (d_x[z][y][x-1]                                              ),
                                    .i_y_p   ({2*ACC_WIDTH{1'b0}}                                                           ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );                           
                            end
                            else if(y==N-1) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(5)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (A_reg[N*WIDTH*x+(y+1)*WIDTH-1 : WIDTH*N*x+y*WIDTH]              ),
                                    .i_x_b   (d_x[z][y][x-1]                                              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (result[N*2*ACC_WIDTH*z+(x+1)*2*ACC_WIDTH-1 : 2*ACC_WIDTH*N*z+x*2*ACC_WIDTH]         )
                                ); 
                            end
                            else begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(4)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (A_reg[N*WIDTH*x+(y+1)*WIDTH-1 : WIDTH*N*x+y*WIDTH]              ),
                                    .i_x_b   (d_x[z][y][x-1]                                              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );
                            end  
                        end
                    end
                    else begin
                        if(x==0) begin
                            if(y==0) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE //(7)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (d_z[z-1][y][x]                                              ),
                                    .i_x_b   (B_reg[N*WIDTH*z+(y+1)*WIDTH-1 : WIDTH*N*z+y*WIDTH]              ),
                                    .i_y_p   ({2*ACC_WIDTH{1'b0}}                                                          ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );                           
                            end
                            else if(y==N-1) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(9)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (d_z[z-1][y][x]                                              ),
                                    .i_x_b   (B_reg[N*WIDTH*z+(y+1)*WIDTH-1 : WIDTH*N*z+y*WIDTH]              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (result[N*2*ACC_WIDTH*z+(x+1)*2*ACC_WIDTH-1 : 2*ACC_WIDTH*N*z+x*2*ACC_WIDTH]         )
                                ); 
                            end
                            else begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(8)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (d_z[z-1][y][x]                                              ),
                                    .i_x_b   (B_reg[N*WIDTH*z+(y+1)*WIDTH-1 : WIDTH*N*z+y*WIDTH]              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );
                            end
                        end
                        else begin
                            if(y==0) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE //(10)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (d_z[z-1][y][x]                                              ),
                                    .i_x_b   (d_x[z][y][x-1]                                              ),
                                    .i_y_p   ({2*ACC_WIDTH{1'b0}}                                                        ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );                           
                            end
                            else if(y==N-1) begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(12)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (d_z[z-1][y][x]                                              ),
                                    .i_x_b   (d_x[z][y][x-1]                                              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (result[N*2*ACC_WIDTH*z+(x+1)*2*ACC_WIDTH-1 : 2*ACC_WIDTH*N*z+x*2*ACC_WIDTH]         )
                                ); 
                            end
                            else begin
                                PE #(.WIDTH(WIDTH),.ACC_WIDTH(ACC_WIDTH)) u_PE//(11)
                                (
                                    .rst_n   (rst_n                                                       ),
                                    .clk     (clk                                                         ),
                                    .i_z_a   (d_z[z-1][y][x]                                              ),
                                    .i_x_b   (d_x[z][y][x-1]                                              ),
                                    .i_y_p   (d_y[z][y-1][x]                                              ),
                                    .o_z_a   (d_z[z][y][x]                                                ),
                                    .o_x_b   (d_x[z][y][x]                                                ),
                                    .o_y_p   (d_y[z][y][x]                                                )
                                );
                            end  
                        end
                    end
                end
            end
        end
    endgenerate

endmodule
