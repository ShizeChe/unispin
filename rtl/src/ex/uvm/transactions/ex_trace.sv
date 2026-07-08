class ex_trace extends uvm_sequence_item;

    // ex_eop_t already carries the sampled w_realx16 payload directly, so
    // unlike rf_trace no separate value array is needed.
    ex_eop_t eop_trace[];

    function new(string name = "ex_trace");
        super.new(name);
    endfunction

    `uvm_object_utils(ex_trace);

endclass
