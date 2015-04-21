class transaction;
    // vars
    bit [127:0] result [31:0]; 
    int which;

    function void reset_environment();
        for(int i = 0; i<32; i++) begin
            result[i] = 0;
        end
        which = 0;
    endfunction


    // Checking the reset functionality
    function bit check_reset(logic [3:0] state);
        reset_environment();
        return((state == 0));
    endfunction 
    
    function bit check_read_rsa(logic [3:0] state, int count);
        return 0;
    endfunction

    function bit check_read_kbd(logic [3:0] state, int count, bit[7:0] kbd,
        bit reset, bit valid, bit enter);
        return 0;
    endfunction
    
    function bit check_hash(logic [3:0] state, int count);
        return 0;
    endfunction
    
    function bit check_aes(logic [3:0] state, int count);
        return 0;
    endfunction
    
    function bit check_read_nrtnp(logic [3:0] state, int count);
        return 0;
    endfunction
    
    function bit check_read_msg(logic [3:0] state, int count);
        return 0;
    endfunction
    
    function bit check_rsa(logic [3:0] state, int count);
        return 0;
    endfunction

    function bit check_send(logic [3:0] state, int count, logic [127:0] out);
        return 0;
    endfunction
    
    function bit check_wait_loop(logic [3:0] state, int count);
        return 0;
    endfunction

    function void transmit(logic [127:0] data);

    endfunction

    function void calculateResult();

    endfunction

    function bit[127:0] getResult();
        return result[which];
    endfunction

    
endclass 



class testing_env;
    //random number for probabilistic data
    rand int unsigned rn;

    /* DUT inputs */
    rand bit [7:0] ps2_data;
    

    bit sd_spi_i;
    bit sw1_spi_i;
    bit sw2_spi_i;
    bit start;
    bit next;
    bit reset;
    /* end dut inputs 

    /* probabilistic data */
    int reset_thresh; //reset probability
    int ps2_thresh; //ps2 data valid probability

    int iter;

    function void read_config(string filename);
        int file, chars_returned, seed, value;
        string param;
        file = $fopen(filename, "r");

        while(!$feof(file)) begin
            chars_returned = $fscanf(file, "%s %d", param, value);
            if("RANDOM_SEED" == param) begin
                seed = value;
                $srandom(seed);
            end else if("ITERATIONS" == param) begin
                iter = value;
            end else if("RESET_PROB" == param) begin
                reset_thresh = value;
            end else if("PS2_PROB" == param) begin
                ps2_thresh = value;
            end
            else begin
                $display("Invalid parameter");
                $exit();
            end
        end
    endfunction

    function bit get_reset();
        return((rn%1000)<reset_thresh);
    endfunction

    function bit get_ps2();
        return((rn%1000)<ps2_thresh);
    endfunction

    function bit[7:0] get_char();
        return rn % 128;
    endfunction 


endclass




program mfe_tb (mfe_ifc.bench ds);

    transaction t; 
    testing_env v;

    int failures = 0; 
    bit reset;

    initial begin
        t = new();
        v = new();
        v.read_config("config.txt");

        // Drive inputs for next cycles
        // ds.cb.rst <= t.reset; 

        //manual force reset
        repeat(10) begin
            ds.cb.rst <= 1'b1;
            @(ds.cb);
        end
        ds.cb.rst <= 1'b0;
        @(ds.cb);

        // Iterate iter number of cycles 
        repeat (v.iter) begin

            //randomize vars
            v.randomize();

            //reseting
            if(v.get_reset()) begin
                ds.cb.rst <= 1'b1;
                $display("%t : %s \n", $realtime, "Driving Reset");
            end else begin
                ds.cb.rst <= 1'b0;
            end




            @(ds.cb);

            if(v.get_reset()) begin    
                $display("%t \t state: %d \t status: %s \n", $realtime,ds.cb.state_debug, t.check_reset(ds.cb.state_debug)?"Pass-reset":"Fail-reset");
                ds.cb.rst <= 1'b0;
            end else begin

            end


            //TODO: Test whether results are as expected (golden_output)
        end

    end
endprogram



/*

ps2_key generates random key sequence

password correctness feedback 

*/

