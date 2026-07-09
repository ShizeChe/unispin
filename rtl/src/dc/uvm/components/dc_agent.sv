class dc_agent #(int MIN_HOLD_CYCLES, int PROGRAM_ITERS_MAX, int HOLD_CYCLES_MAX) extends uvm_agent;

    `uvm_component_param_utils(dc_agent #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX))

    dc_sequencer #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX) sqr;
    dc_driver #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX) drv;
    dc_monitor mon;

    uvm_analysis_port #(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX)) pgm_ap;
    uvm_analysis_port #(dc_trace) trc_ap;


    function new(string name = "agt", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_agent", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info("dc_agent", "build_phase is called\n", UVM_LOW);

        sqr = dc_sequencer #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX)::type_id::create("sqr", this);
        drv = dc_driver #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX)::type_id::create("drv", this);
        mon = dc_monitor::type_id::create("mon", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info("dc_agent", "connect_phase is called\n", UVM_LOW);

        drv.seq_item_port.connect(sqr.seq_item_export);
        pgm_ap = drv.pgm_ap;
        trc_ap = mon.trc_ap;

    endfunction

endclass
