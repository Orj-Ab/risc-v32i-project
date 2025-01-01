module decode import yarp_pkg::*; (
  input logic [31:0] instr_mem_instr_i,

  // Outputs to the control unit
  output logic [2:0] funct3_o,
  output logic [6:0] funct7_o,
  output logic [6:0] op_o,
  output logic       r_type_o,
  output logic       j_type_o,
  output logic       i_type_o,
  output logic       u_type_o,
  output logic       s_type_o,
  output logic       b_type_o, // also to the branch control

  // Outputs to the register file
  output logic [4:0] rs1_addr_o,
  output logic [4:0] rs2_addr_o,
  output logic [4:0] rd_addr_o,

  // Immediate output to the muxes (ALU)
  output logic [31:0] instr_immed_o
);

  // Internal wires and regs
  logic        r_type;
  logic        i_type;
  logic        s_type;
  logic        b_type;
  logic        u_type;
  logic        j_type;
  logic [6:0]  op;
  logic [31:0] instr_imm;
  logic [31:0] i_type_imm;
  logic [31:0] s_type_imm;
  logic [31:0] b_type_imm;
  logic [31:0] u_type_imm;
  logic [31:0] j_type_imm;

  // Decoding the 32 instruction bits
  assign op = instr_mem_instr_i[6:0];

  assign s_type_imm = {{20{instr_mem_instr_i[31]}}, instr_mem_instr_i[31:25], instr_mem_instr_i[11:7]};
  assign b_type_imm = {{21{instr_mem_instr_i[31]}}, instr_mem_instr_i[7],
                       instr_mem_instr_i[31:25], instr_mem_instr_i[11:8], 1'b0};
  assign u_type_imm = {instr_mem_instr_i[31:12], 12'b0};
  assign j_type_imm = {{12{instr_mem_instr_i[31]}}, instr_mem_instr_i[19:12],
                       instr_mem_instr_i[20], instr_mem_instr_i[30:21], 1'b0};
  assign i_type_imm = {{20{instr_mem_instr_i[31]}}, instr_mem_instr_i[31:20]};

  always_comb begin
    // Reset all type flags
    r_type = 1'b0;
    i_type = 1'b0;
    s_type = 1'b0;
    b_type = 1'b0;
    u_type = 1'b0;
    j_type = 1'b0;

    // Determine the instruction type based on the opcode
    case (op)
      R_TYPE:    r_type = 1'b1;
      I_TYPE_0,
      I_TYPE_1,
      I_TYPE_2:  i_type = 1'b1;
      S_TYPE:    s_type = 1'b1;
      B_TYPE:    b_type = 1'b1;
      U_TYPE_0,
      U_TYPE_1:  u_type = 1'b1;
      J_TYPE:    j_type = 1'b1;
      default: ;
    endcase
  end

  // Output assignment
  always_comb begin


    // Case for specific instruction types
    case (op)
      R_TYPE: begin
        rs1_addr_o = instr_mem_instr_i[19:15];
        rs2_addr_o = instr_mem_instr_i[24:20];
        rd_addr_o = instr_mem_instr_i[11:7];
        funct3_o = instr_mem_instr_i[14:12];
        funct7_o = instr_mem_instr_i[31:25];
      end
      I_TYPE_0, I_TYPE_1: begin
        rd_addr_o = instr_mem_instr_i[11:7];
        funct3_o = instr_mem_instr_i[14:12];
        rs1_addr_o = instr_mem_instr_i[19:15];
        instr_immed_o = i_type_imm;
      end
      S_TYPE: begin
        rs1_addr_o = instr_mem_instr_i[19:15];
        rs2_addr_o = instr_mem_instr_i[24:20];
        funct3_o = instr_mem_instr_i[14:12];
        instr_immed_o = s_type_imm;
      end
      B_TYPE: begin
        rs1_addr_o = instr_mem_instr_i[19:15];
        rs2_addr_o = instr_mem_instr_i[24:20];
        funct3_o = instr_mem_instr_i[14:12];
        instr_immed_o = b_type_imm;
      end
      U_TYPE_0, U_TYPE_1: begin
        rd_addr_o = instr_mem_instr_i[11:7];
        instr_immed_o = u_type_imm;
      end
      J_TYPE: begin
        rd_addr_o = instr_mem_instr_i[11:7];
        instr_immed_o = j_type_imm;
      end
     // default: ;
    endcase
  end

  // Output type flags
  assign r_type_o = r_type;
  assign i_type_o = i_type;
  assign s_type_o = s_type;
  assign b_type_o = b_type;
  assign u_type_o = u_type;
  assign j_type_o = j_type;
  assign op_o = op;

endmodule
