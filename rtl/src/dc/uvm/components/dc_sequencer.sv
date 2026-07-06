class dc_sequencer extends uvm_sequencer #(dc_program #(MIN_HOLD_CYCLES));

    `uvm_component_utils(dc_sequencer)

    function new(string name = "dc_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
