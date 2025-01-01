module fetch (
  input logic           clk,
  input logic           reset_n,
  input logic  [31:0]   instr_mem_rd_data_i,
  input logic  [31:0]   pc_q_i,
  output logic          instr_mem_req_o,
  output logic [31:0]   instr_mem_addr_o,
  output logic [31:0]   instr_mem_instr_o
 );

  always_ff @(posedge clk or reset_n) begin 
    if (!reset_n) begin
	   instr_mem_req_o <= 1'b0;
	   instr_mem_addr_o <= 32'b0;
	   instr_mem_instr_o <= 32'b0;
	end else begin
	   instr_mem_req_o <= 1'b1;
	   instr_mem_addr_o <=pc_q_i;
	   instr_mem_instr_o <=instr_mem_rd_data_i;
	end
	
  end
endmodule
 