`timescale 1ns/1ps  


module branch_control import yarp_pkg ::*;(
    //branch type
	input   logic             is_b_type_clt_i,
	input   logic   [2:0]     instr_func3_clt_i,
	
	//sources operands
    input   logic   [31:0] 	  opr_a_i,
	input   logic   [31:0] 	  opr_b_i,
	
	//branch outcome
	output  logic     branch_taken_o
);

   //internal signals
   logic  [31:0]   twos_compl_a;
   logic  [31:0]   twos_compl_b;
   
   logic  branch_taken;
   
   //computation of the twos compliment (for signed operation)
   assign  twos_compl_a = opr_a_i[31] ? ~opr_a_i + 32'h1 : opr_a_i;
   assign  twos_compl_b = opr_b_i[31] ? ~opr_b_i + 32'h1 : opr_b_i;
   
   
   // Branch condition logic based on funct3
    always_comb begin
	    case (instr_func3_clt_i)
		   BEQ     :   branch_taken = (opr_a_i==opr_b_i);
		   BNE     :   branch_taken = (opr_a_i!=opr_b_i);
           BLT     :   branch_taken = (twos_compl_a < twos_compl_b);
           BGE     :   branch_taken = (twos_compl_a >= twos_compl_b);
           BLTU    :   branch_taken = (opr_a_i < opr_b_i);
           BGEU    :   branch_taken = (opr_a_i >= opr_b_i);
           default :   branch_taken = 1'b0;
		endcase
	end
	

  // Final branch decision: only if it's a branch-type instruction
  
  assign branch_taken_o = is_b_type_clt_i & branch_taken ; 
  
 endmodule
 
   
	
	