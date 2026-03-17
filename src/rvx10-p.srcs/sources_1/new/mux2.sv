module mux2 #(parameter WIDTH=8)(
  input  logic [WIDTH-1:0] d0, d1, // Data inputs
  input  logic             s,      // Select signal
  output logic [WIDTH-1:0] y       // Data output
);
    
  // If s=1, select d1; otherwise select d0
  assign y = s ? d1 : d0;
endmodule
