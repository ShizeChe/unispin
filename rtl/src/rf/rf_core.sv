// `default_nettype none
`timescale 1ns / 1ps
`include "rf.svh"

module rf_core
   #(parameter KBC_WIDTH=RF_KBC_WIDTH,
     parameter NUM_SAMPLE_WIDTH=RF_NUM_SAMPLE_WIDTH,
     parameter INSN_WIDTH=RF_INSN_WIDTH,
     parameter IQ_WIDTH=RF_IQ_WIDTH,
     parameter DAC_WIDTH=RF_DAC_WIDTH,
     parameter PHASE_WIDTH=RF_PHASE_WIDTH,
     parameter CORDIC_STAGES=RF_CORDIC_STAGES,
     parameter CORDIC_PAD_ZEROS=RF_CORDIC_PAD_ZEROS,
     parameter DEPTH=RF_DEPTH,
     parameter BUFFER_STAGES=RF_BUFFER_STAGES)
    (input  logic i_clk, i_rst,
     
     // sequencer interface
     input  logic [$clog2(DEPTH)-1:0] i_addr,
     input  rf_insn_t i_insn,
     output logic o_next,
     input  logic i_empty,
     output rf_insn_t o_insn_modified,

     // control interface
     input  rf_ctrl_t i_ctrl,
     
     // rfdac interface
     output logic [DAC_WIDTH*16-1:0] o_QIx8,

     // launcher interface
     input  logic i_start,
     output logic o_armed,

     // pipeline empty flag
     output logic o_empty,

     // marker bit
     output logic o_marker,

     // eop for verification
     output rf_eop_t o_eop);

    logic w_stall;

    /**************
    * decode stage
    **************/

    rf_decode_stg_t d;

    rf_decode #(
        .DEPTH(DEPTH)
    ) DECODER (
        .i_addr(i_addr),
        .i_insn(i_insn),
        .d(d),
        .o_insn_modified(o_insn_modified)
    );

    /**************
    * buffer stage
    **************/

    rf_buffer_stg_t b [0:BUFFER_STAGES-1];

    rf_phase_stg_t p;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            b[0] <= '{
                r_addr: 'bx,
                r_valid: 1'b0,
                r_k: 'bx,
                r_b: 'bx,
                r_c: 'bx,
                r_samples: 'd0,
                r_arm: 1'b0,
                r_idle: 1'b1,
                r_set_phasor: 1'b0,
                r_marker: 1'b0
            };
        end
        else if (!w_stall && p.r_samples_left <= 'd8) begin
            b[0] <= '{
                r_addr: i_empty ? 'bx : d.w_addr,
                r_valid: !i_empty,
                r_k: i_empty ? 'b0 : d.w_k,
                r_b: i_empty ? 'b0 : d.w_b,
                r_c: i_empty ? 'b0 : d.w_c,
                r_samples: i_empty ? 'd0 : d.w_samples,
                r_arm: i_empty ? 'd0 : d.w_arm,
                r_idle: i_empty ? 'd0 : d.w_idle,
                r_set_phasor: i_empty ? 1'b0 : d.w_set_phasor,
                r_marker: i_empty ? 1'b0 : d.w_marker
            };
        end
    end

    assign o_next = !w_stall && (p.r_samples_left <= 'd8) && !i_empty;

    for (genvar i = 1; i < BUFFER_STAGES; i++) begin : BUFFER_GEN
        always_ff @(posedge i_clk) begin
            if (i_rst) begin
                b[i] <= '{
                    r_addr: 'bx,
                    r_valid: 1'b0,
                    r_k: 'bx,
                    r_b: 'bx,
                    r_c: 'bx,
                    r_samples: 'd0,
                    r_arm: 1'b0,
                    r_idle: 1'b1,
                    r_set_phasor: 1'b0,
                    r_marker: 1'b0
                };
            end
            else if (!w_stall && p.r_samples_left <= 'd8) begin
                b[i] <= b[i - 1];
            end
        end
    end

    rf_buffer_stg_t bf;
    assign bf = b[BUFFER_STAGES-1];

    /*************
    * phase stage
    *************/

    logic w_new_phase;
    assign w_new_phase = !w_stall && (p.r_samples_left <= 'd8) && bf.r_valid && bf.r_set_phasor;

    rf_phasor #(
        .IW(PHASE_WIDTH*2),
        .OW(PHASE_WIDTH)
    ) PHASOR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_set(w_new_phase),
        .i_k(bf.r_k),
        .i_b(bf.r_b),
        .i_c(bf.r_c),
        .o_p(p.w_phasex8),
        .i_stall(w_stall)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_addr <= 'bx;
            p.r_samples <= 'bx;
            p.r_samples_left <= 'd0;
            p.r_arm <= 1'b0;
            p.r_idle <= 1'b0;
            p.r_marker <= 1'b0;
        end
        else if (!w_stall) begin

            if (p.r_samples_left > 'd8) begin
                p.r_arm <= 1'b0;
                p.r_samples_left <= p.r_samples_left - 'd8;
            end
            else if (bf.r_valid) begin
                p.r_addr <= bf.r_addr;
                p.r_samples <= bf.r_samples;
                p.r_samples_left <= bf.r_samples;
                p.r_arm <= bf.r_arm;
                p.r_idle <= bf.r_idle;
                p.r_marker <= bf.r_marker;
            end
            else begin
                p.r_arm <= 1'b0;
                p.r_samples_left <= 'd0;
                p.r_marker <= 1'b0;
            end

        end
    end

    assign p.w_zerox8 = p.r_idle ? 8'hff : ~((8'b1 << p.r_samples_left) - 8'd1);

    /*************************
    * cordic and result stage
    **************************/

    rf_result_stg_t r [0:7];

    for (genvar i = 0; i < 8; i++) begin : CORDIC_GEN

        rf_cordic #(
            .PHASE_WIDTH(PHASE_WIDTH),
            .IQ_WIDTH(IQ_WIDTH),
            .NUM_STAGES(CORDIC_STAGES),
            .PAD_ZEROS(CORDIC_PAD_ZEROS),
            .INDEX(i)
        ) CORDIC (
            .i_clk(i_clk),
            .i_rst(i_rst),
            .p(p),
            .r(r[i]),
            .i_stall(w_stall)
        );

    end

    logic [$clog2(DEPTH)-1:0] w_addr;
    logic [NUM_SAMPLE_WIDTH-1:0] w_sample_start, w_sample_end;
    logic [DAC_WIDTH*16-1:0] w_QIx8;

    rf_format #(
        .NUM_SAMPLE_WIDTH(NUM_SAMPLE_WIDTH),
        .DAC_WIDTH(DAC_WIDTH),
        .DEPTH(DEPTH)
    ) FMT (
        .r(r),
        .i_ctrl(i_ctrl),
        .o_addr(w_addr),
        .o_sample_start(w_sample_start),
        .o_sample_end(w_sample_end),
        .o_QIx8(w_QIx8)
    );

    /**************
    * output stage
    **************/

    rf_output_stg_t o;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o.r_addr <= 'bx;
            o.r_sample_start <= 'bx;
            o.r_sample_end <= 'bx;
            o.r_QIx8 <= 'h0;
            o.r_marker <= 1'b0;
        end
        else if (!w_stall) begin
            o.r_addr <= w_addr;
            o.r_sample_start <= w_sample_start;
            o.r_sample_end <= w_sample_end;
            o.r_QIx8 <= w_QIx8;
            o.r_marker <= |{r[0].r_marker, r[1].r_marker, r[2].r_marker, r[3].r_marker,
                            r[4].r_marker, r[5].r_marker, r[6].r_marker, r[7].r_marker};
        end
    end

    /*************
    * stall logic
    *************/

    assign w_stall = (o_armed && !i_start); 

    /****************
    * output signals
    ****************/

    assign o_QIx8 = o.r_QIx8;

    assign o_marker = o.r_marker;

    assign o_armed = |{r[0].r_arm, r[1].r_arm, r[2].r_arm, r[3].r_arm,
                       r[4].r_arm, r[5].r_arm, r[6].r_arm, r[7].r_arm};

    assign o_empty = i_empty && p.r_samples_left == 'd0 &&
        (&{r[0].r_bubble, r[1].r_bubble, r[2].r_bubble, r[3].r_bubble,
           r[4].r_bubble, r[5].r_bubble, r[6].r_bubble, r[7].r_bubble});

    assign o_eop = '{
        w_addr: o.r_addr,
        w_sample_start: o.r_sample_start,
        w_sample_end: o.r_sample_end,
        w_marker: o.r_marker
    };

endmodule
