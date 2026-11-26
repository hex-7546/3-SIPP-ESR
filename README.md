<div align="center">

# 3-SIPP-ESR

<p align="center">
  <img src="https://img.shields.io/badge/ISA-RV32IMACB-green" alt="ISA"/>
  <img src="https://img.shields.io/badge/Extensions-Zicsr%20%2B%20Zcb%20%2B%20Zbc%20%2B%20Zifencei-blue" alt="Extensions"/>
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License"/>
  <a href="https://www.linkedin.com/company/open-risc-v/"><img src="https://img.shields.io/badge/LinkedIn-Follow-0077B5" alt="LinkedIn Follow"/></a>
  <a href="https://or5.org"><img src="https://img.shields.io/badge/Visit-or5.org-brightgreen?logo=google-chrome" alt="Visit or5.org"/></a>
</p>

</div>

A fast, lightweight **RV32IMACB** processor core written in SystemVerilog. Built around a 3-stage in-order pipeline with dynamic branch prediction and zero-stall forwarding, it targets embedded control planes, real-time RTOS workloads, and resource-constrained FPGA soft-cores.

![diagram](diagram.svg)

---

## Overview

| | |
| :--- | :--- |
| **ISA** | `RV32IMACB_Zicsr_Zcb_Zbc_Zifencei` |
| **Microarchitecture** | 3-stage in-order pipeline (Fetch / Execute / Memory-Writeback) |
| **Branch Prediction** | 256-entry gshare + 64-entry BTB + RAS |
| **Privilege Modes** | Machine (M); optional User (U) in `SECURE` configuration |
| **Security & Memory Protection** | 8-region PMP + Smepmp (`mseccfg`: MML, MMWP, RLB) |
| **Triggers** | 2 hardware breakpoint/watchpoint triggers (`Sdtrig`, `mcontrol6`) |
| **Bus Interfaces** | Native memory port + AXI4-Lite master bridge |
| **Debug** | RISC-V External Debug via JTAG (debug spec 0.13, DTM + DM) |
| **Target FPGA** | Digilent Arty A7-100T |

---

## Features

- **3-Stage Pipelined Execution:** Results are forwarded directly from write-back to execute with zero load-use stall — only multiplies, divides, and hardware-resolved misaligned accesses stall the pipeline
- **Full Standard Extension Coverage:** Complete support for `I`, `M`, `A`, `C`, `B` (`Zba`/`Zbb`/`Zbs`/`Zbc`), `Zcb`, `Zicsr`, and `Zifencei`
- **Two-Tier Trust Model (`SECURE` Build):** Optional `SECURE` build adds User privilege mode, an 8-region Physical Memory Protection (PMP) unit with **Smepmp** (`MML`, `MMWP`, `RLB`), and user-level trap delegation
- **Hardware Triggers:** Two `Sdtrig` (`mcontrol6`) triggers supporting instruction address breakpoints and load/store data watchpoints
- **Hardware-Resolved Misalignment:** Unaligned loads and stores complete normally in hardware without raising exceptions
- **RISC-V External Debug over JTAG:** JTAG Debug Transport Module (DTM) and RISC-V Debug Module (0.13 spec) supporting halt, register/memory inspection, resume, and single-step
- **Real-Time Ready:** Runs FreeRTOS with preemptive multitasking and deterministic 63-cycle interrupt latency
- **Clean Synthesizable RTL:** Pure SystemVerilog with no proprietary IP, tested on Digilent Arty A7-100T and verified across Icarus Verilog, Verilator, and Vivado

---

## Resource Utilization

Synthesized and implemented using **AMD Vivado 2023.2** targeting the **Arty A7-100T** (`xc7a100tcsg324-1`) evaluation board.

| Configuration | LUTs | BRAM | DSP |
| :--- | :---: | :---: | :---: |
| **Default** (`RV32IMACB`, M-mode) | 7,418 | 0 | 12 |
| **SECURE** (`M+U`, 8-region PMP/Smepmp) | 8,647 | 0 | 12 |

---

## Benchmark Metrics

Measured on FPGA **Arty A7-100T**.

| Benchmark | FPGA (Arty A7-100T @ 25 MHz) |
| :--- | :--- |
| **CoreMark 1.0** (10 iterations) | **2.920 CoreMark/MHz** (341,542 cycles/iter, CRC Validated) |
| **Dhrystone 2.1** (1,000 runs) | **1.310 DMIPS/MHz** (434 cycles/run) |

