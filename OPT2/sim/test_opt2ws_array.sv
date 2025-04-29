module test_opt2ws_array();
/************************************************/
/*    Sub-Matrix Block Matrix Multiplication    */
/*    A[M,K] * B[K,N] = C[M,N]                  */
/************************************************/
//M and N can be adjusted arbitrarily in software, 
//while modifying K requires changing the reduction dimension in the TPE.
parameter  M = 32; 
parameter  K = 16;
parameter  N = 16;
parameter  clk_T = 2.0 ;
parameter  RESULT_WIDTH = 20;
localparam CLOG_M = $clog2(M);

reg                              clk;
reg                              rst_n;
reg        [127:0]               operand_a;
reg                              weight_wen;
reg        [8*N-1:0]             weight_din;
reg                              data_valid;
wire                             pip_stage;
wire       [N-1:0]               result_valid;
reg        [CLOG_M-1:0]          row_count [0:N-1];
reg signed [7:0]                 matrix_a  [0:M-1][0:K-1];
reg signed [7:0]                 matrix_b  [0:K-1][0:N-1];
reg signed [RESULT_WIDTH-1:0]    matrix_c  [0:M-1][0:N-1];
reg signed [RESULT_WIDTH-1:0]    tpe_matrix_c [0:M-1][0:N-1];
wire       [RESULT_WIDTH*N-1:0]  result;
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
      rst_n = 0;
      weight_wen = 0;
      weight_din = 0;
      data_valid = 0;
      tpe_matrix_c = '{default: 0};
      matrix_c = '{default: 0};
      #clk_T;
      for (i = 0; i < 8; i = i + 1) begin
        #clk_T;
      end
      rst_n = 1;
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
   
  task load_matrix_b;
    integer i, j; 
    begin
      for (i = 0; i < K; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          weight_din[j*8 +: 8] = matrix_b[i][j];
          weight_wen = 1;
        end
        #clk_T;
        weight_din = 0;
        weight_wen = 0;
        #clk_T;
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
begin 
    // Initialize matrices b
    for (times_b = 0; times_b < 10; times_b = times_b + 1) begin
      generate_int8_matrix_b();
      load_matrix_b(); 
      // Generate matrix_a and perform matrix multiplication
      for (times_a = 0; times_a < 10; times_a = times_a + 1) begin
          generate_int8_matrix_a();
          matrix_multiply();
        for (cycle = 0; cycle < M; cycle = cycle + 1) begin
            for (k = 0; k < K; k = k + 1) begin
              operand_a[k*8 +: 8] = matrix_a[cycle][k];
            end
            data_valid = 1;
            #clk_T;
        end
        data_valid = 0;
        operand_a = 0;
        // Wait for result and check with standard matrix_multiply result
        for (i = 0; i < 8+N; i = i + 1) begin
            #clk_T;
        end
        compare_matrices(times_a, times_b);
        tpe_matrix_c = '{default: 0};
      end
    end
    $finish;
end
endtask

// Pipeline stage for result_valid signal
genvar i;
get_pipeline_mulwidth #(
    .N(7),       
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
       if(!rst_n)
         row_count[i] <= 0;
       else
         if(result_valid[i]) begin
           if(row_count[i] == M - 1)
             row_count[i] <= 0;
           else
             row_count[i] <= row_count[i] + 1;
         end
      end

      always @(*) begin
        if(result_valid[i]) begin
            tpe_matrix_c[row_count[i]][i] = result[(i+1)*RESULT_WIDTH-1:i*RESULT_WIDTH];
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

top_tpe #(
    .N(N)
) u_top (
   .clk(clk),
   .operand_a(operand_a),
   .weight_wen(weight_wen),
   .weight_din(weight_din),
   .result(result)
);

endmodule



























