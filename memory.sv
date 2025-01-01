`timescale 1ns/1ps
module memory (
 input  logic           clk,
 input  logic           reset_n,
 input logic            data_mem_wr,
 input logic  [31:0]    data_mem_addr,
 input logic  [31:0]    data_mem_wr_data,
 input logic            data_mem_req,
 input logic  [1:0]     data_mem_byte_en,
 output logic [31:0]    mem_rd_data
 );

  // Memory array declaration
  logic [31:0] memory_array [0:1023];
  integer file; // Declare 'file' for file operations

 // Write logic
 always_ff @(posedge clk or negedge reset_n) begin
  if (!reset_n) begin
      // Optional reset logic
  end else if (data_mem_req && data_mem_wr) begin
      case (data_mem_byte_en)
        2'b00: begin // BYTE write
            memory_array[data_mem_addr[11:2]] <= 
                (memory_array[data_mem_addr[11:2]] & 32'hFFFFFF00) | // Clear byte
                {24'b0, data_mem_wr_data[7:0]};                     // Insert byte
        end
        2'b01: begin // HALF_WORD write
            memory_array[data_mem_addr[11:2]] <= 
                (memory_array[data_mem_addr[11:2]] & 32'hFFFF0000) | // Clear half-word
                {16'b0, data_mem_wr_data[15:0]};                    // Insert half-word
        end
        2'b11: begin // FULL_WORD write
            memory_array[data_mem_addr[11:2]] <= data_mem_wr_data;
        end
      endcase
  end
 end

 // Read logic
 always_ff @(posedge clk or negedge reset_n) begin
  if (!reset_n) begin
      mem_rd_data <= 32'b0;
  end else if (data_mem_req && ! data_mem_wr) begin
     mem_rd_data <= memory_array[data_mem_addr[11:2]];
	end
 end

 // Task to write memory contents to a file
 initial begin
    file = $fopen("mem.results", "w"); // Open the file in write mode
    if (file) $display("File mem.results opened successfully");
    else $fatal("Failed to open file mem.results");

    // Close file immediately as we only open it here for validation
    $fclose(file);
 end
    
 // Dump memory contents to file at the end of simulation
 final begin
    file = $fopen("rv32i/mem.results", "w");
    if (file) begin
        for (int i = 0; i < 1024; i++) begin
            $fwrite(file, "Address %0h: %h\n", i, memory_array[i]);
        end
        $fclose(file);
        $display("Memory contents written to mem.results.");
    end else begin
        $fatal("Error: Could not open mem.results for writing.");
    end
 end

endmodule
