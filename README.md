[instrguide]:https://repository.tugraz.at/oer/nytm4-grv34
[lvref]:https://online.tugraz.at/tug_online/wbLv.wbShowLVDetail?pStpSpNr=525082
[vivado]:https://www.xilinx.com/support/download.html
[verilator]:https://verilator.org
[basys]:https://digilent.com/reference/programmable-logic/basys-3/reference-manual?redirect=1
[gtkwave]:https://gtkwave.sourceforge.net/
[sv]:https://doi.org/10.1109/IEEESTD.2018.8299595
[rvgcc]:https://github.com/riscv-collab/riscv-gnu-toolchain

![image](https://www.scheipel.com/wp-content/uploads/2024/12/hades_logo.svg)
# Microcontroller Design, Lab: HaDes-V

***Ever thought about developing a processor from scratch and bringing it to life on an FPGA? With HaDes-V, you'll delve into hardware design and create your own pipelined 32-bit RISC-V processor, mastering efficient computing principles and practical FPGA implementation.***

The [Instruction Guide][instrguide] and this source code template for the [**Microcontroller Design, Lab**][lvref] is an **Open Educational Resource (OER)** developed by [Tobias Scheipel](https://www.scheipel.com), David Beikircher, and Florian Riedl, Embedded Architectures & Systems Group at Graz University of Technology. It is designed for teaching and learning microcontroller design and hardware description languages, using the **HaDes-V architecture**, a RISC-V-based processor.

## Project Overview

The lab is structured around designing, simulating, and synthesizing the HaDes-V processor. It integrates software and hardware design exercises using SystemVerilog, assembly, and C.

One of the standout features of HaDes-V is its **modular design**:  
- Implement each module of the pipeline individually in the [`rtl/`](rtl) directory and cross-check its functionality using pre-compiled Verilator libraries provided in [`ref/`](ref).  
- Validate that your implementation fits seamlessly into the overall processor—just like solving a jigsaw puzzle.  
- Focus on one stage at a time, integrate step-by-step, and build confidence as you progress.  

Key topics covered:
- **RISC-V Architecture**: Hands-on implementation of a pipelined processor with custom extensions.
- **FPGA Development**: Using the AMD [Vivado][vivado] toolchain and the [Basys3][basys] development board.
- **Hardware/Software Co-design**: Combining hardware description and software programming skills.

## Why HaDes-V?

- **Learn by Building**: Design a pipelined RISC-V processor from scratch.
- **Modular Design**: Implement, test, and integrate each module of the pipeline step by step—just like solving a jigsaw puzzle.
- **Immediate Validation**: Use golden references in [`ref/`](ref) to ensure your functionality matches expectations.
- **Hands-On Debugging**: Simulate and verify your work with tools like [Verilator][verilator] and [GTKWave][gtkwave].
- **Real Hardware Integration**: Bring your design to life on an FPGA using the [Basys3][basys]  board.

## Learning Outcomes  
By completing the lab, students will:  
- **Design** a modular, pipelined 32-bit RISC-V processor with multiple stages.  
- **Implement** CPU functionality using SystemVerilog.  
- **Program** software for the processor in RISC-V Assembly and C.  
- **Deploy** the processor design onto FPGA boards.  
- **Analyze** the processor using simulation and waveform tools.

## Tools and Dependencies

The following tools are required for the lab exercises (details in the [Instruction Guide][instrguide]):
- **[SystemVerilog][sv]**: HDL for processor and peripheral design.
- **[RISC-V Toolchain][rvgcc]**: Compiler for RV32I assembly and C programs.
- **[Vivado][vivado]**: FPGA synthesis and programming.
- **[Verilator][verilator]**: Open-source HDL simulator.
- **[GTKWave][gtkwave]**: Waveform viewer for debugging simulations.

## Repository Structure

- [`defines/`](defines): HDL constants and definitions.
- [`lib/`](lib): Peripheral modules (e.g., UART, timer).
- [`ref/`](ref): Precompiled reference libraries.
- [`rtl/`](rtl): The actual student implementation. Contains code stubs for further development.
- [`synth/`](synth): Synthesis scripts and FPGA configuration files.
- [`test/`](test): Test files in assembly (`asm`), C (`c`), and SystemVerilog (`sv`).
- [`.vscode/`](.vscode): Configuration files for Visual Studio Code.

Refer to the [Instruction Guide][instrguide] for a detailed project structure.

## Exercises

The laboratory includes several exercises to progressively build the HaDes-V processor:
- **Basic Implementation**: CPU module, instruction fetch, decode, and execution stages.
- **Advanced Features**: Memory stage, writeback stage, and control/status registers.
- **Extensions**: Final project to extend the processor with custom peripherals or functionality.

Each exercise allows you to implement and test individual modules while leveraging the **golden references** in [`ref/`](ref) for validation—ensuring seamless integration like solving a puzzle.

See the detailed exercise instructions in Chapter 4 of the [Instruction Guide][instrguide].

## Test Benches
A closed-source test bench system is available for teaching purposes. For more information, please refer to the [Contact](#contact) section.

## License

This OER and all of its creative material (text, logos, etc.) is licensed under the **CC BY 4.0 International License**, allowing you to share and adapt the resource, provided appropriate credit is given. See the full license details [here](https://creativecommons.org/licenses/by/4.0/).

>![CCBY](https://mirrors.creativecommons.org/presskit/buttons/88x31/svg/by.svg)\
>Tobias Scheipel, David Beikircher, Florian Riedl\
>TU Graz 2024

All the software files included in the repository are licensed under the **MIT License**. See the [LICENSE](./LICENSE) file for details.

Contributions to this OER are welcome and encouraged! The LaTeX sources for the [Instruction Guide][instrguide] can be requested as well. For more OERs, visit [https://www.scheipel.com/oer](https://www.scheipel.com/oer).

## Contact

For questions, licensing, test bench inquiries, or further information, please contact and/or consult:
- **Email**: [tobias.scheipel@tugraz.at](mailto:tobias.scheipel@tugraz.at)
- **Website**: [https://www.scheipel.com/oer](https://www.scheipel.com/oer)

## Publication @ RISC-V Summit Europe 2025
We published this OER at the [RISC-V Summit Europe 2025](https://riscv-europe.org/summit/2025/) as a [Poster](https://graz.elsevierpure.com/files/93678000/HaDes_V_Poster-CR_v1.pdf) and an extended [Abstract Paper](https://www.scheipel.com/wp-content/uploads/2025/05/HaDes_V_RISC_V_Summit_camera_ready-1.pdf). 

**The work also got featured on the official RISC-V International [Blog](https://riscv.org/blog/) [here](https://riscv.org/blog/2025/05/hades-v-learning-by-puzzling-a-modular-approach-to-risc-v-processor-design-education/).**


