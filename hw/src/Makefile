MFE_TOP=mfe_top.sv
MFE_INTERFACE=mfe_ifc.sv
MFE_INTERFACE_DIR=mfe_ifc_dirbench.sv
MFE_BENCH=mfe_tb.sv
MFE_DIRBENCH=mfe_tbd.sv
MFE_DUT=mfe.sv
MFE_DUT_DIR=mfe_dirbench.sv
MFE_OUTPUT=mfetestbench.exe

MODULES = status_driver.sv \
	mont_mult/*.v \
	aes/*.v \
	aes/*sv \
	sha/*v \
	sdspi/*sv

.PHONY: all
all: mfebench

help:
	@echo "The following make targets are supported:" ;\
	echo " mfebench  - builds the testbench";\
	echo " wave   - convert vcd to vpd";\
	echo " clean  - cleans testbench and intermediate files" ;\
	echo " help   - show this information";\

mfebench: 
	vcs -full64 -PP -sverilog +define+SV +define+VPD -notice $(MFE_TOP) $(MFE_INTERFACE) $(MFE_BENCH) $(MFE_DUT) $(MODULES) -o $(MFE_OUTPUT) 

mfedirbench: 
	vcs -full64 -PP -sverilog +define+SV +define+VPD -notice $(MFE_INTERFACE_DIR) $(MFE_DIRBENCH) $(MFE_DUT_DIR) $(MODULES) -o $(MFE_OUTPUT) 

wave:
	vcs -vpd2vcd vcdplus.vpd waveform.vcd
	gtkwave waveform.vcd &

clean:
	rm -rf *.o *~ *.vpd sim* csrc DVEfiles *daidir *exe *.key *.exe.vdb
