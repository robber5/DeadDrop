`timescale 1 ns / 1 ns

module modexp_tb();
	reg clk;
	reg reset;
	reg [127  : 0] m_buf; //TODO we only need one input now
	reg [127  : 0] e_buf;
	reg [127  : 0] n_buf;
	reg [127  : 0] r_buf;
	reg [127  : 0] t_buf;
	reg [63:0] nprime0_buf;
	reg [63:0] nprime0 = 64'h3bea2df6a3b18a91;
	reg startInput;
	reg startCompute;
	reg getResult;
	reg read;
	reg loadNext;
	wire [127  : 0] res_out;
	wire [4 : 0] exp_state;
	wire [3 : 0] state;
	
	modexp modexp(.*);
	
	initial begin
		clk = 0;
		reset = 0;
		startInput = 0;
		startCompute = 0;
		getResult = 0;
		loadNext = 0;
		read = 1;
		m_buf = 128'h0000000000000000;
		e_buf = 128'h0000000000000000;
		n_buf = 128'h0000000000000000;
		r_buf = 128'h0000000000000000;
		t_buf = 128'h0000000000000000;
		nprime0_buf = 1'b0;
		#10 reset = 1;
		#10 reset = 0;
		#10 startInput = 1;	



		#10 e_buf = 128'h00000000000000000000000000000005;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;
		#10 e_buf = 128'h0000000000000000;

            #10 read = 1;
            

		#10 n_buf = 128'ha9ec0806705fca161622bd795fec898f;
		#10 n_buf = 128'h29e821a4c74803e31ba1621582283d15;
		#10 n_buf = 128'h5eda92d864ac5db9d707107e855c3844;
		#10 n_buf = 128'h78255d6807923986bb968a437d5c8dfc;
		#10 n_buf = 128'hd92a4aa2b410d93c4efbc8d60b21fbac;
		#10 n_buf = 128'h9403560d97dae38d9d643c25fbb230bb;
		#10 n_buf = 128'h2b28fef02b9c014ea5ac06d864c2f2e3;
		#10 n_buf = 128'h0326324dfb695ffb3a1890c78092b4d4;
		#10 n_buf = 128'heb8ac8ce8a245e6b33138131c541013d;
		#10 n_buf = 128'h678a5aa33b6fe5078c5fe8f8dc3bf364;
		#10 n_buf = 128'hd8f33418f3d4e7115804f92283868a29;
		#10 n_buf = 128'he8e5b4617589a82b5a702cfa93ea5c4e;
		#10 n_buf = 128'h9be3cecb8c497c68a8c24d4244ef7feb;
		#10 n_buf = 128'h62397bc701762741bab9f87ff5059285;
		#10 n_buf = 128'hf463b337d20b5d59db610487c89da11b;
		#10 n_buf = 128'h83333218bd91a1b7f03edca7e2dcaa37;
		#10 n_buf = 128'hc703806984c8199921167d8fcf23cae8;
		#10 n_buf = 128'hf320cd576d14475b349aae908fb5262c;
		#10 n_buf = 128'h5d5f576cdeb8fc4c7b297d0b0e5e18ba;
		#10 n_buf = 128'hf0e642f43328ad088ded3c9691eb79fa;
		#10 n_buf = 128'hd037cdff7c240d4969d495dd81355c53;
		#10 n_buf = 128'h0067dba8589890086a17b9af5b569643;
		#10 n_buf = 128'hc9546b439f9d01298a449ebe89d9bf02;
		#10 n_buf = 128'h99901c0475491bc354c56c9a9cc9af4e;
		#10 n_buf = 128'ha2a7ae1f3ac7652ccdf8440407295e42;
		#10 n_buf = 128'h2e47dc0e959f3a518cfe5cd12d5db79b;
		#10 n_buf = 128'h8d103ed3cc667e971773308cdc6b13ab;
		#10 n_buf = 128'hee52bdb6d1020a15d9ed17e3cc0e95ee;
		#10 n_buf = 128'hf18dd1eed77c96c0084f3dd6415af341;
		#10 n_buf = 128'hde3a5db5154ed51212093d26ac512b01;
		#10 n_buf = 128'hc10faa4003ba33db73f7ba8e0445d656;
		#10 n_buf = 128'h84c5b4763fe31d0347fc816ac16e2284;


            #10 read = 1;

		#10 r_buf = 128'h5613f7f98fa035e9e9dd4286a0137671;
		#10 r_buf = 128'hd617de5b38b7fc1ce45e9dea7dd7c2ea;
		#10 r_buf = 128'ha1256d279b53a24628f8ef817aa3c7bb;
		#10 r_buf = 128'h87daa297f86dc679446975bc82a37203;
		#10 r_buf = 128'h26d5b55d4bef26c3b1043729f4de0453;
		#10 r_buf = 128'h6bfca9f268251c72629bc3da044dcf44;
		#10 r_buf = 128'hd4d7010fd463feb15a53f9279b3d0d1c;
		#10 r_buf = 128'hfcd9cdb20496a004c5e76f387f6d4b2b;
		#10 r_buf = 128'h1475373175dba194ccec7ece3abefec2;
		#10 r_buf = 128'h9875a55cc4901af873a0170723c40c9b;
		#10 r_buf = 128'h270ccbe70c2b18eea7fb06dd7c7975d6;
		#10 r_buf = 128'h171a4b9e8a7657d4a58fd3056c15a3b1;
		#10 r_buf = 128'h641c313473b68397573db2bdbb108014;
		#10 r_buf = 128'h9dc68438fe89d8be454607800afa6d7a;
		#10 r_buf = 128'h0b9c4cc82df4a2a6249efb7837625ee4;
		#10 r_buf = 128'h7ccccde7426e5e480fc123581d2355c8;
		#10 r_buf = 128'h38fc7f967b37e666dee9827030dc3517;
		#10 r_buf = 128'h0cdf32a892ebb8a4cb65516f704ad9d3;
		#10 r_buf = 128'ha2a0a893214703b384d682f4f1a1e745;
		#10 r_buf = 128'h0f19bd0bccd752f77212c3696e148605;
		#10 r_buf = 128'h2fc8320083dbf2b6962b6a227ecaa3ac;
		#10 r_buf = 128'hff982457a7676ff795e84650a4a969bc;
		#10 r_buf = 128'h36ab94bc6062fed675bb6141762640fd;
		#10 r_buf = 128'h666fe3fb8ab6e43cab3a9365633650b1;
		#10 r_buf = 128'h5d5851e0c5389ad33207bbfbf8d6a1bd;
		#10 r_buf = 128'hd1b823f16a60c5ae7301a32ed2a24864;
		#10 r_buf = 128'h72efc12c33998168e88ccf732394ec54;
		#10 r_buf = 128'h11ad42492efdf5ea2612e81c33f16a11;
		#10 r_buf = 128'h0e722e112883693ff7b0c229bea50cbe;
		#10 r_buf = 128'h21c5a24aeab12aededf6c2d953aed4fe;
		#10 r_buf = 128'h3ef055bffc45cc248c084571fbba29a9;
		#10 r_buf = 128'h7b3a4b89c01ce2fcb8037e953e91dd7b;

            #10 read = 1;

		#10 t_buf = 128'h490666572b90f2c573053f82acaa289e;
		#10 t_buf = 128'h4255b841d1a34bdb41d7011500400a06;
		#10 t_buf = 128'hef79ce5f386efa550d21bcdfdf4473e0;
		#10 t_buf = 128'h432c1e910135f001a401baa22b888c2e;
		#10 t_buf = 128'hd4b94bc352c949d7192d6bf19f25d484;
		#10 t_buf = 128'hdc64dc90e98f4afe5e12a9a96f7d7742;
		#10 t_buf = 128'h17df090edd741e9f2b94c7ae4af92d64;
		#10 t_buf = 128'he4e415995f80cfb6cb06c0a97843a5f8;
		#10 t_buf = 128'hfb05f6b41fca9bc4a0a34b0f89fd1237;
		#10 t_buf = 128'hd1aeed41c012e824ae264f5fc010a19e;
		#10 t_buf = 128'hd8e7aee5bebbc2b0f2bb3810c6183272;
		#10 t_buf = 128'h79c730582a57f5213bf4e86e41840ab5;
		#10 t_buf = 128'he2276688a89b7b2a71a5acdaa14ea7d5;
		#10 t_buf = 128'h7acdff93e6b100354e1fd46c8dac7c5e;
		#10 t_buf = 128'h11a738951c5836fd35605d6ab7d595c7;
		#10 t_buf = 128'hae06fdfb77efa45d06cdb515499fa607;
		#10 t_buf = 128'hfc9227224374a351c79891833b715d01;
		#10 t_buf = 128'he28601753d3988efd7c2368322eec88a;
		#10 t_buf = 128'h67329a416f1cd4b76f39db9920e96cfc;
		#10 t_buf = 128'h9409db1237b42777bc768610a3668dd1;
		#10 t_buf = 128'h713bc2b69544b8f0565a3bcbc8747603;
		#10 t_buf = 128'h3c4a088ffc15c724fb94efe911f499d4;
		#10 t_buf = 128'h578e46c026e95b17ebafa21eb031aa15;
		#10 t_buf = 128'h3a9a9a285a43a743c95f516a94fb9120;
		#10 t_buf = 128'h7d90a87cd03fbbc4958f626f4a113152;
		#10 t_buf = 128'h1b9e6229191b68a6de0ae73aa48bb1b9;
		#10 t_buf = 128'h6482cd53c788fa6917f328b41c901b92;
		#10 t_buf = 128'h6748cb70d58c588c1b98a5e684eecd0d;
		#10 t_buf = 128'h3ef4b1440a12b8ef9518ae092a7c394a;
		#10 t_buf = 128'h07c9917922a964a86e6637fa3ca95da4;
		#10 t_buf = 128'h9d89062bd8eda4fdf2066470f135295f;
		#10 t_buf = 128'h149c1965ad98fa46718523dad5f58f40;

            #10 read = 1;


		#10 nprime0_buf = nprime0;

            #10 read = 1;

		#10 m_buf = 128'h2aa50f4ec6f0093395d1805142cb6d1d;
		#10 m_buf = 128'h1d7173e55bc7fdeb31234efe6e648043;
		#10 m_buf = 128'hda54f267dd138266d26d53961058fe8c;
		#10 m_buf = 128'h869bdbd2e72bb5b707120911b3b68b57;
		#10 m_buf = 128'h33a1d1c2ad4ab155c09fcd8f739cd488;
		#10 m_buf = 128'h41a8a6e165e049937f411fed1e70e799;
		#10 m_buf = 128'hff3e0ba10ac728b4a41865bf350d278d;
		#10 m_buf = 128'h9f9821883744da64cc249558f2ad985f;
		#10 m_buf = 128'h755a3ac132ae2a201ac902ee25777cf0;
		#10 m_buf = 128'hd3b564b08be04c3e5c94938160c6b3ed;
		#10 m_buf = 128'h98a33736fd1ac7ce1ad0a6f226bdd974;
		#10 m_buf = 128'h905c053b25fdacbe7ce71b48fba52e59;
		#10 m_buf = 128'h6c596216ae0fdbc8a36bcb0167e98363;
		#10 m_buf = 128'hade7cef37ed2ec2f856f3d95e0ae1a1b;
		#10 m_buf = 128'hd5627386528cc241e345ac72eac39204;
		#10 m_buf = 128'ha2939b3b7fa74d8aff88ec827f99d273;
		#10 m_buf = 128'h8af5890333b5b3cedfec4623ab899605;
		#10 m_buf = 128'h027c013f38018399ee6a8e2f9c19ed34;
		#10 m_buf = 128'hbf3df0bbf66ac168b4a1ca795718ada2;
		#10 m_buf = 128'h52631db9d17034ce51797350e6256403;
		#10 m_buf = 128'hdfde228125fb5f3d866d7002091472ad;
		#10 m_buf = 128'h27e969e2c8bf23fb9a431f7a41c30359;
		#10 m_buf = 128'h4b5ca436953c178e61067a8cd7a3283c;
		#10 m_buf = 128'h786e30efce9b2e70b4d4dfccb7d779cc;
		#10 m_buf = 128'h843b2a7d15ab2c21ccc93ff710fce97d;
		#10 m_buf = 128'h10fc9eee0a1727f7ea5f24b6de6fec4b;
		#10 m_buf = 128'h4cea2df00a66dc4e21681081399f8a8f;
		#10 m_buf = 128'h72d6bc20d80d6a1cc2472fd603e9ba02;
		#10 m_buf = 128'hccf719ab2922fbd8dca5b35354a1d505;
		#10 m_buf = 128'h75f2bc20a7f5195cde62d43f261908b9;
		#10 m_buf = 128'h61d9fe398147a8f45f0ef320f7f60e7f;
		#10 m_buf = 128'h044d9850809f292387a1798fe6addd9e;

	#10 read = 0;


		startCompute = 1;
		
		while(exp_state!=13) begin
		#10 startCompute = 1;
		end
		startCompute = 0;
		getResult = 1;

		while(exp_state!=15) begin
		#10 getResult = 1;
		end
		$finish;

	end
	

	initial begin
		$vcdpluson;
		$monitor("%d \t %h", exp_state, res_out);
	end

	always begin
		#5 clk = ~clk;
	end


endmodule	
