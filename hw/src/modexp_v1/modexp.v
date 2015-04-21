// MonPro module
// follow this algorithm: http://cs.ucsb.edu/~koc/cs290g/docs/w01/mon1.pdf
`timescale 1 ns / 1 ns


module modexp
(
	input clk,
	input reset,
	input startInput,	// tell FPGA to start input 
	input startCompute,	// tell FPGA to start compute
	input loadNext, 
	input getResult,	// tell FPGA to output result
	input read,
	input [127 : 0] m_buf,	
	input [127 : 0] e_buf,
	//TODO VERIFY IF THE FOLLOWING IS TRUE
	/*
	Since the modulus is shared between private and public key, 
	I can offload all of the work computing n0', r, and t to the SW
	system, and merely buffer these as I do M and E.
	*/
	input [127 : 0] r_buf,	
	input [127 : 0] t_buf,
	input [127 : 0] n_buf,	
	input [63:0] nprime0_buf,

	output reg [3 : 0] state,
	output reg [4 : 0] exp_state,	//	for MonExp
	output reg [127 : 0] res_out
);

	//These are the only vars I need. 
	reg [63 : 0] m_in [63 : 0];	// for m input
	reg [63 : 0] r_in [63 : 0];	// for r input
	reg [63 : 0] t_in [63 : 0];	// for t input
	reg [63 : 0] e_in [63 : 0];	// for e input
	reg [63 : 0] nprime0;	// a memory must have unpacked array! for readmemh
	reg [63 : 0] n_in [63 : 0];	// for n input
	
	//TODO necessary?
	reg [63 : 0] m_bar [63 : 0];	// multiple usage, to save regs
	reg [63 : 0] c_bar [63 : 0];	// multiple usage, to save regs
	
	//TODO necessary?
	reg [63 : 0] z;
	reg [63 : 0] v [64 + 1 : 0];
	reg [63 : 0] m;


	// Declare states WHATEVER
	parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6, S7 = 7;
	parameter INIT_STATE = 0, LOAD_E =1, LOAD_N = 2, LOAD_R = 3, 
	       LOAD_T = 4, LOAD_NP = 5, LOAD_M = 6, WAIT_COMPUTE = 7, 
                  CALC_M_BAR = 8, GET_K_E = 9, BIGLOOP = 10, CALC_C_BAR_M_BAR = 11, 
                  CALC_C_BAR_1 = 12, COMPLETE = 13, OUTPUT_RESULT = 14, TERMINAL = 15;
							
	integer i;	// big loop i
	integer j;
	integer k;
	integer k_e1;
	integer k_e2;
	
	reg [63 : 0] x0;
	reg [63 : 0] y0;
	reg [63 : 0] z0;
	reg [63 : 0] last_c0;
	wire [63 : 0] s0;
	wire [63 : 0] c0;
	mul_add mul_add0 (.clk(clk), .x(x0), .y(y0), .z(z0), .last_c(last_c0), 
                .s(s0), .c(c0));


	always @ (posedge clk or posedge reset) begin
		if (reset) begin	// reset all...
			for(i = 0; i < 64 + 2; i = i + 1) begin
				v[i] = 64'h0000000000000000;
			end
			for(i = 0; i < 64; i = i + 1) begin
				m_in[i] <= 64'h0000000000000000;
				e_in[i] <= 64'h0000000000000000;
				n_in[i] <= 64'h0000000000000000;
				r_in[i] <= 64'h0000000000000000;
				t_in[i] <= 64'h0000000000000000;
				nprime0[i] <= 1'b0;
			end
			res_out <= 128'h0000000000000000;
			z = 64'h0000000000000000;	// initial C = 0
			i = 0;
			j = 0;
			k = 0;
			state <= S0;
			exp_state <= INIT_STATE;
			k_e1 = 64 - 1;
			k_e2 = 64 - 1;
		end
		else begin
			case (exp_state)
				INIT_STATE: // initial state
				begin
					if(startInput)
						exp_state <= LOAD_E;
				end
			
				LOAD_E:	// read in and initialize e, r, t, n, n0'
				begin		
					if(i < 64 && read) begin
						e_in[i] <= e_buf[63:0];
						e_in[i+1] <= e_buf[127:64];
						//$display("Reading: %h %h %h %h %h", e_buf, r_buf, t_buf, n_buf, nprime0_buf);
						i = i + 2;
					end else if(i< 64) begin
						//do nothing
					end
					else begin
						i = 0;
						exp_state <= LOAD_N;
					end
				end

				LOAD_N:	// read in and initialize e, r, t, n, n0'
				begin		
					if(i < 64 && read) begin
						n_in[i] <= n_buf[63:0];
						n_in[i+1] <= n_buf[127:64];
						//$display("Reading: %h %h %h %h %h", e_buf, r_buf, t_buf, n_buf, nprime0_buf);
						i = i + 2;
					end else if(i< 64) begin
						//do nothing
					end else begin
						i = 0;
						exp_state <= LOAD_R;
					end
				end

				LOAD_R:	// read in and initialize e, r, t, n, n0'
				begin		
					if(i < 64 && read) begin
						r_in[i] <= r_buf[63:0];
						r_in[i+1] <= r_buf[127:64];
						//$display("Reading: %h %h %h %h %h", e_buf, r_buf, t_buf, n_buf, nprime0_buf);
						i = i + 2;
					end else if(i< 64) begin
						//do nothing
					end
					else begin
						i = 0;
						exp_state <= LOAD_T;
					end
				end
				LOAD_T:	// read in and initialize e, r, t, n, n0'
				begin		
					if(i < 64 && read) begin
						t_in[i] <= t_buf[63:0];
						t_in[i+1] <= t_buf[127:0];
						//$display("Reading: %h %h %h %h %h", e_buf, r_buf, t_buf, n_buf, nprime0_buf);
						i = i + 2;
					end else if(i< 64) begin
						//do nothing
					end
					else begin
						i = 0;
						exp_state <= LOAD_NP;
					end
				end
				LOAD_NP:	// read in and initialize e, r, t, n, n0'
				begin		
					if(i < 1 && read) begin
						nprime0 <= nprime0_buf;	
						//$display("Reading: %h %h %h %h %h", e_buf, r_buf, t_buf, n_buf, nprime0_buf);
						i = i + 1;
					end else if(i< 1) begin
						//do nothing
					end
					else begin
						i = 0;
						exp_state <= LOAD_M;
					end
				end
				
				LOAD_M: //load m
				begin		
					if(i < 64 && read) begin
						m_in[i] <= m_buf[63:0];
						m_in[i+1] <= m_buf[127:0];
						//$display("Reading: %h %h %h %h %h", e_buf, r_buf, t_buf, n_buf, nprime0_buf);
						i = i + 2;
					end else if (i< 64) begin

                                        end
					else begin
						i = 0;
						exp_state <= WAIT_COMPUTE;
					end
				end
			
				WAIT_COMPUTE:
				begin
					if(startCompute) begin
						exp_state <= CALC_M_BAR;		
					end					
				end
				
				CALC_M_BAR:	// calculate m_bar = MonPro(m, t) and copy: c_bar = r
				begin
					case (state)
						S0: 
						begin	// vector(v) = x[0] * y + prev[vector(v)] + z
							if(k == 0) begin	// first clock: initial input 
								// initial a new multiplier computation
								x0 <= m_in[i];
								y0 <= t_in[j];
								z0 <= v[j];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin	// second clock: store output
								// store the output of multiplier
								v[j] <= s0;
								z <= c0;
								j = j + 1;
								if(j == 64) begin	// loop end
									j = 0;
									state <= S1;
								end
								k = 0;
							end 
						end
						
						S1:
						begin // (C, S) = v[s] + C, v[s] = S, v[s + 1] = C
							if(k == 0) begin	// first clock: initial input 
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin
								v[64] <= s0;
								v[64 + 1] <= c0;
								state <= S2;
								k = 0;
							end 
						end
						
						S2:
						begin // m = (v[0] * n0_prime) mod 2^w
							if(k == 0) begin	// first clock: initial input 
								x0 <= v[0];
								y0 <= nprime0;
								z0 <= 64'h0000000000000000;
								last_c0 <= 64'h0000000000000000;
								k = 1;
							end
							else if(k == 1) begin
								m <= s0;	
								state <= S3;
								k = 0;
							end
						end
						
						S3:	
						begin // vector(v) = (m * vector(n) + vector(v)) >> WIDTH
						// (C, S) = v[0] + m * n[0]
							if(j == 0) begin
								if(k == 0) begin	// first clock: initial input 
									x0 <= m;
									y0 <= n_in[0];
									z0 <= v[0];
									last_c0 <= 64'h0000000000000000;
									k = 1;
								end		
								else if(k == 1) begin
									z <= c0;	
									j = j + 1;
									k = 0;
								end
							end
							else begin
								if(k == 0) begin
									x0 <= m;
									y0 <= n_in[j];
									z0 <= v[j];
									last_c0 <= z;
									k = 1;
								end
								else if(k == 1) begin
									v[j - 1] <= s0;
									z <= c0;	
									j = j + 1;						
									if(j == 64) begin
										j = 0;
										state <= S4;
									end
									k = 0;
								end
							end
						end
						
						S4:
						begin //	(C, S) = v[s] + C, v[s - 1] = S
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64 - 1] <= s0;
								z <= c0;	
								state <= S5;
								k = 0;
							end
						end
						
						S5:
						begin // v[s] = v[s + 1] + C
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64 + 1];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64] <= s0;
								i = i + 1;
								if(i >= 64) begin	// end
									state <= S6;
									i = 0;
								end else begin
									state <= S0;
								end
								k = 0;
							end
						end
						
						S6:
						begin
							// prepaer end state, update output, and set all to default
							// store into m_bar and c_bar
							for(i = 0; i < 64; i = i + 1) begin
								m_bar[i] = v[i];
							end
							for(i = 0; i < 64; i = i + 1) begin
								c_bar[i] = r_in[i];
							end
							for(i = 0; i < 64 + 2; i = i + 1) begin
								v[i] = 64'h0000000000000000;
							end
							z = 64'h0000000000000000;
							i = 0;
							j = 0;
							k = 0;
							state <= S7;
						end
						
						S7:
						begin
							exp_state <= GET_K_E;	// go to next state
							state <= S0;
						end
					endcase
				end
			
				GET_K_E:	// a clock to initial the leftmost 1 in e = k_e
				begin
					if(e_in[k_e1][k_e2] == 1) begin
						exp_state <= BIGLOOP;
					end
					else begin
						if(k_e2 == 0) begin
							k_e1 = k_e1 - 1;
							k_e2 = 64 - 1;
						end
						else begin
							k_e2 = k_e2 - 1;
						end
					end
				end
			
				BIGLOOP:	// for i = k_e1 * 64 + k_e2 downto 0
				begin
					case (state)	// c_bar = MonPro(c_bar, c_bar)
						S0: 
						begin	// vector(v) = x[0] * y + prev[vector(v)] + z
							if(k == 0) begin	// first clock: initial input 
								// initial a new multiplier computation
								x0 <= c_bar[i];
								y0 <= c_bar[j];
								z0 <= v[j];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin	// second clock: store output
								// store the output of multiplier
								v[j] <= s0;
								z <= c0;
								j = j + 1;
								if(j == 64) begin	// loop end
									j = 0;
									state <= S1;
								end
								k = 0;
							end 
						end
						
						S1:
						begin // (C, S) = v[s] + C, v[s] = S, v[s + 1] = C
							if(k == 0) begin	// first clock: initial input 
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin
								v[64] <= s0;
								v[64 + 1] <= c0;
								state <= S2;
								k = 0;
							end 
						end
						
						S2:
						begin // m = (v[0] * n0_prime) mod 2^w
							if(k == 0) begin	// first clock: initial input 
								x0 <= v[0];
								y0 <= nprime0;
								z0 <= 64'h0000000000000000;
								last_c0 <= 64'h0000000000000000;
								k = 1;
							end
							else if(k == 1) begin
								m <= s0;	
								state <= S3;
								k = 0;
							end
						end
						
						S3:	
						begin // vector(v) = (m * vector(n) + vector(v)) >> WIDTH
						// (C, S) = v[0] + m * n[0]
							if(j == 0) begin
								if(k == 0) begin	// first clock: initial input 
									x0 <= m;
									y0 <= n_in[0];
									z0 <= v[0];
									last_c0 <= 64'h0000000000000000;
									k = 1;
								end		
								else if(k == 1) begin
									z <= c0;	
									j = j + 1;
									k = 0;
								end
							end
							else begin
								if(k == 0) begin
									x0 <= m;
									y0 <= n_in[j];
									z0 <= v[j];
									last_c0 <= z;
									k = 1;
								end
								else if(k == 1) begin
									v[j - 1] <= s0;
									z <= c0;	
									j = j + 1;						
									if(j == 64) begin
										j = 0;
										state <= S4;
									end
									k = 0;
								end
							end
						end
						
						S4:
						begin //	(C, S) = v[s] + C, v[s - 1] = S
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64 - 1] <= s0;
								z <= c0;	
								state <= S5;
								k = 0;
							end
						end
						
						S5:
						begin // v[s] = v[s + 1] + C
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64 + 1];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64] <= s0;
								i = i + 1;
								if(i >= 64) begin	// end
									state <= S6;
									i = 0;
								end else begin
									state <= S0;
								end
								k = 0;
							end
						end
						
						S6:
						begin
							// prepaer end state, update output, and set all to default
							// store into m_bar and c_bar
							for(i = 0; i < 64; i = i + 1) begin
								c_bar[i] = v[i];
							end
							for(i = 0; i < 64 + 2; i = i + 1) begin
								v[i] = 64'h0000000000000000;
							end
							z = 64'h0000000000000000;
							i = 0;
							j = 0;
							k = 0;
							state <= S7;
						end
						
						S7:
						begin
							if(e_in[k_e1][k_e2] == 1) begin
								exp_state <= CALC_C_BAR_M_BAR;	// go to c_bar = MonPro(c_bar, m_bar)
							end
							else begin
								if(k_e1 <= 0 && k_e2 <= 0)
									exp_state <= CALC_C_BAR_1;
								else if(k_e2 == 0) begin	// down 1 of e
									k_e1 = k_e1 - 1;
									k_e2 = 64 - 1;
								end else
									k_e2 = k_e2 - 1;
							end
							state <= S0;
						end
					endcase				
				end
				
				CALC_C_BAR_M_BAR:	// c_bar = MonPro(c_bar, m_bar)
				begin
					case (state)	// c_bar = MonPro(c_bar, c_bar)
						S0: 
						begin	// vector(v) = x[0] * y + prev[vector(v)] + z
							if(k == 0) begin	// first clock: initial input 
								// initial a new multiplier computation
								x0 <= c_bar[i];
								y0 <= m_bar[j];
								z0 <= v[j];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin	// second clock: store output
								// store the output of multiplier
								v[j] <= s0;
								z <= c0;
								j = j + 1;
								if(j == 64) begin	// loop end
									j = 0;
									state <= S1;
								end
								k = 0;
							end 
						end
						
						S1:
						begin // (C, S) = v[s] + C, v[s] = S, v[s + 1] = C
							if(k == 0) begin	// first clock: initial input 
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin
								v[64] <= s0;
								v[64 + 1] <= c0;
								state <= S2;
								k = 0;
							end 
						end
						
						S2:
						begin // m = (v[0] * n0_prime) mod 2^w
							if(k == 0) begin	// first clock: initial input 
								x0 <= v[0];
								y0 <= nprime0;
								z0 <= 64'h0000000000000000;
								last_c0 <= 64'h0000000000000000;
								k = 1;
							end
							else if(k == 1) begin
								m <= s0;	
								state <= S3;
								k = 0;
							end
						end
						
						S3:	
						begin // vector(v) = (m * vector(n) + vector(v)) >> WIDTH
						// (C, S) = v[0] + m * n[0]
							if(j == 0) begin
								if(k == 0) begin	// first clock: initial input 
									x0 <= m;
									y0 <= n_in[0];
									z0 <= v[0];
									last_c0 <= 64'h0000000000000000;
									k = 1;
								end		
								else if(k == 1) begin
									z <= c0;	
									j = j + 1;
									k = 0;
								end
							end
							else begin
								if(k == 0) begin
									x0 <= m;
									y0 <= n_in[j];
									z0 <= v[j];
									last_c0 <= z;
									k = 1;
								end
								else if(k == 1) begin
									v[j - 1] <= s0;
									z <= c0;	
									j = j + 1;						
									if(j == 64) begin
										j = 0;
										state <= S4;
									end
									k = 0;
								end
							end
						end
						
						S4:
						begin //	(C, S) = v[s] + C, v[s - 1] = S
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64 - 1] <= s0;
								z <= c0;	
								state <= S5;
								k = 0;
							end
						end
						
						S5:
						begin // v[s] = v[s + 1] + C
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64 + 1];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64] <= s0;
								i = i + 1;
								if(i >= 64) begin	// end
									state <= S6;
									i = 0;
								end else begin
									state <= S0;
								end
								k = 0;
							end
						end
						
						S6:
						begin
							// prepaer end state, update output, and set all to default
							// store into m_bar and c_bar
							for(i = 0; i < 64; i = i + 1) begin
								c_bar[i] = v[i];
							end
							for(i = 0; i < 64 + 2; i = i + 1) begin
								v[i] = 64'h0000000000000000;
							end
							z = 64'h0000000000000000;
							i = 0;
							j = 0;
							k = 0;
							state <= S7;
						end
						
						S7:
						begin
							if(k_e1 <= 0 && k_e2 <= 0) begin
								exp_state <= CALC_C_BAR_1;
								state <= S0;
							end
							else begin
								if(k_e2 == 0) begin	// down 1 of e
									k_e1 = k_e1 - 1;
									k_e2 = 64 - 1;
								end else
									k_e2 = k_e2 - 1;
								exp_state <= BIGLOOP;
								state <= S0;
							end
						end
					endcase					
				end
				
				CALC_C_BAR_1:	// c = MonPro(1, c_bar)
				begin
					case (state)	// c_bar = MonPro(c_bar, c_bar)
						S0: 
						begin	// vector(v) = x[0] * y + prev[vector(v)] + z
							if(i == 0) begin
								if(k == 0) begin	// first clock: initial input 
									// initial a new multiplier computation
									x0 <= 64'h0000000000000001;
									y0 <= c_bar[j];
									z0 <= v[j];
									last_c0 <= z;
									k = 1;
								end 
								else if(k == 1) begin	// second clock: store output
									// store the output of multiplier
									v[j] <= s0;
									z <= c0;
									j = j + 1;
									if(j == 64) begin	// loop end
										j = 0;
										state <= S1;
									end
									k = 0;
								end 
							end
							else begin
								if(k == 0) begin	// first clock: initial input 
									// initial a new multiplier computation
									x0 <= 64'h0000000000000000;
									y0 <= c_bar[j];
									z0 <= v[j];
									last_c0 <= z;
									k = 1;
								end 
								else if(k == 1) begin	// second clock: store output
									// store the output of multiplier
									v[j] <= s0;
									z <= c0;
									j = j + 1;
									if(j == 64) begin	// loop end
										j = 0;
										state <= S1;
									end
									k = 0;
								end 	
							end
						end
						
						S1:
						begin // (C, S) = v[s] + C, v[s] = S, v[s + 1] = C
							if(k == 0) begin	// first clock: initial input 
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end 
							else if(k == 1) begin
								v[64] <= s0;
								v[64 + 1] <= c0;
								state <= S2;
								k = 0;
							end 
						end
						
						S2:
						begin // m = (v[0] * n0_prime) mod 2^w
							if(k == 0) begin	// first clock: initial input 
								x0 <= v[0];
								y0 <= nprime0;
								z0 <= 64'h0000000000000000;
								last_c0 <= 64'h0000000000000000;
								k = 1;
							end
							else if(k == 1) begin
								m <= s0;	
								state <= S3;
								k = 0;
							end
						end
						
						S3:	
						begin // vector(v) = (m * vector(n) + vector(v)) >> WIDTH
						// (C, S) = v[0] + m * n[0]
							if(j == 0) begin
								if(k == 0) begin	// first clock: initial input 
									x0 <= m;
									y0 <= n_in[0];
									z0 <= v[0];
									last_c0 <= 64'h0000000000000000;
									k = 1;
								end		
								else if(k == 1) begin
									z <= c0;	
									j = j + 1;
									k = 0;
								end
							end
							else begin
								if(k == 0) begin
									x0 <= m;
									y0 <= n_in[j];
									z0 <= v[j];
									last_c0 <= z;
									k = 1;
								end
								else if(k == 1) begin
									v[j - 1] <= s0;
									z <= c0;	
									j = j + 1;						
									if(j == 64) begin
										j = 0;
										state <= S4;
									end
									k = 0;
								end
							end
						end
						
						S4:
						begin //	(C, S) = v[s] + C, v[s - 1] = S
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64 - 1] <= s0;
								z <= c0;	
								state <= S5;
								k = 0;
							end
						end
						
						S5:
						begin // v[s] = v[s + 1] + C
							if(k == 0) begin
								x0 <= 64'h0000000000000000;
								y0 <= 64'h0000000000000000;
								z0 <= v[64 + 1];
								last_c0 <= z;
								k = 1;
							end
							else if(k == 1) begin
								v[64] <= s0;
								i = i + 1;
								if(i >= 64) begin	// end
									state <= S6;
									i = 0;
								end else begin
									state <= S0;
								end
								k = 0;
							end
						end
						
						S6:
						begin
							// prepare end state, update output, and set all to default
							// store into m_bar and c_bar
							for(i = 0; i < 64; i = i + 1) begin
								c_bar[i] = v[i];
							end
							for(i = 0; i < 64 + 2; i = i + 1) begin
								v[i] = 0;
							end
							z = 64'h0000000000000000;
							i = 0;
							j = 0;
							k = 0;
							state <= S7;
						end
						
						S7:
						begin
							exp_state <= COMPLETE;	// end state of exp!
							state <= S0;
						end
					endcase		
				end
				
				COMPLETE:
				begin
					if(getResult) begin
						exp_state <= OUTPUT_RESULT;
					end				
				end
				
				OUTPUT_RESULT:	// output 4096 bits result (c_bar) to output buffer!
				begin
					if(i < 64) begin
						res_out[63:0] <= c_bar[i];
						res_out[127:64] <= c_bar[i+1];
						//$display("Outputting result");
						i = i + 2;
					end
					else begin
						exp_state <= TERMINAL;
						i = 0;
						res_out <= 128'h0000000000000000;
					end
				end
				
				TERMINAL:
				begin
					res_out <= 128'h0000000000000000;
					if(loadNext) begin
						exp_state <= LOAD_M;		
					end	
				end
			endcase
		end
	end
	
endmodule
	
