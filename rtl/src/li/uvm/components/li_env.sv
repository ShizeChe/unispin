class li_env extends uvm_env;

    `uvm_component_utils(li_env)

    li_agent agt;
    li_model mdl;
    li_scoreboard sbd;

    // agent sends the program to be executed to model
    uvm_tlm_analysis_fifo #(li_program) agt2mdl_pgm_fifo;

    // agent sends captured trace to scoreboard
    uvm_tlm_analysis_fifo #(li_trace) agt2sbd_trc_fifo;


    // model sends expected trace to scoreboard
    uvm_tlm_analysis_fifo #(li_trace) mdl2sbd_trc_fifo;


    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("li_env", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        `uvm_info("li_env", "build_phase is called\n", UVM_LOW);

        agt = li_agent::type_id::create("agt", this);
        mdl = li_model::type_id::create("mdl", this);
        sbd = li_scoreboard::type_id::create("sbd", this);

        agt2mdl_pgm_fifo = new("agt2mdl_pgm_fifo", this);
        agt2sbd_trc_fifo = new("agt2sbd_trc_fifo", this);
        mdl2sbd_trc_fifo = new("mdl2sbd_trc_fifo", this);

    endfunction


    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        `uvm_info("li_env", "connect_phase is called\n", UVM_LOW);

        agt.pgm_ap.connect(agt2mdl_pgm_fifo.analysis_export);
        mdl.pgm_port.connect(agt2mdl_pgm_fifo.blocking_get_export);

        agt.trc_ap.connect(agt2sbd_trc_fifo.analysis_export);
        sbd.exp_port.connect(agt2sbd_trc_fifo.blocking_get_export);

        mdl.trc_ap.connect(mdl2sbd_trc_fifo.analysis_export);
        sbd.act_port.connect(mdl2sbd_trc_fifo.blocking_get_export);

    endfunction

endclass
