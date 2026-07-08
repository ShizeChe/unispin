class rf_agent extends uvm_agent;

    `uvm_component_utils(rf_agent)

    rf_sequencer sqr;
    rf_driver drv;
    rf_monitor mon;

    uvm_analysis_port #(rf_program) pgm_ap;
    uvm_analysis_port #(rf_trace) trc_ap;


    function new(string name = "agt", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("rf_agent", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info("rf_agent", "build_phase is called\n", UVM_LOW);

        sqr = rf_sequencer::type_id::create("sqr", this);
        drv = rf_driver::type_id::create("drv", this);
        mon = rf_monitor::type_id::create("mon", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info("rf_agent", "connect_phase is called\n", UVM_LOW);

        drv.seq_item_port.connect(sqr.seq_item_export);
        pgm_ap = drv.pgm_ap;
        trc_ap = mon.trc_ap;

    endfunction

endclass
