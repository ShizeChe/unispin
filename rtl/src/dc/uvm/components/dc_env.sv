class dc_env extends uvm_env;

    `uvm_component_utils(dc_env)

    dc_agent      agent;
    dc_model      model;
    dc_scoreboard scoreboard;

    function new(string name = "dc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = dc_agent::type_id::create("agent", this);
        model      = dc_model::type_id::create("model", this);
        scoreboard = dc_scoreboard::type_id::create("scoreboard", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Actual DUT trace: monitor -> scoreboard
        agent.monitor.ap.connect(scoreboard.act_export);
        // Predicted trace: model -> scoreboard
        model.ap.connect(scoreboard.exp_export);
        // Programs consumed by the driver -> model's fifo, which model's own
        // run_phase actively drains to predict each one
        agent.driver.ap_pgm.connect(model.pgm_fifo.analysis_export);
    endfunction

endclass
