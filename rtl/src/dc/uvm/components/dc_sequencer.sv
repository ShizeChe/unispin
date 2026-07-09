class dc_sequencer #(int MIN_HOLD_CYCLES, int PROGRAM_ITERS_MAX, int HOLD_CYCLES_MAX)
    extends uvm_sequencer #(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX));

    `uvm_component_param_utils(dc_sequencer #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX))

    function new(string name = "dc_sequencer", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_sequencer", "new is called\n", UVM_LOW);
    endfunction

endclass
