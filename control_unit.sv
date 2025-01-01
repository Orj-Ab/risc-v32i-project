`timescale 1ns/1ps


module Control_unit import yarp_pkg::*;(  
 //instruction type
 input   logic   is_j_type_i,
 input   logic   is_i_type_i,
 input   logic   is_b_type_i,
 input   logic   is_u_type_i,
 input   logic   is_r_type_i,
 input   logic   is_s_type_i,
 
 // Instruction opcode/funct fields
 input   logic  [6:0]  instr_opcode_i,
 input   logic  [2:0]  instr_funct3_i,
 input   logic         instr_funct7_bit5_i,
 
 // Control signals
 output   logic   pc_sel_o,
 output   logic   op1_sel_o,
 output   logic   op2_sel_o,
 output   logic   data_req_o,
 output   logic   data_wr_o,
 output   logic   zero_extnd_o,
 output   logic   rf_wr_en_o,
 output   logic   [1:0]  rf_wr_data_o,
 output   logic   [1:0]  data_byte_o,
 output   logic   [3:0]  alu_funct_o
);

//internal signals
logic [3:0] instr_funct_rtype;
logic [3:0] instr_funct_itype; // I-type funct bits
logic [3:0] instr_opc;
control_t   r_type_controls;
control_t   s_type_controls;
control_t   u_type_controls;
control_t   b_type_controls;
control_t   j_type_controls;
control_t   i_type_controls;
control_t   controls;

// R-type
// --------------------------------------------------------
// Construct funct bits for R-type isntruction
assign instr_funct_rtype = {instr_funct7_bit5_i , instr_funct3_i} ; 
always_comb begin
r_type_controls = '0;
r_type_controls.rf_wr_en = 1'b1 ; 
r_type_controls.rf_wr_data_sel = ALU;
  case (instr_funct_rtype)
    ADD      :  r_type_controls.alu_funct_sel = OP_ADD;
	SUB      :  r_type_controls.alu_funct_sel = OP_SUB;
	SLL      :  r_type_controls.alu_funct_sel = OP_SLL;
	SLT      :  r_type_controls.alu_funct_sel = OP_SLT;
	SLTU     :  r_type_controls.alu_funct_sel = OP_SLTU;
	XOR      :  r_type_controls.alu_funct_sel = OP_XOR;
	SRL      :  r_type_controls.alu_funct_sel = OP_SRL;
	SRA      :  r_type_controls.alu_funct_sel = OP_SRA;
	OR       :  r_type_controls.alu_funct_sel = OP_OR;
	AND      :  r_type_controls.alu_funct_sel = OP_AND;
	default  :  r_type_controls.alu_funct_sel = OP_ADD;
endcase
end


// I-type
// --------------------------------------------------------
// Construct opcode bits for I-type isntruction
assign instr_funct_itype = {instr_opcode_i[4] , instr_funct3_i} ; 
always_comb begin
i_type_controls = '0;
i_type_controls.rf_wr_en = 1'b1 ;
i_type_controls.op2_sel  = 1'b1;

case (instr_opc)
   LB     :  {i_type_controls.data_req,
                      i_type_controls.data_byte,
                      i_type_controls.rf_wr_data_sel} = {1'b1, BYTE, MEM};
   LH     :  {i_type_controls.data_req,
                      i_type_controls.data_byte,
					  i_type_controls.rf_wr_data_sel} = {1'b1, HALF_WORD,MEM};
   LW     :  {i_type_controls.data_req,
                      i_type_controls.data_byte,
					  i_type_controls.rf_wr_data_sel} = {1'b1, WORD,MEM};
   LBU    :  {i_type_controls.data_req,
                      i_type_controls.data_byte,
					  i_type_controls.rf_wr_data_sel,
					  i_type_controls.zero_extnd} = {1'b1, BYTE,MEM,1'b1};
   LHU    :  {i_type_controls.data_req,
                      i_type_controls.data_byte,
					  i_type_controls.rf_wr_data_sel,
					  i_type_controls.zero_extnd} = {1'b1,HALF_WORD,MEM,1'b1};
   ADDI   :  i_type_controls.alu_funct_sel = OP_ADD;
   SLTI   :  i_type_controls.alu_funct_sel = OP_SLT;
   SLTIU  :  i_type_controls.alu_funct_sel = OP_SLTU;
   XORI   :  i_type_controls.alu_funct_sel = OP_XOR;
   ORI     :  i_type_controls.alu_funct_sel = OP_OR;
   ANDI    :  i_type_controls.alu_funct_sel = OP_AND;
   SLLI   :  i_type_controls.alu_funct_sel = OP_SLL;
   SRXI   :  i_type_controls.alu_funct_sel = instr_funct7_bit5_i ? OP_SRA : OP_SRL;
   //default:  i_type_controls = '0;
 endcase
 // JALR
    if ((instr_opcode_i == I_TYPE_2)) begin
      i_type_controls.rf_wr_data_sel  = PC;
      i_type_controls.pc_sel          = 1'b1;
      i_type_controls.alu_funct_sel   = OP_ADD;
    end
  end
  
   // --------------------------------------------------------
  // S-type
  // ---
 always_comb begin
    s_type_controls = '0;
    s_type_controls.data_req = 1'b1;
    s_type_controls.data_wr = 1'b1;
    s_type_controls.op2_sel = 1'b1; 
    case(instr_funct3_i)
      SB        :  s_type_controls.data_byte = BYTE;
      SH        :  s_type_controls.data_byte = HALF_WORD;
      SW        :  s_type_controls.data_byte = WORD;
      default   :  s_type_controls = '0;
    endcase
 end

// --------------------------------------------------------
// B-type
// --------------------------------------------------------
  always_comb begin 
     b_type_controls = '0;
	 b_type_controls.alu_funct_sel = OP_ADD;
	 b_type_controls.op1_sel = 1'b1;
	 b_type_controls.op2_sel = 1'b1;
  end
 
  // --------------------------------------------------------
  // U-type
  // --------------------------------------------------------
  always_comb begin
    u_type_controls = '0;
    u_type_controls.rf_wr_en = 1'b1;
    case (instr_opcode_i)
      AUIPC    :   {u_type_controls.op2_sel, u_type_controls.op1_sel} = {1'b1, 1'b1};
      LUI      :   u_type_controls.rf_wr_data_sel = IMM;
      default  :   u_type_controls = '0;
    endcase
  end

  // --------------------------------------------------------
  // J-type
  // --------------------------------------------------------
  always_comb begin
    j_type_controls = '0;
    j_type_controls.rf_wr_en        = 1'b1;
    j_type_controls.rf_wr_data_sel  = PC;
    j_type_controls.op2_sel         = 1'b1;
    j_type_controls.op1_sel         = 1'b1;
    j_type_controls.pc_sel          = 1'b1;
  end
  
 assign controls = is_r_type_i ? r_type_controls:
                   is_i_type_i ? i_type_controls:
                   is_b_type_i ? b_type_controls:
                   is_u_type_i ? u_type_controls:
                   is_s_type_i ? s_type_controls:
                   is_j_type_i ? j_type_controls:
				                 '0;
								 
								 
  // --------------------------------------------------------
  // Output assignments
  // --------------------------------------------------------
  
  assign  pc_sel_o        = controls.pc_sel;
  assign  op1_sel_o       = controls.op1_sel;
  assign  op2_sel_o       = controls.op2_sel;  
  assign  data_req_o      = controls.data_req;
  assign  data_wr_o       = controls.data_wr;
  assign  zero_extnd_o    = controls.zero_extnd;
  assign  rf_wr_en_o      = controls.rf_wr_en;
  assign  alu_funct_o     = controls.alu_funct_sel;
  assign  rf_wr_data_o    = controls.rf_wr_data_sel;
  assign  data_byte_o     = controls.data_byte;

endmodule


