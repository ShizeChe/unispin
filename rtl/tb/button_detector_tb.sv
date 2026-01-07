`default_nettype none

module button_detector_tb;

    localparam NUM_CYCLES = 10;
    localparam NUM_BUTTONS = 2;

    logic w_clk, w_rst;
    logic w_btn1, w_btn2;
    logic w_pressed1, w_pressed2;

    button_detector #(
        .NUM_CYCLES(NUM_CYCLES),
        .NUM_BUTTONS(NUM_BUTTONS)
    ) DUT (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_btn({w_btn1, w_btn2}),
        .o_pressed({w_pressed1, w_pressed2})
    );

    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin

        w_btn1 = 1'b0;
        w_btn2 = 1'b0;

        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

        repeat (10) begin
            @(negedge w_clk);
            w_btn1 = !w_btn1;
        end

        w_btn1 = 1'b0;

        repeat (3) begin
            w_btn1 = 1'b1;
            #50;
            w_btn1 = 1'b0;
            #($urandom_range(0, 50));
        end

        repeat (10) begin
            @(negedge w_clk);
            w_btn2 = !w_btn2;
        end

        w_btn2 = 1'b0;

        repeat (3) begin
            w_btn2 = 1'b1;
            #50;
            w_btn2 = 1'b0;
            #($urandom_range(0, 50));
        end

    end

endmodule
