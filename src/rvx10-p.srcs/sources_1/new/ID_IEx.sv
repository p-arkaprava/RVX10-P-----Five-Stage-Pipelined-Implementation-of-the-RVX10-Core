`timescale 1ns / 1ps

module ID_IEx  (
  input  logic       clk, reset, clear,
  input  logic [31:0] RD1D, RD2D, PCD, 
  input  logic [4:0] Rs1D, Rs2D, RdD, 
  input  logic [31:0] ImmExtD, PCPlus4D,
  output logic [31:0] RD1E, RD2E, PCE, 
  output logic [4:0] Rs1E, Rs2E, RdE, 
  output logic [31:0] ImmExtE, PCPlus4E,
  
  // --- MODIFICATION: VALID BIT ---
  input  logic       valid_in,  // Valid bit from decode
  output logic       valid_out  // Valid bit for execute
  // -------------------------------
);

  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RD1E     <= 0;
      RD2E     <= 0;
      PCE      <= 0;
      Rs1E     <= 0;
      Rs2E     <= 0;
      RdE      <= 0;
      ImmExtE  <= 0;
      PCPlus4E <= 0;
      valid_out<= 0; // Clear valid bit
    end
    else if (clear) begin // Synchronous clear (flushes to 0)
      RD1E     <= 0;
      RD2E     <= 0;
      PCE      <= 0;
      Rs1E     <= 0;
      Rs2E     <= 0;
      RdE      <= 0;
      ImmExtE  <= 0;
      PCPlus4E <= 0;
      valid_out<= 0; // Clear valid bit
    end
    else begin // Normal operation: latch inputs
      RD1E     <= RD1D;
      RD2E     <= RD2D;
      PCE      <= PCD;
      Rs1E     <= Rs1D;
      Rs2E     <= Rs2D;
      RdE      <= RdD;
      ImmExtE  <= ImmExtD;
      PCPlus4E <= PCPlus4D;
      valid_out<= valid_in; // Propagate valid bit
    end
  end

endmodule
