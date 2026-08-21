# SPM — Serial-Parallel Multiplier (RTL-to-GDSII using OpenLane)

A bit-serial multiplier implemented in Verilog and carried through the complete open-source **RTL-to-GDSII ASIC flow** using OpenLane on the **SKY130** PDK — synthesis, floorplanning, placement, CTS, routing, parasitic extraction, STA, DRC, and LVS, all signed off with **zero violations**.

## Overview

The Serial-Parallel Multiplier (SPM) multiplies an `N`-bit parallel operand (`x`) with a serially-fed operand (`y`), producing the product one bit per clock cycle on the serial output `p`. Unlike a combinational or fully-parallel multiplier, this design trades latency for area efficiency — it reuses a single row of carry-save adders across multiple clock cycles instead of instantiating a full parallel adder array, making it a compact, low-area multiplier architecture well suited to resource-constrained ASIC implementations.

This project covers the design end-to-end: RTL implementation, functional simulation, and the complete physical design flow (synthesis → floorplanning → placement → CTS → routing → parasitic extraction → STA → DRC/LVS sign-off) using **OpenLane**, the open-source digital ASIC flow built on Yosys and OpenROAD.

## Architecture

The multiplier is built from two structural building blocks, instantiated `size` times via a `generate` loop:

### 1. Carry-Save Adder (`CSADD`)
A sequential (registered) carry-save adder cell — the fundamental unit of the multiplier's accumulator chain. Each `CSADD` stage:
- Takes a partial product bit (`x[i] & y`) and a carry-in from the next stage
- Computes sum and carry through two cascaded half-adders
- Registers both `sum` and the internal carry (`sc`) on every clock edge

### 2. Two's Complement / Sign-Correction Stage (`TCMP`)
Handles the final (MSB) stage of the accumulator chain, applying the correction needed for signed multiplication using a running XOR/OR-based carry-propagation scheme.

### 3. Top Module (`spm`)
Chains `size-1` instances of `CSADD` and a single `TCMP` stage via a `generate`/`genvar` loop, forming a systolic-style bit-serial multiplier pipeline. The design is fully synchronous, with `clk` and `rst` common to every stage.
```text
y ──────────────────────────────────────────┐
                                                  │

x[0] ──AND──▶ CSADD₀ ──▶ p (serial output) │
▲ │
x[1] ──AND──▶ CSADD₁ ────────────────────────────┘
▲
x[2] ──AND──▶ CSADD₂
⋮
x[N-1] ──AND──▶ TCMP (sign correction, final stage)
```

## Port Description

| Signal | Direction | Width      | Description                                  |
|--------|-----------|------------|-----------------------------------------------|
| `clk`  | Input     | 1 bit      | Clock                                         |
| `rst`  | Input     | 1 bit      | Synchronous reset                             |
| `x`    | Input     | `size` bits| Parallel multiplicand input                   |
| `y`    | Input     | 1 bit      | Serial multiplier input (fed one bit/cycle)   |
| `p`    | Output    | 1 bit      | Serial product output (one bit/cycle)         |

`size` is a parameter (default `32`, instantiated as `8` in the testbench).


## Simulation / Verification

The testbench (`spm_tb.v`) instantiates an 8-bit (`size=8`) version of the multiplier and verifies it by:
1. Applying a fixed multiplicand `x = 50`
2. Feeding the multiplier operand `Y` in through the serial `y` port, shifting one bit out per clock cycle
3. Collecting the serial product output `p` back into a 16-bit shift register `P`
4. Applying reset for the first 20ns and running for 1000ns total

**> 📸 Add screenshot:** waveform showing `x`, `Y`, `p`, and reconstructed `P` → save as `docs/waveform.png` and embed with `![Simulation Waveform](docs/waveform.png)`

## Physical Design Flow (OpenLane / SKY130)

The design was carried through OpenLane's full **RTL-to-GDSII** flow targeting the **SKY130 (`sky130_fd_sc_hd`)** standard cell library, at a **100 MHz (10 ns period)** target clock.
```text
RTL (Verilog)
│
▼
Synthesis (Yosys) → 301 cells, 3711.06 µm²
│
▼
Floorplanning (OpenROAD) → pin_order.cfg, 45% core utilization
│
▼
Placement (OpenROAD)
│
▼
Clock Tree Synthesis (CTS) → clock skew 0.04 ns
│
▼
Routing (OpenROAD)
│
▼
Parasitic Extraction (SPEF)
│
▼
Static Timing Analysis (OpenSTA) → WNS 0.00 ns, TNS 0.00 ns
│
▼
DRC (Magic) / LVS (Netgen) → 0 DRC, 0 LVS errors
│
▼
GDSI
```

