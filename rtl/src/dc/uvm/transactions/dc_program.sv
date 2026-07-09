class dc_program #(
    int MIN_HOLD_CYCLES,
    int PROGRAM_ITERS_MAX,
    int HOLD_CYCLES_MAX
) extends uvm_sequence_item;

    rand dc_insn_t insns[];
    rand int unsigned iters;

    constraint iters_cons {
        iters > 0;
        iters <= PROGRAM_ITERS_MAX;
    };

    constraint num_insns_cons {
        insns.size() > 0;
        insns.size() <= DC_DEPTH;
    };

    constraint idle_no_iters {
        foreach (insns[i]) {
            insns[i].w_idle -> (insns[i].w_iters == 0);
        }
    };

    constraint no_sticky_arm {
        foreach (insns[i]) {
            !insns[i].w_sticky_arm;
        }
    };

    constraint first_arm {
        foreach (insns[i]) {
            insns[i].w_arm == (i == 0);
        }
    };

    // dc_ctrl (dvsr=3, delay=3, cs_up=3, ldac=2) is fixed and burst into the
    // DUT once before the driver's forever loop (see dc_driver::run_phase),
    // not carried per-program anymore -- MIN_HOLD_CYCLES is precomputed to
    // safely cover that fixed configuration's SPI transaction time.
    // HOLD_CYCLES_MAX caps the upper end -- hold waits are real DUT cycles,
    // not just a delay to write, so an unbounded top end makes sims slow.
    constraint insn_hold_cycles_cons {
        foreach (insns[i]) {
            insns[i].w_hold_cycles >= MIN_HOLD_CYCLES;
            insns[i].w_hold_cycles <= HOLD_CYCLES_MAX;
        }
    };

    function new(string name = "dc_program");
        super.new(name);
        `uvm_info("dc_program", "new is called\n", UVM_LOW);
    endfunction

    `uvm_object_utils_begin(dc_program#(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX))
        `uvm_field_array_int(insns, UVM_ALL_ON)
        `uvm_field_int(iters, UVM_ALL_ON)
    `uvm_object_utils_end

endclass
