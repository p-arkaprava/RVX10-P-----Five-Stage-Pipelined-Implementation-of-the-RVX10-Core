# RVX10-P: Five-Stage Pipelined RISC-V Processor

## Overview

This repository contains the implementation of **RVX10-P**, a **five-stage pipelined RISC-V processor** supporting the **RV32I instruction set along with the RVX10 custom instruction extension**.

The processor is an extension of a previously implemented **single-cycle RVX10 core**, redesigned using a **pipelined datapath** to improve throughput and performance.

The architecture includes **pipeline registers, forwarding logic, hazard detection, and pipeline flushing** to correctly execute instructions while maintaining high instruction throughput.

---

# Processor Architecture

The processor follows the standard **five-stage pipeline architecture**:

| Stage | Description                                   |
| ----- | --------------------------------------------- |
| IF    | Instruction Fetch                             |
| ID    | Instruction Decode / Register Read            |
| EX    | Execute (ALU operations and branch decisions) |
| MEM   | Data Memory Access                            |
| WB    | Write Back to Register File                   |

Pipeline registers separate each stage:

```
IF/ID → ID/EX → EX/MEM → MEM/WB
```

These registers store intermediate values such as:

* Program Counter (PC)
* Instruction
* Register operands
* Immediate values
* Control signals
* ALU results
* Memory data

---

# Supported Instruction Set

The processor supports:

### Base ISA

```
RV32I
```

### RVX10 Custom Instructions

```
ANDN
ORN
XNOR
MIN
MAX
MINU
MAXU
ROL
ROR
ABS
```

These custom ALU instructions execute in the **Execute stage**.

---

# Hazard Handling

To maintain correct execution in the pipeline, the processor implements **data forwarding, hazard detection, and pipeline flushing**.

---

# Forwarding Logic

Forwarding resolves data hazards when results are available in later pipeline stages.

### Forwarding for ALU Operand A

```
if ((Rs1E == RdM) & RegWriteM & (Rs1E != 0))
    ForwardAE = 10
else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0))
    ForwardAE = 01
else
    ForwardAE = 00
```

### Forwarding for ALU Operand B

The forwarding logic for **SrcBE (ForwardBE)** is identical except that it compares **Rs2E** instead of **Rs1E**.

```
if ((Rs2E == RdM) & RegWriteM & (Rs2E != 0))
    ForwardBE = 10
else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0))
    ForwardBE = 01
else
    ForwardBE = 00
```

---

# Load Hazard Detection

A stall is introduced when a **load-use hazard** occurs.

```
lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE))

StallF = lwStall
StallD = lwStall
```

This prevents the next instruction from using data that has not yet been written back.

---

# Pipeline Flushing

The pipeline must be flushed when a **branch is taken** or when a **load stall introduces a bubble**.

```
FlushD = PCSrcE
FlushE = lwStall | PCSrcE
```

This removes incorrect instructions from the pipeline.

---

# Pipeline Operation

Example pipeline overlap:

```
Cycle 1: IF
Cycle 2: ID  IF
Cycle 3: EX  ID  IF
Cycle 4: MEM EX  ID  IF
Cycle 5: WB  MEM EX  ID  IF
```

Multiple instructions execute concurrently, improving throughput compared to a single-cycle design.

---

# Performance Counters

Optional counters track processor performance:

```verilog
reg [31:0] cycle_count;
reg [31:0] instr_retired;

always @(posedge clk)
    cycle_count <= cycle_count + 1;

if (RegWriteW)
    instr_retired <= instr_retired + 1;
```

Average CPI:

```
CPI = cycle_count / instr_retired
```

---

# Project Structure

```
rvx10p/
│
├── src/
│   ├── riscvpipeline.sv
│   ├── datapath.sv
│   ├── controller.sv
│   ├── hazard_unit.sv
│   └── forwarding_unit.sv
│
├── tb/
│   └── tb_pipeline.sv
│
├── tests/
│   └── rvx10_pipeline.hex
│
├── docs/
│   └── REPORT.md
│
└── README.md
```

---

# Simulation

### Tools Required

* **Icarus Verilog**
* **GTKWave**

Install (Ubuntu):

```
sudo apt install iverilog gtkwave
```

---

# Run Simulation

Compile the design:

```
iverilog -o sim.out src/*.sv tb/tb_pipeline.sv
```

Run simulation:

```
vvp sim.out
```

View waveform:

```
gtkwave wave.vcd
```

---

# Verification

The processor is verified using test programs that:

* Execute **RV32I and RVX10 instructions**
* Store **25 at memory address 100** when the program completes
* Demonstrate **pipeline overlap in waveform simulations**

Key checks include:

* Correct instruction execution
* Forwarding for back-to-back ALU operations
* One-cycle stall for load-use hazards
* Correct pipeline flush for taken branches
* Register **x0 always remains zero**

---

# Key Concepts Demonstrated

* Five-stage pipelined CPU design
* Data hazard resolution
* Forwarding and stall control
* Control hazard handling
* RTL modeling using Verilog/SystemVerilog
* Hardware simulation and waveform analysis

---

# Author

**Arkaprava Paul**

student
Dept of EEE
IIT Guwahati
