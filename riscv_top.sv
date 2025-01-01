`timescale 1ns/1ps


module riscv_top import yarp_pkg::*; 
     
	
(
	input  logic              clk,
	input  logic              reset_n
	////must be internal signals not 
	//instruction memory interface
	//input   logic   [31:0]   instr_mem_rd_data_i,
	
	//output  logic   [31:0]   instr_mem_addr_o,
	//output  logic            instr_mem_req_o,
	
	//data memory interface
	//input   logic   [31:0]   data_mem_rd_data_i,
	
	//output  logic   [31:0]   data_mem_addr_o,
	//output  logic   [31:0]   data_mem_wr_data_o,
	//output  logic   [1:0]    data_mem_byte_en_o,
	//output  logic            data_mem_wr_o,
	//output  logic            data_mem_req_o
);
parameter RESET_PC = 32'h1000;

   //internal signals
   logic   [31:0]    instr, pc_q,instr_instr;
   logic   [4:0]     rs1,rs2,rd;
   logic   [31:0]    rs1_data,rs2_data,wr_data;
   logic   [31:0]    alu_opr_a,alu_opr_b;
   logic   [3:0]     alu_func;
   logic   [31:0]    alu_res;
   logic             r_type, i_type, s_type, b_type, u_type, j_type;
   logic   [6:0]     opcode;
   logic   [6:0]     funct7;
   logic   [2:0]     funct3;
   logic   [31:0]    imm;
   logic             branch_taken, zero_extnd, data_req, data_wr, pc_sel, op1_sel, op2_sel, rf_wr_en;
   logic   [31:0]    mem_rd_data,mem_rd_data_from_mem,mem_rd_data_final;
   logic   [1:0]     rf_wr_data_sel, data_byte;
   logic   [31:0]    next_seq_pc, next_pc,instr_addr;
   logic             reset_seen_q, instr_mem_req; 

   
  // Capture reset state
    always_ff @ (posedge clk or negedge reset_n) begin
       if(!reset_n) begin
	     reset_seen_q <= 1'b0;
	   end else begin 
	     reset_seen_q <= 1'b1;
	   end
    end

  // program counter (pc) logic 
    assign next_seq_pc = pc_q + 32'h4;
    assign next_pc = (branch_taken | pc_sel) ? {alu_res[31:0],1'b0} : next_seq_pc;
  
    always_ff @  (posedge clk or negedge reset_n) begin
       if(!reset_n) begin
	     pc_q <= RESET_PC;
	   end else if (reset_seen_q) begin
	     pc_q <= next_pc;
		end
	end

  
  //instruction memory
    instruction_memory u_yarp_instruction_memory (
	     .clk                       (clk),
		 .reset_n                   (reset_n),
		 .instr_mem_req_i           (instr_mem_req),
		 .instr_mem_addr_i          (instr_addr),
		 .instr_mem_rd_data_o       (instr_instr)
	);
	
	
	   
  //instruction fetch
    fetch u_yarp_fetch (
         .clk                       (clk),
		 .reset_n                   (reset_n),
         .instr_mem_rd_data_i       (instr_instr),
		 .instr_mem_req_o           (instr_mem_req), 
		 .instr_mem_addr_o          (instr_addr),
		 .pc_q_i                    (pc_q),
		 .instr_mem_instr_o         (instr)
		 
	);
	
	// Instruction Decode
	decode u_yarp_decode (
	     .instr_mem_instr_i  (instr),
	     .funct3_o           (funct3),
		 .funct7_o           (funct7),
		 .op_o               (opcode),
		 .r_type_o           (r_type),
         .j_type_o           (j_type),
         .i_type_o           (i_type),
         .u_type_o           (u_type),
         .s_type_o           (s_type),
         .b_type_o           (b_type),
		 .rs1_addr_o         (rs1),
		 .rs2_addr_o         (rs2),
		 .rd_addr_o          (rd),
		 .instr_immed_o      (imm)
	);
	
		 
		 
	// register file
	  assign wr_data = (rf_wr_data_sel == ALU) ? alu_res :
	                   (rf_wr_data_sel == MEM) ? mem_rd_data_final :
					   (rf_wr_data_sel == IMM) ? imm :
					                             next_seq_pc ; 
	register_file  u_yarp_register_file (
	     .clk               (clk),
		 .reset_n           (reset_n),
		 .wr_en_i           (rf_wr_en),
		 .rs1_addr_i        (rs1),
		 .rs2_addr_i        (rs2),
		 .rd_addr_i         (rd),
		 .wr_data_i         (wr_data),
		 .rs1_data_o        (rs1_data),
		 .rs2_data_o        (rs2_data)
	);
	
	// Control Unit
	Control_unit u_yarp_control_unit (
         .instr_opcode_i         (opcode),
         .instr_funct3_i         (funct3),
		 .instr_funct7_bit5_i    (funct7[5]),
		 .is_j_type_i            (j_type),
         .is_i_type_i            (i_type),
         .is_r_type_i            (r_type),
         .is_b_type_i            (b_type),
         .is_u_type_i            (u_type),
         .is_s_type_i            (s_type),
		 .pc_sel_o               (pc_sel),
		 .op1_sel_o              (op1_sel),
		 .op2_sel_o              (op2_sel),
		 .data_req_o             (data_req),
		 .data_wr_o              (data_wr),
		 .zero_extnd_o           (zero_extnd),
		 .rf_wr_en_o             (rf_wr_en),
		 .rf_wr_data_o           (rf_wr_data_sel),
		 .alu_funct_o            (alu_func),
		 .data_byte_o            (data_byte)
	);
	
	// --------------------------------------------------------
    // Branch Control
    // --------------------------------------------------------
	
	branch_control u_yarp_branch_control (
	     .is_b_type_clt_i       (b_type),
		 .instr_func3_clt_i     (funct3),
		 .opr_a_i               (rs1_data),
		 .opr_b_i               (rs2_data),
		 .branch_taken_o        (branch_taken)
    );

    // --------------------------------------------------------
    // Execute Unit
    // --------------------------------------------------------
	//ALU operand mux
	assign alu_opr_a = op1_sel ? pc_q : rs1_data;
	assign alu_opr_b = op2_sel ? imm : rs2_data;
	
	execute u_yarp_execute (
	     .opr_a_i               (alu_opr_a),
		 .opr_b_i               (alu_opr_b),
         .alu_funct_i           (alu_func),
		 .alu_res_o             (alu_res)
	);
	
	/////////check inputs and outputs with between data memory and memory so we can add them properly to the top
	// --------------------------------------------------------
    // Data Memory (Internal)
    // --------------------------------------------------------
    data_mem u_yarp_data_mem (
	     .clk                  (clk),
		 .reset_n              (reset_n),
		 .data_mem_rd_data_o   (mem_rd_data_final),
		 .data_zero_extnd_i    (zero_extnd),
		 .data_byte_en_i       (data_byte),
		 .data_addr_i          (alu_res),
		 .data_req_i           (data_req),
		 .data_wr_i            (data_wr),
		 .data_wr_data_i       (rs2_data)
	);
	
	// --------------------------------------------------------
    // Data Memory (Internal)
    // --------------------------------------------------------
    memory u_yarp_memory (
         .clk                 (clk),
		 .reset_n             (reset_n),
		 .data_mem_wr         (data_wr),
		 .data_mem_addr       (alu_res),
		 .data_mem_wr_data    (rs2_data),
		 .data_mem_req        (data_req),
		 .data_mem_byte_en    (data_byte),
		 .mem_rd_data         (mem_rd_data_from_mem)
    );
		 
    // Connect internal wires to top module ports
       assign  instr_mem_req_o      = instr_mem_req;
       assign  instr_mem_addr_o     = instr_addr;
	   assign  instr_mem_rd_data_i  = instr_instr;
	   assign  data_mem_rd_data_i   = mem_rd_data;
	   assign  data_mem_addr_o      = alu_res;
	   assign  data_mem_byte_en_o   = data_byte;
	   assign  data_mem_wr_o        = data_wr;
	   assign  data_mem_req_o       = data_req;
	   
endmodule
	   
	   
 