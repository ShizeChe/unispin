class ex_sequencer extends uvm_sequencer #(ex_program);

    `uvm_component_utils(ex_sequencer)

    function new(string name = "ex_sequencer", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("ex_sequencer", "new is called\n", UVM_LOW);
    endfunction

endclass
