module instruction_memory (
    input logic          clk ,
    input logic          reset_n , 
    input logic          instr_mem_req_i,
    input logic  [31:0]  instr_mem_addr_i,
    output logic [31:0]  instr_mem_rd_data_o
);

// Memory declaration
    logic [31:0] memory  [0:495] ; // 256 words of 32 bits each
    initial begin 
    $readmemh("machineCode.txt", memory);
    end
 // On reset, clear output; otherwise, respond to requests
    always_ff @(posedge clk or reset_n) begin
        if (!reset_n) begin
	         instr_mem_rd_data_o<= 32'b0;  // Clear output on reset
	    end else if (instr_mem_req_i) begin
	          instr_mem_rd_data_o<= memory[instr_mem_addr_i[31:2]]; // Use upper bits for word addressing
			  
	    end
	end
endmodule
	 
 
 
 
 
