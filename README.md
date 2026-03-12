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
