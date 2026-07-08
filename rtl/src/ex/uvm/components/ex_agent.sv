class ex_agent extends uvm_agent;

    `uvm_component_utils(ex_agent)

    ex_sequencer sqr;
    ex_driver drv;
    ex_monitor mon;

    uvm_analysis_port #(ex_program) pgm_ap;
    uvm_analysis_port #(ex_trace) trc_ap;


    function new(string name = "agt", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("ex_agent", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info("ex_agent", "build_phase is called\n", UVM_LOW);

        sqr = ex_sequencer::type_id::create("sqr", this);
        drv = ex_driver::type_id::create("drv", this);
        mon = ex_monitor::type_id::create("mon", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info("ex_agent", "connect_phase is called\n", UVM_LOW);

        drv.seq_item_port.connect(sqr.seq_item_export);
        pgm_ap = drv.pgm_ap;
        trc_ap = mon.trc_ap;

    endfunction

endclass
