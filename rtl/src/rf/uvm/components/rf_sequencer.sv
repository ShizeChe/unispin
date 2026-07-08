class rf_sequencer extends uvm_sequencer #(rf_program);

    `uvm_component_utils(rf_sequencer)

    function new(string name = "rf_sequencer", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("rf_sequencer", "new is called\n", UVM_LOW);
    endfunction

endclass
