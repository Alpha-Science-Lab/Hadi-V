#=========================================================
# Tang Nano 9K
# GW1NR-LV9QN88PC6/I5
#=========================================================

# Get root directory
set ROOT [file normalize [file dirname [info script]]/..]


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

    lib/*.sv
    lib/peripherals/*.sv
    lib/wishbone/*.sv
    
    rtl/*.sv

    synth/gowin_rpll.v
    synth/tang9k_bram8_tdp.v
    synth/tang9k_ram_32kib.sv
    synth/tang9k_ram.sv
    synth/tang9k_mcu.sv

    synth/tang9k_top.sv
}


foreach source $SOURCES {
    foreach file [glob -nocomplain [file join $ROOT $source]] {
        add_file $file
    }
}

#---------------------------------------------------------
# Read Constraints
#---------------------------------------------------------
add_file $ROOT/synth/tang9k.cst
add_file $ROOT/synth/tang9k.sdc

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
