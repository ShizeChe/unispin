class dc_trace extends uvm_sequence_item;

    dc_eop_t eop_trace[];
    logic [DC_DAC_WIDTH-1:0] v_trace[];

    function new(string name = "dc_trace");
        super.new(name);
    endfunction

    `uvm_object_utils(dc_trace);

endclass
