class dc_driver #(int MIN_HOLD_CYCLES, int PROGRAM_ITERS_MAX, int HOLD_CYCLES_MAX)
    extends uvm_driver #(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX));

    `uvm_component_param_utils(dc_driver #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX))

    virtual dc_input_if vif;

    // Publishes each dc_program as it's pulled off the sequencer, so
    // dc_model can predict its expected trace independently of driving it.
    uvm_analysis_port #(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX)) pgm_ap;

    function new(string name = "dc_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_driver", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);
        `uvm_info("dc_driver", "build_phase is called\n", UVM_LOW);

        if (!uvm_config_db#(virtual dc_input_if)::get(this, "", "vif", vif))
            `uvm_fatal("dc_driver", "virtual interface must be set\n");

        pgm_ap = new("pgm_ap", this);

    endfunction


    typedef struct {
        logic [DC_INSN_WIDTH-1:0] pcmem_q [$];
        logic [DC_INSN_WIDTH-1:0] imem_q [$];
    } mem_content_t;


    virtual function mem_content_t get_mem_content(dc_program #(MIN_HOLD_CYCLES, PROGRAM_ITERS_MAX, HOLD_CYCLES_MAX) pgm);

        mem_content_t m;
        int insn2addr_map [logic [DC_INSN_WIDTH-1:0]];
        logic [DC_INSN_WIDTH-1:0] bits;
        int addr = 0;

        foreach (pgm.insns[i]) begin

            bits = pgm.insns[i];

            if (insn2addr_map.exists(bits)) begin
                m.pcmem_q.push_back(insn2addr_map[bits]);
            end
            else begin
                insn2addr_map[bits] = addr;
                m.imem_q.push_back(bits);
                m.pcmem_q.push_back(addr);
                addr++;
            end

        end

        return m;

    endfunction


    virtual task burst_ctrl(dc_ctrl_t ctrl);
        vif.cb.i_ctrl_regs[DC_DVSR_REG]  <= 32'(ctrl.w_dvsr);
        vif.cb.i_ctrl_regs[DC_DELAY_REG] <= 32'(ctrl.w_delay_cycles);
        vif.cb.i_ctrl_regs[DC_CS_UP_REG] <= 32'(ctrl.w_cs_up_cycles);
        vif.cb.i_ctrl_regs[DC_LDAC_REG]  <= 32'(ctrl.w_ldac_cycles);
        vif.cb.i_ctrl_regs[DC_CTRL_STRB_REG] <= 32'h0;
        @(vif.cb);
        vif.cb.i_ctrl_regs[DC_CTRL_STRB_REG] <= 32'h1;
        @(vif.cb);
        vif.cb.i_ctrl_regs[DC_CTRL_STRB_REG] <= 32'h0;
        @(vif.cb);
        @(vif.cb);
    endtask


    virtual task burst_mem(mem_content_t m, int unsigned iters);
        logic [DC_INSN_WIDTH-1:0] insn;

        // write unique instructions to IMEM
        foreach (m.imem_q[i]) begin
            insn = m.imem_q[i];
            vif.cb.i_seq_regs[`IST_ADDR_REG] <= 32'(i);
            for (int r = 0; r < DC_REG_PER_INSN; r++)
                vif.cb.i_seq_regs[`IST_REG_LO + r] <= 32'(insn >> ((DC_REG_PER_INSN - 1 - r) * 32));
            @(vif.cb);
            vif.cb.i_seq_regs[`IST_STRB_REG(DC_REG_PER_INSN)] <= 32'h1;
            @(vif.cb);
            vif.cb.i_seq_regs[`IST_STRB_REG(DC_REG_PER_INSN)] <= 32'h0;
            @(vif.cb);
            @(vif.cb);
        end

        // write PC sequence to PCMEM
        foreach (m.pcmem_q[i]) begin
            vif.cb.i_seq_regs[`PCST_ADDR_REG] <= 32'(i);
            vif.cb.i_seq_regs[`PCST_REG]      <= 32'(m.pcmem_q[i]);
            @(vif.cb);
            vif.cb.i_seq_regs[`PCST_STRB_REG] <= 32'h1;
            @(vif.cb);
            vif.cb.i_seq_regs[`PCST_STRB_REG] <= 32'h0;
            @(vif.cb);
            @(vif.cb);
        end

        // set depth (inclusive last address) and iters
        vif.cb.i_seq_regs[`ITERS_REG(DC_REG_PER_INSN)] <= 32'(iters);
        vif.cb.i_seq_regs[`DEPTH_REG(DC_REG_PER_INSN)] <= 32'(m.pcmem_q.size() - 1);
        @(vif.cb);
    endtask


    // Kicks off the sequencer (pulses START_STRB_REG), then handles the
    // launch handshake: every program's first instruction carries a plain
    // (non-sticky) arm, so o_armed always asserts exactly once per program,
    // right at the start, before anything data-relevant has run -- just
    // wait for it and pulse i_start.
    virtual task start_program();
        vif.cb.i_seq_regs[`START_STRB_REG(DC_REG_PER_INSN)] <= 32'h1;
        @(vif.cb);
        vif.cb.i_seq_regs[`START_STRB_REG(DC_REG_PER_INSN)] <= 32'h0;
        @(vif.cb);
        @(vif.cb);

        `uvm_info("dc_driver", "start waiting for armed\n", UVM_LOW);

        while (!vif.cb.o_armed)
            @(vif.cb);

        `uvm_info("dc_driver", "see armed\n", UVM_LOW);

        vif.cb.i_start <= 1'b1;
        @(vif.cb);
        vif.cb.i_start <= 1'b0;
        @(vif.cb);
    endtask

    virtual task wait_empty();
        `uvm_info("dc_driver", "wait for empty\n", UVM_LOW);
        while (!vif.cb.o_empty)
            @(vif.cb);
        `uvm_info("dc_driver", $sformatf("vif.cb.o_empty=%0b\n", vif.cb.o_empty), UVM_LOW);
        `uvm_info("dc_driver", "see empty\n", UVM_LOW);
    endtask


    virtual task run_phase(uvm_phase phase);
        mem_content_t m;
        dc_ctrl_t fixed_ctrl;
        super.run_phase(phase);
        `uvm_info("dc_driver", "run_phase is called\n", UVM_LOW);

        vif.cb.i_seq_regs <= '0;
        vif.cb.i_ctrl_regs <= '0;
        vif.cb.i_start <= 1'b0;
        while (vif.i_rst)
            @(vif.cb);

        // dc_ctrl is fixed for the life of the test -- burst it in once here
        // rather than per-program.
        fixed_ctrl = '{
            w_dvsr: 3,
            w_delay_cycles: 3,
            w_cs_up_cycles: 3,
            w_ldac_cycles: 2
        };
        burst_ctrl(fixed_ctrl);

        forever begin
            seq_item_port.get_next_item(req);
            phase.raise_objection(this);
            `uvm_info("dc_driver", "got new program\n", UVM_LOW);
            req.print();
            pgm_ap.write(req);
            m = get_mem_content(req);
            burst_mem(m, req.iters);
            start_program();
            wait_empty();
            seq_item_port.item_done();
            phase.drop_objection(this);
        end
    endtask

endclass
