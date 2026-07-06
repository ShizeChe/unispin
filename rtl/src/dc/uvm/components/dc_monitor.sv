class dc_monitor extends uvm_monitor;

    `uvm_component_utils(dc_monitor)

    virtual dc_input_if  in_vif;
    virtual dc_output_if out_vif;

    uvm_analysis_port #(dc_trace) ap;

    // The DAC's committed output code. A real register that persists across
    // separate programs (the pipeline draining to o_empty doesn't reset it),
    // so it lives here rather than as a run_phase-local variable -- mirrors
    // dc_model's dac_voltage.
    protected logic [DC_DAC_WIDTH-1:0] dac_voltage;

    function new(string name = "dc_monitor", uvm_component parent = null);
        super.new(name, parent);
        dac_voltage = '0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        if (!uvm_config_db #(virtual dc_input_if)::get(this, "", "in_vif", in_vif))
            `uvm_fatal("dc_monitor", "input virtual interface must be set")

        if (!uvm_config_db #(virtual dc_output_if)::get(this, "", "out_vif", out_vif))
            `uvm_fatal("dc_monitor", "output virtual interface must be set")
    endfunction

    // One dc_eop_t / DAC voltage per committed dc_core beat, matching
    // dc_model's granularity exactly:
    //  - a beat is "committed" the cycle o_eop.w_cycles_left first reads 0
    //    (h.r_done becomes true on that exact same cycle -- see dc_core --
    //    so this is a reliable proxy for it using only the exposed o_eop
    //    field, no internal hierarchical reference needed);
    //  - w_ldac_cycles decays to 0 well before w_cycles_left does, so
    //    "did this beat strobe ldac" can't be read at the commit cycle --
    //    instead track the max w_ldac_cycles seen since the last commit,
    //    which catches the fresh nonzero value from whenever this beat was
    //    loaded;
    //  - w_spi_dout is left 'x and w_ldac_cycles/w_cycles_left left '0,
    //    matching what dc_model predicts (see dc_model's header comment).
    virtual task run_phase(uvm_phase phase);
        while (in_vif.i_rst)
            @(posedge in_vif.i_clk);

        forever begin
            dc_trace act_trace;
            dc_eop_t eop_q[$];
            logic [DC_DAC_WIDTH-1:0] v_q[$];
            logic [DC_CYCLE_WIDTH-1:0] prev_cycles_left;
            logic [DC_SPI_LDAC_WIDTH-1:0] max_ldac_seen;

            // idle between programs
            while (out_vif.cb.o_empty)
                @(out_vif.cb);

            act_trace = dc_trace::type_id::create("act_trace");
            prev_cycles_left = 1; // sentinel: guarantees the first real 0 edge-triggers
            max_ldac_seen = '0;

            while (!out_vif.cb.o_empty) begin

                dc_eop_t eop;
                eop = out_vif.cb.o_eop;

                if (eop.w_ldac_cycles > max_ldac_seen)
                    max_ldac_seen = eop.w_ldac_cycles;

                if (eop.w_cycles_left == '0 && prev_cycles_left != '0) begin
                    dc_eop_t beat;
                    beat = eop;
                    beat.w_spi_dout    = 'x;
                    beat.w_ldac_cycles = '0;
                    beat.w_cycles_left = '0;
                    eop_q.push_back(beat);

                    if (max_ldac_seen > 0)
                        dac_voltage = eop.w_spi_din[DC_DAC_WIDTH-1:0];
                    v_q.push_back(dac_voltage);

                    max_ldac_seen = '0;
                end

                prev_cycles_left = eop.w_cycles_left;

                @(out_vif.cb);
            end

            act_trace.eop_trace = eop_q;
            act_trace.v_trace   = v_q;
            ap.write(act_trace);
        end
    endtask

endclass