Detailed results, compiler flags, and methodology: **[benchmarks.md](benchmarks.md)**

---

## Requirements

| Tool | Version | Purpose |
| :--- | :--- | :--- |
| **Verilator** | 5.0 or later | Cycle-accurate RTL simulation |
| **Python** | 3.10 or later | Test-program builders and co-simulation |
| **RISC-V GCC** | 13.0 or later (`riscv-none-elf-*` or `riscv64-unknown-elf-*`) | Compiling RTOS, SECURE tests, and FPGA firmware |
| **Vivado** | 2023.2 *(optional)* | FPGA synthesis and implementation for Digilent Arty A7-100T (xc7a100tcsg324-1) |

Set `RISCV_TC=/path/to/toolchain/bin` to point at a non-`PATH` toolchain.

---

## Build & Test

A single top-level **Makefile** covers the most common workflows. For fine-grained control every action is also available directly through `build.sh`.

### Makefile targets

```bash
make              # compile RTL + run self-checking smoke test
make rtos         # FreeRTOS preemptive demo + negative control
make rtos-suite   # full 5-stage RTOS verification battery
make clean        # remove simulation and build artifacts
make help         # list all targets
```

### All `build.sh` actions

```bash
./build.sh            # smoke test
./build.sh cosim      # co-simulate against the golden RV32IM ISA model
./build.sh rvfi       # RISC-V Formal Interface trace self-check
./build.sh zcb        # directed Zcb tests + negative control
./build.sh trig       # Sdtrig hardware trigger tests
./build.sh debug      # JTAG DTM + Debug Module
./build.sh priv       # SECURE config: M/U privilege, PMP, Smepmp, triggers
./build.sh axi        # AXI4-Lite master bridge BFM test
./build.sh fpga       # FPGA SoC simulation (UART banner + LED blink)
./build.sh rtos       # FreeRTOS demo
./build.sh rtos-suite # full 5-stage RTOS verification suite
./build.sh clean      # remove build artifacts
./run_tests.sh        # full regression battery checked against tests/expected.txt
```

Every action exits non-zero if the testbench reports `FAIL`, `TIMEOUT`, `MISMATCH`, or does not print its `PASS` verdict.

For in depth results and per-test details: **[tests.md](tests.md)**.

---

## Configuration Options

3-SIPP-ESR ships in two build-time configurations, selected by the `SECURE` RTL parameter or compile-time define `-DTHREE_SIPP_ESR_SECURE`:

| Property / Feature | Default | SECURE |
| :--- | :--- | :--- |
| **Privilege Modes** | Machine (M) only | Machine (M) + User (U) |
| **Memory Protection** | — | 8-region PMP + Smepmp (`mseccfg`: MML, MMWP, RLB) |
| **Target Use Case** | Smallest area footprint | Isolation, security, user-mode trap delegation |
| **`misa` U-bit** | Not set | Set (bit 20 = 1) |
| **Locked PMP Regions** | — | Enforced on Machine mode as well |

---

## Repository Layout

```
3-SIPP-ESR/
├── Makefile                    top-level build & test entry point
├── build.sh                    fine-grained simulation & test driver
├── run_tests.sh                automated regression runner (checks against tests/expected.txt)
├── tests.md                    comprehensive verification & test report
├── benchmarks.md               detailed performance benchmarks (CoreMark, Dhrystone)
├── rtl/
│   ├── three_sipp_esr_core.sv      3-stage pipeline, predictor, forwarding
│   ├── three_sipp_esr_soc.sv       minimal SoC (IMEM, DRAM, CLINT, UART, tohost)
│   ├── three_sipp_esr_debug.sv     JTAG DTM + RISC-V Debug Module (0.13 spec)
│   ├── three_sipp_esr_axi_lite.sv  AXI4-Lite master bridge
│   ├── three_sipp_esr_uart.sv      UART peripheral
│   └── common/                     shared leaf cells (ALU, MulDiv, RegFile,
│                                   CSR, RVC, ImmGen, Branch, Decode, PMP)
├── tb/                         testbenches (smoke, RVFI, debug, priv, AXI)
├── rtos/                       FreeRTOS port (kernel, BSP, verification apps)
├── fpga/                       FPGA top-level SoC wrapper + Digilent Arty A7-100T XDC constraints
├── programs/                   test-program builders
├── sw/                         firmware, binary-to-hex utilities, bring-up tests
└── tools/                      golden Python ISA model + co-simulation driver
```

---

## License

Released under the [MIT License](LICENSE) — free for commercial, research, and academic use.
