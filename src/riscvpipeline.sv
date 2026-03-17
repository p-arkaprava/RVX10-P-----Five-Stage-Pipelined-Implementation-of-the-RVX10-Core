`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Arkaprava Paul
// 
// Create Date:
// Design Name: 
// Module Name: riscvpipeline
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top-level module for the 5-stage pipelined processor.
// 
// Dependencies: riscv.module, imem.module, dmem.module
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Modified for 5-stage pipeline
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module riscvpipeline (
  input  logic       clk, reset, 
  output logic [31:0] WriteDataM, DataAdrM, 
  output logic       MemWriteM
);
    
  // Internal wires connecting the components
  logic [31:0] PCF, InstrF, ReadDataM;
    
  // Instantiate processor and memories

  // Instantiate the RISC-V processor core
  riscv rv(
    .clk        (clk),
    .reset      (reset),
    .PCF        (PCF),
    .InstrF     (InstrF),
    .MemWriteM  (MemWriteM),
    .ALUResultM (DataAdrM),   // ALU result from MEM stage is used as data memory address
    .WriteDataM (WriteDataM),
    .ReadDataM  (ReadDataM)
  );
  
  // Instantiate the Instruction Memory
  imem imem(
    .a  (PCF),      // Address input from PCF
    .rd (InstrF)    // Read data (instruction) output to InstrF
  );
  
  // Instantiate the Data Memory
  dmem dmem(
    .clk (clk),
    .we  (MemWriteM),  // Write enable
    .a   (DataAdrM),   // Address input
    .wd  (WriteDataM), // Write data input
    .rd  (ReadDataM)   // Read data output
  );
endmodule

module riscv(
  input  logic       clk, reset,
  output logic [31:0] PCF,
  input  logic [31:0] InstrF,
  output logic       MemWriteM,
  output logic [31:0] ALUResultM, WriteDataM,
  input  logic [31:0] ReadDataM
);
    
  // Internal wires for control and data signals
  logic ALUSrcE, RegWriteM, RegWriteW, ZeroE, PCSrcE;
  logic StallD, StallF, FlushD, FlushE, ResultSrcE0;
  logic [1:0] ResultSrcW; 
  logic [1:0] ImmSrcD;
  logic [3:0] ALUControlE;
  logic [31:0] InstrD;
  logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E;
  logic [4:0] RdE, RdM, RdW;
  logic [1:0] ForwardAE, ForwardBE;
  logic validD, validE, validM, validW; // Valid bits for each stage
  
  // Instantiate the Pipelined Controller
  controller c(
    .clk        (clk),
    .reset      (reset),
    .op         (InstrD[6:0]),
    .funct3     (InstrD[14:12]),
    .funct7b5   (InstrD[30]),
    .funct7_2b  (InstrD[26:25]),
    .ZeroE      (ZeroE),
    .FlushE     (FlushE),
    .ResultSrcE0(ResultSrcE0),
    .ResultSrcW (ResultSrcW),
    .MemWriteM  (MemWriteM),
    .PCSrcE     (PCSrcE),
    .ALUSrcE    (ALUSrcE),
    .RegWriteM  (RegWriteM),
    .RegWriteW  (RegWriteW),
    .ImmSrcD    (ImmSrcD),
    .ALUControlE(ALUControlE)
  );

  // *** NEW SEPARATED UNITS (ADDED) ***
  
  // Instantiate the new Forwarding Unit
  forwarding_unit fu (
    .Rs1E     (Rs1E), 
    .Rs2E     (Rs2E),
    .RdM      (RdM), 
    .RdW      (RdW),
    .RegWriteM(RegWriteM), 
    .RegWriteW(RegWriteW),
    .ForwardAE(ForwardAE), 
    .ForwardBE(ForwardBE)
  );

  // Instantiate the new Hazard Unit
  hazard_unit hu (
    .Rs1D       (Rs1D), 
    .Rs2D       (Rs2D),
    .RdE        (RdE),
    .ResultSrcE0(ResultSrcE0),
    .PCSrcE     (PCSrcE),
    .StallD     (StallD), 
    .StallF     (StallF), 
    .FlushD     (FlushD), 
    .FlushE     (FlushE)
  );
  // *** END OF NEW INSTANTIATIONS ***

  // Instantiate the 5-Stage Pipelined Datapath
  datapath dp(
    .clk        (clk),
    .reset      (reset),
    .ResultSrcW (ResultSrcW),
    .PCSrcE     (PCSrcE),
    .ALUSrcE    (ALUSrcE),
    .RegWriteW  (RegWriteW),
    .ImmSrcD    (ImmSrcD),
    .ALUControlE(ALUControlE),
    .ZeroE      (ZeroE),
    .PCF        (PCF),
    .InstrF     (InstrF),
    .InstrD     (InstrD),
    .ALUResultM (ALUResultM),
    .WriteDataM (WriteDataM),
    .ReadDataM  (ReadDataM),
    .ForwardAE  (ForwardAE),
    .ForwardBE  (ForwardBE),
    .Rs1D       (Rs1D),
    .Rs2D       (Rs2D),
    .Rs1E       (Rs1E),
    .Rs2E       (Rs2E),
    .RdE        (RdE),
    .RdM        (RdM),
    .RdW        (RdW),
    .StallD     (StallD),
    .StallF     (StallF),
    .FlushD     (FlushD),
    .FlushE     (FlushE),

    // --- MODIFICATION: VALID BITS ADDED ---
    .validD     (validD),
    .validE     (validE),
    .validM     (validM),
    .validW     (validW)
    // --------------------------------------
  );
  
  // --- Performance Counters (Bonus) ---
  logic [31:0] cycle_count;
  logic [31:0] instr_retired;
  // ------------------------------------

  // --- Performance Counter Logic (Bonus) ---
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      // Reset counters to zero
      cycle_count   <= '0; // Use '0 to set all bits to zero
      instr_retired <= '0;
    end
    else begin
      // Always increment the cycle counter
      cycle_count <= cycle_count + 1;

      // --- MODIFICATION: RETIREMENT LOGIC ---
      // Increment instruction counter ONLY if a VALID instruction
      // reaches the WriteBack (WB) stage. This correctly
      // counts ALL retired instructions (R-type, I-type, loads,
      // stores, and branches) and ignores flushed bubbles.
      if (validW) begin
        instr_retired <= instr_retired + 1;
      end
      // --------------------------------------
    end
  end
  // -----------------------------------------

endmodule


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


module dmem(
  input  logic       clk, we,
  input  logic [31:0] a, wd,
  output logic [31:0] rd
);
    
  // Memory array (64 entries, 32-bits wide)
  logic [31:0] RAM [63:0];
    
  // Combinational read (word-aligned)
  assign rd = RAM[a[31:2]]; 
    
  // Synchronous write (on positive clock edge)
  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
    
endmodule


module controller(
  input  logic       clk, reset,
  input  logic [6:0] op,
  input  logic [2:0] funct3,
  input  logic       funct7b5,
  input  logic [1:0] funct7_2b,
  input  logic       ZeroE,
  input  logic       FlushE,
  output logic       ResultSrcE0,
  output logic [1:0] ResultSrcW,
  output logic       MemWriteM,
  output logic       PCSrcE, ALUSrcE, 
  output logic       RegWriteM, RegWriteW,
  output logic [1:0] ImmSrcD,
  output logic [3:0] ALUControlE
);

  // Internal wires for control signals in Decode stage
  logic [1:0] ALUOpD;
  logic [1:0] ResultSrcD, ResultSrcE, ResultSrcM;
  logic [3:0] ALUControlD;
  logic BranchD, BranchE, MemWriteD, MemWriteE, JumpD, JumpE;
  logic ZeroOp, ALUSrcD, RegWriteD, RegWriteE;

  // Instantiate the Main Decoder
  maindec md(
    .op        (op),
    .ResultSrc (ResultSrcD),
    .MemWrite  (MemWriteD),
    .Branch    (BranchD),
    .ALUSrc    (ALUSrcD),
    .RegWrite  (RegWriteD),
    .Jump      (JumpD),
    .ImmSrc    (ImmSrcD),
    .ALUOp     (ALUOpD)
  );

  // Instantiate the ALU Decoder
  aludec ad(
    .opb5       (op[5]),
    .funct3     (funct3),
    .funct7b5   (funct7b5),
    .funct7_2b  (funct7_2b),
    .ALUOp      (ALUOpD),
    .ALUControl (ALUControlD)
  );

  // Instantiate the ID/EX Control Pipeline Register
  c_ID_IEx c_pipreg0(
    .clk         (clk),
    .reset       (reset),
    .clear       (FlushE),       // FlushE clears this register
    .RegWriteD   (RegWriteD),
    .MemWriteD   (MemWriteD),
    .JumpD       (JumpD),
    .BranchD     (BranchD),
    .ALUSrcD     (ALUSrcD),
    .ResultSrcD  (ResultSrcD),
    .ALUControlD (ALUControlD), 
    .RegWriteE   (RegWriteE),
    .MemWriteE   (MemWriteE),
    .JumpE       (JumpE),
    .BranchE     (BranchE),
    .ALUSrcE     (ALUSrcE),
    .ResultSrcE  (ResultSrcE),
    .ALUControlE (ALUControlE)
  );
  
  // Expose bit 0 of ResultSrcE for the hazard unit (to detect loads)
  assign ResultSrcE0 = ResultSrcE[0];

  // Instantiate the EX/MEM Control Pipeline Register
  c_IEx_IM c_pipreg1(
    .clk        (clk),
    .reset      (reset),
    .RegWriteE  (RegWriteE),
    .MemWriteE  (MemWriteE),
    .ResultSrcE (ResultSrcE),
    .RegWriteM  (RegWriteM), 
    .MemWriteM  (MemWriteM),
    .ResultSrcM (ResultSrcM)
  );

  // Instantiate the MEM/WB Control Pipeline Register
  c_IM_IW c_pipreg2 (
    .clk        (clk),
    .reset      (reset),
    .RegWriteM  (RegWriteM),
    .ResultSrcM (ResultSrcM),
    .RegWriteW  (RegWriteW),
    .ResultSrcW (ResultSrcW)
  );

  // Logic to determine PC source: taken branch (BranchE AND ZeroE) OR a jump (JumpE)
  assign PCSrcE = (BranchE & ZeroE) | JumpE;

endmodule


module maindec(
  input  logic [6:0] op,
  output logic [1:0] ResultSrc,
  output logic       MemWrite,
  output logic       Branch, ALUSrc,
  output logic       RegWrite, Jump,
  output logic [1:0] ImmSrc,
  output logic [1:0] ALUOp
);

  // Internal wire to hold all control signals
  logic [10:0] controls;

  // Assign bits from the 'controls' wire to the respective output ports
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  // Combinational logic to decode the opcode
  always_comb
    case(op)
    //         RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type 
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      7'b0001011: controls = 11'b1_xx_0_0_00_0_11_0; // R-type_newly_added_instructions (RVX10)
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule


module aludec(
  input  logic       opb5,
  input  logic [2:0] funct3,
  input  logic       funct7b5, 
  input  logic [1:0] funct7_2b,
  input  logic [1:0] ALUOp,
  output logic [3:0] ALUControl
);

  logic  RtypeSub;
  assign RtypeSub = funct7b5 & opb5;  // TRUE for R-type subtract instruction

  // Combinational logic to set ALUControl
  always_comb
    case(ALUOp)
      2'b00:            ALUControl = 4'b0000; // addition (for lw, sw)
      2'b01:            ALUControl = 4'b0001; // subtraction (for beq)
      2'b10: case(funct3) // R-type or I-type ALU
               3'b000:  if (RtypeSub) 
                          ALUControl = 4'b0001; // sub
                        else        
                          ALUControl = 4'b0000; // add, addi
               3'b010:    ALUControl = 4'b0101; // slt, slti
               3'b110:    ALUControl = 4'b0011; // or, ori
               3'b111:    ALUControl = 4'b0010; // and, andi
               default:   ALUControl = 4'bxxxx; // ???
             endcase
      2'b11: case(funct7_2b) //RVX10 cases
               2'b00:  case (funct3)
                         3'b000: ALUControl = 4'b0110; //andn
                         3'b001: ALUControl = 4'b0111; //orn
                         3'b010: ALUControl = 4'b1000; //xorn
                         default: ALUControl = 4'bxxxx; // ???
                       endcase
               2'b01:  case (funct3)
                         3'b000: ALUControl = 4'b1001; //min
                         3'b001: ALUControl = 4'b1010; //max
                         3'b010: ALUControl = 4'b1011; //minu
                         3'b011: ALUControl = 4'b1100; //maxu
                         default: ALUControl = 4'bxxxx; // ???
                       endcase
               2'b10:  case (funct3)
                         3'b000: ALUControl = 4'b1101; //rol
                         3'b001: ALUControl = 4'b1110; //ror
                         default: ALUControl = 4'bxxxx; // ???
                       endcase
               2'b11:  case (funct3)
                         3'b000: ALUControl = 4'b1111; //abs
                         default: ALUControl = 4'bxxxx; // ???
                       endcase
               default: ALUControl = 4'bxxxx; // ???
             endcase
      default: ALUControl = 4'bxxxx; // ???
    endcase
endmodule


module c_ID_IEx (
  input  logic       clk, reset, clear,
  input  logic       RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD,
  input  logic [1:0] ResultSrcD, 
  input  logic [3:0] ALUControlD,  
  output logic       RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE,
  output logic [1:0] ResultSrcE,
  output logic [3:0] ALUControlE
);

  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RegWriteE   <= 0;
      MemWriteE   <= 0;
      JumpE       <= 0;
      BranchE     <= 0; 
      ALUSrcE     <= 0;
      ResultSrcE  <= 0;
      ALUControlE <= 0;
    end
    else if (clear) begin // Synchronous clear (flushes to 0)
      RegWriteE   <= 0;
      MemWriteE   <= 0;
      JumpE       <= 0;
      BranchE     <= 0; 
      ALUSrcE     <= 0;
      ResultSrcE  <= 0;
      ALUControlE <= 0;
    end
    else begin // Normal operation: latch inputs
      RegWriteE   <= RegWriteD;
      MemWriteE   <= MemWriteD;
      JumpE       <= JumpD;
      BranchE     <= BranchD; 
      ALUSrcE     <= ALUSrcD;
      ResultSrcE  <= ResultSrcD;
      ALUControlE <= ALUControlD; 
    end
  end
  
endmodule


module c_IEx_IM (
  input  logic       clk, reset,
  input  logic       RegWriteE, MemWriteE,
  input  logic [1:0] ResultSrcE,  
  output logic       RegWriteM, MemWriteM,
  output logic [1:0] ResultSrcM
);

  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RegWriteM  <= 0;
      MemWriteM  <= 0;
      ResultSrcM <= 0;
    end
    else begin // Normal operation: latch inputs
      RegWriteM  <= RegWriteE;
      MemWriteM  <= MemWriteE;
      ResultSrcM <= ResultSrcE; 
    end
  end

endmodule


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

module forwarding_unit(
  input  logic [4:0] Rs1E, Rs2E,  // Source registers in Execute
  input  logic [4:0] RdM, RdW,     // Destination registers in Memory & WriteBack
  input  logic       RegWriteM,   // Write enable in Memory
  input  logic       RegWriteW,   // Write enable in WriteBack
  output logic [1:0] ForwardAE,  // Forwarding control for ALU operand A
  output logic [1:0] ForwardBE   // Forwarding control for ALU operand B
);

  // Combinational logic for forwarding
  always_comb begin
    // --- Defaults (no forwarding) ---
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;

    // --- Forwarding for Rs1 (Operand A) ---
    
    // EX/MEM Hazard: Forward from Memory stage (highest priority)
    // If Rs1 in EX matches Rd in MEM, and MEM is writing, forward ALUResultM
    if ((Rs1E == RdM) & RegWriteM & (Rs1E != 0))
      ForwardAE = 2'b10; // Forward ALUResultM
        
    // MEM/WB Hazard: Forward from WriteBack stage
    // Else if Rs1 in EX matches Rd in WB, and WB is writing, forward ResultW
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0))
      ForwardAE = 2'b01; // Forward ResultW

        
    // --- Forwarding for Rs2 (Operand B) ---
    
    // EX/MEM Hazard: Forward from Memory stage (highest priority)
    // If Rs2 in EX matches Rd in MEM, and MEM is writing, forward ALUResultM
    if ((Rs2E == RdM) & RegWriteM & (Rs2E != 0))
      ForwardBE = 2'b10; // Forward ALUResultM
        
    // MEM/WB Hazard: Forward from WriteBack stage
    // Else if Rs2 in EX matches Rd in WB, and WB is writing, forward ResultW
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0))
      ForwardBE = 2'b01; // Forward ResultW
  end

endmodule


module hazard_unit(
  input  logic [4:0] Rs1D, Rs2D,    // Source registers in Decode
  input  logic [4:0] RdE,           // Destination register in Execute
  input  logic       ResultSrcE0,   // Control signal: 1 if instruction in EXE is a load
  input  logic       PCSrcE,        // Control signal: 1 if branch is taken
  output logic       StallD, StallF,  // Stall signals for Fetch and Decode
  output logic       FlushD, FlushE   // Flush signals for Decode and Execute
);

  // --- Load-Use Hazard Detection ---
  // Stall if instruction in Decode needs data from a load in Execute
  logic lwStall;
  assign lwStall = (ResultSrcE0 == 1) & ((RdE == Rs1D) | (RdE == Rs2D));

  // Stall the pipeline for one cycle
  assign StallF = lwStall; // Stall PC and IF/ID pipeline register
  assign StallD = lwStall; // Stall ID/EX pipeline register
    
  // --- Flush Logic ---
    
  // Flush Execute stage if a load-use stall occurs (insert bubble)
  // OR if a branch is taken (instruction in EXE is wrong)
  assign FlushE = lwStall | PCSrcE;
    
  // Flush Decode stage only if a branch is taken (instruction in DEC is wrong)
  assign FlushD = PCSrcE;

endmodule


module datapath(
  input  logic       clk, reset,
  input  logic [1:0] ResultSrcW,
  input  logic       PCSrcE, ALUSrcE, 
  input  logic       RegWriteW,
  input  logic [1:0] ImmSrcD,
  input  logic [3:0] ALUControlE,
  output logic       ZeroE,
  output logic [31:0] PCF,
  input  logic [31:0] InstrF,
  output logic [31:0] InstrD,
  output logic [31:0] ALUResultM, WriteDataM,
  input  logic [31:0] ReadDataM,
  input  logic [1:0] ForwardAE, ForwardBE,
  output logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
  output logic [4:0] RdE, RdM, RdW,
  input  logic       StallD, StallF, FlushD, FlushE,

  // --- MODIFICATION: VALID BITS ADDED ---
  output logic       validD,
  output logic       validE,
  output logic       validM,
  output logic       validW
  // --------------------------------------
);

  // Internal datapath signals
  logic [31:0] PCD, PCE, ALUResultE, ALUResultW, ReadDataW;
  logic [31:0] PCNextF, PCPlus4F, PCPlus4D, PCPlus4E, PCPlus4M, PCPlus4W, PCTargetE;
  logic [31:0] WriteDataE;
  logic [31:0] ImmExtD, ImmExtE;
  logic [31:0] SrcAE, SrcBE, RD1D, RD2D, RD1E, RD2E;
  logic [31:0] ResultW;
  logic [4:0] RdD; // destination register address

    
  // -----------------
  // --- Fetch Stage ---
  // -----------------
    
  // Mux to select next PC (either PC+4 or branch/jump target)
  mux2 #(.WIDTH(32)) pcmux(
    .d0 (PCPlus4F),
    .d1 (PCTargetE),
    .s  (PCSrcE),
    .y  (PCNextF)
  );
  
  // PC Register (stalls if StallF is high)
  flopenr #(.WIDTH(32)) IF(
    .clk   (clk),
    .reset (reset),
    .en    (~StallF), // Enable only if not stalling
    .d     (PCNextF),
    .q     (PCF)
  );
  
  // Adder for PC + 4
  adder pcadd4(
    .a (PCF),
    .b (32'd4),
    .y (PCPlus4F)
  );
    
  // ---------------------------------------------------
  // --- Instruction Fetch - Decode Pipeline Register ---
  // ---------------------------------------------------
    
  IF_ID pipreg0 (
    .clk      (clk),
    .reset    (reset),
    .clear    (FlushD),  // Flush if branch taken
    .enable   (~StallD), // Stall for load-use
    .InstrF   (InstrF),
    .PCF      (PCF),
    .PCPlus4F (PCPlus4F),
    .InstrD   (InstrD),
    .PCD      (PCD),
    .PCPlus4D (PCPlus4D),

    // --- MODIFICATION: VALID BIT ---
    // A new instruction is always valid (1'b1).
    // On stall, 'enable' is false, so 'validD' holds.
    // On flush, 'clear' is true, so 'validD' becomes 0.
    .valid_in (1'b1),
    .valid_out(validD)
    // -------------------------------
  );
  
  // ------------------
  // --- Decode Stage ---
  // ------------------
  
  // Extract register addresses from instruction
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];  
  assign RdD  = InstrD[11:7];
  
  // Register File
  regfile rf (
    .clk (clk),
    .we3 (RegWriteW), // Write enable from WB stage
    .a1  (Rs1D),      // Read address 1
    .a2  (Rs2D),      // Read address 2
    .a3  (RdW),       // Write address from WB stage
    .wd3 (ResultW),   // Write data from WB stage
    .rd1 (RD1D),      // Read data 1 output
    .rd2 (RD2D)       // Read data 2 output
  );  
  
  // Sign/Immediate Extension Unit
  extend ext(
    .instr  (InstrD[31:7]),
    .immsrc (ImmSrcD),
    .immext (ImmExtD)
  );
    
  // ------------------------------------------------
  // --- Decode - Execute Pipeline Register ---
  // ------------------------------------------------
    
  ID_IEx pipreg1 (
    .clk      (clk),
    .reset    (reset),
    .clear    (FlushE), // Flush for stalls or taken branches
    .RD1D     (RD1D),
    .RD2D     (RD2D),
    .PCD      (PCD),
    .Rs1D     (Rs1D),
    .Rs2D     (Rs2D),
    .RdD      (RdD),
    .ImmExtD  (ImmExtD),
    .PCPlus4D (PCPlus4D),
    .RD1E     (RD1E),
    .RD2E     (RD2E),
    .PCE      (PCE),
    .Rs1E     (Rs1E),
    .Rs2E     (Rs2E),
    .RdE      (RdE),
    .ImmExtE  (ImmExtE),
    .PCPlus4E (PCPlus4E),

    // --- MODIFICATION: VALID BIT ---
    // Propagate valid bit. 'clear' (FlushE) will set validE to 0.
    // This register has no 'enable', so it never stalls.
    .valid_in (validD),
    .valid_out(validE)
    // -------------------------------
  );
  
  // -------------------
  // --- Execute Stage ---
  // -------------------
  
  // Forwarding Mux for ALU Operand A
  mux3 #(.WIDTH(32)) forwardMuxA (
    .d0 (RD1E),       // 00: From register file (RD1E)
    .d1 (ResultW),    // 01: From WriteBack (ResultW)
    .d2 (ALUResultM), // 10: From Memory (ALUResultM)
    .s  (ForwardAE),
    .y  (SrcAE)
  );
  
  // Forwarding Mux for ALU Operand B (also serves as WriteData for 'sw')
  mux3 #(.WIDTH(32)) forwardMuxB (
    .d0 (RD2E),       // 00: From register file (RD2E)
    .d1 (ResultW),    // 01: From WriteBack (ResultW)
    .d2 (ALUResultM), // 10: From Memory (ALUResultM)
    .s  (ForwardBE),
    .y  (WriteDataE)  // This is data to be written for 'sw'
  );
  
  // Mux to select ALU Operand B (either from regfile/forward or immediate)
  mux2 #(.WIDTH(32)) srcbmux(
    .d0 (WriteDataE), // From regfile/forwarding
    .d1 (ImmExtE),    // From immediate extender
    .s  (ALUSrcE),
    .y  (SrcBE)
  );  
  
  // Adder for branch/jump target address
  adder pcaddbranch(
    .a (PCE),
    .b (ImmExtE),
    .y (PCTargetE)
  );  
  
  // The main Arithmetic Logic Unit (ALU)
  alu alu(
    .a          (SrcAE),
    .b          (SrcBE),
    .alucontrol (ALUControlE),
    .result     (ALUResultE),
    .zero       (ZeroE)
  );
    
  // ----------------------------------------------------
  // --- Execute - Memory Access Pipeline Register ---
  // ----------------------------------------------------
  
  IEx_IMem pipreg2 (
    .clk        (clk),
    .reset      (reset),
    .ALUResultE (ALUResultE),
    .WriteDataE (WriteDataE),
    .RdE        (RdE),
    .PCPlus4E   (PCPlus4E),
    .ALUResultM (ALUResultM),
    .WriteDataM (WriteDataM),
    .RdM        (RdM),
    .PCPlus4M   (PCPlus4M),

    // --- MODIFICATION: VALID BIT ---
    // Propagate valid bit.
    .valid_in (validE),
    .valid_out(validM)
    // -------------------------------
  );
    
  // -----------------
  // --- Memory Stage ---
  // -----------------
  // (No components here, just wires to 'top' module's dmem)
    
  // --------------------------------------------------
  // --- Memory - Register Write Back Stage Register ---
  // --------------------------------------------------
  
  IMem_IW pipreg3 (
    .clk        (clk),
    .reset      (reset),
    .ALUResultM (ALUResultM),
    .ReadDataM  (ReadDataM),
    .RdM        (RdM),
    .PCPlus4M   (PCPlus4M),
    .ALUResultW (ALUResultW),
    .ReadDataW  (ReadDataW),
    .RdW        (RdW),
    .PCPlus4W   (PCPlus4W),

    // --- MODIFICATION: VALID BIT ---
    // Propagate valid bit.
    .valid_in (validM),
    .valid_out(validW)
    // -------------------------------
  );
  
  // ----------------------
  // --- WriteBack Stage ---
  // ----------------------
  
  // Mux to select the final result to write back to the register file
  mux3 #(.WIDTH(32)) resultmux(
    .d0 (ALUResultW), // 00: From ALU
    .d1 (ReadDataW),  // 01: From Data Memory
    .d2 (PCPlus4W),   // 10: From PC+4 (for JAL)
    .s  (ResultSrcW),
    .y  (ResultW)
  );

endmodule


module mux2 #(parameter WIDTH=8)(
  input  logic [WIDTH-1:0] d0, d1, // Data inputs
  input  logic             s,      // Select signal
  output logic [WIDTH-1:0] y       // Data output
);
    
  // If s=1, select d1; otherwise select d0
  assign y = s ? d1 : d0;
endmodule


module flopenr #(
  parameter WIDTH = 8
) (
  input  logic             clk,   // Clock
  input  logic             reset, // Asynchronous reset
  input  logic             en,    // Synchronous enable
  input  logic [WIDTH-1:0] d,     // Data input
  output logic [WIDTH-1:0] q      // Data output
);

  // Sequential logic with an asynchronous reset.
  always_ff @(posedge clk or posedge reset) begin
    // Asynchronous reset has the highest priority.
    if (reset)
      q <= 0;
    // On a clock edge, load 'd' into 'q' only if enabled.
    else if (en)
      q <= d;
    // If 'en' is low, 'q' holds its previous value.
    // else if (!en) // This is redundant
    //   q <= q;
  end

endmodule


module adder(
  input  [31:0] a, b, // 32-bit inputs
  output [31:0] y     // 32-bit output (a + b)
);

  assign y = a + b;
endmodule


module IF_ID (
  input  logic       clk, reset, clear, enable,
  input  logic [31:0] InstrF, PCF, PCPlus4F,
  output logic [31:0] InstrD, PCD, PCPlus4D,
  
  // --- MODIFICATION: VALID BIT ---
  input  logic       valid_in,  // Valid bit from fetch (always 1'b1)
  output logic       valid_out  // Valid bit for decode
  // -------------------------------
);

  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous Clear
      InstrD   <= 0;
      PCD      <= 0;
      PCPlus4D <= 0;
      valid_out<= 0; // Clear valid bit
    end
    else if (enable) begin // Only latch if enabled (not stalled)
      if (clear) begin // Synchronous Clear (flushes to a NOP)
        InstrD   <= 32'h00000033; // add x0,x0,x0 (nop)
        PCD      <= 0;
        PCPlus4D <= 0; 
        valid_out<= 0; // Clear valid bit
      end
      else begin // Normal operation
        InstrD   <= InstrF;
        PCD      <= PCF;
        PCPlus4D <= PCPlus4F;
        valid_out<= valid_in; // Propagate valid bit
      end
    end
    // If enable is 0, registers (including valid_out) hold their previous value (stall)
  end

endmodule

module regfile (
  input  logic       clk,
  input  logic       we3,      // Write enable (from WB stage)
  input  logic [4:0] a1, a2, a3, // a1,a2=Read addrs, a3=Write addr
  input  logic [31:0] wd3,    // Write data
  output logic [31:0] rd1, rd2 // Read data
);

  // The register file storage array
  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on *NEGATIVE* edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0

  // **MODIFICATION**: Writing on negedge clk as requested
  always_ff @(negedge clk)
    if (we3 & a3 != 0) rf[a3] <= wd3; // x0 no rewrites

  // Combinational reads
  // This simple logic works *because* write is on negedge
  // and read (in ID stage) is sampled on posedge.
  assign rd1 = (a1 != 0) ? rf[a1] : 0; // Hardwire x0 to 0
  assign rd2 = (a2 != 0) ? rf[a2] : 0; // Hardwire x0 to 0
  
endmodule

module extend(
  // --- Input ---
  input  logic [31:7] instr,   // Relevant bits of the instruction
  input  logic [1:0]  immsrc,  // Selects immediate type
  
  // --- Output ---
  output logic [31:0] immext   // 32-bit sign-extended immediate
);
 
  // Combinational logic to generate the correct immediate
  always_comb
    case(immsrc) 
      // I-type (lw, addi, slti, etc.)
      2'b00:  immext = {{20{instr[31]}}, instr[31:20]}; 
            
      // S-type (stores)
      2'b01:  immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
            
      // B-type (branches)
      2'b10:  immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
            
      // J-type (jal)
      2'b11:  immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; 
            
      default: immext = 32'bx; // undefined
    endcase       
endmodule


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


module mux3 #(parameter WIDTH=8)(
  input  logic [WIDTH-1:0] d0, d1, d2, // Data inputs
  input  logic [1:0]       s,        // Select signal
  output logic [WIDTH-1:0] y         // Data output
);
    
  // s=00 -> d0
  // s=01 -> d1
  // s=10 -> d2
  // s=11 -> d2 (based on this logic)
  assign y = s[1] ? d2 : (s[0] ? d1: d0);
endmodule


module alu(
  input  logic [31:0] a, b,
  input  logic [3:0]  alucontrol,
  output logic [31:0] result,
  output logic        zero
);

  // Existing signals
  logic [31:0] condinvb, sum;
  logic        v;          // overflow
  logic        isAddSub;   // true when add or subtract

  // Logic for add/sub/slt
  assign condinvb = alucontrol[0] ? ~b : b;       // Invert b for subtraction
  assign sum      = a + condinvb + alucontrol[0]; // Add/Sub
  assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                    ~alucontrol[1] & alucontrol[0];

  // signed views for MIN/MAX/ABS
  wire signed [31:0] s1 = a;
  wire signed [31:0] s2 = b;

  // Main ALU operation logic
  always_comb
    case (alucontrol)
      // ---- original arithmetic/logic ----
      4'b0000:  result = sum;      // add
      4'b0001:  result = sum;      // subtract
      4'b0010:  result = a & b;    // and
      4'b0011:  result = a | b;    // or
      4'b0100:  result = a ^ b;    // xor
      4'b0101:  result = sum[31] ^ v; // slt (Set Less Than)

      // ---- new ops starting from 0110 (RVX10) ----
      4'b0110:  result = a & ~b;                       // ANDN
      4'b0111:  result = a | ~b;                       // ORN
      4'b1000:  result = ~(a ^ b);                     // XNOR (typo in original, was XORN)
      4'b1001:  result = (s1 < s2) ? a : b;            // MIN (signed)
      4'b1010:  result = (s1 > s2) ? a : b;            // MAX (signed)
      4'b1011:  result = (a  < b)  ? a : b;            // MINU (unsigned)
      4'b1100:  result = (a  > b)  ? a : b;            // MAXU (unsigned)
      4'b1101: begin                                   // ROL (Rotate Left)
          logic [4:0] sh = b[4:0];
          result = (sh == 0) ? a : ((a << sh) | (a >> (32 - sh)));
        end
      4'b1110: begin                                   // ROR (Rotate Right)
          logic [4:0] sh = b[4:0];
          result = (sh == 0) ? a : ((a >> sh) | (a << (32 - sh)));
        end
      4'b1111:  result = (s1 >= 0) ? a : (0 - a);      // ABS (Absolute Value)
      default:  result = 32'bx;
    endcase

  // Zero flag logic
  assign zero = (result == 32'b0);
  
  // Overflow logic (for 'slt')
  assign v    = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;

endmodule



module IEx_IMem(
  input  logic       clk, reset,
  input  logic [31:0] ALUResultE, WriteDataE, 
  input  logic [4:0] RdE, 
  input  logic [31:0] PCPlus4E,
  output logic [31:0] ALUResultM, WriteDataM,
  output logic [4:0] RdM, 
  output logic [31:0] PCPlus4M,

  // --- MODIFICATION: VALID BIT ---
  input  logic       valid_in,  // Valid bit from execute
  output logic       valid_out  // Valid bit for memory
  // -------------------------------
);

  always_ff @( posedge clk, posedge reset ) begin 
    if (reset) begin // Asynchronous reset
      ALUResultM <= 0;
      WriteDataM <= 0;
      RdM        <= 0; 
      PCPlus4M   <= 0;
      valid_out  <= 0; // Clear valid bit
    end
    else begin // Normal operation: latch inputs
      ALUResultM <= ALUResultE;
      WriteDataM <= WriteDataE;
      RdM        <= RdE; 
      PCPlus4M   <= PCPlus4E;      
      valid_out  <= valid_in; // Propagate valid bit
    end
  end

endmodule


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
