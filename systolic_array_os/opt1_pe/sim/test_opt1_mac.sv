module test_opt1_mac();

parameter clk_T = 2.0 ;
parameter ACC_WIDTH = 32;
reg clk;  
reg rst_n;
reg  [7:0]            operand_a_in;
reg  [7:0]            operand_b_in;
wire [ACC_WIDTH-1:0]  acc_sum;
wire [ACC_WIDTH-1:0]  acc_carry;
wire [ACC_WIDTH-1:0]  full_sum;

reg         [15:0]           standard_mul_result;
reg  signed [ACC_WIDTH-1:0]  standard_result;


initial begin
    initialize();
    integrity_test(); 
    random_test();
end

always #(clk_T/2) clk  = ~clk;

task 	initialize();
begin	
	clk = 0;
  rst_n = 0;
  operand_a_in = 0;
  operand_b_in = 0;
	#clk_T;
  #clk_T;
  rst_n = 1;
  #clk_T;
end
endtask

task 	integrity_test();
        integer a;
        integer b;
begin  
    for (a = -128; a <= 127; a = a + 1) begin
        for (b = -128; b <= 127; b = b + 1) begin
            operand_a_in = a;
            operand_b_in = b;
            #clk_T;
            if (standard_result != full_sum) begin
                $display("Error: a: %d , b: %d", a, b);
            end
        end
        operand_a_in = 0;
        operand_b_in = 0;
        #clk_T;
        rst_n = 0;
        #clk_T;
        #clk_T;
        rst_n = 1;
        #clk_T;
    end
    // $finish; 
end
endtask


task 	random_test();
        integer a;
        integer b;
begin  
    for (a = 0; a <= 10; a = a + 1) begin
        for (b = 0; b <= 32768; b = b + 1) begin
            operand_a_in =  $urandom_range(127, -128);
            operand_b_in =  $urandom_range(127, -128);
            #clk_T;
            if (standard_result != full_sum) begin
                $display("Error: a: %d , b: %d", a, b);
            end
        end
        operand_a_in = 0;
        operand_b_in = 0;
        #clk_T;
        rst_n = 0;
        #clk_T;
        #clk_T;
        rst_n = 1;
        #clk_T;
    end
    $finish; 
end
endtask

/* standard multiplication-accumulator output */
always @(posedge clk) begin
  if(!rst_n) begin
    standard_result     <= 0;  
    standard_mul_result <= 0;
  end
  else begin
    standard_result <= standard_result + $signed(standard_mul_result); 
    standard_mul_result <= $signed(operand_a_in) * $signed(operand_b_in);
  end
end
/**********************************************/


/* summing sum and carry in OPT1-PE. Please note that in the actual system, when the accumulation is not completed, "full sum" is not calculated in each cycle. Here, it is only for the convenience of comparing the results */
assign full_sum = acc_sum + acc_carry;
/**********************************************/

`ifdef FSDB
initial begin
	  $fsdbDumpfile("test.fsdb");
	  // $fsdbDumpvars("+mda"); //18
    $fsdbDumpvars(); //16
    $fsdbDumpMDA();
end
`endif

opt1_mac #(
    .ACC_WIDTH(ACC_WIDTH),
    .INPUT_PIP(1)
) opt1_mac_test (
    .clk(clk),
    .rst_n(rst_n),
    .operand_a_in(operand_a_in),  
    .operand_b_in(operand_b_in),  
    .acc_sum(acc_sum),
    .acc_carry(acc_carry)
);

endmodule



























