class dc_monitor extends uvm_monitor;

    `uvm_component_utils(dc_monitor)

    virtual dc_output_if     vif;
    virtual dc_dac_output_if vif_dac;

    uvm_analysis_port #(dc_trace) trc_ap;

    function new(string name = "dc_monitor", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_monitor", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("dc_monitor", "build_phase is called\n", UVM_LOW);

        trc_ap = new("trc_ap", this);

        if (!uvm_config_db #(virtual dc_output_if)::get(this, "", "vif", vif))
            `uvm_fatal("dc_monitor", "output virtual interface must be set")

        if (!uvm_config_db #(virtual dc_dac_output_if)::get(this, "", "vif_dac", vif_dac))
            `uvm_fatal("dc_monitor", "DAC virtual interface must be set")
    endfunction

    // One dc_eop_t / DAC voltage per committed dc_core beat, matching
    // dc_model's granularity exactly:
    //  - a beat is "committed" the cycle o_eop.w_cycles_left first reads 0
    //    (h.r_done becomes true on that exact same cycle -- see dc_core --
    //    so this is a reliable proxy for it using only the exposed o_eop
    //    field, no internal hierarchical reference needed);
    //  - v_digital is read straight off the ad5791 VIP's committed DAC
    //    register (vif_dac.vdigital), so no LDAC-timing heuristic is needed
    //    to decide whether this beat strobed ldac;
    //  - w_spi_dout is left 'x and w_ldac_cycles/w_cycles_left left '0,
    //    matching what dc_model predicts (see dc_model's header comment).
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("dc_monitor", "run_phase is called\n", UVM_LOW);

        // Exiting on i_rst via a raw @(posedge) (or even checking cb.i_rst
        // right at the exit edge) isn't enough: the clocking block's #1step
        // sample for the very edge reset deasserts on still reflects the
        // pre-reset (X) value of everything else in cb, since that sample
        // was captured just *before* this edge's NBA-committed reset values
        // took effect. One extra @(vif.cb) is needed so cb.o_empty/cb.o_eop
        // reflect an already-settled, post-reset cycle before we trust them.
        while (vif.i_rst)
            @(vif.cb);

        @(vif.cb);

        forever begin
            dc_trace act_trace;
            dc_eop_t eop_q[$];
            logic [DC_DAC_WIDTH-1:0] v_q[$];
            logic [DC_CYCLE_WIDTH-1:0] prev_cycles_left;

            // idle between programs
            while (vif.cb.o_empty)
                @(vif.cb);

            `uvm_info("dc_monitor", "see not empty start capture\n", UVM_LOW);

            act_trace = dc_trace::type_id::create("act_trace");
            prev_cycles_left = 1; // sentinel: guarantees the first real 0 edge-triggers

            while (!vif.cb.o_empty) begin

                dc_eop_t eop;
                eop = vif.cb.o_eop;

                if (eop.w_cycles_left == 0 && prev_cycles_left != 0) begin
                    dc_eop_t beat;
                    beat = eop;
                    beat.w_spi_dout    = 'bx;
                    beat.w_ldac_cycles = 0;
                    beat.w_cycles_left = 0;
                    eop_q.push_back(beat);
                    v_q.push_back(vif_dac.vdigital);
                end

                prev_cycles_left = eop.w_cycles_left;

                @(vif.cb);
            end

            act_trace.eop_trace = eop_q;
            act_trace.v_trace   = v_q;
            `uvm_info("dc_monitor", "finished capture, send to scoreboard\n", UVM_LOW);
            trc_ap.write(act_trace);
        end
    endtask

endclass
