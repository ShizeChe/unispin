class rf_monitor extends uvm_monitor;

    `uvm_component_utils(rf_monitor)

    virtual rf_output_if vif;

    uvm_analysis_port #(rf_trace) trc_ap;

    function new(string name = "rf_monitor", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("rf_monitor", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("rf_monitor", "build_phase is called\n", UVM_LOW);

        trc_ap = new("trc_ap", this);

        if (!uvm_config_db #(virtual rf_output_if)::get(this, "", "vif", vif))
            `uvm_fatal("rf_monitor", "output virtual interface must be set")
    endfunction

    // One rf_eop_t / o_QIx8 sample per committed rf_core beat. Unlike dc's
    // SPI path, rf_core has no multi-cycle drain to coalesce -- assumed to
    // tick exactly one beat per cycle while !o_empty.
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("rf_monitor", "run_phase is called\n", UVM_LOW);

        while (vif.i_rst)
            @(posedge vif.i_clk);

        forever begin
            rf_trace act_trace;
            rf_eop_t eop_q[$];
            logic [RF_DAC_WIDTH*16-1:0] qix8_q[$];

            // idle between programs
            while (vif.cb.o_empty)
                @(vif.cb);

            act_trace = rf_trace::type_id::create("act_trace");

            while (!vif.cb.o_empty) begin
                eop_q.push_back(vif.cb.o_eop);
                qix8_q.push_back(vif.cb.o_QIx8);
                @(vif.cb);
            end

            act_trace.eop_trace  = eop_q;
            act_trace.qix8_trace = qix8_q;
            trc_ap.write(act_trace);
        end
    endtask

endclass
