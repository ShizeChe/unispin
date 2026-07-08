class rf_program extends uvm_sequence_item;

    rand rf_insn_t insns[];
    rand bit has_ctrl;
    rand rf_ctrl_t ctrl;
    rand int unsigned iters;

    constraint iters_cons {
        iters > 0;
        iters <= 8;
    };

    constraint num_insns_cons {
        insns.size() > 0;
        insns.size() <= RF_DEPTH;
    };

    constraint no_ctrl_cons {
        (!has_ctrl) -> (ctrl == '0);
    };

    // Bounds per-instruction sample counts -- rf_core spends real cycles
    // per sample, so an unconstrained RF_NUM_SAMPLE_WIDTH-wide field (up to
    // ~1M) would make sims impractically slow.
    constraint insn_samples_cons {
        foreach (insns[i]) {
            insns[i].w_samples <= 8;
        }
    };

    function new(string name = "rf_program");
        super.new(name);
        `uvm_info("rf_program", "new is called\n", UVM_LOW);
    endfunction

    `uvm_object_utils_begin(rf_program)
        `uvm_field_int(has_ctrl, UVM_ALL_ON)
        `uvm_field_int(ctrl, UVM_ALL_ON)
        `uvm_field_array_int(insns, UVM_ALL_ON)
        `uvm_field_int(iters, UVM_ALL_ON)
    `uvm_object_utils_end

endclass
