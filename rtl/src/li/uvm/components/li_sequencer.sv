class li_sequencer extends uvm_sequencer #(li_program);

    `uvm_component_utils(li_sequencer)

    function new(string name = "li_sequencer", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("li_sequencer", "new is called\n", UVM_LOW);
    endfunction

endclass
