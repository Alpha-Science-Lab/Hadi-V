# -----------------------------------------------------------------------------
# CPU-only constraints for Basys3
# -----------------------------------------------------------------------------

## 100 MHz System Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } \
    [get_ports {clk_100mhz}]

create_clock \
    -name clk_100mhz \
    -period 10.000 \
    [get_ports clk_100mhz]

# -----------------------------------------------------------------------------
# FPGA Configuration
# -----------------------------------------------------------------------------

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]