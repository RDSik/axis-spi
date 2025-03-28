set top      "axis_spi_top"
set part     "GW2A-LV18PG256C8/I7"
set dev_ver  "C"
set language "sysv2017"

set rtl_dir       "../../rtl"
set constrain_dir ".."

create_project -name $top -dir project -pn $part -device_version $dev_ver -force

add_file $rtl_dir/axis_if.sv
add_file $rtl_dir/axis_spi_top.sv
add_file $rtl_dir/axis_spi_master.sv
add_file $rtl_dir/axis_fifo.sv
add_file $rtl_dir/axis_data_gen.sv
add_file $rtl_dir/config.mem

add_file $constrain_dir/axis_spi_top.sdc
add_file $constrain_dir/axis_spi_top.cst

set_option -top_module $top
set_option -verilog_std $language

run all