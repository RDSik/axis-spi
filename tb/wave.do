vlib work
vmap work

vlog tb/axis_spi_top_tb.sv
vlog tb/axis_spi_top_if.sv
vlog tb/environment.sv

vlog rtl/axis_spi_master.sv
vlog rtl/axis_if.sv

vsim -voptargs="+acc" axis_spi_top_tb
add log -r /*

add wave -expand /axis_spi_top_tb/dut/DIVIDER
add wave -expand /axis_spi_top_tb/dut/HALF_DIVIDER
add wave -expand /axis_spi_top_tb/dut/CPHA
add wave -expand /axis_spi_top_tb/dut/CPOL
add wave -expand -group SPI /axis_spi_top_tb/dut/*
add wave -expand -group M_AXIS /axis_spi_top_tb/m_axis/*
add wave -expand -group S_AXIS /axis_spi_top_tb/s_axis/*

run -all
wave zoom full