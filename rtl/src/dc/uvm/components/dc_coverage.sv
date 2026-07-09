// Coverage collector for dc_program instruction sequences.
//
// Subscribes to the same agt.pgm_ap that feeds dc_model, so it sees each
// dc_program exactly as authored (insns[] intact). This is deliberately
// *not* sampled from dc_monitor's trace: dc_core unrolls each instruction
// into w_iters+1 beats, coalesces consecutive idle beats into one, and
// re-sweeps w_spi_din/w_hold_cycles via w_modify before the next pass --
// none of which preserves "instruction N was immediately followed by
// instruction N+1" as it was originally programmed. Sequence-adjacency
// properties (arm-then-modify, idle/active transitions, ...) only exist
// here, before the DUT gets a chance to obscure them.
class dc_coverage #(
    int MIN_HOLD_CYCLES,
    int PROGRAM_ITERS_MAX,
    int HOLD_CYCLES_MAX
) extends uvm_subscriber #(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX));

    `uvm_component_param_utils(dc_coverage #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX))

    typedef enum {ARM_NONE, ARM_FIRST, ARM_LAST, ARM_MIDDLE} arm_pos_e;

    // program-level sampling vars
    int unsigned cg_num_insns;
    int unsigned cg_iters;
    arm_pos_e    cg_arm_pos;
    bit          cg_has_sticky_arm;
    bit          cg_has_dup_insn;

    covergroup pgm_cg;
        option.per_instance = 1;

        num_insns_cp: coverpoint cg_num_insns {
            bins few  = {[1:4]};
            bins some = {[5:32]};
            bins many = {[33:DC_DEPTH]};
        }

        iters_cp: coverpoint cg_iters {
            bins low  = {[1:2]};
            bins mid  = {[3:(PROGRAM_ITERS_MAX/2)]};
            bins high = {[(PROGRAM_ITERS_MAX/2)+1:PROGRAM_ITERS_MAX]};
        }

        arm_pos_cp:    coverpoint cg_arm_pos;
        sticky_arm_cp: coverpoint cg_has_sticky_arm;
        dup_insn_cp:   coverpoint cg_has_dup_insn;

        arm_pos_x_iters: cross arm_pos_cp, iters_cp;
    endgroup

    // adjacent-instruction-pair sampling vars (insns[idx-1] -> insns[idx])
    bit cg_prev_idle, cg_cur_idle;
    bit cg_prev_armed, cg_cur_modify;
    bit cg_cur_modify_on_idle;

    covergroup adj_cg;
        option.per_instance = 1;

        idle_transition_cp: coverpoint {cg_prev_idle, cg_cur_idle} {
            bins active_to_active = {2'b00};
            bins active_to_idle   = {2'b01};
            bins idle_to_active   = {2'b10};
            bins idle_to_idle     = {2'b11};
        }

        arm_then_modify_cp: coverpoint {cg_prev_armed, cg_cur_modify} {
            bins none            = {2'b00};
            bins modify_only     = {2'b01};
            bins arm_only        = {2'b10};
            bins arm_then_modify = {2'b11};
        }

        modify_on_idle_cp: coverpoint cg_cur_modify_on_idle;
    endgroup

    function new(string name = "dc_coverage", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_coverage", "new is called\n", UVM_LOW);
        pgm_cg = new();
        adj_cg = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("dc_coverage", "build_phase is called\n", UVM_LOW);
    endfunction

    // Called by the analysis port every time the driver publishes a
    // dc_program -- see dc_env's connect_phase.
    virtual function void write(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX) t);

        int insn2addr_map[logic [DC_INSN_WIDTH-1:0]];

        cg_num_insns      = t.insns.size();
        cg_iters          = t.iters;
        cg_has_sticky_arm = 1'b0;
        cg_has_dup_insn   = 1'b0;
        cg_arm_pos        = ARM_NONE;

        foreach (t.insns[idx]) begin
            logic [DC_INSN_WIDTH-1:0] bits;
            bit armed;

            armed = t.insns[idx].w_arm || t.insns[idx].w_sticky_arm;

            if (t.insns[idx].w_sticky_arm)
                cg_has_sticky_arm = 1'b1;

            if (armed && cg_arm_pos == ARM_NONE) begin
                if (idx == 0)
                    cg_arm_pos = ARM_FIRST;
                else if (idx == t.insns.size() - 1)
                    cg_arm_pos = ARM_LAST;
                else
                    cg_arm_pos = ARM_MIDDLE;
            end

            bits = t.insns[idx];
            if (insn2addr_map.exists(bits))
                cg_has_dup_insn = 1'b1;
            else
                insn2addr_map[bits] = idx;
        end

        pgm_cg.sample();

        for (int idx = 1; idx < t.insns.size(); idx++) begin
            cg_prev_idle          = t.insns[idx-1].w_idle;
            cg_cur_idle           = t.insns[idx].w_idle;
            cg_prev_armed         = t.insns[idx-1].w_arm || t.insns[idx-1].w_sticky_arm;
            cg_cur_modify         = t.insns[idx].w_modify;
            cg_cur_modify_on_idle = t.insns[idx].w_modify && t.insns[idx].w_idle;

            adj_cg.sample();
        end

    endfunction

endclass
