#=========================================================
# Tang Nano 9K
# GW1NR-LV9QN88PC6/I5
#=========================================================

# Get root directory
set ROOT [file normalize [file dirname [info script]]/..]

#---------------------------------------------------------
# Optional feature flags passed from command line
#---------------------------------------------------------
set m_ext 0

if {$argc > 0} {
    set m_ext [lindex $argv 0]
}

#---------------------------------------------------------
# Target Device
#---------------------------------------------------------
set_device GW1NR-LV9QN88PC6/I5

#---------------------------------------------------------
# Verilog/SystemVerilog Options
#---------------------------------------------------------
set_option -verilog_std sysv2017

#---------------------------------------------------------
# Define source files
#---------------------------------------------------------
set SOURCES {
    defines/csr.sv
    defines/op.sv
    defines/instruction.sv
    defines/pipeline_status.sv
    defines/forwarding.sv
    defines/branch_pred_pkg.sv
    defines/constants.sv
    defines/clk_params.sv

    lib/gowin_rpll.v
    lib/*.sv
    lib/peripherals/*.sv
    lib/wishbone/*.sv
    
    rtl/*.sv

    synth/tang9k_top.sv
}

#---------------------------------------------------------
# Optional M Extension
#---------------------------------------------------------
if {$m_ext == 1} {
    puts "INFO: Enabling M extension"
    # Uncomment if your Gowin version supports it
    set_option -verilog_define M_EXT
}

foreach source $SOURCES {
    foreach file [glob -nocomplain [file join $ROOT $source]] {
        add_file $file
    }
}

#---------------------------------------------------------
# Read Constraints
#---------------------------------------------------------
add_file $ROOT/synth/tangnano9k.cst
add_file $ROOT/synth/tangnano9k.sdc

#---------------------------------------------------------
# Read Memory File
#---------------------------------------------------------
add_file $ROOT/build/test/c/bootloader/init.mem

#---------------------------------------------------------
# Project Options
#---------------------------------------------------------
set_option -top_module tang9k_top
set_option -output_base_name hadi_v

#---------------------------------------------------------
# Synthesize, Place & Route, Generate Bitstream
#---------------------------------------------------------
run all

exit
