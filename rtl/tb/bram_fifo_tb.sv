`timescale 1ns / 1ps

module fifo_tb;

    localparam WIDTH = 128;
    localparam ADDR_WIDTH = 8;
    localparam DEPTH = 2 ** ADDR_WIDTH;

    logic             i_clk, i_rst;
    logic [WIDTH-1:0] i_data;
    logic             i_enq;
    logic             i_deq;
    logic [WIDTH-1:0] o_data;
    logic             o_full, o_empty;
    logic [ADDR_WIDTH:0] o_num_data;

    bram_fifo #(WIDTH, ADDR_WIDTH) dut(.*);

    logic [WIDTH-1:0] randarray [DEPTH];
    logic [WIDTH-1:0] queue [$:DEPTH];

    localparam NUM_ITER = 10000;
    integer iter, length, i, whatToDo, delay;

    logic [WIDTH-1:0] randdata, data;

    initial begin
        i_clk = 1'b0;
        forever #5 i_clk = !i_clk;
    end

    initial begin

        $display("Performing reset...");

        i_rst = 1'b1;
        @(negedge i_clk);
        i_rst = 1'b0;

        $display("Finished reset...");

        $display("Initialize input signals...");

        i_data = 'd0;
        i_enq = 1'b0;
        i_deq = 1'b0;

        $display("Random enqueue all dequeue all test starts...");

        for (iter = 0; iter < NUM_ITER; iter++) begin

            randomize(length) with {
                length >= 1 && length <= DEPTH;
            };

            randomize(randarray);

            i = 0;
            while (i < length) begin
                i_data = randarray[i];
                i_enq = 1'b1;
                @(negedge i_clk);
                i = i + 1;
            end

            i_data = 'd0;
            i_enq = 1'b0;

            i = 0;
            while (i < length) begin
                i_deq = 1'b1;
                @(negedge i_clk);
                assert(o_data == randarray[i]) else begin
                    $fatal(1, "deque value incorrect");
                end
                i = i + 1;
            end

            i_deq = 1'b0;
        
        end

        $display("Finished random enqueue all dequeue all tests...");

        $display("Random enqueue all dequeue all with random delays test starts...");

        for (iter = 0; iter < NUM_ITER; iter++) begin

            randomize(length) with {
                length >= 1 && length <= DEPTH;
            };

            randomize(randarray);

            i = 0;
            while (i < length) begin
                i_data = randarray[i];
                i_enq = 1'b1;
                @(negedge i_clk);
                i_enq = 1'b0;
                randomize(delay) with {
                    delay >= 0 && delay <= 100;
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
                @(negedge i_clk);
                assert(o_data == randarray[i]) else begin
                    $fatal(1, "deque value incorrect");
                end
                i_deq = 1'b0;
                randomize(delay) with {
                    delay >= 0 && delay <= 100;
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
                    $fatal(1, "o_empty not flagged when fifo is suppose to be empty");
                end

                i_enq = 1'b1;
                randomize(randdata);
                i_data = randdata;

                queue.push_back(randdata);

                @(negedge i_clk);

                i_enq = 1'b0;

            end
            else if (queue.size == DEPTH) begin

                assert(o_full == 1'b1) else begin
                    $fatal(1, "o_full not flagged when fifo is suppose to be full");
                end

                data = queue.pop_front();
                i_deq = 1'b1;

                @(negedge i_clk);

                assert(o_data == data) else begin
                    $display(1, "dequeue incorrect");
                end

                i_deq = 1'b0;

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
                        @(negedge i_clk);
                        i_enq = 1'b0;
                    end
                    1: begin
                        data = queue.pop_front();
                        i_deq = 1'b1;
                        @(negedge i_clk);
                        assert(o_data == data) else begin
                            $fatal(1, "dequeue incorrect");
                        end
                        i_deq = 1'b0;
                    end
                    default: begin
                        i_enq = 1'b0;
                        i_deq = 1'b0;
                        i_data = 'd0;
                    end
                endcase
            end

            i++;

        end

        i = 0;

        while (queue.size() > 0) begin
            i_deq = 1'b1;
            data = queue.pop_front();
            @(negedge i_clk);
            assert(data == o_data) else begin
                $fatal(1, "dequeue incorrect");
            end
        end

        assert(o_empty == 1'b1) else begin
            $fatal(1, "o_empty not flagged when fifo is suppose to be empty");
        end

        $finish;

    end

endmodule
