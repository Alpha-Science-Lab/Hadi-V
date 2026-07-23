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

# puts "DEBUG: m_ext = $m_ext"

set config_file [file join $ROOT synth tang9k.svh]
set fp [open $config_file w]


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
    synth/tang9k.svh

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
if {$m_ext} {
    puts $fp "`define M_EXT"
    close $fp
} else {
    puts $fp ""
    close $fp
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
# Project Options
#---------------------------------------------------------
set_option -top_module tang9k_top
set_option -output_base_name hadi_v

#---------------------------------------------------------
# Synthesize, Place & Route, Generate Bitstream
#---------------------------------------------------------
run all

exit
