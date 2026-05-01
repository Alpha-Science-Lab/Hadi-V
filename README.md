### Microcontroller Design, Lab: HaDes-V (Adapted Work)

![image](https://www.scheipel.com/wp-content/uploads/2024/12/hades_logo.svg)

This repository is based on the **HaDes-V Open Educational Resource (OER)** developed by **Tobias Scheipel**, David Beikircher, and Florian Riedl from the Embedded Architectures & Systems Group at **Graz University of Technology**.

We gratefully acknowledge and credit the original authors for making this resource publicly available under an open license. Their work provides a structured and highly effective foundation for learning processor design, and it has significantly contributed to our development process.

> This repository contains adaptations and extensions built upon the original HaDes-V framework for educational and research purposes.

---

## Alpha Science Lab
### Independence Day Initiative - March 26

On the occasion of Independence Day March 26, **Alpha Science Lab, Mymensingh Engineering College**, humbly shares a milestone from its ongoing journey in hardware design and engineering.

## • Hadi-V

**Hadi-V** is an in-house developed RISC-V processor core, named in tribute to the nation’s martyred hero **Sharif Osman Hadi**.

Through this effort, we aim to honor his legacy by embedding his name within a pursuit that represents resilience, progress, and the spirit of building.

---

## • Core Specifications

* RV32I_Zicsr compliant core
* Machine-mode support
* 5-stage scalar pipeline architecture
* Dynamic branch prediction
* Designed with a focus on clarity, modularity, and extensibility

---

## • Development Status

* **Design**: Initial phase completed
* **Verification**: Functionally verified using the verification platform provided by **Graz University of Technology**
* **Synthesis**: Successfully deployed on the **Digilent Basys3 FPGA Board**

---

## • Our Perspective

This work represents our effort across the complete digital design flow — from architecture and RTL development to verification and hardware realization.

It reflects our commitment to contributing, in our own capacity, toward advancing capability in deep technology domains such as VLSI and processor design in Bangladesh.

---

## Getting Started

This section helps you set up the environment, run simulations, and synthesize the design.

### 1. Prerequisites

Make sure the following tools are installed:

* **Verilator** (for simulation)
* **GTKWave** (for debugging waveforms)
* **Xilinx Vivado** (for synthesis and FPGA deployment)
* **RISC-V GNU Toolchain** (for compiling tests)

> ⚠️ Ensure the toolchain paths in the `Makefile` match your local installation (e.g., `/opt/riscv32i/`, `/opt/Xilinx/`).

---

### 2. Clone the Repository

```bash
git clone <your-repo-url>
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

To synthesize the design for FPGA (e.g., Basys3):

```bash
make synthesis
```

This uses **Xilinx Vivado** in batch mode to generate the bitstream.

---

### Notes

* The simulation uses precompiled reference models from the `ref/` directory for validation.
* Output files are generated in the `build/` directory.
* Waveform save configurations are located in the `saves/` directory.

---

## • Acknowledgment

We remain sincerely grateful to:

* The original HaDes-V authors for their open educational contribution
* Our mentors and peers
* The broader academic and open-source communities

for their continued guidance and support.

---

**Alpha Science Lab**
Mymensingh Engineering College

