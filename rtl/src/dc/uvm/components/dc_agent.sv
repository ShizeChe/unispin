class dc_agent extends uvm_agent;

    `uvm_component_utils(dc_agent)

    dc_sequencer sequencer;
    dc_driver    driver;
    dc_monitor   monitor;

    function new(string name = "dc_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = dc_sequencer::type_id::create("sequencer", this);
        driver    = dc_driver::type_id::create("driver", this);
        monitor   = dc_monitor::type_id::create("monitor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
