class rf_trace extends uvm_sequence_item;

    rf_eop_t eop_trace[];

    // rf_eop_t itself doesn't carry the sample data (only addr/sample
    // range/marker), so the IQ payload is captured alongside it here,
    // straight off the o_QIx8 bus.
    logic [RF_DAC_WIDTH*16-1:0] qix8_trace[];

    function new(string name = "rf_trace");
        super.new(name);
    endfunction

    `uvm_object_utils(rf_trace);

endclass
