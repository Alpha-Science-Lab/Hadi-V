# 27 MHz clock (37.037 ns period) on Tang Nano 9K
create_clock -name clk_27mhz -period 37.037 -waveform {0 18.518} [get_ports {clk_27mhz}]
