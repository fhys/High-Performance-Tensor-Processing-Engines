module test_opt3_pe_inner_product_vectors();
/************************************************/
/*    Sub-Vector Block Vector inner_product     */
/*    A[1,K] * B[K,1] = C[1,1]                  */
/************************************************/
parameter  M = 1; 
parameter  K = 32;  //divided evenly by 4
parameter  N = 1;
parameter  clk_T = 2.0 ;
parameter  RESULT_WIDTH = 32;
localparam CLOG_K = $clog2(K);

reg                              clk;
reg                              rst_n;
reg signed [7:0]                 vector_a  [0:K-1]; // used for Comparison vector input
reg signed [7:0]                 vector_b  [0:K-1];
reg signed [RESULT_WIDTH-1:0]    vector_c;         // used for Comparison output vector result

//Since the encoding bit width of EN-T is relatively low, we directly store the number of encodings in the input buffer, but an additional sign bit needs to be stored for each operand2
reg signed [7:0]                 multiplicand;
reg                              multiplicand_valid;
wire       [8:0]                 en_t_multiplicand;
wire                             en_t_multiplicand_valid; 
reg signed [1:0]                 vector_en_a  [0:K-1][0:3]; // used for pe input
reg        [K-1:0]               signed_vector;        // used for pe input
reg signed [RESULT_WIDTH-1:0]    tpe_vector_c;         // used for pe vector result
wire       [52-1:0]              pe_result;

reg                              compute_phase;
reg        [CLOG_K-1:0]          vector_b_address;
reg        [2:0]                 bw_count;
wire       [2:0]                 bw_count_control;
reg signed [2:0]                 cal_count;
wire                             result_valid;
reg signed [25:0]                fuse_result;
reg signed [31:0]                shift_result;
reg                              clr;
reg                              clr_ins;
reg        [7:0]                 en_multiplicand;
reg        [3:0]                 sign_en_multiplicand;
reg                              encode_valid;
reg        [7:0]                 operand_b;
reg        [7:0]                 operand_b_ins;
wire       [1:0]                 position;
wire       [2:0]                 cal_cycle;

// benchmark for average partial_product
reg [31:0] sum = 0;       // 
reg [31:0] cnt = 0;       // 
real average;          // 


initial begin
    initialize(); 
    random_test_vector_inner_product();
end

always #(clk_T/2) clk  = ~clk;

  task initialize();
      integer i;
    begin	
      clk = 1;
      rst_n = 0;
      clr = 0;
      encode_valid = 0;
      multiplicand = 0;
      compute_phase = 0;
      bw_count = 0 ;
      multiplicand_valid = 0;
      operand_b = 0;
      vector_c = '{default: 0};
      tpe_vector_c = '{default: 0};
      #clk_T;
      rst_n = 1;
      clr = 1;
      #clk_T;
    end
  endtask

  task generate_int8_vector_a_b; 
    integer i, j;
    begin
        for (i = 0; i < K; i = i + 1) begin
          vector_a[i] = normal_random(0, 30, -128, 127); //Normal distribution(mean,std_dev,min,max)
          vector_b[i] = normal_random(0, 30, -128, 127); //Normal distribution(mean,std_dev,min,max)
          // vector_a[i] = uniform_random(127, -128); //uniform distribution
          // vector_b[i] = uniform_random(127, -128); //uniform distribution
        end
      end
  endtask


  // get standard vector inner_product result
  task vector_inner_product;
    integer k;
    integer sum;
    begin
      sum = 0;
      for (k = 0; k < K; k = k + 1) begin
        sum = sum + (vector_a[k] * vector_b[k]);
      end
      vector_c = sum;
    end
  endtask

  // get input vector buffer for sparse_pe
  task load_encoded_vector_a_buffer;
    integer i,j,t; 
    begin
      j = 0;
      for (i = 0; i < K; i = i + 1) begin
          multiplicand = vector_a[i];
          multiplicand_valid = 1;
          if(en_t_multiplicand_valid) begin
            vector_en_a[j][0] = en_t_multiplicand[1:0];
            vector_en_a[j][1] = en_t_multiplicand[3:2];
            vector_en_a[j][2] = en_t_multiplicand[5:4];
            vector_en_a[j][3] = en_t_multiplicand[7:6];
            signed_vector[j]  = en_t_multiplicand[8];
            j = j + 1;
          end
          #clk_T;
        end
      multiplicand = 0;
      multiplicand_valid = 0;
      for (t = 0; t < 3; t = t + 1) begin
          if(en_t_multiplicand_valid) begin
            vector_en_a[j][0] = en_t_multiplicand[1:0];
            vector_en_a[j][1] = en_t_multiplicand[3:2];
            vector_en_a[j][2] = en_t_multiplicand[5:4];
            vector_en_a[j][3] = en_t_multiplicand[7:6];
            signed_vector[j] = en_t_multiplicand[8];
            j = j + 1;
            #clk_T;
          end
      end
      #clk_T;
    end
  endtask

encoder_multi_bit en_t_encoder(
    .clk(clk),
    .rst_n(rst_n),
    .multiplicand(multiplicand),  // multiplicand with sign-magnitude representation.   
    .multiplicand_valid(multiplicand_valid), // valid signal for the multiplicand
    .en_multiplicand(en_t_multiplicand), // native EN-T encoding is sent to tensorcore local memory or local rf.
    .en_multiplicand_valid(en_t_multiplicand_valid) // valid signal for the EN-T encoding
    );


