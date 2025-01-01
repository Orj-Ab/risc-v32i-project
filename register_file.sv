
module register_file (
  input  logic        clk,
  input  logic        reset_n,
  input  logic        wr_en_i,
  input  logic [4:0]  rs1_addr_i,
  input  logic [4:0]  rs2_addr_i,
  input  logic [4:0]  rd_addr_i,
  input  logic [31:0] wr_data_i,
  output logic [31:0] rs1_data_o,
  output logic [31:0] rs2_data_o
  );
  
  logic [31:0] reg_file [0:31];
  
  always_ff @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
	  for (int i=0; i < 32 ; i++) begin 
	      reg_file [i] <= 32'b0;
		end
	end else if (wr_en_i && (rd_addr_i !=5'b0)) begin
        reg_file[rd_addr_i] <= wr_data_i;
	end
   end  

    always_comb begin
	   rs1_data_o = reg_file[rs1_addr_i];
	   rs2_data_o = reg_file[rs2_addr_i];
	  end
endmodule 
	  
