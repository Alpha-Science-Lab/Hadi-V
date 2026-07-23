# 27 MHz clock (37.037 ns period) on Tang Nano 9K
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
