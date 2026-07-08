class li_agent extends uvm_agent;

    `uvm_component_utils(li_agent)

    li_sequencer sqr;
    li_driver drv;
    li_monitor mon;

    uvm_analysis_port #(li_program) pgm_ap;
    uvm_analysis_port #(li_trace) trc_ap;


    function new(string name = "agt", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("li_agent", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info("li_agent", "build_phase is called\n", UVM_LOW);

        sqr = li_sequencer::type_id::create("sqr", this);
        drv = li_driver::type_id::create("drv", this);
        mon = li_monitor::type_id::create("mon", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info("li_agent", "connect_phase is called\n", UVM_LOW);

        drv.seq_item_port.connect(sqr.seq_item_export);
        pgm_ap = drv.pgm_ap;
        trc_ap = mon.trc_ap;

    endfunction

endclass
