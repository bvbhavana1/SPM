### SPM — Serial-Parallel Multiplier | Complete RTL-to-GDSII ASIC Implementation

> **A parameterized Serial-Parallel Multiplier designed in Verilog and implemented through a complete open-source RTL-to-GDSII ASIC flow using OpenLane and the SKY130 PDK.**

[![Verilog](https://img.shields.io/badge/HDL-Verilog-blue)]()
[![ASIC](https://img.shields.io/badge/Design-ASIC-orange)]()
[![PDK](https://img.shields.io/badge/PDK-SKY130-red)]()
[![Flow](https://img.shields.io/badge/Flow-OpenLane-purple)]()
[![Target](https://img.shields.io/badge/Target-100%20MHz-success)]()
[![DRC](https://img.shields.io/badge/DRC-0%20Violations-success)]()
[![LVS](https://img.shields.io/badge/LVS-0%20Errors-success)]()


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
```
🧩 Architecture

The Serial-Parallel Multiplier consists of:
* Partial Product Generation
* Carry-Save Adder (CSADD) stages
* Two's Complement / Sign-Correction (TCMP) stage
* Top-level spm module
* Serial product output

For an N-bit configuration, the architecture contains:

```text
(N − 1) × CSADD
       +
    1 × TCMP

```

For example, with size = 8:


```text
7 × CSADD + 1 × TCMP

```
## Architecture Diagram
```text
                         Serial Input
                              y
                              │
              ┌───────────────┼────────────────┐
              │               │                │
              ▼               ▼                ▼
           x[0] & y        x[1] & y         x[2] & y       ...       x[N-1] & y
              │               │                │                         │
              ▼               ▼                ▼                         ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐              ┌──────────┐
        │  CSADD₀  │───▶│  CSADD₁  │───▶│  CSADD₂  │─── ... ────▶│   TCMP   │
        └────┬─────┘    └────┬─────┘    └────┬─────┘              └────┬─────┘
             │               │               │                          │
             ▼               ▼               ▼                          ▼
             p             pp[1]           pp[2]                     pp[N-1]

              Sequential Carry-Save Accumulation / Correction Chain

                    Common clk / asynchronous active-high rst
```
1. Partial Product Generation
For every stage, the partial-product contribution is generated using:


```text
x[i] & y
```
Here:

x is the N-bit parallel operand.
y is the single-bit serial multiplier input.
x[i] & y generates the corresponding partial-product bit.

Conceptually:
```text
                  y
                  │
        ┌─────────┼─────────┐
        │         │         │
        ▼         ▼         ▼
      x[0]      x[1]      x[2]      ...      x[N-1]
        │         │         │                  │
        └─────────┴─────────┴──────────────────┘
                         │
                         ▼
                  Partial Products
```
The partial-product bits are then processed by the corresponding sequential arithmetic stages.

2. Carry-Save Adder — CSADD

CSADD is the primary processing element of the multiplier.

Each CSADD stage receives:

The current partial-product bit
The intermediate value from the next stage
A registered internal carry state sc

The addition is implemented using two cascaded half-adders.
```text
                  y
                  │
                  ▼
           ┌─────────────┐
           │ Half Adder  │
           └──────┬──────┘
                  │
                hsum1
                  │
                  ▼
        x ───▶ ┌─────────────┐
               │ Half Adder  │
               └──────┬──────┘
                      │
                      ▼
                     sum
```
The carry outputs are combined to generate the next internal carry:

sc <= hco1 ^ hco2;

Both the sum output and internal carry sc are registered on the rising edge of clk.

This provides sequential carry-save accumulation, allowing intermediate arithmetic state to propagate through the multiplier chain over successive clock cycles.

3. Two's Complement / Sign-Correction Stage — TCMP

The final stage of the architecture is the TCMP module.

It processes the most significant partial-product contribution:

x[size-1] & y

The module maintains an internal state z and generates the corrected output using:

```text
z <= a | z;
s <= a ^ z;
```

The TCMP stage provides the required MSB/sign-correction behavior for the implemented two's-complement multiplication architecture.

Like the CSADD stages, TCMP is sequential and operates using the common:

clk
asynchronous active-high rst
4. Top-Level spm Module
The spm module connects the complete multiplier architecture.

The design is parameterized using:

```text
parameter size = 32;
```
The intermediate outputs are connected through the pp signal chain.

The repeated CSADD stages are generated using Verilog's:
```text
generate
genvar
```
This provides a scalable structural implementation without manually replicating each stage.

## Structural Organization

```text                         spm
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
       CSADD₀          CSADD₁          CSADD[N-2]
          │               │                │
          └───────────────┴────────────────┘
                          │
                          ▼
                        TCMP
                          │
                          ▼
                          p


              Common clk / asynchronous active-high rst

```
## Serial Processing

The multiplier operand is supplied serially through the single-bit input y.

In the testbench, the multiplier operand is shifted right by one bit every clock cycle:

```text 
Y <= {1'b0, Y[7:1]};
```
Therefore:
```text
Y[0] ──▶ y ──▶ SPM ──▶ p
```
The serial product output p is collected and reconstructed in a 16-bit product register:
```text
P <= {p, P[15:1]};
```
Serial Data Path
```text
             Parallel Operand
                    x
                    │
                    ▼
             ┌──────────────┐
Serial Y ───▶│     SPM      │────▶ p
             │              │
             └──────────────┘
                    │
                    ▼
              Serial Product
                    │
                    ▼
               Product P
```
🧪 RTL Verification

The testbench instantiates an 8-bit version of the multiplier:
```text
spm #(8) uut (
    .clk(clk),
    .rst(rst),
    .y(Y[0]),
    .x(x),
    .p(p)
);
```
## Test Configuration
```text
| Parameter            |                    Value |
|-------------------------------------------------|
| SPM Configuration    |                    8-bit |
| Parallel Operand `x` |                       50 |
| Serial Operand `Y`   |                      -50 |
| Product Register     |                   16-bit |
| Clock Period         |                    10 ns |
| Simulation Duration  |                  1000 ns |
| Reset                | Asynchronous active-high |
```
The testbench performs:

Initialization of the input operands.
* Reset assertion and release.
* Serial extraction of the multiplier operand.
* One-bit-per-cycle processing.
* Serial product capture.
* Product reconstruction using a shift register.
* Cycle counting for the serial processing sequence.
RTL Simulation Waveform

 ## RTL-to-GDSII ASIC Flow

The design was implemented using the OpenLane RTL-to-GDSII flow, targeting the SKY130 PDK and sky130_fd_sc_hd standard-cell library.
```text
┌──────────────────────────┐
│       Verilog RTL        │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│    Yosys Synthesis       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│      Floorplanning       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│       Placement          │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Clock Tree Synthesis     │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│        Routing           │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Parasitic Extraction     │
│       / RCX / SPEF       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│     OpenSTA — STA        │
└────────────┬─────────────┘
             │
       ┌─────┴─────┐
       ▼           ▼
   ┌───────┐   ┌───────┐
   │ Magic │   │ Netgen│
   │  DRC  │   │  LVS  │
   └───┬───┘   └───┬───┘
       │           │
       └─────┬─────┘
             ▼
       ┌────────────┐
       │   GDSII    │
       └────────────┘
```

## OpenLane Configuration
The main OpenLane configuration uses the following parameters:
```text
| Parameter               |             Value |
| Design Name             |             `spm` |
| RTL Source              |         `src/*.v` |
| PDK                     |            SKY130 |
| Standard Cell Library   | `sky130_fd_sc_hd` |
| Clock Port              |             `clk` |
| Clock Name              |      `core_clock` |
| Clock Period            |         **10 ns** |
| Target Frequency        |       **100 MHz** |
| Core Utilization Target |           **45%** |
| Pin Order Configuration |   `pin_order.cfg` |
| PDN Horizontal Offset   |              7 µm |
| PDN Vertical Offset     |              7 µm |
```
## OpenLane Configuration
The main OpenLane configuration uses the following parameters:
Clock Constraint

The design is constrained using:
```text
set_units -time ns
create_clock [get_ports clk] -name core_clock -period 10
```
The 10 ns clock period corresponds to a 100 MHz target clock frequency.

 ##Physical Design Results
Floorplan :
The floorplan was configured for a 45% target core utilization, with custom pin ordering specified through pin_order.cfg.

Clock Tree Synthesis :
The reported clock skew after implementation is: 0.04 ns

## Sign-Off Results
The design was taken through the complete RTL-to-GDSII implementation flow and evaluated at the final physical implementation stage.
The reported sign-off results include post-RCX static timing analysis, power analysis, DRC, LVS, and antenna verification.
```text
| Metric                        |                 Value |
| PDK                           |                SKY130 |
| Standard Cell Library         |     `sky130_fd_sc_hd` |
| Die Size                      | 101.85 µm × 112.57 µm |
| Die Area                      |          ≈ 11,465 µm² |
| Core Size                     |   90.62 µm × 89.76 µm |
| Core Area                     |           ≈ 8,134 µm² |
| Core Utilization              |               45%     |
| Post-Synthesis Cell Count     |               301     |
| Post-Synthesis Cell Area      |      3,711.06 µm²     |
| Target Clock Period           |             10 ns     |
| Target Frequency              |           100 MHz     |
```

## Post-RCX Static Timing Analysis
```text
| Timing Metric                    |        Value |
| Setup WNS                        |  0.00 ns     |
| Hold WNS                         | +0.32 ns     |
| TNS                              |  0.00 ns     |
| Worst Setup Slack — Post-RCX     | +6.79 ns     |    
| Clock Skew                       |  0.04 ns     |
| Timing Status                    |      MET     |
```
The final reported post-RCX STA achieved non-negative setup and hold timing, with 0.00 ns total negative slack.

## Power Analysis — Typical Corner
```text
| Power Metric              |        Value |
| **Total Power**           |  **1.06 mW** |
| Sequential Power Share    |        38.9% |
| Combinational Power Share |        61.1% |
| Internal Power            |     0.754 mW |
| Switching Power           |     0.309 mW |
| Leakage Power             | ≈ 0.00279 µW |
```
The reported total power at the analyzed typical corner is 1.06 mW.
Power Distribution
```text
Sequential Logic       38.9%  ███████████████████
Combinational Logic    61.1%  ██████████████████████████████
```
## Physical Implementation
```text
| Sign-Off Check                   |    Result |
| DRC Violations — Magic           |     0     |
| LVS Errors — Netgen              |     0     |
| LVS Nets                         |   435     |
| Antenna Violations               |     0     |
| Physical Verification Status     | CLEAN    |
```
The final reported physical verification completed with:
0 DRC violations
0 LVS errors
0 antenna violations

## Final Implementation Summary
```text
| Category              | Metric                     | 
| Architecture          | Serial-Parallel Multiplier |    
| RTL                   | Parameterized Verilog      |     
| PDK                   | SKY130                     |     
| Standard Cell Library | `sky130_fd_sc_hd`          |      
| Core Utilization      | 45%                        |    
| Standard Cells        | 301                        |     
| Die Area              | ≈ 11,465 µm²               |     
| Core Area             | ≈ 8,134 µm²                |     
| Target Frequency      | 100 MHz                    |      
| Setup WNS             | 0.00 ns                    |      
| Hold WNS              | +0.32 ns                   |     
| TNS                   | 0.00 ns                    |     
| Worst Setup Slack     | +6.79 ns                   |      
| Clock Skew            | 0.04 ns                    |      
| Typical-Corner Power  | 1.06 mW                    |     
| DRC                   | 0 violations               |     
| LVS                   | 0 errors                   |      
| Antenna               | 0 violations               |      
| GDSII                 | Generated                  |
```  
## Post-Synthesis Cell Breakdown
The synthesized design contains 301 standard cells.
```text
| Standard Cell              |   Count |
| `sky130_fd_sc_hd__dfrtp_2` |      64 |
| `sky130_fd_sc_hd__inv_2`   |      64 |
| `sky130_fd_sc_hd__and2_2`  |      32 |
| `sky130_fd_sc_hd__a31o_2`  |      31 |
| `sky130_fd_sc_hd__nand2_2` |      31 |
| `sky130_fd_sc_hd__xnor2_2` |      31 |
| `sky130_fd_sc_hd__xor2_2`  |      31 |
| `sky130_fd_sc_hd__buf_1`   |      15 |
| `sky130_fd_sc_hd__a21o_2`  |       1 |
| `sky130_fd_sc_hd__nand3_2` |       1 |
| **Total**                  | **301** |
```

## Tools and Technologies
```text
| Category               | Tool / Technology          |
| RTL Design             | Verilog HDL                |
| RTL Simulation         | Icarus Verilog / Verilator |
| Waveform Analysis      | GTKWave                    |
| Logic Synthesis        | Yosys                      |
| Floorplanning          | OpenROAD                   |
| Placement              | OpenROAD                   |
| Clock Tree Synthesis   | OpenROAD                   |
| Routing                | OpenROAD                   |
| Parasitic Extraction   | SPEF / RCX                 |
| Static Timing Analysis | OpenSTA                    |
| DRC                    | Magic                      |
| LVS                    | Netgen                     |
| Layout Viewing         | KLayout                    |
| ASIC Flow              | OpenLane                   |
| PDK                    | SKY130                     |
| Standard Cell Library  | `sky130_fd_sc_hd`          |
| Scripting              | Tcl / Bash                 |
| Environment            | Linux / WSL                |
```
## Engineering Learnings
```text
RTL 
Verification
RTL simulation and waveform analysis
Synthesis & Physical Design
Clock Tree Synthesis
Routing
Parasitic extraction
Post-route / post-RCX timing analysis
Sign-Off & Analysis
Setup and hold timing analysis
WNS and TNS interpretation
Clock skew analysis
Power analysis
DRC verification
LVS verification
Antenna verification
GDSII generation
Final layout inspection using KLayout
```
## Architecture Trade-Off
The SPM architecture intentionally trades latency for hardware efficiency.
A conventional parallel multiplier generally provides high throughput at the cost of a larger combinational datapath.
The serial-parallel architecture instead processes multiplication over multiple clock cycles, reducing the need for a fully parallel multiplication structure.
```text
          Fully Parallel Multiplier
                     │
             ┌───────┴───────┐
             │               │
          Higher          Lower
           Area           Latency
             │               │
             └───────┬───────┘
                     │
                     ▼
              Area / Speed
                Trade-Off
                     ▲
                     │
             ┌───────┴───────┐
             │               │
          Lower           Higher
           Area           Latency
             │               │
             └───────┬───────┘
                     │
          Serial-Parallel Multiplier
```
## Future Improvements
Develop a self-checking scoreboard-based verification environment.
Add randomized signed and unsigned multiplication test vectors.
Increase functional coverage for boundary and corner cases.
Parameterize the verification environment along with the RTL width.
Characterize area, power, timing, and latency across multiple operand widths.
Perform detailed multi-corner / PVT static timing analysis.
Compare the SPM against conventional parallel multiplier architectures.
Investigate architectural optimizations for improved throughput.
Add automated RTL regression testing.
Integrate ASIC-flow checks into a CI/CD pipeline.
Explore alternative standard-cell libraries and physical-design constraints.

## Conclusion
The Serial-Parallel Multiplier was successfully taken from parameterized RTL to a physically verified GDSII implementation using an open-source ASIC design flow.
The project demonstrates practical experience across the complete digital ASIC implementation cycle.

 ## Final Reported Results
```text
301 standard cells · 45% core utilization · 100 MHz target clock · +6.79 ns worst setup slack · +0.32 ns hold WNS · 0.00 ns TNS · 1.06 mW typical-corner power · 0 DRC · 0 LVS · 0 antenna violations
```
The project demonstrates hands-on understanding of RTL design, digital synthesis, physical implementation, timing closure, power analysis, and ASIC physical verification, culminating in a complete RTL-to-GDSII implementation.

## Project Information
```text
| Field                | Details                        |
| Project              | Serial-Parallel Multiplier     |
| Domain               | Digital VLSI / ASIC Design     |
| Architecture         | Serial-Parallel Multiplication |
| HDL                  | Verilog                        |
| ASIC Flow            | OpenLane                       |
| Synthesis            | Yosys                          |
| Physical Design      | OpenROAD                       |
| STA                  | OpenSTA                        |
| PDK                  | SKY130                         |
| Standard Cells       | `sky130_fd_sc_hd`              |
| Target Frequency     | 100 MHz                        |
| Implementation       | RTL-to-GDSII                   |
```
