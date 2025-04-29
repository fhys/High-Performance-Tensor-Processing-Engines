module test_opt2tc_array();
/************************************************/
/*    Sub-Matrix Block Matrix Multiplication    */
/*    A[K,N,N] * B[K,N,N] = C[K,N,N]            */
/************************************************/
//K can be adjusted arbitrarily in software, 
//while modifying N requires changing the reduction dimension in the TPE.
parameter  K = 17;
parameter  N = 8;
parameter  clk_T = 2.0 ;
parameter  WIDTH = 8;
parameter  RESULT_WIDTH = 2*WIDTH + $clog2(N);
localparam CLOG_N = $clog2(N);

reg                              clk;
reg                              rst_n;
reg                              clc;
reg signed [WIDTH*N*N-1:0]       operand_a;
reg signed [WIDTH*N*N-1:0]       operand_b;
reg                              data_valid;
wire                             pip_stage;
wire       [N-1:0]               result_valid [0:K-1];
reg        [CLOG_N  :0]          row_count [0:K-1][0:N-1];
reg signed [WIDTH -1:0]          matrix_a  [0:K-1][0:N-1][0:N-1];
reg signed [WIDTH -1:0]          matrix_b  [0:K-1][0:N-1][0:N-1];
reg signed [RESULT_WIDTH-1:0]    matrix_c  [0:K-1][0:N-1][0:N-1];
reg signed [RESULT_WIDTH-1:0]    tpe_matrix_c [0:K-1][0:N-1][0:N-1];
wire       [2*RESULT_WIDTH*N*N-1:0]  result;
integer                          row_index = 0;

initial begin
    initialize(); 
    random_test_gemm();
end

always #(clk_T/2) clk  = ~clk;

  task initialize();
      integer i;
    begin	
      clk = 0;
      operand_a = 0;
      operand_b = 0;
      rst_n = 0;
      clc = 1;
      data_valid = 0;
      tpe_matrix_c = '{default: 0};
      matrix_c = '{default: 0};
      #clk_T;
      for (i = 0; i < 8; i = i + 1) begin
        #clk_T;
      end
      rst_n = 1;
      clc = 0; 
    end
  endtask

  task generate_int8_matrix_a; 
    integer i, j, z;
    begin
      for (z = 0; z < K; z = z + 1) begin
        for (i = 0; i < N; i = i + 1) begin
          for (j = 0; j < N; j = j + 1) begin
            matrix_a[z][i][j] = $urandom_range(127, -128);
          end
        end
      end
    end
  endtask

  task generate_int8_matrix_b; 
    integer i, j, z;
    begin
      for (z = 0; z < K; z = z + 1) begin
        for (i = 0; i < N; i = i + 1) begin
          for (j = 0; j < N; j = j + 1) begin
            matrix_b[z][i][j] = $urandom_range(127, -128);
          end
        end
      end
    end
  endtask
   
// get standard matrix_multiply result
  task matrix_multiply;
    integer i, j, k, z;
    integer sum;
    begin
      for (z = 0; z < K; z = z + 1) begin
        for (i = 0; i < N; i = i + 1) begin
          for (j = 0; j < N; j = j + 1) begin
            sum = 0;
            for (k = 0; k < N; k = k + 1) begin
              sum = sum + (matrix_a[z][i][k] * matrix_b[z][k][j]);
               //$display("matrix_a[%d][%d][%d] * matrix_b[%d][%d][%d] : %x * %x", z, i, k, z, k, j, matrix_a[z][i][k], matrix_b[z][k][j]);
            end
            matrix_c[z][i][j] = sum;
            //$display("matrix_c[%d][%d][%d]=%x", z, i, j, matrix_c[z][i][j]);
          end
        end
      end
    end
  endtask


task 	random_test_gemm();
    integer cycle;
    integer times_a;
    integer times_b;
    integer k;
    integer i;
    integer i_operand_a, i_operand_b;
    integer j_operand_a, j_operand_b;
begin 
    // Initialize matrices b
    for (times_b = 0; times_b < 10; times_b = times_b + 1) begin
      generate_int8_matrix_b();
      // Generate matrix_a and perform matrix multiplication
      for (times_a = 0; times_a < 10; times_a = times_a + 1) begin
          generate_int8_matrix_a();
          matrix_multiply();
        for(cycle = 0; cycle < (N+N+K); cycle = cycle + 1) begin
            operand_a = 'd0;
            operand_b = 'd0;
            for(i_operand_a = 0; i_operand_a < N; i_operand_a = i_operand_a + 1) begin
                for(j_operand_a = 0; j_operand_a < N; j_operand_a = j_operand_a + 1) begin
                    if(j_operand_a <= cycle && i_operand_a <= cycle && ((cycle - (j_operand_a + i_operand_a))) < K && ((cycle - (j_operand_a + i_operand_a)) >= 0)) begin
                        operand_a[WIDTH * (i_operand_a * N + j_operand_a) +: WIDTH] = matrix_a[(cycle - (j_operand_a + i_operand_a))][i_operand_a][j_operand_a]; // ($random & 8'hff);
                    end
                end
            end
            for(i_operand_b = 0; i_operand_b < N; i_operand_b = i_operand_b + 1) begin
                for(j_operand_b = 0; j_operand_b < N; j_operand_b = j_operand_b + 1) begin
                    if(j_operand_b <= cycle && i_operand_b <= cycle && (cycle - (j_operand_b + i_operand_b)) < K && (cycle - (j_operand_b + i_operand_b)) >= 0) begin
                        operand_b[WIDTH * (i_operand_b * N + j_operand_b) +: WIDTH] = matrix_b[(cycle - (j_operand_b + i_operand_b))][j_operand_b][i_operand_b]; // ($random & 8'hff);
                    end
                end
            end
            data_valid = 1;
            #clk_T;
        end
        data_valid = 0;
        operand_a = 0;
        operand_b = 0;
        // Wait for result and check with standard matrix_multiply result
        for (i = 0; i < N+N+K; i = i + 1) begin
            #clk_T;
        end
        compare_matrices(times_a, times_b);
        tpe_matrix_c = '{default: 0};
        clc = 1; 
        #clk_T;
        clc = 0; 
      end
    end
    $finish;