**> 📸

### Sign-off Results

| Metric                          | Value                          |
|----------------------------------|---------------------------------|
| Die area                          | 101.85 µm × 112.57 µm (≈ 11,465 µm²) |
| Core area                          | 90.62 µm × 89.76 µm (≈ 8,134 µm²)   |
| Core utilization                    | 45%                            |
| Post-synthesis cell count             | 301 cells                    |
| Post-synthesis chip area                | 3,711.06 µm²                |
| Target frequency                          | 100 MHz (10 ns period)     |
| **Worst Negative Slack (WNS) — setup**      | **0.00 ns**                |
| **Total Negative Slack (TNS)**                | **0.00 ns**              |
| Worst setup slack (post-RCX)                    | 6.79 ns                |
| Worst hold slack (post-RCX)                       | 0.32 ns               |
| Clock skew                                          | 0.04 ns              |
| Total power (typical corner, post-extraction)         | 1.06 mW             |
| — Sequential power share                                 | 38.9%             |
| — Combinational power share                                | 61.1%           |
| Number of nets (LVS)                                          | 435          |
| DRC violations (Magic)                                          | **0**       |
| LVS errors                                                        | **0** — design is LVS clean |
| **Antenna violations (pin + net)**                                   | **0** |

All timing, power, and physical verification results were signed off at the **post-RC-extraction (RCX)** stage — the most accurate, parasitic-aware timing/power corner in the flow — confirming a fully closed, DRC-clean, LVS-clean implementation.

**> 📸 

## Cell Breakdown (Post-Synthesis)

| Standard Cell            | Count |
|----------------------------|-------|
| `sky130_fd_sc_hd__dfrtp_2` (DFF) | 64 |
| `sky130_fd_sc_hd__inv_2`           | 64 |
| `sky130_fd_sc_hd__and2_2`            | 32 |
| `sky130_fd_sc_hd__a31o_2`              | 31 |
| `sky130_fd_sc_hd__nand2_2`               | 31 |
| `sky130_fd_sc_hd__xnor2_2`                 | 31 |
| `sky130_fd_sc_hd__xor2_2`                    | 31 |
| `sky130_fd_sc_hd__buf_1`                       | 15 |
| `sky130_fd_sc_hd__a21o_2`                        | 1 |
| `sky130_fd_sc_hd__nand3_2`                         | 1 |
| **Total**                                            | **301** |

## Tools Used

| Purpose                | Tool                                  |
|--------------------------|----------------------------------------|
| RTL Design                | Verilog HDL                            |
| Simulation                 | Icarus Verilog / Verilator             |
| Physical Design Flow          | OpenLane (Yosys, OpenROAD)          |
| Static Timing Analysis            | OpenSTA                          |
| DRC / LVS                            | Magic, Netgen                    |
| Circuit Validity Checking                | CVC                          |
| PDK                                          | SKY130 (`sky130_fd_sc_hd`)   |

## How to Run

### Simulation
```bash
iverilog -o spm_sim src/spm.v spm_tb.v
vvp spm_sim
```

### OpenLane Flow
```bash
cd $OPENLANE_ROOT
make mount
./flow.tcl -design spm
```

## Key Learnings

- Implementing a **bit-serial multiplier architecture** — trading latency (N cycles per multiplication) for significantly reduced area versus a fully parallel multiplier
- Practical use of Verilog `generate`/`genvar` constructs to build scalable, parameterized hardware structures
- Hands-on use of **OpenLane's config system** — both modern `config.json` (PDK-conditional overrides) and legacy `config_in.tcl` formats
- Custom **floorplan pin ordering** via `pin_order.cfg` for physical pin placement per side of the die
- Reading and interpreting **sign-off-grade STA reports** — the difference between pre-route and post-RC-extraction (RCX) timing, and why RCX numbers are the ones that matter for tape-out
- Achieving a **fully clean physical sign-off**: 0 DRC violations, 0 LVS mismatches, 0.00 ns WNS/TNS across the complete open-source ASIC toolchain (Yosys → OpenROAD → Magic → Netgen)

## Future Improvements

- Add signed-multiplication test vectors to more rigorously verify the `TCMP` correction stage
- Parameterize and re-run the flow across multiple `size` values to compare area/power/timing tradeoffs
- Add a self-checking (assertion-based or scoreboard) testbench instead of visual waveform verification
- Explore hold-slack margin (currently 0.32 ns) sensitivity across PVT corners

