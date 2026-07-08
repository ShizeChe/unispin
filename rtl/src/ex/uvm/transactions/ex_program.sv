// ex has no control register bank (no ex_ctrl_t) -- unlike dc/rf/li, ex_program
// carries only instructions and the iteration count.
class ex_program extends uvm_sequence_item;

    rand ex_insn_t insns[];
    rand int unsigned iters;

    constraint iters_cons {
        iters > 0;
        iters <= 8;
    };

    constraint num_insns_cons {
        insns.size() > 0;
        insns.size() <= EX_DEPTH;
    };

    // Bounds per-instruction sample counts -- ex_core spends real cycles
    // per sample, so an unconstrained EX_NUM_SAMPLE_WIDTH-wide field (up to
    // ~1M) would make sims impractically slow.
    constraint insn_samples_cons {
        foreach (insns[i]) {
            insns[i].w_samples <= 8;
        }
    };

    function new(string name = "ex_program");
        super.new(name);
        `uvm_info("ex_program", "new is called\n", UVM_LOW);
    endfunction

    `uvm_object_utils_begin(ex_program)
        `uvm_field_array_int(insns, UVM_ALL_ON)
        `uvm_field_int(iters, UVM_ALL_ON)
    `uvm_object_utils_end

endclass