end
endtask

// Pipeline stage for result_valid signal
genvar i,z;
get_pipeline_mulwidth #(
    .N(N),       
    .WIDTH(1)    
) pipeline_stage (
    .clk(clk), 
    .rst_n(rst_n),                
    .signal(data_valid),     
    .pipeline_signal(pip_stage) 
);

generate
for (z = 0 ; z < K ; z = z + 1) begin
  if(z==0)begin
      for (i = 0 ; i < N ; i = i + 1) begin
        if(i == 0) begin
          get_pipeline_mulwidth #(
              .N(1),       
              .WIDTH(1)    
          ) pipeline_valid_0 (
              .clk(clk),   
              .rst_n(rst_n),              
              .signal(pip_stage),     
              .pipeline_signal(result_valid[z][i]) 
          );
        end 
        else begin
          get_pipeline_mulwidth #(
              .N(1),       
              .WIDTH(1)    
          ) pipeline_valid_1 (
              .clk(clk),   
              .rst_n(rst_n),              
              .signal(result_valid[z][i-1]),     
              .pipeline_signal(result_valid[z][i]) 
          );
        end
      end
  end else begin
      get_pipeline_mulwidth #(
          .N(1),       
          .WIDTH(N)    
      ) pipeline_valid_2 (
          .clk(clk),   
          .rst_n(rst_n),              
          .signal(result_valid[z-1]),     
          .pipeline_signal(result_valid[z]) 
      );
  end
end
endgenerate


generate
for (z = 0 ; z < K; z = z + 1) begin
  for (i = 0 ; i < N ; i = i + 1) begin
      if(z == 0) begin
          always @(posedge clk or negedge rst_n) begin
           if(!rst_n || clc)
             row_count[z][i] <= 0;
           else
             if(result_valid[z][i]) begin
               if(row_count[z][i] == N)
                 row_count[z][i] <= row_count[z][i];
               else
                 row_count[z][i] <= row_count[z][i] + 1;
             end
          end
      end else begin
            always @(posedge clk or negedge rst_n) begin
               if(!rst_n || clc)
                 row_count[z][i] <= 0;
               else
                 row_count[z][i] <= row_count[z-1][i];
            end
      end

      always @(posedge clk) begin
        if(result_valid[z][i] && row_count[z][i] < N) begin
            tpe_matrix_c[z][row_count[z][i]][i] = (result[(i*N+row_count[z][i])*2*RESULT_WIDTH+:RESULT_WIDTH]+result[((i*N+row_count[z][i])*2+1)*RESULT_WIDTH+:RESULT_WIDTH]);
            //$display("result_valid[%d][%d]=%d, i=%d, row_count[%d][%d]=%d, z=%d, tpe=%x",i, z, result_valid[i][z], i, i, z, row_count[i][z], z, tpe_matrix_c[z][row_count[i][z]][i]);
        end
      end

  end
end
endgenerate


task compare_matrices;
  input integer times_a;
  input integer times_b;
  integer i, j, z; 
  reg error_flag;
  begin
    error_flag = 0; 
    for (z = 0; z < K; z = z + 1) begin
        for (i = 0; i < N; i = i + 1) begin
          for (j = 0; j < N; j = j + 1) begin
            if (matrix_c[z][i][j] !== tpe_matrix_c[z][i][j]) begin
              $error("Mismatch at [%0d][%0d][%0d]: matrix_c = %d, tpe_matrix_c = %d", 
                     z, i, j, matrix_c[z][i][j], tpe_matrix_c[z][i][j]);
              error_flag = 1; 
              #1 $finish; 
            end
          end
        end
    end
    if (!error_flag) begin
      $display("\033[1;32mSUCCESS: times_a=%0d, times_b=%0d, all elements match in matrix_c and tpe_matrix for size A[%d,%0d,%0d] * B[%d,%0d,%0d] = C[%0d,%0d,%0d]!\033[0m",times_a, times_b, K, N, N, K, N, N, K, N, N);
    end
  end
endtask


`ifdef FSDB
initial begin
	$fsdbDumpfile("test.fsdb");
	  // $fsdbDumpvars("+mda"); //18
    $fsdbDumpvars(); //16
    $fsdbDumpMDA();
end
`endif

top #
(
    .N                               (N             ), 
    .WIDTH                           (WIDTH         ),
    .ACC_WIDTH                       (RESULT_WIDTH  )  
) u_top(
    .rst_n                           (rst_n         ), // input   wire                              
    .clk                             (clk           ), // input   wire                              
    .A                               (operand_a     ), // input   wire    [A_H*WIDTH-1    :0]       
    .B                               (operand_b     ), // input   wire    [B_W*WIDTH-1    :0]       
    .result                          (result        )  // output  wire    [A_H*B_W*ACC_WIDTH-1  :0] 
);

endmodule



























