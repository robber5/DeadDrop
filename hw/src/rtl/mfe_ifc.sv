`timescale 1ns/1ns

interface mfe_ifc(input bit clk);

	logic rst;

	//status leds
	logic [6:0] status_leds;


	//clock for spi
	logic spi_clk;
	/* external spi interfaces */
	logic [2:0] sd_spi_o;
	logic sd_spi_i;
	logic [2:0] sw1_spi_o;
	logic sw1_spi_i;
	logic [2:0] sw2_spi_o;
	logic sw2_spi_i;

	logic [7:0] kbd_data_i; 
	logic kbd_done, kbd_reset, kbd_valid_i;

	//SW controls
	logic start; //start processing
	logic next; //process next message


	/* debug */
	logic [2:0] state_debug; //for debugging

	// note that the outputs and inputs are reversed from the dut
	clocking cb @(posedge clk);
		output rst, sd_spi_i, sw1_spi_i, sw2_spi_i,
		start, next,
		kbd_reset, kbd_done, kbd_data_i,
		kbd_valid_i;
		input status_leds, spi_clk,
		sd_spi_o, sw1_spi_o, sw2_spi_o, 
		state_debug;
	endclocking

	modport bench (clocking cb);

	modport dut (
		input clk, rst, sd_spi_i, start, next,
		sw1_spi_i, sw2_spi_i,
		kbd_data_i, kbd_valid_i,
		kbd_reset, kbd_done,
		output spi_clk, sd_spi_o, 
		sw1_spi_o, sw2_spi_o,
		state_debug
	);
endinterface
