`timescale 1ns/10ps


module aes_tb();
	parameter CLK_HALF_PERIOD = 1;
	parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

	// The DUT address map.
	parameter ADDR_CTRL        = 8'h08;
	parameter CTRL_INIT_BIT    = 0;
	parameter CTRL_NEXT_BIT    = 1;
	parameter CTRL_ENCDEC_BIT  = 2;
	parameter CTRL_KEYLEN_BIT  = 3;

	parameter ADDR_CONFIG      = 8'h09;

	parameter ADDR_STATUS      = 8'h0a;
	parameter STATUS_READY_BIT = 0;
	parameter STATUS_VALID_BIT = 1;

	parameter ADDR_KEY0        = 8'h10;
	parameter ADDR_KEY1        = 8'h11;
	parameter ADDR_KEY2        = 8'h12;
	parameter ADDR_KEY3        = 8'h13;
	parameter ADDR_KEY4        = 8'h14;
	parameter ADDR_KEY5        = 8'h15;
	parameter ADDR_KEY6        = 8'h16;
	parameter ADDR_KEY7        = 8'h17;

	parameter ADDR_BLOCK0      = 8'h20;
	parameter ADDR_BLOCK1      = 8'h21;
	parameter ADDR_BLOCK2      = 8'h22;
	parameter ADDR_BLOCK3      = 8'h23;

	parameter ADDR_RESULT0     = 8'h30;
	parameter ADDR_RESULT1     = 8'h31;
	parameter ADDR_RESULT2     = 8'h32;
	parameter ADDR_RESULT3     = 8'h33;

	parameter AES_256_BIT_KEY = 1;

	parameter AES_DECIPHER = 1'b0;

	reg [31 : 0]  read_data;
	reg [127 : 0] result_data;

	reg           tb_clk;
	reg           tb_reset_n;
	reg           tb_cs;
	reg           tb_we;
	reg [7  : 0]  tb_address;
	reg [31 : 0]  tb_write_data;
	wire [31 : 0] tb_read_data;
	wire          tb_error;

	aes dut(
	       .clk(tb_clk),
	       .reset_n(tb_reset_n),
	       .cs(tb_cs),
	       .we(tb_we),
	       .address(tb_address),
	       .write_data(tb_write_data),
	       .read_data(tb_read_data),
	       .error(tb_error)
	      );


	task init_key(input [255 : 0] key, input key_length);
	begin
	  write_word(ADDR_KEY0, key[255  : 224]);
	  write_word(ADDR_KEY1, key[223  : 192]);
	  write_word(ADDR_KEY2, key[191  : 160]);
	  write_word(ADDR_KEY3, key[159  : 128]);
	  write_word(ADDR_KEY4, key[127  :  96]);
	  write_word(ADDR_KEY5, key[95   :  64]);
	  write_word(ADDR_KEY6, key[63   :  32]);
	  write_word(ADDR_KEY7, key[31   :   0]);

	  if (key_length)
	    begin
	      write_word(ADDR_CONFIG, 8'h02);
	    end
	  else
	    begin
	      write_word(ADDR_CONFIG, 8'h00);
	    end

	  write_word(ADDR_CTRL, 8'h01);

	  #(100 * CLK_PERIOD);
	end
	endtask // init_key
	
	task write_word(input [11 : 0]  address,
	              input [31 : 0] word);
	begin
	  tb_address = address;
	  tb_write_data = word;
	  tb_cs = 1;
	  tb_we = 1;
	  #(2 * CLK_PERIOD);
	  tb_cs = 0;
	  tb_we = 0;
	end
	endtask // write_word

	task write_block(input [127 : 0] block);
	begin
	  write_word(ADDR_BLOCK0, block[127  :  96]);
	  write_word(ADDR_BLOCK1, block[95   :  64]);
	  write_word(ADDR_BLOCK2, block[63   :  32]);
	  write_word(ADDR_BLOCK3, block[31   :   0]);
	end
	endtask // write_block

	task read_word(input [11 : 0]  address);
	begin
	  tb_address = address;
	  tb_cs = 1;
	  tb_we = 0;
	  #(CLK_PERIOD);
	  read_data = tb_read_data;
	  tb_cs = 0;
	end
	endtask // read_word

	task read_result();
	begin
	  read_word(ADDR_RESULT0);
	  result_data[127 : 096] = read_data;
	  read_word(ADDR_RESULT1);
	  result_data[095 : 064] = read_data;
	  read_word(ADDR_RESULT2);
	  result_data[063 : 032] = read_data;
	  read_word(ADDR_RESULT3);
	  result_data[031 : 000] = read_data;
	end
	endtask // read_result

	initial begin
		reg [255 : 0] nist_aes256_key;

		reg [127 : 0] nist_plaintext0;
		reg [127 : 0] nist_plaintext1;
		reg [127 : 0] nist_plaintext2;
		reg [127 : 0] nist_plaintext3;

		reg [127 : 0] nist_ecb_256_enc_expected0;
		reg [127 : 0] nist_ecb_256_enc_expected1;
		reg [127 : 0] nist_ecb_256_enc_expected2;
		reg [127 : 0] nist_ecb_256_enc_expected3;
		
		nist_aes256_key = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;

		nist_plaintext0 = 128'h6bc1bee22e409f96e93d7e117393172a;
		nist_plaintext1 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
		nist_plaintext2 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
		nist_plaintext3 = 128'hf69f2445df4f9b17ad2b417be66c3710;

		nist_ecb_256_enc_expected0 = 128'hf3eed1bdb5d2a03c064b5a7e3db181f8;
		nist_ecb_256_enc_expected1 = 128'h591ccb10d410ed26dc5ba74a31362870;
		nist_ecb_256_enc_expected2 = 128'hb6ed21b99ca6f4f9f153e7b1beafed1d;
		nist_ecb_256_enc_expected3 = 128'h23304b7a39f9f3ff067d8d8f9e24ecc7;


		//reset 
		tb_clk = 0;
		tb_reset_n = 1;

		tb_reset_n = 0;
		#(4 * CLK_HALF_PERIOD);
		tb_reset_n = 1;


		init_key(nist_aes256_key, AES_256_BIT_KEY);
		write_block(nist_ecb_256_enc_expected0);
		write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1)+ AES_DECIPHER));
		write_word(ADDR_CTRL, 8'h02);
		#(100 * CLK_PERIOD);
		read_result();

		$display("received  : %h", result_data);
		$display("expected  : %h", nist_plaintext0);

		//init_key(nist_aes256_key, AES_256_BIT_KEY);
		write_block(nist_ecb_256_enc_expected1);
		write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1)+ AES_DECIPHER));
		write_word(ADDR_CTRL, 8'h02);
		#(100 * CLK_PERIOD);
		read_result();

		$display("received  : %h", result_data);
		$display("expected  : %h", nist_plaintext1);

		//init_key(nist_aes256_key, AES_256_BIT_KEY);
		write_block(nist_ecb_256_enc_expected2);
		write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1)+ AES_DECIPHER));
		write_word(ADDR_CTRL, 8'h02);
		#(100 * CLK_PERIOD);
		read_result();

		$display("received  : %h", result_data);
		$display("expected  : %h", nist_plaintext2);

		//init_key(nist_aes256_key, AES_256_BIT_KEY);
		write_block(nist_ecb_256_enc_expected3);
		write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1)+ AES_DECIPHER));
		write_word(ADDR_CTRL, 8'h02);
		#(100 * CLK_PERIOD);
		read_result();

		$display("received  : %h", result_data);
		$display("expected  : %h", nist_plaintext3);




		#100
		tb_reset_n = 1;


		$finish;

	end
	

	initial begin
		$vcdpluson;
		//$monitor("%h \t %b", tb_read_data, tb_error);
	end

	always 
	begin : clk_gen
		#CLK_HALF_PERIOD tb_clk = !tb_clk;
	end // clk_gen


endmodule	
