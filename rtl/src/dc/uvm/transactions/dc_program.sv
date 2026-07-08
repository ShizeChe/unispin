class dc_program #(
    int MIN_HOLD_CYCLES
) extends uvm_sequence_item;

    rand dc_insn_t insns[];
    rand bit has_ctrl;
    rand dc_ctrl_t ctrl;
    rand int unsigned iters;

    constraint iters_cons {
        iters > 0;
        iters <= 8;
    };

    constraint num_insns_cons {
        insns.size() > 0;
        insns.size() <= DC_DEPTH;
    };

    constraint no_ctrl_cons {
        (!has_ctrl) -> (ctrl == '0);
    };

    constraint delay_gt_ldac_cons {
        has_ctrl -> (ctrl.w_delay_cycles >= ctrl.w_ldac_cycles);
    };

    constraint insn_min_hold_cycles_cons {
        foreach (insns[i]) {
            has_ctrl -> (insns[i].w_hold_cycles >= 
                ((DC_SPI_DATA_WIDTH + 4) * (ctrl.w_dvsr + 1) * 2) + 
                ctrl.w_delay_cycles + ctrl.w_cs_up_cycles);
        }
    };

    function new(string name = "dc_program");
        super.new(name);
        `uvm_info("dc_program", "new is called\n", UVM_LOW);
    endfunction

    `uvm_object_utils_begin(dc_program#(MIN_HOLD_CYCLES))
        `uvm_field_int(has_ctrl, UVM_ALL_ON)
        `uvm_field_int(ctrl, UVM_ALL_ON)
        `uvm_field_array_int(insns, UVM_ALL_ON)
        `uvm_field_int(iters, UVM_ALL_ON)
    `uvm_object_utils_end

endclass
