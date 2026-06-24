// `default_nettype none
`timescale 1ns / 1ps

module serial_sequencer
   #(parameter PC_WIDTH=9,
     parameter INSN_WIDTH=72,
     parameter REG_PER_INSN=(INSN_WIDTH+31)/32,
     parameter ITER_WIDTH=16,
     parameter DEPTH_WIDTH=PC_WIDTH,
     parameter SEQ_REGS=REG_PER_INSN+7)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_regs,
     output logic [INSN_WIDTH-1:0] o_insn_rd,

     output logic o_active,
     output logic [ITER_WIDTH-1:0] o_iters,
     output logic [DEPTH_WIDTH-1:0] o_depth,

     output logic [PC_WIDTH-1:0] o_pc,
     output logic [INSN_WIDTH-1:0] o_insn,
     input  logic i_next,
     output logic o_empty,
     input  logic [INSN_WIDTH-1:0] i_insn_modified);

    logic w_propagate;

    /************
    * imem store
    ************/

    localparam ILDST_ADDR_REG = 0;
    localparam IST_REG_LO = ILDST_ADDR_REG + 1;
    localparam IST_REG_HI = IST_REG_LO + REG_PER_INSN - 1;
    localparam IST_STRB_REG = IST_REG_HI + 1;

    logic [PC_WIDTH-1:0] w_ildst_addr;
    logic [INSN_WIDTH-1:0] w_ist;
    logic w_ist_strb, w_ist_wr;

    assign w_ildst_addr = i_regs[ILDST_ADDR_REG][PC_WIDTH-1:0];
    assign w_ist = {i_regs[IST_REG_LO:IST_REG_HI]}[INSN_WIDTH-1:0];
    assign w_ist_strb = i_regs[IST_STRB_REG][0];

    edge_detector IWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_ist_strb),
        .o_posedge(w_ist_wr),
        .o_negedge()
    );

    /***********
    * imem load 
    ***********/

    localparam ILD_STRB_REG = IST_STRB_REG + 1;

    logic w_ild_strb, w_ild_rd;

    assign w_ild_strb = i_regs[ILD_STRB_REG][0];

    edge_detector IRD (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_ild_strb),
        .o_posedge(w_ild_rd),
        .o_negedge()
    );

    /**********
    * pc stage
    **********/

    localparam ITERS_REG = ILD_STRB_REG + 1;
    localparam DEPTH_REG = ITERS_REG + 1;
    localparam START_STRB_REG = DEPTH_REG + 1;
    localparam HALT_STRB_REG = START_STRB_REG + 1;

    logic [ITER_WIDTH-1:0] w_iters;
    logic [DEPTH_WIDTH-1:0] w_depth;
    logic w_start_strb;
    logic w_halt_strb;

    assign w_iters = i_regs[ITERS_REG][ITER_WIDTH-1:0];
    assign w_depth = i_regs[DEPTH_REG][DEPTH_WIDTH-1:0];
    assign w_start_strb = i_regs[START_STRB_REG][0];
    assign w_halt_strb = i_regs[HALT_STRB_REG][0];

    typedef struct {
        logic [PC_WIDTH-1:0] r_pc;
        logic [ITER_WIDTH-1:0] r_iters;
        logic [DEPTH_WIDTH-1:0] r_depth;
        logic r_active;
        logic w_start;
        logic w_halt;
    } pc_stg_t;

    pc_stg_t p;

    edge_detector STARTSEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_start_strb),
        .o_posedge(p.w_start),
        .o_negedge()
    );

    edge_detector HALTSEQ (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_halt_strb),
        .o_posedge(p.w_halt),
        .o_negedge()
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_pc <= 'b0;
            p.r_iters <= 'd0;
            p.r_depth <= 'd0;
            p.r_active <= 1'b0;
        end
        else if (p.w_halt) begin
            p.r_iters <= 'd0;
            p.r_active <= 1'b0;
        end
        else if (p.w_start && !p.r_active) begin
            p.r_pc <= 'h0;
            p.r_iters <= w_iters;
            p.r_depth <= w_depth;
            p.r_active <= 1'b1;
        end
        else if (w_propagate) begin

            if (p.r_iters > 'd0) begin
                p.r_pc <= (p.r_pc < p.r_depth) ? (p.r_pc + 'd1) : 'd0;
                p.r_iters <= (p.r_pc < p.r_depth) ? p.r_iters : p.r_iters - 'd1;
                p.r_active <= !(p.r_iters == 'd1 && !(p.r_pc < p.r_depth));
            end
            
        end
    end

    assign o_active = p.r_active;
    assign o_iters = p.r_iters;
    assign o_depth = p.r_depth;

    /************
    * insn stage
    ************/

    typedef struct {
        logic [PC_WIDTH-1:0] r_pc;
        logic r_pc_valid;
    } insn_stg_t;

    insn_stg_t i;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            i.r_pc <= 'h0;
            i.r_pc_valid <= 1'b0;
        end
        else if (w_propagate) begin
            i.r_pc <= p.r_pc;
            i.r_pc_valid <= (p.r_iters > 'd0);
        end
    end

    /***********
    * out stage
    ***********/

    typedef struct {
        logic [PC_WIDTH-1:0] r_pc;
        logic [INSN_WIDTH-1:0] w_insn;
        logic [INSN_WIDTH-1:0] r_insn;
        logic r_insn_buffered;
        logic [INSN_WIDTH-1:0] w_insn2use;
        logic r_insn_valid;
    } output_stg_t;

    output_stg_t o;

    logic w_imem_wr;
    logic [PC_WIDTH-1:0] w_imem_wr_addr;
    logic [INSN_WIDTH-1:0] w_imem_wr_data;

    logic [PC_WIDTH-1:0] w_imem_rd_addr;
    logic [INSN_WIDTH-1:0] w_imem_rd_data;

    bram #(
        .DATA_WIDTH(INSN_WIDTH),
        .ADDR_WIDTH(PC_WIDTH)
    ) IMEM (
        .i_clk_a(i_clk),
        .i_wr_a(w_imem_wr),
        .i_addr_a(w_imem_wr_addr),
        .i_din_a(w_imem_wr_data),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(1'b0),
        .i_addr_b(w_imem_rd_addr),
        .i_din_b(),
        .o_dout_b(w_imem_rd_data)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o.r_pc <= 'h0;
            o.r_insn <= 'h0;
            o.r_insn_buffered <= 1'b0;
            o.r_insn_valid <= 1'b0;
        end
        else if (w_propagate) begin
            o.r_pc <= i.r_pc;
            o.r_insn <= (i.r_pc_valid && o.r_insn_valid && (i.r_pc == o.r_pc)) ? i_insn_modified : 'h0;
            o.r_insn_buffered <= (i.r_pc_valid && o.r_insn_valid && (i.r_pc == o.r_pc));
            o.r_insn_valid <= i.r_pc_valid;
        end
        else begin
            if (o.r_insn_valid && !o.r_insn_buffered) begin
                o.r_insn <= o.w_insn;
                o.r_insn_buffered <= 1'b1;
            end
        end
    end

    assign o.w_insn = w_imem_rd_data;
    assign o.w_insn2use = o.r_insn_buffered ? o.r_insn : o.w_insn;

    /******************
    * pcmem imem write
    ******************/

    always_comb begin
        if (!p.r_active) begin
            w_imem_wr = w_ist_wr;
            w_imem_wr_addr = w_ildst_addr;
            w_imem_wr_data = w_ist;

            w_imem_rd_addr = w_ildst_addr;
        end
        else begin
            w_imem_wr = i_next && !o_empty;
            w_imem_wr_addr = o_pc;
            w_imem_wr_data = i_insn_modified;

            w_imem_rd_addr = i.r_pc;
        end
    end

    /*****************
    * propagate logic
    *****************/

    assign w_propagate = (o.r_insn_valid && i_next) || (!o.r_insn_valid && (i.r_pc_valid || p.r_active));

    /****************
    * output signals
    ****************/

    assign o_pc = o.r_pc;
    assign o_insn = o.w_insn2use;
    assign o_empty = !o.r_insn_valid;

    always_ff @(posedge i_clk) begin
        if (i_rst)
            o_insn_rd <= 'h0;
        else if (w_ild_rd)
            o_insn_rd <= w_imem_rd_data;
    end

endmodule
