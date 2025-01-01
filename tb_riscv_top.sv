`timescale 1ns/1ps

module tb_riscv_top;

    // Testbench signals
    logic clk;
    logic reset_n;
   
    // Clock generation: 10ns clock period (50MHz)
    always #5 clk = ~clk;
	initial begin
	clk = 0 ;
	reset_n = 0;
	#10 reset_n = 1;
	# 50000 $finish;
	end

    // Instantiate the DUT (Device Under Test)
    riscv_top #(
        .RESET_PC(32'h000) // Set reset PC
    ) uut (
        .clk(clk),
        .reset_n(reset_n)
  
    );
	
endmodule
