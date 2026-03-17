module IMem_IW (
  input  logic       clk, reset,
  input  logic [31:0] ALUResultM, ReadDataM,  
  input  logic [4:0] RdM, 
  input  logic [31:0] PCPlus4M,
  output logic [31:0] ALUResultW, ReadDataW,
  output logic [4:0] RdW, 
  output logic [31:0] PCPlus4W,

  // --- MODIFICATION: VALID BIT ---
  input  logic       valid_in,  // Valid bit from memory
  output logic       valid_out  // Valid bit for writeback
  // -------------------------------
);

  always_ff @( posedge clk, posedge reset ) begin 
    if (reset) begin // Asynchronous reset
      ALUResultW <= 0;
      ReadDataW  <= 0;
      RdW        <= 0; 
      PCPlus4W   <= 0;
      valid_out  <= 0; // Clear valid bit
    end
    else begin // Normal operation: latch inputs
      ALUResultW <= ALUResultM;
      ReadDataW  <= ReadDataM;
      RdW        <= RdM; 
      PCPlus4W   <= PCPlus4M;      
      valid_out  <= valid_in; // Propagate valid bit
    end
  end

endmodule
