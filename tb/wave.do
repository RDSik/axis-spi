vlib work
vmap work

vlog tb/axis_spi_top_tb.sv
vlog tb/axis_spi_top_if.sv
vlog tb/environment.sv

vlog rtl/axis_spi_master.sv
vlog rtl/axis_spi_slave.sv
vlog rtl/axis_if.sv

vsim -voptargs="+acc" axis_spi_top_tb
add log -r /*

add wave -expand -group SPI_SLAVE /axis_spi_top_tb/i_axis_spi_slave/*
add wave -expand -group SPI_MASSTER /axis_spi_top_tb/i_axis_spi_master/*
add wave -expand -group M_AXIS /axis_spi_top_tb/m_axis/*
add wave -expand -group S_AXIS /axis_spi_top_tb/s_axis/*

run -all
wave zoom full