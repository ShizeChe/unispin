// `default_nettype none
`timescale 1ns / 1ps

module bram_sequencer
   #(parameter PC_ADDR_WIDTH=12,
     parameter PC_WIDTH=9,
     parameter INSN_WIDTH=115,
     parameter REG_PER_INSN=(INSN_WIDTH+31)/32,
     parameter ITER_WIDTH=16,
     parameter DEPTH_WIDTH=PC_ADDR_WIDTH,
     parameter SEQ_REGS=REG_PER_INSN+11)
    (input  logic i_clk, i_rst,

     input  logic [0:SEQ_REGS-1][31:0] i_regs,
     output logic o_active,
     output logic [ITER_WIDTH-1:0] o_iters,
     output logic [DEPTH_WIDTH-1:0] o_pcmem_depth,
     output logic [PC_WIDTH-1:0] o_pc_rd,
     output logic [INSN_WIDTH-1:0] o_insn_rd,

     output logic [PC_ADDR_WIDTH-1:0] o_pc_addr,
     output logic [PC_WIDTH-1:0] o_pc,
     output logic [INSN_WIDTH-1:0] o_insn,
     input  logic i_next,
     output logic o_empty,
     input  logic [INSN_WIDTH-1:0] i_insn_modified);

    logic w_propagate;

    /*************
    * pcmem store
    *************/

    localparam PCST_ADDR_REG = 0;
    localparam PCST_REG = PCST_ADDR_REG + 1;
    localparam PCST_STRB_REG = PCST_REG + 1;

    logic [PC_ADDR_WIDTH-1:0] w_pcldst_addr;
    logic [PC_WIDTH-1:0] w_pcst;
    logic w_pcst_strb, w_pcst_wr;

    assign w_pcldst_addr = i_regs[PCST_ADDR_REG][PC_ADDR_WIDTH-1:0];
    assign w_pcst = i_regs[PCST_REG][PC_WIDTH-1:0];
    assign w_pcst_strb = i_regs[PCST_STRB_REG][0];

    edge_detector PCWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_pcst_strb),
        .o_posedge(w_pcst_wr),
        .o_negedge()
    );

    /************
    * imem store
    ************/

    localparam IST_ADDR_REG = PCST_STRB_REG + 1;
    localparam IST_REG_LO = IST_ADDR_REG + 1;
    localparam IST_REG_HI = IST_REG_LO + REG_PER_INSN - 1;
    localparam IST_STRB_REG = IST_REG_HI + 1;

    logic [PC_WIDTH-1:0] w_ildst_addr;
    logic [INSN_WIDTH-1:0] w_ist;
    logic w_ist_strb, w_ist_wr;

    assign w_ildst_addr = i_regs[IST_ADDR_REG][PC_WIDTH-1:0];
    assign w_ist = {i_regs[IST_REG_LO:IST_REG_HI]}[INSN_WIDTH-1:0];
    assign w_ist_strb = i_regs[IST_STRB_REG][0];

    edge_detector IWR (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_ist_strb),
        .o_posedge(w_ist_wr),
        .o_negedge()
    );

    /**********
    * pc stage
    **********/

    localparam ITERS_REG      = IST_STRB_REG + 1;
    localparam DEPTH_REG      = ITERS_REG + 1;
    localparam START_STRB_REG = DEPTH_REG + 1;
    localparam HALT_STRB_REG  = START_STRB_REG + 1;
    localparam PCLD_STRB_REG  = HALT_STRB_REG + 1;
    localparam ILD_STRB_REG   = PCLD_STRB_REG + 1;

    logic [ITER_WIDTH-1:0] w_iters;
    logic [DEPTH_WIDTH-1:0] w_depth;
    logic w_start_strb, w_halt_strb;
    logic w_pcld_strb, w_pcld_rd;
    logic w_ild_strb, w_ild_rd;

    assign w_iters      = i_regs[ITERS_REG][ITER_WIDTH-1:0];
    assign w_depth      = i_regs[DEPTH_REG][DEPTH_WIDTH-1:0];
    assign w_start_strb = i_regs[START_STRB_REG][0];
    assign w_halt_strb  = i_regs[HALT_STRB_REG][0];
    assign w_pcld_strb  = i_regs[PCLD_STRB_REG][0];
    assign w_ild_strb   = i_regs[ILD_STRB_REG][0];

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
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

    edge_detector PCRD (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_pcld_strb),
        .o_posedge(w_pcld_rd),
        .o_negedge()
    );

    edge_detector IRD (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_signal(w_ild_strb),
        .o_posedge(w_ild_rd),
        .o_negedge()
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_pc_addr <= 'b0;
            p.r_iters <= 'd0;
            p.r_depth <= 'd0;
            p.r_active <= 1'b0;
        end
        else if (p.w_halt) begin
            p.r_iters <= 'd0;
            p.r_active <= 1'b0;
        end
        else if (p.w_start && !p.r_active) begin
            p.r_pc_addr <= 'h0;
            p.r_iters <= w_iters;
            p.r_depth <= w_depth;
            p.r_active <= 1'b1;
        end
        else if (w_propagate) begin

            if (p.r_iters > 'd0) begin
                p.r_pc_addr <= (p.r_pc_addr < p.r_depth) ? (p.r_pc_addr + 'd1) : 'd0;
                p.r_iters <= (p.r_pc_addr < p.r_depth) ? p.r_iters : p.r_iters - 'd1;
                p.r_active <= !(p.r_iters == 'd1 && !(p.r_pc_addr < p.r_depth));
            end

        end
    end

    assign o_active      = p.r_active;
    assign o_iters       = p.r_iters;
    assign o_pcmem_depth = p.r_depth;

    /************
    * insn stage
    ************/

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
        logic [PC_WIDTH-1:0] w_pc;
        logic [PC_WIDTH-1:0] r_pc;
        logic r_pc_buffered;
        logic [PC_WIDTH-1:0] w_pc2use;
        logic r_pc_valid;
    } insn_stg_t;

    insn_stg_t i;

    logic w_pcmem_wr;
    logic [PC_ADDR_WIDTH-1:0] w_pcmem_wr_addr;
    logic [PC_WIDTH-1:0] w_pcmem_wr_data;
    logic [PC_ADDR_WIDTH-1:0] w_pcmem_rd_addr;

    assign w_pcmem_rd_addr = p.r_active ? p.r_pc_addr : w_pcldst_addr;

    bram #(
        .DATA_WIDTH(PC_WIDTH),
        .ADDR_WIDTH(PC_ADDR_WIDTH)
    ) PCMEM (
        .i_clk_a(i_clk),
        .i_wr_a(w_pcmem_wr),
        .i_addr_a(w_pcmem_wr_addr),
        .i_din_a(w_pcmem_wr_data),
        .o_dout_a(),

        .i_clk_b(i_clk),
        .i_wr_b(1'b0),
        .i_addr_b(w_pcmem_rd_addr),
        .i_din_b({PC_WIDTH{1'b0}}),
        .o_dout_b(i.w_pc)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            i.r_pc_addr <= 'h0;
            i.r_pc <= 'h0;
            i.r_pc_buffered <= 1'b0;
            i.r_pc_valid <= 1'b0;
        end
        else if (w_propagate) begin
            i.r_pc_addr <= p.r_pc_addr;
            i.r_pc <= 'h0;
            i.r_pc_buffered <= 1'b0;
            i.r_pc_valid <= p.r_active;
        end
        else begin
            if (i.r_pc_valid && !i.r_pc_buffered) begin
                i.r_pc <= i.w_pc;
                i.r_pc_buffered <= 1'b1;
            end
        end
    end

    assign i.w_pc2use = i.r_pc_buffered ? i.r_pc : i.w_pc;

    /***********
    * out stage
    ***********/

    typedef struct {
        logic [PC_ADDR_WIDTH-1:0] r_pc_addr;
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

    assign w_imem_rd_addr = i.r_pc_valid ? i.w_pc2use : w_ildst_addr;

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
        .i_din_b('0),
        .o_dout_b(o.w_insn)
    );

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o.r_pc_addr <= 'h0;
            o.r_pc <= 'h0;
            o.r_insn <= 'h0;
            o.r_insn_buffered <= 1'b0;
            o.r_insn_valid <= 1'b0;
        end
        else if (w_propagate) begin
            o.r_pc_addr <= i.r_pc_addr;
            o.r_pc <= i.w_pc2use;
            o.r_insn <= (i.r_pc_valid && o.r_insn_valid && (i.w_pc2use == o.r_pc)) ? i_insn_modified : 'h0;
            o.r_insn_buffered <= (i.r_pc_valid && o.r_insn_valid && (i.w_pc2use == o.r_pc));
            o.r_insn_valid <= i.r_pc_valid;
        end
        else begin
            if (o.r_insn_valid && !o.r_insn_buffered) begin
                o.r_insn <= o.w_insn;
                o.r_insn_buffered <= 1'b1;
            end
        end
    end

    assign o.w_insn2use = o.r_insn_buffered ? o.r_insn : o.w_insn;

    /******************
    * pcmem imem write
    ******************/

    always_comb begin
        if (!p.r_active) begin
            w_pcmem_wr = w_pcst_wr;
            w_pcmem_wr_addr = w_pcldst_addr;
            w_pcmem_wr_data = w_pcst;

            w_imem_wr = w_ist_wr;
            w_imem_wr_addr = w_ildst_addr;
            w_imem_wr_data = w_ist;
        end
        else begin
            w_pcmem_wr = 1'b0;
            w_pcmem_wr_addr = 'h0;
            w_pcmem_wr_data = 'h0;

            w_imem_wr = i_next && !o_empty;
            w_imem_wr_addr = o_pc;
            w_imem_wr_data = i_insn_modified;
        end
    end

    /*****************
    * propagate logic
    *****************/

    assign w_propagate = (o.r_insn_valid && i_next) || (!o.r_insn_valid && (i.r_pc_valid || p.r_active));

    /****************
    * output signals
    ****************/

    assign o_pc_addr = o.r_pc_addr;
    assign o_pc = o.r_pc;
    assign o_insn = o.w_insn2use;
    assign o_empty = !o.r_insn_valid;

    always_ff @(posedge i_clk) begin
        if (i_rst)
            o_pc_rd <= 'h0;
        else if (w_pcld_rd)
            o_pc_rd <= i.w_pc;
    end

    always_ff @(posedge i_clk) begin
        if (i_rst)
            o_insn_rd <= 'h0;
        else if (w_ild_rd)
            o_insn_rd <= o.w_insn;
    end

endmodule
