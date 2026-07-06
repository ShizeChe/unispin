class dc_base_test extends uvm_test;

    `uvm_component_utils(dc_base_test)

    dc_env env;

    function new(string name = "dc_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = dc_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        // TODO: build/start a dc_program sequence on env.agent.sequencer
        phase.raise_objection(this);
        #1000;
        phase.drop_objection(this);
    endtask

endclass
