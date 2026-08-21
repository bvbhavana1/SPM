# ⚡ SPM — Serial-Parallel Multiplier | Complete RTL-to-GDSII ASIC Implementation

> **A parameterized Serial-Parallel Multiplier designed in Verilog and implemented through a complete open-source RTL-to-GDSII ASIC flow using OpenLane and the SKY130 PDK.**

[![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)]()
[![ASIC](https://img.shields.io/badge/Design-ASIC-orange)]()
[![PDK](https://img.shields.io/badge/PDK-SKY130-red)]()
[![Flow](https://img.shields.io/badge/Flow-OpenLane-purple)]()
[![Target](https://img.shields.io/badge/Target-100%20MHz-success)]()
[![DRC](https://img.shields.io/badge/DRC-0%20Violations-success)]()
[![LVS](https://img.shields.io/badge/LVS-0%20Errors-success)]()

---

## 🚀 Project Highlights

- Designed a **parameterized Serial-Parallel Multiplier (SPM)** using synthesizable Verilog HDL.
- Implemented a sequential **Carry-Save Accumulation architecture** using registered `CSADD` stages.
- Designed a dedicated **Two's Complement / MSB Sign-Correction (`TCMP`) stage**.
- Used Verilog `generate` / `genvar` constructs for scalable hardware generation.
- Developed an RTL testbench for **serial operand processing and product reconstruction**.
- Executed the complete **RTL-to-GDSII ASIC flow** using OpenLane, Yosys, and OpenROAD.
- Performed **synthesis, floorplanning, placement, CTS, routing, parasitic extraction, and post-RCX STA**.
- Analyzed **area, timing, power, clock skew, and physical verification** results.
- Achieved **+6.79 ns reported worst setup slack, +0.32 ns hold WNS, and 0.00 ns TNS** in post-RCX STA.
- Achieved **0 DRC violations, 0 LVS errors, and 0 antenna violations**.
- Reported **1.06 mW total power** at the analyzed typical corner.
- Generated the final **GDSII physical layout** using the SKY130 standard-cell technology.

---

# 📌 Overview

The **Serial-Parallel Multiplier (SPM)** multiplies an `N`-bit parallel operand `x` with a serially supplied multiplier operand `y`.

Unlike a fully combinational or fully parallel multiplier, the SPM processes the multiplier operand **one bit per clock cycle** and performs sequential carry-save accumulation.

This architecture trades **computation latency for reduced hardware complexity**, making it useful for applications where hardware/resource efficiency is more important than maximum multiplication throughput.

The design is parameterized through the `size` parameter, allowing the architecture to scale across different operand widths.

The project covers the complete digital ASIC implementation flow:

```text
RTL Design
    │
    ▼
RTL Simulation
    │
    ▼
Logic Synthesis
    │
    ▼
Floorplanning
    │
    ▼
Placement
    │
    ▼
Clock Tree Synthesis
    │
    ▼
Routing
    │
    ▼
Parasitic Extraction
    │
    ▼
Static Timing Analysis
    │
    ▼
DRC / LVS / Antenna Verification
    │
    ▼
GDSII