task 	random_test_vector_inner_product();
    integer cycle;
    integer times_a;
    integer k;
    integer bw;
    integer d;
begin 
    // Initialize vector
      for (times_a = 1; times_a <= 1000; times_a = times_a + 1) begin
          compute_phase = 1;
          generate_int8_vector_a_b();
          vector_inner_product();
          load_encoded_vector_a_buffer();
          for (bw = 0; bw < 4; bw = bw + 1) begin
            bw_count = bw;
            for (k = 0; k < K/4; k = k + 1) begin
              en_multiplicand = {vector_en_a[4*k+3][bw],vector_en_a[4*k+2][bw],vector_en_a[4*k+1][bw],vector_en_a[4*k][bw]};
              sign_en_multiplicand = signed_vector[4*k +: 4];
              for (cycle = 1; cycle <= 4; cycle = cycle + 1) begin
                  if(cycle == 1) encode_valid = 1;
                  else encode_valid = 0;
                  #clk_T
                  clr = 1;
                  vector_b_address = 4*k+position;
                  if(cal_cycle == 0)
                    operand_b = 0;
                  else
                    operand_b = vector_b[vector_b_address];
                  cal_count = cal_cycle - cycle;
                  if(cal_count < 1)
                    break;
              end
            end
            clr = 0;
          end
        #clk_T;
        en_multiplicand = 0;
        sign_en_multiplicand = 0;
        encode_valid = 0;
        operand_b = 0;
        // Wait for result and check with standard matrix_multiply result
        for (d = 0; d < 5; d = d + 1) begin
            #clk_T;
        end
        compute_phase = 0;
        #clk_T;
        compare_matrices(times_a);
        tpe_vector_c = '{default: 0}; 
      end
    average = real'(sum) / real'(cnt); 
    $display("\033[31mAverage cal_cycle for per-operand = %.2f\033[0m", average); 
    $finish;  
end
endtask

// controll signal and result_valid
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) operand_b_ins <= 0;
  else       operand_b_ins <= operand_b;
end

get_pipeline_mulwidth #(
          .N(3),       
          .WIDTH(1)    
      ) pipeline_valid (
          .clk(clk),   
          .rst_n(rst_n),              
          .signal(clr),     
          .pipeline_signal(clr_ins) 
      );

get_pipeline_mulwidth #(
          .N(4),       
          .WIDTH(3)    
) pipeline_bw_count (
          .clk(clk),   
          .rst_n(rst_n),              
          .signal(bw_count),     
          .pipeline_signal(bw_count_control) 
      );

assign result_valid = (~clr_ins) & compute_phase;

always @(*) begin
  if(result_valid) begin
      // After intra-PE reduction completes, shift the co-located weight vectors and then merge the final results.
      fuse_result  = $signed(pe_result[25:0]) + $signed(pe_result[51:26]);
      shift_result = $signed(fuse_result << {bw_count_control,1'b0});
  end
end

always @(posedge clk) begin
  if(result_valid) begin
    tpe_vector_c <= shift_result + tpe_vector_c;
  end
end

task compare_matrices;
  input integer times_a;
  integer i, j; 
  reg error_flag;
  begin
    error_flag = 0; 
    if (tpe_vector_c !== vector_c) begin
      $error("Mismatch at times_a=%0d, expected %0d, got %0d", times_a, vector_c, tpe_vector_c);
      error_flag = 1; 
      #1 $finish; 
    end
    if (!error_flag) begin
      $display("\033[1;32mSUCCESS: times_a=%0d, elements match in tpe_vector_c and vector_c for size A[%0d,%0d] * B[%0d,%0d] = C[%0d,%0d]!\033[0m",times_a, M, K, K, N, M, N);
    end
  end
endtask

// benchmark for average partial product
always @(posedge clk) begin
  if (encode_valid) begin
    sum <= sum + cal_cycle; 
    cnt <= cnt + 1;         
  end
end

// Normal distribution generation function (compatible with mainstream simulators)
function int normal_random(int mean, std_dev, int min, max);
    real rand1, rand2, z0;
    do begin
        // range (0,1)
        rand1 = ($urandom() + 1.0) / 4294967296.0;  // 
        rand2 = ($urandom() + 1.0) / 4294967296.0;  // 
        // Box-Muller
        z0 = $sqrt(-2.0 * $ln(rand1)) * $cos(2.0 * 3.1415926 * rand2);
        z0 = z0 * std_dev + mean;  
    end while (z0 < min || z0 > max);  
    return int'(z0);
endfunction
// Uniform distribution
function int uniform_random(int max, min);
    if (min > max) begin
        uniform_random = $urandom_range(min, max);
    end else begin
        uniform_random = $urandom_range(max, min);
    end
endfunction


`ifdef FSDB
initial begin
	$fsdbDumpfile("test.fsdb");
	  // $fsdbDumpvars("+mda"); //18
    $fsdbDumpvars(); //16
    $fsdbDumpMDA();
end
`endif

top_pe opt3_pe(
    .clk(clk),
    .rst_n(rst_n),
    .clr(clr_ins),
    .en_multiplicand(en_multiplicand),   // operand a
    .sign_en_multiplicand(sign_en_multiplicand),
    .encode_valid(encode_valid),
    .operand_b(operand_b_ins), 
    .position(position),           // to prefetch operand b            
    .cal_cycle(cal_cycle),         // to prefetch operand a                 
    .pe_result(pe_result) 
);



endmodule



























