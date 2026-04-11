# Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
# Embedded Architectures & Systems Group, Graz University of Technology
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------------
# File: Makefile
#
# Sanity check (taken from verilator examples)
ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

# Binaries
VERILATOR ?= verilator

CC = /opt/riscv32i/bin/riscv32-unknown-elf-gcc
OBJCOPY = /opt/riscv32i/bin/riscv32-unknown-elf-objcopy
OBJDUMP = /opt/riscv32i/bin/riscv32-unknown-elf-objdump

XILINX_VIVADO ?= /opt/Xilinx/Vivado/2023.2/
VIVADO ?= $(XILINX_VIVADO)/bin/vivado

# Directories
SIM_DIR = sim
BUILD_DIR = build
RTL_DIR = rtl
REF_DIR = ref
LIB_DIR = lib
SAVES_DIR = saves
STD_LIB_DIR = std
SYNTH_DIR = synth
DEFINES_DIR = defines

TEST_DIR = test
ASM_DIR = $(TEST_DIR)/asm
C_DIR = $(TEST_DIR)/c
SV_DIR = $(TEST_DIR)/sv

# Verilator Flags
VERILATOR_FLAGS =
VERILATOR_FLAGS += -cc
VERILATOR_FLAGS += -Wall -Wno-fatal
VERILATOR_FLAGS += -f $(SIM_DIR)/files.txt
VERILATOR_FLAGS += $(abspath $(wildcard $(REF_DIR)/*.so)) -j

################################################################################
#                                  Print Help                                  #
################################################################################

.PHONY: help
help:
	@echo "Usage: make TARGET"
	@echo ""
	@echo "The following options exist for TARGET:"
	@echo "  help        Prints this help message"
	@echo "  clean       Deletes build artifacts"
	@echo "  test/...    Builds and runs the specified test"
	@echo "  show        Show the waveform of the most recently run test (if available)"
	@echo "  bootloader  Build the bootloader"
	@echo "  synthesis   Synthesize the MCU using Vivado"


################################################################################
#                                 Clean Project                                #
################################################################################

.PHONY: clean
clean::
	rm -rf $(BUILD_DIR)

################################################################################
#                                   Synthesis                                  #
################################################################################

MODE ?= batch

.PHONY: synthesis
synthesis: $(BUILD_DIR)/$(C_DIR)/bootloader/init.mem
	@ mkdir -p $(BUILD_DIR)/$(SYNTH_DIR)
	cd $(BUILD_DIR)/$(SYNTH_DIR) && $(VIVADO) -mode $(MODE) -source $(CURDIR)/$(SYNTH_DIR)/synth.tcl

################################################################################
#                                  Simulation                                  #
################################################################################

# Include dependency file (if it exists)
-include $(BUILD_DIR)/$(SIM_DIR)/top__ver.d

# Verilate simulation
$(BUILD_DIR)/$(SIM_DIR)/top.mk:
	@ mkdir -p $(BUILD_DIR)/$(SIM_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) --trace-fst --trace-structs --timing --assert --main --exe --prefix top -Mdir $(BUILD_DIR)/$(SIM_DIR) --top-module top sim/top.sv

# Build simulation executable
$(BUILD_DIR)/$(SIM_DIR)/top: $(BUILD_DIR)/$(SIM_DIR)/top.mk
	$(MAKE) -C $(BUILD_DIR)/$(SIM_DIR) -f top.mk

################################################################################
#                                Assembly Tests                                #
################################################################################

# Collect asembly tests
ASM_TESTS = $(wildcard $(ASM_DIR)/*.s)
ASM_TEST_NAMES = $(patsubst $(ASM_DIR)/%.s, $(ASM_DIR)/%, $(ASM_TESTS))

# Compile assembly to elf
$(BUILD_DIR)/$(ASM_DIR)/%/init.elf: $(ASM_DIR)/%.s $(STD_LIB_DIR)/hades-v.ld
	@ mkdir -p $(BUILD_DIR)/$(ASM_DIR)/$*
	$(CC) -nostdlib -nostartfiles -T $(STD_LIB_DIR)/hades-v.ld -o $@ $<
	$(OBJDUMP) -d -r -t -S $@ > $(@:.elf=.dis)

# Copy elf to bin
$(BUILD_DIR)/$(ASM_DIR)/%/init.bin: $(BUILD_DIR)/$(ASM_DIR)/%/init.elf
	$(OBJCOPY) -O binary $< $@

# Copy elf to mem
$(BUILD_DIR)/$(ASM_DIR)/%/init.mem: $(BUILD_DIR)/$(ASM_DIR)/%/init.bin
	$(OBJCOPY) -I binary -O verilog --verilog-data-width 4 --reverse-bytes=4 $< $@

# Run test
.PHONY: $(ASM_TEST_NAMES)
$(ASM_TEST_NAMES): $(ASM_DIR)/%: $(BUILD_DIR)/$(ASM_DIR)/%/init.mem $(BUILD_DIR)/$(SIM_DIR)/top
	cd $(BUILD_DIR)/$(ASM_DIR)/$* && $(CURDIR)/$(BUILD_DIR)/$(SIM_DIR)/top
	@echo 'gtkwave $(BUILD_DIR)/$(ASM_DIR)/$*/sim.fst $(SAVES_DIR)/pipeline.gtkw' > $(BUILD_DIR)/show.sh

################################################################################
#                                   C Tests                                    #
################################################################################

# Collect c tests
C_TESTS = $(wildcard $(C_DIR)/*.c)
C_TEST_NAMES = $(patsubst $(C_DIR)/%.c, $(C_DIR)/%, $(C_TESTS))

# Collect std lib
C_LIB_SRC = $(wildcard $(STD_LIB_DIR)/src/*.c)
C_LIB_OBJ = $(patsubst $(STD_LIB_DIR)/src/%.c, $(BUILD_DIR)/$(STD_LIB_DIR)/%.o, $(C_LIB_SRC))

# Compile std lib c files
$(BUILD_DIR)/$(STD_LIB_DIR)/%.o: $(STD_LIB_DIR)/src/%.c
	@ mkdir -p $(BUILD_DIR)/$(STD_LIB_DIR)
	$(CC) -fdata-sections -ffunction-sections -c -o $@ -I $(STD_LIB_DIR)/include $<

# Compile test c file
$(BUILD_DIR)/$(C_DIR)/%/out.o: $(C_DIR)/%.c
	@ mkdir -p $(BUILD_DIR)/$(C_DIR)/$*
	$(CC) -fdata-sections -ffunction-sections -c -o $@ -I $(STD_LIB_DIR)/include $<

# Link binary
$(BUILD_DIR)/$(C_DIR)/%/out.elf: $(BUILD_DIR)/$(C_DIR)/%/out.o $(C_LIB_OBJ) $(STD_LIB_DIR)/hades-v.ld
	$(CC) -o $@ -nostdlib -nostartfiles -T $(STD_LIB_DIR)/hades-v.ld $< $(C_LIB_OBJ) -lgcc -Wl,--no-warn-rwx-segments -Wl,--gc-sections

# Create hex file (for sending to bootloader)
$(BUILD_DIR)/$(C_DIR)/%/out.hex: $(BUILD_DIR)/$(C_DIR)/%/out.elf
	$(OBJCOPY) -O ihex $< $@

# Create bin file (intermediate step for creating mem file)
$(BUILD_DIR)/$(C_DIR)/%/out.bin: $(BUILD_DIR)/$(C_DIR)/%/out.elf
	$(OBJCOPY) -O binary $< $@

# Create mem file (for simulation and synthesis)
$(BUILD_DIR)/$(C_DIR)/%/init.mem: $(BUILD_DIR)/$(C_DIR)/%/out.bin
	$(OBJCOPY) -I binary -O verilog -S --verilog-data-width 4 --reverse-bytes=4 $< $@

# Create disassembly view (for debugging)
$(BUILD_DIR)/$(C_DIR)/%/out.dis: $(BUILD_DIR)/$(C_DIR)/%/out.elf
	$(OBJDUMP) -d -x $< > $@

# Run test
.PHONY: $(C_TEST_NAMES)
$(C_TEST_NAMES): $(C_DIR)/%: $(BUILD_DIR)/$(C_DIR)/%/init.mem $(BUILD_DIR)/$(C_DIR)/%/out.hex $(BUILD_DIR)/$(C_DIR)/%/out.elf $(BUILD_DIR)/$(C_DIR)/%/out.dis $(BUILD_DIR)/$(SIM_DIR)/top
	cd $(BUILD_DIR)/$(C_DIR)/$* && $(CURDIR)/$(BUILD_DIR)/$(SIM_DIR)/top
	@echo 'gtkwave $(BUILD_DIR)/$(C_DIR)/$*/sim.fst $(SAVES_DIR)/pipeline.gtkw' > $(BUILD_DIR)/show.sh

################################################################################
#                             SystemVerilog Tests                              #
################################################################################

SV_TESTS = $(wildcard $(SV_DIR)/*.sv)
SV_TEST_NAMES = $(patsubst $(SV_DIR)/%.sv, $(SV_DIR)/%, $(SV_TESTS))

# Include dependency files (if they exist)
-include $(wildcard $(BUILD_DIR)/$(SV_DIR)/*/top__ver.d)

# Run test bench
.PHONY: $(SV_TEST_NAMES)
$(SV_TEST_NAMES): $(SV_DIR)/%: $(BUILD_DIR)/$(SV_DIR)/%/top
	cd $(BUILD_DIR)/$(SV_DIR)/$* && $(CURDIR)/$(BUILD_DIR)/$(SV_DIR)/$*/top

# Build system verilog executable
$(BUILD_DIR)/$(SV_DIR)/%/top: $(BUILD_DIR)/$(SV_DIR)/%/top.mk
	$(MAKE) -j -C $(BUILD_DIR)/$(SV_DIR)/$* -f top.mk

# Verilate system verilog testbench
$(BUILD_DIR)/$(SV_DIR)/%/top.mk:
	@ mkdir -p $(BUILD_DIR)/$(SV_DIR)/$*
	$(VERILATOR) $(VERILATOR_FLAGS) -f $(SV_DIR)/files.txt --trace-fst --trace-structs --timing --assert --main --exe --prefix top -Mdir $(BUILD_DIR)/$(SV_DIR)/$* --top-module $* $(SV_DIR)/$*.sv
	@echo 'gtkwave $(BUILD_DIR)/$(SV_DIR)/$*/$*.fst $(SAVES_DIR)/$*.gtkw' > $(BUILD_DIR)/show.sh

################################################################################
#                                   Waveform                                   #
################################################################################

.PHONY: show
show:
	$(file < build/show.sh)
