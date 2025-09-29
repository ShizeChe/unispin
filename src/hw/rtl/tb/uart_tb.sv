module uart_tb;

    logic w_clk, w_rst;
    logic w_rx, w_tx;
    logic w_deq_rxq;
    logic [7:0] w_rxq_data;
    logic w_rxq_empty;
    logic w_enq_txq;
    logic [7:0] w_txq_data;
    logic w_txq_full;

    uart u (
        .i_clk(w_clk), 
        .i_rst(w_rst),

        .i_rx(w_rx),
        .o_tx(w_tx),

        .i_deq_rxq(w_deq_rxq),
        .o_rxq_data(w_rxq_data),
        .o_rxq_empty(w_rxq_empty),

        .i_enq_txq(w_enq_txq),
        .i_txq_data(w_txq_data),
        .o_txq_full(w_txq_full),

        /* verilator lint_off PINCONNECTEMPTY */
        .o_rxq_ae(),
        .o_rxq_full(),
        .o_rxq_af(),

        .o_txq_empty(),
        .o_txq_ae(),
        .o_txq_af()
    );

    initial begin
        w_clk = 1'b0;
        forever #5 w_clk = !w_clk;
    end

    initial begin
        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;
    end

    localparam NUM_ITERS = 100;
    localparam MAX_LEN = 100;
    localparam MAX_DELAY = 10000;

    localparam bit_duration = 8680.556;

    /* verilator lint_off UNUSEDSIGNAL */
    int pc_tsmt_which_bit;

    // pc->fpga
    task pc_tsmt (input logic [7:0] data);
        
        // start bit = 0
        w_rx = 1'b0;
        pc_tsmt_which_bit = -1;
        #bit_duration;

        // data bits
        for (int i = 0; i < 8; i++) begin
            w_rx = data[i];
            pc_tsmt_which_bit = i;
            #bit_duration;
        end

        // end bit = 1
        w_rx = 1'b1;
        pc_tsmt_which_bit = 8;
        #bit_duration;

    endtask

    logic [7:0] pc_sent [$];
    logic [7:0] fpga_received [$];
    initial begin
        pc_sent = {};
        fpga_received = {};
    end
    logic pc2fpga_done;

    int pc2fpga_delay;
    int pc2fpga_len;
    int pc2fpga_iter;

    /* verilator lint_off UNUSEDSIGNAL */
    int pc2fpga_data32;
    logic [7:0] pc2fpga_byte;

    initial begin

        pc2fpga_done = 1'b0;
        wait (w_rst == 1'b0);
        pc2fpga_iter = 1;

        repeat (NUM_ITERS) begin
            
            $display("At %0.3f ns: pc->fpga iteration%0d starts", $realtime, pc2fpga_iter);
        
            pc2fpga_delay = $urandom_range(0, MAX_DELAY);
            #pc2fpga_delay;

            pc2fpga_len = $urandom_range(1, MAX_LEN);
            repeat (pc2fpga_len) begin
                
                pc2fpga_data32 = $urandom_range(0, 255);
                pc2fpga_byte = pc2fpga_data32[7:0];
                pc_sent.push_back(pc2fpga_byte);
                pc_tsmt(pc2fpga_byte);

            end

            pc2fpga_iter++;
        
        end

        wait (fpga_received.size() == pc_sent.size());
        pc2fpga_done = 1'b1;

    end

    // fpga receive
    initial begin

        forever begin

            @(negedge w_clk);

            if (!w_rxq_empty) begin

                w_deq_rxq = 1'b1;
                fpga_received.push_back(w_rxq_data);

                foreach (fpga_received[i]) begin
                    assert (fpga_received[i] == pc_sent[i])
                    else $fatal("At %0.3f ns: [%0d] mismatch, fpga_received[%0d] = %0h, pc_sent[%0d] = %0h", 
                                  $realtime, i, i, fpga_received[i], i, pc_sent[i]);
                end

                for (int j = 0; j < fpga_received.size(); j++) begin
                    assert (fpga_received[j] == pc_sent[j])
                    else $fatal("At %0.3f ns: for loop [%0d] mismatch, fpga_received[%0d] = %0h, pc_sent[%0d] = %0h", 
                                  $realtime, j, j, fpga_received[j], j, pc_sent[j]);
                end

            end
            else
                w_deq_rxq = 1'b0;

        end

    end

    // fpga->pc
    logic [7:0] fpga_sent [$];
    logic [7:0] pc_received [$];

    initial begin
        fpga_sent = {};
        pc_received = {};
    end

    logic fpga2pc_done;

    int fpga2pc_delay;
    int fpga2pc_len;
    int fpga2pc_iter;

    /* verilator lint_off UNUSEDSIGNAL */
    int fpga2pc_data32;
    logic [7:0] fpga2pc_byte;

    int num_pushed;

    initial begin

        fpga2pc_done = 1'b0;
        w_enq_txq = 1'b0;
        w_txq_data = 'd0;

        wait (w_rst == 1'b0);
        fpga2pc_iter = 1;

        repeat (NUM_ITERS) begin

            $display("At %0.3f ns: fpga->pc iteration%0d starts", $realtime, fpga2pc_iter);
        
            fpga2pc_delay = $urandom_range(0, MAX_DELAY);
            #fpga2pc_delay;

            fpga2pc_len = $urandom_range(1, MAX_LEN);
            num_pushed = 0;

            while (num_pushed < fpga2pc_len) begin

                @(negedge w_clk);

                if (!w_txq_full) begin

                    fpga2pc_data32 = $urandom_range(0, 255);
                    fpga2pc_byte = fpga2pc_data32[7:0];

                    fpga_sent.push_back(fpga2pc_byte);

                    w_enq_txq = 1'b1;
                    w_txq_data = fpga2pc_byte;

                    num_pushed++;

                end
                else
                    w_enq_txq = 1'b0;

            end

            @(negedge w_clk);
            w_enq_txq = 1'b0;
            fpga2pc_iter++;

        end

        wait (pc_received.size() == fpga_sent.size());
        fpga2pc_done = 1'b1;

    end

    // pc receive
    logic [7:0] rx_data;

    task pc_recv;

        // start bit == 0
        @(negedge w_tx);
        #(bit_duration / 2);
        assert (w_tx == 1'b0)
        else $fatal("At %0.3f ns: o_tx didn't hold start bit as 0", $realtime);

        // data bits
        for (int i = 0; i < 8; i++) begin
            #bit_duration;
            rx_data[i] = w_tx;
        end

        // stop bit == 1
        #bit_duration;
        assert (w_tx == 1'b1)
        else $fatal("At %0.3f ns: o_tx didn't hold stop bit as 1", $realtime);

        pc_received.push_back(rx_data);

        foreach (pc_received[i]) begin
            assert (pc_received[i] == fpga_sent[i])
            else $fatal("At %0.3f ns: [%0d] mismatch, pc_received[%0d] = %0h, fpga_sent[%0d] = %0h", 
                          $realtime, i, i, pc_received[i], i, fpga_sent[i]);
        end

        for (int j = 0; j < pc_received.size(); j++) begin
            assert (pc_received[j] == fpga_sent[j])
            else $fatal("At %0.3f ns: for loop [%0d] mismatch, pc_received[%0d] = %0h, fpga_sent[%0d] = %0h", 
                          $realtime, j, j, pc_received[j], j, fpga_sent[j]);
        end

    endtask

    initial begin

        wait (w_rst == 1'b0);

        forever pc_recv;

    end

    // check done
    initial begin

        wait (pc2fpga_done && fpga2pc_done);

        #100;
        $finish;

    end

endmodule
