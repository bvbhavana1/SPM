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
