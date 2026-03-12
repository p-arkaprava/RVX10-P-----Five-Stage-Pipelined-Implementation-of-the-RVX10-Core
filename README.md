# 🚀 RVX10-P: Five-Stage Pipelined RISC-V Core

A **five-stage pipelined implementation of a RISC-V processor** supporting **RV32I + 10 custom ALU instructions (RVX10)**.

This project converts a **single-cycle RV32I processor** into a **five-stage pipelined CPU** that improves throughput while maintaining **identical architectural behavior**.

📚 Developed under the course  
**Digital Logic and Computer Architecture**  
Instructor: **Dr. Satyajit Das, IIT Guwahati**

---

# 📌 Project Overview

The **RVX10-P processor** executes the standard **RV32I instruction set** along with **10 custom ALU instructions**.

The goal of this project is to demonstrate how **pipelining increases CPU throughput** by allowing multiple instructions to execute simultaneously.

---

# 🎯 Learning Outcomes

- 🧠 Understand the **five pipeline stages**
- ⚙️ Implement **pipeline registers**
- 🔄 Implement **forwarding, stalling, and flushing**
- 📊 Verify correctness and evaluate **cycle-level performance**
- 🚀 Observe **throughput improvements due to pipelining**

---

# 🧩 Five-Stage Pipeline Architecture

| Stage | Name | Description |
|------|------|-------------|
| IF | Instruction Fetch | Fetch instruction from instruction memory |
| ID | Instruction Decode / Register Read | Decode instruction and read register values |
| EX | Execute | Perform ALU operations and branch decision |
| MEM | Memory Access | Read or write data memory |
| WB | Write Back | Write results back to the register file |

---

# 🔗 Pipeline Registers

Pipeline registers separate each stage and store intermediate data.

| Pipeline Register | Stored Data |
|------------------|------------|
| IF/ID | Program counter and fetched instruction |
| ID/EX | Register values, immediate values, control bits |
| EX/MEM | ALU output, destination register, memory control signals |
| MEM/WB | Data memory result and write-back control |

---

# ⚙️ Implementation Guidelines

- Support **RV32I + RVX10 instructions**
- Each pipeline stage must complete in **one clock cycle**
- Split the **single-cycle combinational logic across stages**
- Add **pipeline registers** between stages
- Implement hazard handling logic

Two additional control blocks are required:

| Unit | Purpose |
|-----|--------|
| 🔁 Forwarding Unit | Forwards results from later pipeline stages to resolve data hazards |
| ⚠️ Hazard Detection Unit | Detects load-use hazards and inserts stalls or flush signals |

Additional requirements:

- On **branch or jump**, flush the next instruction
- Writes to **x0 must always be ignored**

---

# 🛠 Design Tasks

## 1️⃣ Partition the Single-Cycle Datapath

Divide the original datapath into **five pipeline stages**.

Pipeline registers must hold intermediate values.

| Pipeline Register | Contents |
|------------------|----------|
| IF/ID | PC and instruction |
| ID/EX | Register operands, immediate values, control signals |
| EX/MEM | ALU results, destination register, memory control |
| MEM/WB | Memory read data and writeback control |

---

## 2️⃣ Hazard Handling

### Data Hazards

Implement forwarding paths:

- Forward results from **EX/MEM stage**
- Forward results from **MEM/WB stage**

Detect **load-use hazards**:

If the EX stage requires data from a load still in MEM stage:

-Stall IF stage
-Stall ID stage
-Flush ID/EX stage


---

### Control Hazards

Branches are evaluated in the **EX stage**.

If a branch is taken:

-Flush instruction in IF/ID
-Update program counter

---

## 3️⃣ RVX10 Custom Instructions

The processor supports the following **10 custom ALU instructions**.

| Instruction | Description |
|-------------|-------------|
| ANDN | Bitwise AND with NOT |
| ORN | Bitwise OR with NOT |
| XNOR | Bitwise XNOR |
| MIN | Minimum (signed) |
| MAX | Maximum (signed) |
| MINU | Minimum (unsigned) |
| MAXU | Maximum (unsigned) |
| ROL | Rotate Left |
| ROR | Rotate Right |
| ABS | Absolute value |

All these instructions execute in the **EX stage** because they are purely **ALU operations**.

No changes are required in **MEM** or **WB** stages.

---

# 🧪 Verification

The processor is tested using the **same test programs used in the single-cycle implementation**.

Expected result:
Store value 25 at memory address 100


Verification steps:

- Run all previous test programs
- Confirm identical architectural results
- Observe pipeline activity in **GTKWave**
- Compare **cycle count vs single-cycle design**

---

# 📈 Performance Counters (Optional Bonus)

Optional counters can measure CPU performance.
Average CPI can be computed as:
CPI = cycle_count / instr_retired

```verilog
reg [31:0] cycle_count, instr_retired;

always @(posedge clk)
    cycle_count <= cycle_count + 1;

if (RegWriteW)
    instr_retired <= instr_retired + 1;
```

# 📂 Project Structure
rvx10p_<rollno>/

src/
 ├── riscvpipeline.sv
 ├── controller.sv
 ├── datapath.sv
 ├── hazard_unit.sv
 └── forwarding_unit.sv

tb/
 └── tb_pipeline.sv

tests/
 └── rvx10_pipeline.hex

docs/
 └── REPORT.md

 # 📦 Deliverables

| File / Folder              | Description                            |
| -------------------------- | -------------------------------------- |
| `src/riscvpipeline.sv`     | Top-level pipeline module              |
| `src/controller.sv`        | Control unit                           |
| `src/datapath.sv`          | Processor datapath                     |
| `src/hazard_unit.sv`       | Hazard detection logic                 |
| `src/forwarding_unit.sv`   | Forwarding logic                       |
| `tests/rvx10_pipeline.hex` | Test programs                          |
| `tb/tb_pipeline.sv`        | Self-checking testbench                |
| `docs/REPORT.md`           | Design report and waveform screenshots |


