// (multiplication, addition) component for MonPro
`timescale 1 ns / 1 ns

module mul_add
(
	input clk,
	input [63 : 0] x,
	input [63 : 0] y,
	input [63 : 0] z,
	input [63 : 0] last_c,
	output [63 : 0] s,	// lower output
	output [63 : 0] c	// higher output
);

	// Declare input and output registers
	wire [2 * 64 - 1: 0] mult_out;
	assign mult_out = x * y + z + last_c;
	assign s = mult_out[63 : 0];
	assign c = mult_out[2 * 64 - 1 : 64];

endmodule
