`default_nettype none
`timescale 1ns / 1ps
`include "include/dc.svh"
`include "include/rf.svh"

module swashispin_tb;

    // define number of dc/rf/li channels
    localparam NUM_DC_CHANNEL=4;
    localparam NUM_RF_CHANNEL=2;
    localparam NUM_LI_CHANNEL=1;

    // instantiate modules
    logic w_clk, w_rf_dac_clk, w_rst;

    logic [31:0] dc_regs_unpacked [0:NUM_DC_CHANNEL-1][0:DC_TOTAL_REGS-1];
    logic [0:NUM_DC_CHANNEL-1][0:DC_TOATL_REGS-1][31:0] w_dc_regs;

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

        dc DC (
            .i_clk(w_clk),
            .i_rst(w_rst),
            .i_regs(w_dc_regs[i]),
            .o_sclk(w_dc_sclk_bus[i]),
            .o_mosi(w_dc_mosi_bus[i]),
            .i_miso(w_dc_miso_bus[i]),
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
        assign w_rf_idle_bus[i] = RF.core.w_propagate_bubble;

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
        .i_trigger(1'b1),
        .o_dc_start(w_dc_start_bus),
        .o_rf_start(w_rf_start_bus),
        .o_li_start(w_li_start_bus)
    );

    logic dc_empty, dc_idle, rf_empty, rf_idle;
    assign dc_empty = w_dc_empty_bus == {(NUM_DC_CHANNEL){1'b1}};
    assign dc_idle = w_dc_idle_bus == {(NUM_DC_CHANNEL){1'b1}};
    assign rf_empty = w_rf_empty_bus == {(NUM_RF_CHANNEL){1'b1}};
    assign rf_idle = w_rf_idle_bus == {(NUM_RF_CHANNEL){1'b1}};

    // simulated analog frontend
    logic [NUM_DC_CHANNEL-1:0][DC_DAC_WIDTH-1:0] vdc;

    for (genvar i = 0; i < NUM_DC_CHANNEL; i++) begin : DC_DAC_GEN
        ad5791 DC_DAC (
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
                path = $sformatf("../sw/dump/rf%0d.txt", i);
                $readmemb(path, rf_regs_unpacked[i]);
            end
        end

        wait(LCH.r_state == LCH.LAUNCH);
        @(negedge w_clk);
        wait(LCH.w_all_ready);
        wait(dc_empty && dc_idle && rf_empty && rf_idle);

        $finish;

    end

    // export dc trace
    int dc_trace_chs [$];
    int dc_trace_fds [$];
    int dc_trace_cycles[$];
    logic [DC_DAC_WIDTH-1:0] dc_trace_vprev [$];

    int dc_ch, dc_fd;
    logic [DC_DAC_WIDTH-1:0] dc_vprev;

    string dc_trace_path;

    initial begin
        
        wait(LCH.r_state == LCH.LAUNCH);
        wait(LCH.w_all_ready);

        @(negedge w_clk);
        @(negedge w_clk);
        @(negedge w_clk);

        for (int i = 0; i < NUM_DC_CHANNEL; i++) begin

            if (w_launch_regs[0][i]) begin

                dc_trace_path = $sformatf("../sim/traces/dc%0d_trace.txt", i);

                dc_trace_chs.push_back(i);
                dc_trace_fds.push_back($fopen(dc_trace_path, "w"));
                dc_trace_cycles.push_back(0);
                dc_trace_vprev.push_back(vdc[i]);
            end

        end

        
        while (!(dc_empty && dc_idle)) begin

            @(negedge w_clk);

            for (int i = 0; i < dc_trace_chs.size(); i++) begin

                dc_ch = dc_trace_chs[i];
                dc_vprev = dc_trace_vprev[i];
                
                // dc voltage shifted, save v and cycles and reset
                if (vdc[dc_ch] != dc_vprev) begin
                    dc_fd = dc_trace_fds[i];
                    $fdisplay(dc_fd, "%0h %0h", dc_vprev, dc_trace_cycles[i]);
                    dc_trace_cycles[i] = 0;
                end
                else begin
                    dc_trace_cycles[i]++;
                end

                dc_trace_vprev[i] = vdc[dc_ch];

            end
                
        end
    end

    // export rf trace
    int rf_trace_chs [$];
    int rf_trace_fds [$];
    int rf_ch, rf_fd;

    string rf_trace_path;

    initial begin

        wait(LCH.r_state == LCH.LAUNCH);
        wait(LCH.w_all_ready);

        for (int i = 0; i < NUM_RF_CHANNEL; i++) begin

            if (w_launch_regs[1][i]) begin

                rf_trace_path = $sformatf("../sim/traces/rf%0d_trace.txt", i);

                rf_trace_chs.push_back(i);
                rf_trace_fds.push_back($fopen(rf_trace_path, "w"));
            end

        end

        while (!(rf_empty && rf_idle)) begin

            @(negedge w_rf_dac_clk);

            for (int i = 0; i < rf_trace_chs.size(); i++) begin
                rf_ch = rf_trace_chs[i];
                rf_fd = rf_trace_fds[i];
                $fdisplay(rf_fd, "%f\n", vrf[rf_ch]);
            end
                
        end
    end

endmodule
