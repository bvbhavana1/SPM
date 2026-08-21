# SPM — Serial-Parallel Multiplier (RTL-to-GDSII using OpenLane)

A bit-serial multiplier implemented in Verilog and carried through the complete open-source **RTL-to-GDSII ASIC flow** using OpenLane on the **SKY130** PDK — synthesis, floorplanning, placement, CTS, routing, parasitic extraction, STA, DRC, and LVS, all signed off with **zero violations**.

## Overview

The Serial-Parallel Multiplier (SPM) multiplies an `N`-bit parallel operand (`x`) with a serially-fed operand (`y`), producing the product one bit per clock cycle on the serial output `p`. Unlike a combinational or fully-parallel multiplier, this design trades latency for area efficiency — it reuses a single row of carry-save adders across multiple clock cycles instead of instantiating a full parallel adder array, making it a compact, low-area multiplier architecture well suited to resource-constrained ASIC implementations.

This project covers the design end-to-end: RTL implementation, functional simulation, and the complete physical design flow (synthesis → floorplanning → placement → CTS → routing → parasitic extraction → STA → DRC/LVS sign-off) using **OpenLane**, the open-source digital ASIC flow built on Yosys and OpenROAD.

## Architecture

The **Serial-Parallel Multiplier (SPM)** is a parameterized, synchronous multiplier implemented using a chain of **Carry-Save Adder (`CSADD`) stages** followed by a **Two's Complement / Sign-Correction (`TCMP`) stage**.

The design accepts an `N`-bit operand `x` in parallel, while the multiplier operand is supplied serially through the single-bit input `y`. During each clock cycle, one bit of the serial multiplier operand is processed together with the corresponding partial-product contribution from `x`.

The architecture is parameterized using the `size` parameter, with a default value of `32`.

### Architecture Overview

```text
                         y
                         │
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
     x[0] & y         x[1] & y         x[2] & y       ...      x[N-1] & y
        │                │                │                         │
        ▼                ▼                ▼                         ▼
   ┌─────────┐      ┌─────────┐      ┌─────────┐             ┌─────────┐
   │ CSADD₀  │─────▶│ CSADD₁  │─────▶│ CSADD₂  │─── ... ───▶│  TCMP   │
   └────┬────┘      └────┬────┘      └────┬────┘             └────┬────┘
        │                │                │                         │
        ▼                ▼                ▼                         ▼
        p              pp[1]            pp[2]                    pp[N-1]

              Sequential Carry-Save Accumulation Chain
                         │
                    clk / rst
```

### 1. Partial Product Generation

For every stage, the partial product is generated using:

```verilog
x[i] & y
```

Since `x` is an `N`-bit parallel operand and `y` is a single-bit serial input, each clock cycle activates the required bits of `x` according to the current value of `y`.

The generated partial-product bits are supplied to the corresponding `CSADD` stages.

### 2. Carry-Save Adder (`CSADD`)

`CSADD` is the primary processing element used to perform sequential accumulation.

Each `CSADD` receives:

* `x` — the current partial-product bit (`x[i] & y`)
* `y` — the accumulated value from the next stage
* `sc` — the internally stored carry

The addition is implemented using **two cascaded half-adders**:

```text
        y ───────┐
                 ▼
              Half Adder
                 │
        sc ──────┘
                 │
                 ▼
              hsum1
                 │
                 ▼
        x ───▶ Half Adder
                 │
                 ▼
               sum
```

The carry outputs from the two half-adders are combined to generate the next internal carry:

```verilog
sc <= hco1 ^ hco2;
```

Both `sum` and `sc` are registered on the rising edge of `clk`.

Each `CSADD` therefore provides **sequential carry-save accumulation**, allowing the partial-product information to propagate through the multiplier chain over successive clock cycles.

### 3. Two's Complement / Sign-Correction Stage (`TCMP`)

The final stage of the architecture is the `TCMP` module.

`TCMP` processes the most significant partial-product bit:

```verilog
x[size-1] & y
```

It maintains an internal state `z` and generates the corrected final-stage output using:

```verilog
z <= a | z;
s <= a ^ z;
```

The stage therefore provides the required **MSB/sign-correction behavior** for the multiplier's two's-complement operation.

Like the `CSADD` stages, `TCMP` is sequential and operates on the common `clk` and `rst` signals.

### 4. Top-Level `spm` Module

The `spm` module connects the complete multiplier architecture.

For an `N`-bit configuration:

* One `CSADD` stage is instantiated for `x[0]`.
* `N-2` additional `CSADD` stages are generated using a `generate` loop.
* One `TCMP` stage processes `x[N-1]`.
* The intermediate stage outputs are connected through the `pp` signal chain.
* All stages share the same `clk` and asynchronous active-high `rst`.

The resulting structure contains:

```text
(N - 1) × CSADD
        +
    1 × TCMP
```

For example, with `size = 8`:

```text
7 × CSADD + 1 × TCMP
```

### 5. Serial Processing and Testbench Operation

The testbench demonstrates the serial operation of the multiplier.

The multiplier operand `Y` is initialized and shifted right by one bit every clock cycle:

```verilog
Y <= {1'b0, Y[7:1]};
```

Therefore, `Y[0]` is presented to the SPM as the serial input `y`.

At the same time, the generated serial output `p` is accumulated into the product register `P`:

```verilog
P <= {p, P[15:1]};
```

A cycle counter is also used to track the serial multiplication process.

For the 8-bit test configuration:

```text
       X = 50
       Y = -50

             │
             ▼
     ┌─────────────────┐
     │ Serial bit      │
     │ extraction      │
     │    Y[0]         │
     └────────┬────────┘
              │
              ▼
        ┌───────────┐
 X ────▶│    SPM    │────▶ p
        │ 8-bit     │
        └───────────┘
              │
              ▼
       Serial product
              │
              ▼
        Product P[15:0]
```

### Key Architectural Characteristics

| Feature                     | Description                                                         |
| --------------------------- | ------------------------------------------------------------------- |
| **Architecture**            | Serial-Parallel Multiplier                                          |
| **Parallel Operand**        | `x[size-1:0]`                                                       |
| **Serial Operand**          | Single-bit `y`                                                      |
| **Core Processing Element** | `CSADD`                                                             |
| **Final Stage**             | `TCMP`                                                              |
| **Partial Product**         | `x[i] & y`                                                          |
| **Adder Structure**         | Two cascaded half-adders                                            |
| **Carry Storage**           | Registered `sc`                                                     |
| **Control**                 | `clk` and asynchronous active-high `rst`                            |
| **Parameterization**        | Configurable through `size`                                         |
| **Stage Generation**        | Verilog `generate` / `genvar`                                       |
| **Output**                  | Serial product bit `p`                                              |
| **Verification**            | Verilog testbench with serial `Y` shifting and product accumulation |

### RTL Structure

```text
                         spm
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
       CSADD₀          CSADD₁ ...      CSADD[N-2]
          │               │                │
          └───────────────┴────────────────┘
                          │
                          ▼
                        TCMP
                          │
                          ▼
                          p

             Common clk and asynchronous rst
```

This structural organization makes the SPM **parameterizable, synthesizable, and suitable for RTL-to-GDSII implementation**.


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

