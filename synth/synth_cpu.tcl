# CPU-only synthesis script

# Get root directory
set ROOT [file normalize [file dirname [info script]]/..]

# Optional feature flags passed from Make: <C_EXT> <M_EXT>
set c_ext 0
set m_ext 0

if {$argc > 0} {
    set c_ext [lindex $argv 0]
}
if {$argc > 1} {
    set m_ext [lindex $argv 1]
}

# -----------------------------------------------------------------------------
# Warning Suppression
# -----------------------------------------------------------------------------

# identifier <name> is used before its declaration
set_msg_config -id {Synth 8-6901} -suppress

# <name> is already implicitly declared earlier
set_msg_config -id {Synth 8-8895} -suppress

# initial value of parameter '<parameter>' is omitted
set_msg_config -id {Synth 8-9661} -suppress

# Parallel synthesis criteria is not met
set_msg_config -id {Synth 8-7080} -suppress

# -----------------------------------------------------------------------------
# Source Files
# -----------------------------------------------------------------------------

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
    lib/wishbone/wishbone_interface.sv

    rtl/*.sv

    synth/top_cpu.sv
}

if {$m_ext == 1} {
    puts "INFO: Enabling M extension"
}
if {$c_ext == 1} {
    puts "INFO: Enabling C extension"
}

# Build define list (set_property verilog_define REPLACES, so combine both)
set defines {}
if {$m_ext == 1} {
    lappend defines M_EXT
}
if {$c_ext == 1} {
    lappend defines C_EXT
}
if {[llength $defines] > 0} {
    set_property verilog_define $defines [current_fileset]
}

foreach source $SOURCES {
    read_verilog -sv [glob -directory $ROOT $source]
}

# -----------------------------------------------------------------------------
# Constraints
# -----------------------------------------------------------------------------

read_xdc $ROOT/synth/cpu.xdc

# -----------------------------------------------------------------------------
# Synthesis
# -----------------------------------------------------------------------------

synth_design \
    -top top_cpu \
    -part xc7a35tcpg236-1

opt_design

# -----------------------------------------------------------------------------
# Reports (Post-Synthesis)
# -----------------------------------------------------------------------------

file mkdir reports

report_timing_summary \
    -file reports/timing_cpu_syn.rpt

report_utilization \
    -file reports/utilization_cpu_syn.rpt

report_utilization \
    -hierarchical \
    -file reports/utilization_cpu_hier_syn.rpt

report_power \
    -file reports/power_cpu_syn.rpt

# -----------------------------------------------------------------------------
# Place & Route
# -----------------------------------------------------------------------------

place_design
phys_opt_design
route_design
phys_opt_design

# -----------------------------------------------------------------------------
# Reports (Post-Implementation)
# -----------------------------------------------------------------------------

report_timing_summary \
    -file reports/timing_cpu_pnr.rpt

report_utilization \
    -file reports/utilization_cpu_pnr.rpt

report_utilization \
    -hierarchical \
    -file reports/utilization_cpu_hier_pnr.rpt

report_power \
    -file reports/power_cpu_pnr.rpt

