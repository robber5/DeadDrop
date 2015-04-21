`timescale 1ns/10ps




module sha_tb();
	parameter CLK_HALF_PERIOD = 2;
	parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;
	parameter ADDR_CTRL        = 8'h08;
	parameter CTRL_INIT_VALUE  = 8'h01;
	parameter CTRL_NEXT_VALUE  = 8'h02;
	parameter ADDR_STATUS      = 8'h09;
	parameter STATUS_READY_BIT = 0;
	parameter STATUS_VALID_BIT = 1;
	                 
	parameter ADDR_BLOCK0    = 8'h10;
	parameter ADDR_BLOCK1    = 8'h11;
	parameter ADDR_BLOCK2    = 8'h12;
	parameter ADDR_BLOCK3    = 8'h13;
	parameter ADDR_BLOCK4    = 8'h14;
	parameter ADDR_BLOCK5    = 8'h15;
	parameter ADDR_BLOCK6    = 8'h16;
	parameter ADDR_BLOCK7    = 8'h17;
	parameter ADDR_BLOCK8    = 8'h18;
	parameter ADDR_BLOCK9    = 8'h19;
	parameter ADDR_BLOCK10   = 8'h1a;
	parameter ADDR_BLOCK11   = 8'h1b;
	parameter ADDR_BLOCK12   = 8'h1c;
	parameter ADDR_BLOCK13   = 8'h1d;
	parameter ADDR_BLOCK14   = 8'h1e;
	parameter ADDR_BLOCK15   = 8'h1f;
	                 
	parameter ADDR_DIGEST0   = 8'h20;
	parameter ADDR_DIGEST1   = 8'h21;
	parameter ADDR_DIGEST2   = 8'h22;
	parameter ADDR_DIGEST3   = 8'h23;
	parameter ADDR_DIGEST4   = 8'h24;
	parameter ADDR_DIGEST5   = 8'h25;
	parameter ADDR_DIGEST6   = 8'h26;
	parameter ADDR_DIGEST7   = 8'h27;


	reg clk;
	reg reset;
	reg           tb_cs;
	reg           tb_we;
	reg [7 : 0]   tb_address;
	reg [31 : 0]  tb_write_data;
	wire [31 : 0] tb_read_data;
	wire          tb_error;

	reg [31 : 0]  read_data;
	reg [255 : 0] digest_data;


	sha256 dut(
	         .clk(clk),
	         .reset_n(reset),
	         
	         .cs(tb_cs),
	         .we(tb_we),
	         
	         
	         .address(tb_address),
	         .write_data(tb_write_data),
	         .read_data(tb_read_data),
	         .error(tb_error)
	        );
	
	task wait_ready();
	begin
		read_data = 0;

		while (read_data == 0)
		begin
			read_word(ADDR_STATUS);
		end
	end
	endtask // wait_ready

	task write_word(input [7 : 0]  address,
		input [31 : 0] word);
		begin
		tb_address = address;
		tb_write_data = word;
		tb_cs = 1;
		tb_we = 1;
		#(CLK_PERIOD);
		tb_cs = 0;
		tb_we = 0;
		end
	endtask // write_word
	
	task write_block(input [511 : 0] block);
	begin
	  write_word(ADDR_BLOCK0,  block[511 : 480]);
	  write_word(ADDR_BLOCK1,  block[479 : 448]);
	  write_word(ADDR_BLOCK2,  block[447 : 416]);
	  write_word(ADDR_BLOCK3,  block[415 : 384]);
	  write_word(ADDR_BLOCK4,  block[383 : 352]);
	  write_word(ADDR_BLOCK5,  block[351 : 320]);
	  write_word(ADDR_BLOCK6,  block[319 : 288]);
	  write_word(ADDR_BLOCK7,  block[287 : 256]);
	  write_word(ADDR_BLOCK8,  block[255 : 224]);
	  write_word(ADDR_BLOCK9,  block[223 : 192]);
	  write_word(ADDR_BLOCK10, block[191 : 160]);
	  write_word(ADDR_BLOCK11, block[159 : 128]);
	  write_word(ADDR_BLOCK12, block[127 :  96]);
	  write_word(ADDR_BLOCK13, block[95  :  64]);
	  write_word(ADDR_BLOCK14, block[63  :  32]);
	  write_word(ADDR_BLOCK15, block[31  :   0]);
	end
	endtask // write_block

	task read_word(input [7 : 0]  address);
		begin
		tb_address = address;
		tb_cs = 1;
		tb_we = 0;
		#(CLK_PERIOD);
		read_data = tb_read_data;
		tb_cs = 0;
		end
	endtask // read_word

	task read_digest();
	begin
	  read_word(ADDR_DIGEST0);
	  digest_data[255 : 224] = read_data;
	  read_word(ADDR_DIGEST1);
	  digest_data[223 : 192] = read_data;
	  read_word(ADDR_DIGEST2);
	  digest_data[191 : 160] = read_data;
	  read_word(ADDR_DIGEST3);
	  digest_data[159 : 128] = read_data;
	  read_word(ADDR_DIGEST4);
	  digest_data[127 :  96] = read_data;
	  read_word(ADDR_DIGEST5);
	  digest_data[95  :  64] = read_data;
	  read_word(ADDR_DIGEST6);
	  digest_data[63  :  32] = read_data;
	  read_word(ADDR_DIGEST7);
	  digest_data[31  :   0] = read_data;
	end
	endtask // read_digest

	initial begin
		reg [511 : 0] block;
		reg [255 : 0] expected_data;
		block = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
		expected_data = 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad;
		
		clk = 0;
		reset = 1;

		tb_cs = 0;
		tb_we = 0;

		tb_address = 8'b10;
		tb_write_data = 0;

		reset = 0;
		#(4 * CLK_HALF_PERIOD);
		reset = 1;

		write_block(block);
		write_word(ADDR_CTRL, CTRL_INIT_VALUE);
		#(CLK_PERIOD);
		wait_ready();
		read_digest();

		$display("received  : %h", digest_data);
		$display("expected  : %h", expected_data);

		#100
		reset = 1;


		$finish;

	end
	

	initial begin
		$vcdpluson;
		$monitor("%h \t %b", tb_read_data, tb_error);
	end

	always 
	begin : clk_gen
		#CLK_HALF_PERIOD clk = !clk;
	end // clk_gen


endmodule	
