`timescale 1ns/1ps


module data_mem import yarp_pkg ::*; (
   input  logic           clk,
   input  logic           reset_n,
   input  logic   [31:0]  data_wr_data_i,
   input  logic           data_wr_i,
   input  logic           data_req_i,
   input  logic   [31:0]  data_addr_i,
   input  logic   [1:0]   data_byte_en_i,
   input  logic           data_zero_extnd_i,
   
   
   output logic   [31:0]  data_mem_rd_data_o
   
   );
   
  logic [31:0] rd_data_zero_extnd;
  logic [31:0] mem_rd_data_i;
  logic [31:0] data_mem_rd_data;
  logic [31:0] rd_data_sign_extnd;
  
  
  logic [31:0] data_memory [0:1023];
  
always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        // Optional reset logic
    end else if (data_req_i) begin
        if (data_wr_i) begin
            // Write operation
            if (data_byte_en_i == BYTE) begin
                // Byte write: Mask and update the byte
                data_memory[data_addr_i[11:2]] <= 
                    (data_memory[data_addr_i[11:2]] & 32'hFFFFFF00) | // Clear the least significant byte
                    {24'b0, data_wr_data_i[7:0]};                   // Insert the byte
            end else if (data_byte_en_i == HALF_WORD) begin
                // Half-word write: Mask and update the half-word
                data_memory[data_addr_i[11:2]] <= 
                    (data_memory[data_addr_i[11:2]] & 32'hFFFF0000) | // Clear the least significant half-word
                    {16'b0, data_wr_data_i[15:0]};                   // Insert the half-word
            end else begin
                // Full word write
                data_memory[data_addr_i[11:2]] <= data_wr_data_i;
            end
        end else begin
            // Read operation
            mem_rd_data_i <= data_memory[data_addr_i[11:2]];
        end
    end
end


  assign rd_data_sign_extnd = (data_byte_en_i == BYTE)      ? {{24{mem_rd_data_i[7]}} , mem_rd_data_i[7:0]}:
                              (data_byte_en_i == HALF_WORD) ? {{16{mem_rd_data_i[15]}} , mem_rd_data_i[15:0]}:
                                                                               mem_rd_data_i;
																			   
 
 
   assign rd_data_zero_extnd = (data_byte_en_i == BYTE)      ? {{24{1'b0}} , mem_rd_data_i[7:0]}:
                              (data_byte_en_i == HALF_WORD)  ? {{16{1'b0}} , mem_rd_data_i[15:0]}:
                                                                               mem_rd_data_i;
																			   


  assign data_mem_rd_data = data_zero_extnd_i ? rd_data_zero_extnd : rd_data_sign_extnd ; 



  assign data_mem_rd_data_o = data_mem_rd_data ;

endmodule  

                              
    		
	    
  
  
  
   
