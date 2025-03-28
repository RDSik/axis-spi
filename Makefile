TOP := axis_spi_top

RTL_DIR     := rtl
TB_DIR      := tb
PROJECT_DIR := project

SIM   ?= verilator
BOARD := tangprimer20k

MACRO_FILE := wave.do
TCL        := project.tcl

SRC_FILES += $(RTL_DIR)/axis_spi_top.sv
SRC_FILES += $(RTL_DIR)/axis_if.sv
SRC_FILES += $(RTL_DIR)/axis_spi_master.sv
SRC_FILES += $(RTL_DIR)/axis_data_gen.sv
SRC_FILES += $(RTL_DIR)/axis_fifo.sv

SRC_FILES += $(TB_DIR)/axis_spi_top_tb.sv
SRC_FILES += $(TB_DIR)/axis_spi_top_if.sv
SRC_FILES += $(TB_DIR)/environment.sv

.PHONY: sim project program clean

sim: build run

build:
ifeq ($(SIM), verilator)
	$(SIM) --binary $(SRC_FILES) --trace -I$(RTL_DIR) -I$(TB_DIR) --top $(TOP)_tb
else ifeq ($(SIM), questa)
	vsim -do $(TB_DIR)/$(MACRO_FILE)
endif

run:
ifeq ($(SIM), verilator)
	./obj_dir/V$(TOP)_tb
endif

wave:
	gtkwave $(TOP)_tb.vcd

project:
	gw_sh $(PROJECT_DIR)/$(TCL)

program:
	openFPGALoader -b $(BOARD) -m $(PROJECT_DIR)/$(TOP)/impl/pnr/$(TOP).fs

clean:
ifeq ($(OS), Windows_NT)
	rmdir /s /q work
	del transcript
	del *.vcd
	del *.wlf
	# rmdir /s /q $(PROJECT_DIR)\$(TOP)
else
	rm -rf obj_dir
	rm -rf work
	rm transcript
	rm *.vcd
	rm *.wlf
	rm -rf $(PROJECT_DIR)/$(TOP)
endif