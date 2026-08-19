# ============================================================
# Parameterized N-Bit Hierarchical CLA Adder
# ============================================================

SIM  := iverilog
VVP  := vvp
WAVE := gtkwave

RTL_DIR := rtl
TB_DIR  := tb
SIM_DIR := sim

RTL := $(RTL_DIR)/cla_adder.sv
TB  := $(TB_DIR)/testbench.sv

TOP := cla_adder_tb
OUT := $(SIM_DIR)/cla_adder_sim
VCD := $(SIM_DIR)/cla_adder.vcd

.PHONY: all compile run test wave clean help

all: test

compile:
	@mkdir -p $(SIM_DIR)
	$(SIM) -g2012 \
		-s $(TOP) \
		-o $(OUT) \
		$(RTL) \
		$(TB)

run: compile
	$(VVP) $(OUT)

test: compile
	$(VVP) $(OUT)

wave: test
	$(WAVE) $(VCD)

clean:
	rm -rf $(SIM_DIR)/cla_adder_sim
	rm -f $(SIM_DIR)/cla_adder.vcd
	rm -f *.vcd
	rm -f *.log
	rm -f *.out
	rm -f *.vvp

help:
	@echo ""
	@echo "Parameterized N-Bit Hierarchical CLA Adder"
	@echo ""
	@echo "make         - Compile and run verification"
	@echo "make compile - Compile only"
	@echo "make run     - Compile and run"
	@echo "make test    - Run complete test"
	@echo "make wave    - Run test and open GTKWave"
	@echo "make clean   - Remove generated files"
	@echo "make help    - Show help"
	@echo ""