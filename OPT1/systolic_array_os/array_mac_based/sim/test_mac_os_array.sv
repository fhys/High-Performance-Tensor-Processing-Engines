module test_opt2os_array();
/************************************************/
/*    Sub-Matrix Block Matrix Multiplication    */
/*    A[M,K] * B[K,N] = C[M,N]                  */
/************************************************/
//K can be adjusted arbitrarily in software, 
//while modifying M and N requires changing the array dimension in the TPE.
parameter  M = 32; 
parameter  K = 32;
parameter  N = 32;
parameter  clk_T = 2.0 ;
parameter  WIDTH = 8;
parameter  RESULT_WIDTH = 32;
localparam CLOG_M = $clog2(M);

reg                              clk;
reg                              rst_n;
reg                              clc; // clean_result_cache,
reg signed [WIDTH*M-1:0]         operand_a;
reg signed [WIDTH*N-1:0]         operand_b;
reg                              data_valid;
wire                             pip_stage;
wire       [N-1:0]               result_valid;
reg        [CLOG_M  :0]          row_count [0:N-1];
reg signed [WIDTH -1:0]          matrix_a  [0:M-1][0:K-1];
reg signed [WIDTH -1:0]          matrix_b  [0:K-1][0:N-1];
reg signed [RESULT_WIDTH-1:0]    matrix_c  [0:M-1][0:N-1];
reg signed [RESULT_WIDTH-1:0]    tpe_matrix_c [0:M-1][0:N-1];
wire       [RESULT_WIDTH*M*N-1:0]  result;
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
    integer i, j;
    begin
      for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < K; j = j + 1) begin
          matrix_a[i][j] = $urandom_range(127, -128);
        end
      end
    end
  endtask

  task generate_int8_matrix_b; 
    integer i, j;
    begin
      for (i = 0; i < K; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          matrix_b[i][j] = $urandom_range(127, -128);
        end
      end
    end
  endtask
   
// get standard matrix_multiply result
  task matrix_multiply;
    integer i, j, k;
    integer sum;
    begin
      for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          sum = 0;
          for (k = 0; k < K; k = k + 1) begin
            sum = sum + (matrix_a[i][k] * matrix_b[k][j]);
            // $display("a: %d, i: %d, k: %d, b: %d, c: %d", matrix_a[i][k], i, k,matrix_b[k][j], sum);
          end
          matrix_c[i][j] = sum;
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
begin 
    // Initialize matrices b
    for (times_b = 0; times_b < 10; times_b = times_b + 1) begin
      generate_int8_matrix_b();
      // Generate matrix_a and perform matrix multiplication
      for (times_a = 0; times_a < 10; times_a = times_a + 1) begin
          generate_int8_matrix_a();
          matrix_multiply();
        for(cycle = 0; cycle < (M+N+K); cycle = cycle + 1) begin
            operand_a = 'd0;
            operand_b = 'd0;
            for(i_operand_a = 0; i_operand_a < M; i_operand_a = i_operand_a + 1) begin
                if(i_operand_a <= cycle && (cycle-i_operand_a) < K)
                    operand_a[WIDTH * i_operand_a +: WIDTH] <= matrix_a[i_operand_a][cycle-i_operand_a];  // 填充 A 矩阵
            end
            for(i_operand_b = 0; i_operand_b < N; i_operand_b = i_operand_b + 1) begin
                if(i_operand_b <= cycle && (cycle-i_operand_b) < K)
                    operand_b[WIDTH * i_operand_b +: WIDTH] <= matrix_b[cycle-i_operand_b][i_operand_b];  // 填充 B 矩阵
            end
            data_valid = 1;
            #clk_T;
        end
        data_valid = 0;
        operand_a = 0;
        operand_b = 0;
        // Wait for result and check with standard matrix_multiply result
        for (i = 0; i < M+N+K; i = i + 1) begin
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
genvar i;
get_pipeline_mulwidth #(
    .N(K),       
    .WIDTH(1)    
) pipeline_stage (
    .clk(clk), 
    .rst_n(rst_n),                
    .signal(data_valid),     
    .pipeline_signal(pip_stage) 
);
generate
  for (i = 0 ; i < N ; i = i + 1) begin
    if(i == 0) begin
      get_pipeline_mulwidth #(
          .N(1),       
          .WIDTH(1)    
      ) pipeline_valid (
          .clk(clk),   
          .rst_n(rst_n),              
          .signal(pip_stage),     
          .pipeline_signal(result_valid[i]) 
      );
    end
    else begin
      get_pipeline_mulwidth #(
          .N(1),       
          .WIDTH(1)    
      ) pipeline_valid (
          .clk(clk),   
          .rst_n(rst_n),              
          .signal(result_valid[i-1]),     
          .pipeline_signal(result_valid[i]) 
      );
    end
  end
endgenerate


generate
  for (i = 0 ; i < N ; i = i + 1) begin

      always @(posedge clk or negedge rst_n) begin
       if(!rst_n || clc)
         row_count[i] <= 0;
       else
         if(result_valid[i]) begin
           if(row_count[i] == M)
             row_count[i] <= row_count[i];
           else
             row_count[i] <= row_count[i] + 1;
         end
      end

      always @(*) begin
        if(result_valid[i] && row_count[i] < M) begin
            tpe_matrix_c[row_count[i]][i] = result[(i+row_count[i]*N)*RESULT_WIDTH+:RESULT_WIDTH];
        end
      end
    end
endgenerate


task compare_matrices;
  input integer times_a;
  input integer times_b;
  integer i, j; 
  reg error_flag;
  begin
    error_flag = 0; 
    for (i = 0; i < M; i = i + 1) begin
      for (j = 0; j < N; j = j + 1) begin
        if (matrix_c[i][j] !== tpe_matrix_c[i][j]) begin
          $error("Mismatch at [%0d][%0d]: matrix_c = %d, tpe_matrix_c = %d", 
                 i, j, matrix_c[i][j], tpe_matrix_c[i][j]);
          error_flag = 1; 
          #1 $finish; 
        end
      end
    end
    if (!error_flag) begin
      $display("\033[1;32mSUCCESS: times_a=%0d, times_b=%0d, all elements match in matrix_c and tpe_matrix for size A[%0d,%0d] * B[%0d,%0d] = C[%0d,%0d]!\033[0m",times_a, times_b, M, K, K, N, M, N);
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
    .A_H                             (M             ), 
    .B_W                             (N             ), 
    .WIDTH                           (WIDTH         ),
    .ACC_WIDTH                       (RESULT_WIDTH  )  
) u_top(
    .rst_n                           (rst_n         ), // input   wire                              
    .clk                             (clk           ), // input   wire                              
    .A                               (operand_a     ), // input   wire    [A_H*WIDTH-1    :0]       
    .B                               (operand_b     ), // input   wire    [B_W*WIDTH-1    :0]       
    .clc                             (clc           ), // input   wire    clean_result_cache
    .result                          (result        )  // output  wire    [A_H*B_W*ACC_WIDTH-1  :0] 
);

endmodule



























