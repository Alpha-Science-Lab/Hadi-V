### Microcontroller Design, Lab: HaDes-V (Adapted Work)

![image](https://www.scheipel.com/wp-content/uploads/2024/12/hades_logo.svg)

This repository is based on the **HaDes-V Open Educational Resource (OER)** developed by **Tobias Scheipel**, David Beikircher, and Florian Riedl from the Embedded Architectures & Systems Group at **Graz University of Technology**.

We gratefully acknowledge and credit the original authors for making this resource publicly available under an open license. Their work provides a structured and highly effective foundation for learning processor design, and it has significantly contributed to our development process.

> This repository contains adaptations and extensions built upon the original HaDes-V framework for educational and research purposes.

---

## Independence In Deep Technology

On the occasion of Independence Day, March 26, **Alpha Science Lab, Mymensingh Engineering College**, humbly shares a milestone from its ongoing journey in hardware design and engineering.

## • Swadheen SoC

**Swadheen SoC** is an in-house developed RISC-V based system-on-chip, designed as part of our effort to build practical capability in processor design, SoC integration, verification, and FPGA-based hardware realization.

The SoC integrates a RISC-V processor (In-house developed ***Hadi-V***) core with memory and memory-mapped peripherals through a Wishbone-based interconnect, creating a compact platform for experimentation, learning, and future extension.

Through this effort, we aim to contribute, in our own capacity, to the growth of deep technology capability in Bangladesh.

---

## • Core and SoC Specifications

* RV32I_Zicsr compliant RISC-V processor core
* Machine-mode support
* 5-stage scalar pipeline architecture
* Wishbone-based memory and peripheral interconnect
* Dual-port Wishbone RAM interface for instruction fetch and data access
* Memory-mapped peripheral architecture
* Designed with a focus on clarity, modularity, and extensibility

---

## • Integrated Peripherals

The SoC currently includes the following Wishbone-connected peripherals:

* Wishbone RAM
* Wishbone LEDs
* Wishbone Buttons
* Wishbone UART
* Wishbone Timer
* Wishbone Test Peripheral

The following peripherals are planned or under development:

* Wishbone I2C
* Wishbone PWM

The following peripherals from the original framework are being dropped from this SoC configuration:

* Wishbone Switches
* Wishbone 7-Segment Display
* Wishbone VGA

---

## • Development Status

* **Design**: Initial SoC integration phase ongoing
* **Verification**: System level vefication is ongoing
* **Synthesis**: Target device **Digilent Basys3 FPGA Board**
* **Peripheral Development**: I2C and PWM peripherals are under development

---

## • Our Perspective

This work represents our effort across the complete digital design flow — from architecture and RTL development to SoC integration, verification, and hardware realization.

It reflects our commitment to contributing, in our own capacity, toward advancing capability in deep technology domains such as VLSI, processor design, and SoC development in Bangladesh.

---

## Getting Started

This section helps you set up the environment, run simulations, and synthesize the design.

### 1. Prerequisites

Make sure the following tools are installed:

* **Verilator** for simulation
* **GTKWave** for debugging waveforms
* **Xilinx Vivado** for synthesis and FPGA deployment
* **RISC-V GNU Toolchain** for compiling tests

> ⚠️ Ensure the toolchain paths in the `Makefile` match your local installation, for example `/opt/riscv32i/` and `/opt/Xilinx/`.

---

### 2. Clone the Repository

```bash
git clone <repo-url>
cd <repo-name>
```

---

### 3. Run a Simulation Test

#### ▶️ Assembly Test

```bash
make test/asm/<test_name>
```

#### ▶️ C Test

```bash
make test/c/<test_name>
```

This will:

* Compile the program
* Generate memory initialization files
* Run the simulation using Verilator

---

### 4. View Waveforms

After running a test:

```bash
make show
```

This opens the waveform in **GTKWave** for debugging.

---

### 5. Clean Build Files

```bash
make clean
```

---

### 6. Run SystemVerilog Testbenches

```bash
make test/sv/<testbench_name>
```

---

### 7. Synthesize for FPGA

To synthesize the design for FPGA, for example on the Basys3 board:

```bash
make synthesis
```

This uses **Xilinx Vivado** in batch mode to generate the bitstream.

---

## Notes

* The simulation uses precompiled reference models from the `ref/` directory for validation.
* Output files are generated in the `build/` directory.
* Waveform save configurations are located in the `saves/` directory.
* The SoC uses a Wishbone-based interconnect to connect memory and peripherals.
* Some peripherals are currently under development and may not be enabled in all builds.

---

## • Acknowledgment

We remain sincerely grateful to:

* The original HaDes-V authors
* Our mentors and peers
* The broader academic and open-source communities

For their continued guidance and support.

---

**Alpha Science Lab**  
Mymensingh Engineering College
