module imem (
  input  logic [31:0] a,  // Address
  output logic [31:0] rd  // Read data (instruction)
);
  // Memory array (64 entries, 32-bits wide)
  logic [31:0] RAM[63:0];

  // Initialize memory from file
  initial begin
    // Load the contents of "risctest.mem" into the RAM array
    $readmemh("risctest.mem", RAM);
  end
    
  // Combinational read (uses lower bits of 'a' as word index)
  assign rd = RAM[a[31:2]]; // word-aligned

endmodule