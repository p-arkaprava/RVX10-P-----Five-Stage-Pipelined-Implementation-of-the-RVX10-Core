# RVX10-P: Five-Stage Pipelined RISC-V Processor

## Overview

This repository contains the implementation of **RVX10-P**, a **five-stage pipelined RISC-V processor** supporting the **RV32I instruction set along with the RVX10 custom instruction extension**.

The processor is an extension of a previously implemented **single-cycle RVX10 core**, redesigned using a **pipelined datapath** to improve throughput and overall performance.

The design follows the classic **five-stage RISC pipeline architecture** and includes mechanisms for **hazard detection, forwarding, and pipeline control**.

This project was developed as part of the **Digital Logic and Computer Architecture course at IIT Guwahati**. 

---

# Processor Architecture

The processor is divided into **five pipeline stages**:

| Stage   | Description                                   |
| ------- | --------------------------------------------- |
| **IF**  | Instruction Fetch                             |
| **ID**  | Instruction Decode and Register Read          |
| **EX**  | Execute (ALU operations and branch decisions) |
| **MEM** | Data Memory Access                            |
| **WB**  | Write Back to Register File                   |

Pipeline registers separate each stage:

```
IF/ID → ID/EX → EX/MEM → MEM/WB
```

These registers store intermediate values such as:

* Program Counter (PC)
* Instructions
* Register operands
* Immediate values
* Control signals
* ALU outputs
* Memory data

---

# Supported Instruction Set

The processor supports:

### Standard RISC-V Base ISA

```
RV32I
```

### Custom RVX10 ALU Instructions

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

These instructions are implemented within the **ALU in the Execute stage**. 

---

# Hazard Handling

## Data Hazards

Data hazards are resolved using **forwarding and stalling mechanisms**.

### Forwarding Unit

The forwarding unit selects ALU operands from later pipeline stages when necessary:

```
EX/MEM → EX
MEM/WB → EX
```

This allows the processor to avoid unnecessary pipeline stalls for back-to-back instructions.

---

### Load-Use Hazard

When an instruction depends on a **load result that is still in the pipeline**, the hazard detection unit:

* Stalls the **IF** and **ID** stages
* Inserts a **bubble (NOP)** into the pipeline

---

## Control Hazards

Branches are resolved in the **Execute stage**.

If a branch or jump is taken:

* The instruction in **IF/ID** is flushed
* The **PC is updated** with the branch target

---

# Pipeline Operation

Example pipeline execution:

```
Cycle 1: IF
Cycle 2: ID  IF
Cycle 3: EX  ID  IF
Cycle 4: MEM EX  ID  IF
Cycle 5: WB  MEM EX  ID  IF
```

Multiple instructions execute simultaneously, improving throughput compared to a **single-cycle processor**.

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

Average CPI can be computed as:

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

## Tools Required

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

* Execute RV32I and RVX10 instructions
* Store the value **25 at memory address 100** upon successful completion
* Demonstrate **pipeline overlap in waveform simulations**. 

Key checks include:

* Correct instruction execution
* Forwarding for back-to-back ALU operations
* One-cycle stall for load-use hazards
* Proper pipeline flushing on taken branches
* Register **x0 always remains zero**

---

# Key Concepts Demonstrated

* Five-stage pipelined CPU architecture
* Hazard detection and forwarding
* Pipeline stalls and flush control
* RISC-V instruction execution
* Hardware verification and waveform debugging
* Performance improvement via pipelining

---

# Author

**Arkaprava Paul**
student
IIT Guwahati
