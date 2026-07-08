class dc_sequencer #(int MIN_HOLD_CYCLES) extends uvm_sequencer #(dc_program #(MIN_HOLD_CYCLES));

    `uvm_component_param_utils(dc_sequencer #(MIN_HOLD_CYCLES))

    function new(string name = "dc_sequencer", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_sequencer", "new is called\n", UVM_LOW);
    endfunction

endclass
