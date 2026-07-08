class li_trace extends uvm_sequence_item;

    // li_eop_t already carries the sampled QIx4/tagx4/validx4/last data
    // directly, so unlike rf_trace no separate value array is needed.
    li_eop_t eop_trace[];

    function new(string name = "li_trace");
        super.new(name);
    endfunction

    `uvm_object_utils(li_trace);

endclass
