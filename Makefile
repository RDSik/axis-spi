TOP := axis_spi_master

SRC_DIR     := src
TB_DIR      := tb
PROJECT_DIR := project

SYN ?= gowin

MACRO_FILE := wave.do
GOWIN_TCL  := gowin_project.tcl

.PHONY: sim project clean

sim:
	vsim -do $(TB_DIR)/$(MACRO_FILE)

project:
	gw_sh $(PROJECT_DIR)/$(GOWIN_TCL)

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