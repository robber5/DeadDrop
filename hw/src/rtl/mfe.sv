`timescale 1ns/1ns

// Multimedia File Encryption (Top Level)
module mfe (mfe_ifc.dut d);



    /*
     * States:
     * 1: wait for SPI
     * 2: read key from spi
     * 3: load n,r,t,nprime0 from software and e from key
     * 4: load m from software
     * 5: run modexp until done
     * 6: output result to software
     * 7: wait then loop to 4
     */



     /* MODEXP */
    logic modexp_startInput; //input
    logic modexp_startCompute; //input
    logic modexp_loadNext;
    logic modexp_getResult; //input
    logic modexp_read;

    logic [127 : 0] m_buf;  //64 bits at a time, from SW
    logic [127 : 0] e_buf;   //64 bits at a time, from SD
    logic [127 : 0] n_buf;   //64 bits at a time, from SW
    logic [127 : 0] r_buf;   //64 bits at a time, from SW
    logic [127 : 0] t_buf;   //64 bits at a time, from SW
    logic [63:0] nprime0_buf;   //64 bits at a time, from SW

    logic [3 : 0] unused1; //don't need to keep track of this
    logic [4 : 0] modexp_state;  //don't need to keep track of this
    logic [127 : 0] modexp_out; //64 bits at a time
    modexp mod(.clk(d.clk), .reset(d.rst), .state(unused1), .exp_state(modexp_state), 
        .res_out(modexp_out), .read(modexp_read), 
        .startInput(modexp_startInput), .startCompute(modexp_startCompute), 
        .loadNext(modexp_loadNext), .getResult(modexp_getResult), .*);
    /* END MODEXP */




    /* AES */
    logic [127:0] aes_key;
    logic [127:0] aes_in;
    logic [127:0] aes_out; //38 cycles later
    aes aes(.clk(d.clk), .rst(d.rst), .data_out(aes_out), .key(aes_key), .*);
    /* END AES */



    /*
     * LED BANK
     */
    logic done_failed_i;
    logic done_passed_i;
    logic pass_failed_i;
    logic pass_passed_i;
    logic processing_i;
    logic ready_i;
    logic [6:0] status_leds;
    status_driver sd(.clk(d.clk), .rst(d.rst), .*);
    /* END LED */




    /* SPI */
    logic spi_write;
    logic [127:0] spi_write_data;
    logic [2:0] spi_option; 
    wire spi_read;
    wire [127:0] spi_read_data;
    spi spi(.clk(d.clk), .rst(d.rst), .write_data(spi_write_data),
        .read_data (spi_read_data),.read(spi_read),.write(spi_write),
        .spi_option(spi_option), .sd_in(d.sd_spi_i), .sd_out(d.sd_spi_o), 
        .sw_in1(d.sw1_spi_i), .sw_out1(d.sw1_spi_o), .sw_in2(d.sw2_spi_i),
        .sw_out2(d.sw2_spi_o));
    /* END SPI */




    /* PS2 */
    // logic [7:0] kbd_data_i; 
    // logic kbd_done, kbd_reset, kbd_valid_i;
    // kbd kbd(.*);
    /* END PS2 */




    /* HASH */
    logic [127:0] result; 
    logic cs;
    logic we;
    
    logic [7 : 0]  address;
    logic [31 : 0] sha_write_data;
    logic [31 : 0] sha_read_data;
    logic error;
    sha256 sha256(.clk(d.clk), .reset_n(d.rst), .read_data(sha_read_data), 
      .write_data(sha_write_data), .*);
    /* END HASH */



    /* BUFFERS and VARS */
    /* passphrase */
    logic [447:0] kbd; //56 character max passcode
    integer count;
    logic [2:0] state; 
    logic [63:0] encrypted_e [63:0];


    assign d.state_debug = state;

    /* 
     *
     * Multimedia File Encryption - Decryptor
     *
     * States
     *
     * 0: wait for start
     * 1: read RSA from sd card
     * 2: read from keyboard
     * 3: hash passphrase
     * 4: aes_decrypt rsa key
     * 5: read r,t,n0' from SW
     * 6: read encrypted message from spi
     * 7: rsa decrypt message
     * 8: send back to SW over spi
     * 9: wait for next and go to 6, or wait for reset and go to 0
     *
     *
     */
    parameter WAIT_START =0, READ_RSA = 1,  READ_KBD = 2, HASH=3,
                    AES = 4, READ_NRTNP = 5, READ_MSG = 6, RSA = 7, SEND = 8, 
                    WAIT_LOOP = 9;

    //where is SPI reading from
    parameter NONE=0,KEY=1,NRT=2,MSG=3,RESULT=4;


 always_ff @(posedge d.clk) begin
        if(d.rst) begin
            state<='b0;
            count <= 0;
            
            /* modexp */
            modexp_startInput <= 1'b0;
            modexp_startCompute <= 1'b0;
            modexp_getResult <= 1'b0;
            modexp_loadNext<= 1'b0;
            modexp_read <= 1'b0;
            /* end modexp */       
            
            /* spi */
            spi_option <= NONE;
            spi_write <= 'b0;
            spi_write_data <= 'b0;
            /* end spi */


            /* aes */
            aes_in <= 'b0;
            aes_key <= 'b0;
            /* end aes */     

            /* kbd */
            kbd <= 'b0;


            /* top */
            /* end top */


        end else begin
        case(state)
            //Status : done
            WAIT_START: begin //Wait until we get the signal to start
                if(d.start) begin
                    state <= READ_RSA;
                    spi_option<=KEY;
                    count <= 0;
                end
            end




            //Status : done
            READ_RSA: begin 
                //spi from SD to encrypted_e
                if(spi_read && count < 64) begin
                    encrypted_e[count] <= spi_read_data;
                    count <= count + 1;
                end else if(count == 64) begin
                    //do nothing
                    state <= READ_KBD;
                    spi_option<=NONE;
                    count<=0;
                end
            end




            //Status : check //TODO
            READ_KBD: begin 
                if(d.kbd_done && d.kbd_valid_i) begin
                    //pad zeros up to 448 FIXME for new hash, this is for md5 (almost the same)
                    state<=HASH;
                    count <= 0;
                end else if(d.kbd_valid_i && !d.kbd_done && !d.kbd_reset) begin //don't buffer the enter key
                    kbd[(8*count)+:8] <= d.kbd_data_i; 
                    count <= count + 1;
                end else if(d.kbd_valid_i && d.kbd_reset) begin
                    kbd <= 'b0; //reset buffer
                    count <= 0;
                end //else do nothing
            end
            



            //Status : //TODO
            HASH: begin
                //at end set key = result
                state <= AES; 
                // if(md5_start==1'b1) begin
                //     md5_start<=1'b0;
                // end

                // if(md5_done && running && !md5_start) begin
                //     state <= 2'b10;
                //     count <= 0;
                //     hash <= aes_key;
                //     data <= encrypted_hash;
                //     running <= 1'b0;
                // end else begin
                //     if(count==16 && !running) begin
                //         md5_start <= 1'b1;
                //         md5_wa <= 'b0;
                //         md5_data <= 'b0;
                //         md5_w <= 1'b0;
                //         running <= 1'b1;
                //     end else if(count <16) begin
                //     /* push data into md5 */
                //         md5_wa <= count[3:0];
                //         md5_data <= kbd[count];
                //         md5_w <= 1'b1;
                //         count <= count + 1;
                //     end
                // end
            end
            



            //Status : check
            AES: begin //38 cycles to do AES, 32 rounds to process full 4096 bits
                //count from 0 to 31 inputs RSA key
                //then count from 0 to 5 waits (32 to 38)
                //then count from 0 to 31 reads out RSA key
                if(count <64) begin //send pipelined to AES
                    aes_in <= {encrypted_e[count], encrypted_e[count+1]}; 
                    count <= count + 2;
                end else if (count <68) begin //still waiting for results
                    //do nothing
                    count <= count + 1;
                end else if (count == 68) begin //still waiting for results
                    modexp_read <= 1'b1;
                    modexp_startInput <= 1'b1;
                    count <= count + 1;
                end else if(count < 101) begin //read out results to modexp
                    e_buf <= aes_out;
                    modexp_read <= 1'b1;
                    modexp_startInput <= 1'b1;
                    count <= count + 1;
                end else begin
                    state <= READ_NRTNP;
                    spi_option <= NRT;
                    modexp_read <= 1'b0;
                    count <= 0;
                end
            end
            



            //Status : check
            READ_NRTNP: begin
                if(count == 100) begin
                    state <= READ_MSG;
                    spi_option<=MSG;
                    count <= 0;
                end
                else if(spi_read) begin
                    if(count<32) begin
                        n_buf <= spi_read_data;
                        modexp_read <= 1'b1;
                    end else if(count == 32) begin
                        //state switch
                        modexp_read <= 1'b0;
                    end else if(count < 65 ) begin
                        r_buf <= spi_read_data;
                        modexp_read <= 1'b1;
                    end else if(count == 65) begin
                        //state switch
                        modexp_read <= 1'b0;
                    end else if(count <98) begin
                        t_buf <= spi_read_data;
                        modexp_read <= 1'b1;
                    end else if(count == 98) begin
                        //state switch
                        modexp_read <= 1'b0;
                    end else if(count <100) begin
                        nprime0_buf <= spi_read_data;
                        modexp_read <= 1'b1;
                    end else begin
                        //state switch
                        //UNREACHABLE
                    end
                    count <= count + 1;
                end else begin
                    modexp_read <= 1'b0;
                end
            end            



            //Status : check
            READ_MSG: begin
                if(count == 32) begin
                    state <= RSA;
                    count <= 0;
                    modexp_startInput <= 1'b0;
                    modexp_startCompute <= 1'b1;
                    spi_option<=NONE;
                end
                else if(spi_read) begin
                    m_buf <= spi_read_data; //FIXME
                    modexp_read <= 1'b1;
                    count <= count + 1;
                end else begin
                    //do nothing, not valid in 
                    modexp_read <= 1'b0;

                end
            end
            



            //Status : done
            RSA: begin
                //do modexp
                if(modexp_state == 13) begin //ready to be read
                    modexp_startCompute <= 1'b0;
                    modexp_getResult <= 1'b1;
                    state <= SEND;
                    spi_option <= RESULT;
                end else begin
                    //do nothing, rsa still going on 

                end
            end
            



            //Status : done 
            SEND: begin
                if(count == 64) begin
                    count <= 0;
                    spi_write <= 1'b0;
                    state <= WAIT_LOOP;
                end else begin 
                    spi_write_data <= modexp_out;
                    spi_write <= 1'b1;
                    count <= count + 1;
                end
            end


            
            //Status : done
            WAIT_LOOP: begin
                if(d.next) begin
                    state <= READ_MSG;
                end
            end
            
        endcase
        end
    end


endmodule
