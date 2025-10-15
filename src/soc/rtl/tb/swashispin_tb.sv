`timescale 1ns / 1ps

module swashispin_tb;

    // dc parameters
    localparam DC_DAC_WIDTH=16;
    localparam DC_CYCLE_WIDTH=30;
    localparam DC_STREAM_ITER_WIDTH=10;
    localparam DC_CORE_ITER_WIDTH=10;
    localparam DC_STREAM_DEPTH=20;
    localparam DC_INSN_WIDTH=DC_DAC_WIDTH*2+DC_CORE_ITER_WIDTH+DC_CYCLE_WIDTH;
    localparam DC_TOTAL_REGS=DC_STREAM_DEPTH*3+2;

    //rf parameters
    localparam RF_KBC_WIDTH=36;
    localparam RF_NUM_SAMPLE_WIDTH=30;
    localparam RF_CORE_ITER_WIDTH=10;
    localparam RF_INSN_WIDTH=RF_KBC_WIDTH*3+RF_CORE_ITER_WIDTH+RF_NUM_SAMPLE_WIDTH*4;
    localparam RF_IQ_WIDTH=14;
    localparam RF_DAC_WIDTH=16;
    localparam RF_PHASE_WIDTH=18;
    localparam RF_CORDIC_STAGES=15;
    localparam RF_CORDIC_PAD_ZEROS=8;

    localparam RF_INSN_BUF_DEPTH=16;
    localparam RF_IPTR_WIDTH=$clog2(RF_INSN_BUF_DEPTH);
    localparam RF_IPTR_BUF_DEPTH=1024;
    localparam RF_INSN_REGS=(RF_INSN_WIDTH+31)/32*RF_INSN_BUF_DEPTH;
    localparam RF_IPTR_REGS=(1024+32/RF_IPTR_WIDTH-1)/(32/RF_IPTR_WIDTH);
    localparam RF_STREAM_ITER_WIDTH=10;
    localparam RF_TOTAL_REGS=RF_INSN_REGS+RF_IPTR_REGS+2;

    localparam RF_REG_PER_INSN = (RF_INSN_WIDTH + 31) / 32;
    localparam RF_IPTR_PER_REG = 32 / RF_IPTR_WIDTH;

    // define number of dc/rf/li channels
    localparam NUM_DC_CHANNEL=4;
    localparam NUM_RF_CHANNEL=2;
    localparam NUM_LI_CHANNEL=1;

    // instantiate modules
    logic w_clk, w_rf_dac_clk, w_rst;

    logic [31:0] dc_regs_unpacked [0:NUM_DC_CHANNEL-1][0:DC_TOTAL_REGS-1];
    logic [NUM_DC_CHANNEL-1:0][DC_TOTAL_REGS-1:0][31:0] w_dc_regs;

    logic [NUM_DC_CHANNEL-1:0] w_dc_sclk_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_mosi_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_cs_n_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_ldac_n_bus;

    logic [NUM_DC_CHANNEL-1:0] w_dc_start_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_armed_bus;

    logic [NUM_DC_CHANNEL-1:0] w_dc_empty_bus;
    logic [NUM_DC_CHANNEL-1:0] w_dc_idle_bus;

    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_GEN

        for (genvar j = 0; j < DC_TOTAL_REGS; j++) begin : DC_REG_GEN
            assign w_dc_regs[i][j] = dc_regs_unpacked[i][j];
        end

        dc #(
            .DAC_WIDTH(DC_DAC_WIDTH),
            .CYCLE_WIDTH(DC_CYCLE_WIDTH),
            .STREAM_ITER_WIDTH(DC_STREAM_ITER_WIDTH),
            .CORE_ITER_WIDTH(DC_CORE_ITER_WIDTH),
            .DEPTH(DC_STREAM_DEPTH)
        ) DC (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_regs(w_dc_regs[i]),
            .o_sclk(w_dc_sclk_bus[i]),
            .o_mosi(w_dc_mosi_bus[i]),
            .o_cs_n(w_dc_cs_n_bus[i]),
            .o_ldac_n(w_dc_ldac_n_bus[i]),
            .i_start(w_dc_start_bus[i]),
            .o_armed(w_dc_armed_bus[i])
        );

        assign w_dc_empty_bus[i] = DC.w_empty;
        assign w_dc_idle_bus[i] = DC.core.r_state == DC.core.IDLE;

    end

    logic [31:0] rf_regs_unpacked [0:NUM_RF_CHANNEL-1][0:RF_TOTAL_REGS-1];
    logic [NUM_RF_CHANNEL-1:0][RF_TOTAL_REGS-1:0][31:0] w_rf_regs;

    logic [NUM_RF_CHANNEL-1:0][RF_DAC_WIDTH*16-1:0] w_rf_QIx8_bus;

    logic [NUM_RF_CHANNEL-1:0] w_rf_start_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_armed_bus;

    logic [NUM_RF_CHANNEL-1:0] w_rf_empty_bus;
    logic [NUM_RF_CHANNEL-1:0] w_rf_idle_bus;

    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_GEN

        for (genvar j = 0; j < RF_TOTAL_REGS; j++) begin : RF_REG_GEN
            assign w_rf_regs[i][j] = rf_regs_unpacked[i][j];
        end

        rf #(
            .KBC_WIDTH(RF_KBC_WIDTH),
            .NUM_SAMPLE_WIDTH(RF_NUM_SAMPLE_WIDTH),
            .CORE_ITER_WIDTH(RF_CORE_ITER_WIDTH),
            .IQ_WIDTH(RF_IQ_WIDTH),
            .DAC_WIDTH(RF_DAC_WIDTH),
            .PHASE_WIDTH(RF_PHASE_WIDTH),
            .CORDIC_STAGES(RF_CORDIC_STAGES),
            .CORDIC_PAD_ZEROS(RF_CORDIC_PAD_ZEROS),
            .INSN_BUF_DEPTH(RF_INSN_BUF_DEPTH),
            .IPTR_BUF_DEPTH(RF_IPTR_BUF_DEPTH),
            .STREAM_ITER_WIDTH(RF_STREAM_ITER_WIDTH)
        ) RF (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_regs(w_rf_regs[i]),
            .o_QIx8(w_rf_QIx8_bus[i]),
            .i_start(w_rf_start_bus[i]),
            .o_armed(w_rf_armed_bus[i])
        );

        assign w_rf_empty_bus[i] = RF.w_empty;
        assign w_rf_idle_bus[i] = RF.core.w_obubble;

    end

    logic [NUM_LI_CHANNEL-1:0] w_li_start_bus;
    logic [NUM_LI_CHANNEL-1:0] w_li_armed_bus;

    logic [31:0] launch_regs_unpacked [0:3];
    logic [3:0][31:0] w_launch_regs;

    for (genvar i = 0; i <= 3; i++) begin
        assign w_launch_regs[i] = launch_regs_unpacked[i];
    end

    launch #(
        .NUM_DC_CHANNEL(NUM_DC_CHANNEL),
        .NUM_RF_CHANNEL(NUM_RF_CHANNEL),
        .NUM_LI_CHANNEL(NUM_LI_CHANNEL)
    ) LCH (
        .i_clk(w_clk),
        .i_rst(w_rst),
        .i_regs(w_launch_regs),
        .i_dc_armed(w_dc_armed_bus),
        .i_rf_armed(w_rf_armed_bus),
        .i_li_armed(w_li_armed_bus),
        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start(w_li_start_bus)
    );

    // simulated analog frontend
    logic [NUM_DC_CHANNEL-1:0][DC_DAC_WIDTH-1:0] vdc;

    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_DAC_GEN
        ad4451a DC_DAC (
            .i_sclk(w_dc_sclk_bus[i]),
            .i_mosi(w_dc_mosi_bus[i]),
            .i_cs_n(w_dc_cs_n_bus[i]),
            .i_ldac_n(w_dc_ldac_n_bus[i]),
            .o_vdc(vdc[i])
        );
    end

    real vrf [NUM_RF_CHANNEL-1:0];

    for (genvar i = 0; i < NUM_RF_CHANNEL; i++) begin : RF_DAC_GEN
        zcu216_dac RF_DAC (
            .i_clk(w_clk),
            .i_dac_clk(w_rf_dac_clk),
            .i_QIx8(w_rf_QIx8_bus[i]),
            .o_vrf(vrf[i])
        );
    end

    // clocks
    initial begin
        w_clk = 1'b0;
        forever #2 w_clk = !w_clk;
    end

    initial begin
        w_rf_dac_clk = 1'b1;
        forever #0.25 w_rf_dac_clk = !w_rf_dac_clk;
    end

    // init register values
    string path;

    initial begin
        
        w_li_armed_bus = 'h0;

        for (int i = 0; i < NUM_DC_CHANNEL; i++)
            for (int j = 0; j < DC_TOTAL_REGS; j++)
                dc_regs_unpacked[i][j] = 'h0;

        for (int i = 0; i < NUM_RF_CHANNEL; i++)
            for (int j = 0; j < RF_TOTAL_REGS; j++)
                rf_regs_unpacked[i][j] = 'h0;

        for (int i = 0; i <= 3; i++)
            launch_regs_unpacked[i] = 'h0;

        w_rst = 1'b1;
        @(negedge w_clk);
        w_rst = 1'b0;

        repeat(5) @(negedge w_clk);

        $readmemb("../sw/dump/launch.txt", launch_regs_unpacked);

        for (int i = 0; i < NUM_DC_CHANNEL; i++) begin
            if (w_launch_regs[0][i]) begin
                path = $sformatf("../sw/dump/dc%0d.txt", i);
                $readmemb(path, dc_regs_unpacked[i]);
            end
        end

        for (int i = 0; i < NUM_RF_CHANNEL; i++) begin
            if (w_launch_regs[1][i]) begin
                path = $sformatf("../sw/dump/rf%d.txt", i);
                $readmemb(path, rf_regs_unpacked[i]);
            end
        end


        wait(LCH.r_state == LCH.LAUNCH);
        wait(w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}});
        wait(w_dc_idle_bus == {(NUM_DC_CHANNEL){1'b1}});
        wait(w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}});
        wait(w_rf_idle_bus == {(NUM_RF_CHANNEL){1'b1}});

        $finish;

    end

endmodule
