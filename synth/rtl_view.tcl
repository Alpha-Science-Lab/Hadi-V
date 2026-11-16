
# Get root directory
set ROOT [file normalize [file dirname [info script]]/..]

# Read RTL sources
set SOURCES {
    defines/csr.sv
    defines/op.sv
    defines/instruction.sv
    defines/pipeline_status.sv
    defines/forwarding.sv
    defines/branch_pred_pkg.sv
    defines/constants.sv
    defines/clk_params.sv

    lib/*.sv
    lib/peripherals/*.sv
    lib/wishbone/*.sv

    ref/*.sv
    rtl/*.sv

    synth/top.sv
}

# Read source files
foreach source $SOURCES {
    read_verilog -sv [glob -directory $ROOT $source]
}

# Enable M extension if requested
if {$argc > 0 && [lindex $argv 0] == 1} {
    set_property verilog_define {M_EXT} [current_fileset]
}

# Elaborate RTL
synth_design -rtl -top top -part xc7a35tcpg236-1

# Launch GUI and display schematic
start_gui
show_schematic [get_cells -hier -filter {NAME == top}]
