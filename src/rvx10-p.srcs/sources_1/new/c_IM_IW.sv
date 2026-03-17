module c_IM_IW (
  input  logic       clk, reset, 
  input  logic       RegWriteM, 
  input  logic [1:0] ResultSrcM, 
  output logic       RegWriteW, 
  output logic [1:0] ResultSrcW
);

  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RegWriteW  <= 0;
      ResultSrcW <= 0;
    end
    else begin // Normal operation: latch inputs
      RegWriteW  <= RegWriteM;
      ResultSrcW <= ResultSrcM; 
    end
  end

endmodule
