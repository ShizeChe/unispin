`timescale 1ns / 1ps

module tb;

    localparam WIDTH = 8;
    localparam DEPTH = 20;

    logic             i_clk, i_rst;
    logic [WIDTH-1:0] i_data;
    logic             i_enq;
    logic             i_deq;
    logic [WIDTH-1:0] o_data;
    logic             o_full, o_empty;
    logic             o_almost_full;
    logic             o_almost_empty;

    fifo #(WIDTH, DEPTH, 16, 4) dut(.*);

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0);
    end

    logic [7:0] randarray [8];
    logic [WIDTH-1:0] queue [$:DEPTH];

    localparam NUM_ITER = 10000;
    integer iter, length, i, whatToDo, delay;

    logic [7:0] randdata, data;

    logic [WIDTH-1:0] fifo_logical [DEPTH];

    generate
        for (genvar g = 0; g < DEPTH; g++) begin: fifo_logical_assign
            always_comb begin
                if (g < dut.q_num_data) begin
                    fifo_logical[g] = dut.q_data[({1'b0, dut.q_deq_ptr} + g) % DEPTH];
                end
                else begin
                    fifo_logical[g] = 'd0;
                end
            end
        end
    endgenerate

    logic [WIDTH-1:0] queue_logical [DEPTH];

    generate
        for (genvar g = 0; g < DEPTH; g++) begin: queue_logical_assign
            always_ff @(posedge i_clk) begin
                if (g < queue.size()) begin
                    queue_logical[g] <= queue[g];
                end
                else begin
                    queue_logical[g] <= 'd0;
                end
            end
        end
    endgenerate

    initial begin
        i_clk = 1'b1;
        forever #5 i_clk = !i_clk;
    end

    initial begin

        $display("Performing reset...");

        i_rst = 1'b1;
        @(posedge i_clk);
        i_rst <= 1'b0;

        $display("Finished reset...");

        $display("Initialize input signals...");

        i_data = 'd0;
        i_enq = 1'b0;
        i_deq = 1'b0;

        $display("Random enqueue all dequeue all test starts...");

        for (iter = 0; iter < NUM_ITER; iter++) begin

            randomize(length) with {
                length >= 1 && length <= 8;
            };

            randomize(randarray);

            i = 0;
            while (i < length) begin
                i_data = randarray[i];
                i_enq = 1'b1;
                @(posedge i_clk);
                #1;
                i = i + 1;
            end

            i_data = 'd0;
            i_enq = 1'b0;

            i = 0;
            while (i < length) begin
                i_deq = 1'b1;
                assert(o_data == randarray[i]) else begin
                    $display("deque value incorrect");
                end
                @(posedge i_clk);
                #1;
                i = i + 1;
            end

            i_deq <= 1'b0;
        
        end

        $display("Finished random enqueue all dequeue all tests...");

        $display("Random enqueue all dequeue all with random delays test starts...");

        for (iter = 0; iter < NUM_ITER; iter++) begin

            randomize(length) with {
                length >= 1 && length <= 8;
            };

            randomize(randarray);

            i = 0;
            while (i < length) begin
                i_data = randarray[i];
                i_enq = 1'b1;
                @(posedge i_clk);
                @(negedge i_clk);
                i_enq = 1'b0;
                randomize(delay) with {
                    delay >= 0 && delay <= 1000;
                };
                #delay;
                @(negedge i_clk);
                i = i + 1;
            end

            i_data = 'd0;
            i_enq = 1'b0;

            i = 0;
            while (i < length) begin
                i_deq = 1'b1;
                assert(o_data == randarray[i]) else begin
                    $display("deque value incorrect");
                end
                @(posedge i_clk);
                @(negedge i_clk);
                i_deq = 1'b0;
                randomize(delay) with {
                    delay >= 0 && delay <= 1000;
                };
                #delay;
                @(negedge i_clk);
                i = i + 1;
            end

            i_deq = 1'b0;
        
        end

        $display("Finished enqueue all dequeue all with random delays test starts...");

        $display("Random enqueue dequeue test starts...");

        i = 0;

        while (i < NUM_ITER) begin

            if (queue.size() == 0) begin

                assert(o_empty == 1'b1) else begin
                    $display("o_empty not flagged when fifo is suppose to be empty");
                end

                i_enq = 1'b1;
                randomize(randdata);
                i_data = randdata;

                queue.push_back(randdata);

            end
            else if (queue.size == DEPTH) begin

                assert(o_full == 1'b1) else begin
                    $display("o_full not flagged when fifo is suppose to be full");
                end

                data = queue.pop_front();
                assert(o_data == data) else begin
                    $display("dequeue incorrect");
                end

                i_deq = 1'b1;
            end
            else begin

                randomize(whatToDo) with {
                    0 <= whatToDo && whatToDo <= 2;
                };

                case (whatToDo)
                    0: begin
                        i_enq = 1'b1;
                        randomize(randdata);
                        i_data = randdata;
                        queue.push_back(randdata);
                    end
                    1: begin
                        data = queue.pop_front();
                        assert(o_data == data) else begin
                            $display("dequeue incorrect");
                        end
                        i_deq = 1'b1;
                    end
                    default: begin
                        i_enq = 1'b0;
                        i_deq = 1'b0;
                        i_data = 'd0;
                    end
                endcase
            end

            @(posedge i_clk);
            @(negedge i_clk);

            i_enq = 1'b0;
            i_deq = 1'b0;
            i_data = 'd0;
            i++;
        end

        i = 0;

        while (queue.size() > 0) begin
            i_deq = 1'b1;
            data = queue.pop_front();
            assert(data == o_data) else begin
                $display("dequeue incorrect");
            end
            @(posedge i_clk);
            @(negedge i_clk);
        end

        assert(o_empty == 1'b1) else begin
            $display("o_empty not flagged when fifo is suppose to be empty");
        end

        $finish;

    end

endmodule
