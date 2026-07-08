class li_monitor extends uvm_monitor;

    `uvm_component_utils(li_monitor)

    virtual li_output_if vif;

    uvm_analysis_port #(li_trace) trc_ap;

    function new(string name = "li_monitor", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("li_monitor", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("li_monitor", "build_phase is called\n", UVM_LOW);

        trc_ap = new("trc_ap", this);

        if (!uvm_config_db #(virtual li_output_if)::get(this, "", "vif", vif))
            `uvm_fatal("li_monitor", "output virtual interface must be set")
    endfunction

    // One li_eop_t per committed li_core beat. li_eop_t already carries the
    // sampled QIx4/tagx4/validx4/last payload, so nothing extra needs to be
    // sampled alongside it (unlike rf).
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("li_monitor", "run_phase is called\n", UVM_LOW);

        while (vif.i_rst)
            @(posedge vif.i_clk);

        forever begin
            li_trace act_trace;
            li_eop_t eop_q[$];

            // idle between programs
            while (vif.cb.o_empty)
                @(vif.cb);

            act_trace = li_trace::type_id::create("act_trace");

            while (!vif.cb.o_empty) begin
                eop_q.push_back(vif.cb.o_eop);
                @(vif.cb);
            end

            act_trace.eop_trace = eop_q;
            trc_ap.write(act_trace);
        end
    endtask

endclass
