class dc_env #(int MIN_HOLD_CYCLES) extends uvm_env;

    `uvm_component_param_utils(dc_env #(MIN_HOLD_CYCLES))

    dc_agent #(MIN_HOLD_CYCLES) agt;
    dc_model #(MIN_HOLD_CYCLES) mdl;
    dc_scoreboard sbd;

    // agent sends the program to be executed to model
    uvm_tlm_analysis_fifo #(dc_program #(MIN_HOLD_CYCLES)) agt2mdl_pgm_fifo;

    // agent sends captured trace to scoreboard
    uvm_tlm_analysis_fifo #(dc_trace) agt2sbd_trc_fifo;


    // model sends expected trace to scoreboard
    uvm_tlm_analysis_fifo #(dc_trace) mdl2sbd_trc_fifo;


    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_env", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info("dc_env", "build_phase is called\n", UVM_LOW);

        agt = dc_agent#(MIN_HOLD_CYCLES)::type_id::create("agt", this);
        mdl = dc_model#(MIN_HOLD_CYCLES)::type_id::create("mdl", this);
        sbd = dc_scoreboard::type_id::create("sbd", this);

        agt2mdl_pgm_fifo = new("agt2mdl_pgm_fifo", this);
        agt2sbd_trc_fifo = new("agt2sbd_trc_fifo", this);
        mdl2sbd_trc_fifo = new("mdl2sbd_trc_fifo", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info("dc_env", "connect_phase is called\n", UVM_LOW);

        agt.pgm_ap.connect(agt2mdl_pgm_fifo.analysis_export);
        mdl.pgm_port.connect(agt2mdl_pgm_fifo.blocking_get_export);

        agt.trc_ap.connect(agt2sbd_trc_fifo.analysis_export);
        sbd.exp_port.connect(agt2sbd_trc_fifo.blocking_get_export);

        mdl.trc_ap.connect(mdl2sbd_trc_fifo.analysis_export);
        sbd.act_port.connect(mdl2sbd_trc_fifo.blocking_get_export);

    endfunction

endclass
