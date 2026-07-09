class rf_driver extends uvm_driver #(rf_program);

    `uvm_component_utils(rf_driver)

    virtual rf_input_if vif;

    // Publishes each rf_program as it's pulled off the sequencer, so
    // rf_model can predict its expected trace independently of driving it.
    uvm_analysis_port #(rf_program) pgm_ap;

    function new(string name = "rf_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("rf_driver", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);
        `uvm_info("rf_driver", "build_phase is called\n", UVM_LOW);

        if (!uvm_config_db#(virtual rf_input_if)::get(this, "", "vif", vif))
            `uvm_fatal("rf_driver", "virtual interface must be set\n");

        pgm_ap = new("pgm_ap", this);

    endfunction


    typedef struct {
        logic [RF_INSN_WIDTH-1:0] pcmem_q [$];
        logic [RF_INSN_WIDTH-1:0] imem_q [$];
    } mem_content_t;


    virtual function mem_content_t get_mem_content(rf_program pgm);

        mem_content_t m;
        int insn2addr_map [logic [RF_INSN_WIDTH-1:0]];
        logic [RF_INSN_WIDTH-1:0] bits;
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


    virtual task burst_ctrl(rf_ctrl_t ctrl);
        `uvm_info("rf_driver", "start burst ctrl\n", UVM_LOW);
        vif.cb.i_ctrl_regs[RF_DEFAULT_I_REG] <= 32'(ctrl.w_default_I);
        vif.cb.i_ctrl_regs[RF_DEFAULT_Q_REG] <= 32'(ctrl.w_default_Q);
        vif.cb.i_ctrl_regs[RF_CTRL_STRB_REG] <= 32'h0;
        @(vif.cb);
        vif.cb.i_ctrl_regs[RF_CTRL_STRB_REG] <= 32'h1;
        @(vif.cb);
        vif.cb.i_ctrl_regs[RF_CTRL_STRB_REG] <= 32'h0;
        @(vif.cb);
        @(vif.cb);
    endtask


    virtual task burst_mem(mem_content_t m, int unsigned iters);
        logic [RF_INSN_WIDTH-1:0] insn;

        // write unique instructions to IMEM
        foreach (m.imem_q[i]) begin
            insn = m.imem_q[i];
            vif.cb.i_seq_regs[`IST_ADDR_REG] <= 32'(i);
            for (int r = 0; r < RF_REG_PER_INSN; r++)
                vif.cb.i_seq_regs[`IST_REG_LO + r] <= 32'(insn >> ((RF_REG_PER_INSN - 1 - r) * 32));
            @(vif.cb);
            vif.cb.i_seq_regs[`IST_STRB_REG(RF_REG_PER_INSN)] <= 32'h1;
            @(vif.cb);
            vif.cb.i_seq_regs[`IST_STRB_REG(RF_REG_PER_INSN)] <= 32'h0;
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
        vif.cb.i_seq_regs[`ITERS_REG(RF_REG_PER_INSN)] <= 32'(iters);
        vif.cb.i_seq_regs[`DEPTH_REG(RF_REG_PER_INSN)] <= 32'(m.pcmem_q.size() - 1);
        @(vif.cb);
    endtask


    // Kicks off the sequencer (pulses START_STRB_REG), then handles the
    // launch handshake: every program's first instruction carries a plain
    // (non-sticky) arm, so o_armed always asserts exactly once per program,
    // right at the start, before anything data-relevant has run -- just
    // wait for it and pulse i_start.
    virtual task start_program();
        vif.cb.i_seq_regs[`START_STRB_REG(RF_REG_PER_INSN)] <= 32'h1;
        @(vif.cb);
        vif.cb.i_seq_regs[`START_STRB_REG(RF_REG_PER_INSN)] <= 32'h0;
        @(vif.cb);
        @(vif.cb);

        `uvm_info("rf_driver", "start waiting for armed\n", UVM_LOW);

        while (!vif.cb.o_armed)
            @(vif.cb);

        `uvm_info("rf_driver", "see armed\n", UVM_LOW);

        vif.cb.i_start <= 1'b1;
        @(vif.cb);
        vif.cb.i_start <= 1'b0;
        @(vif.cb);
    endtask


    virtual task run_phase(uvm_phase phase);
        mem_content_t m;
        super.run_phase(phase);
        `uvm_info("rf_driver", "run_phase is called\n", UVM_LOW);

        vif.cb.i_seq_regs <= '0;
        vif.cb.i_ctrl_regs <= '0;
        while (vif.i_rst)
            @(vif.cb);

        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("rf_driver", "got new program\n", UVM_LOW);
            pgm_ap.write(req);
            if (req.has_ctrl)
                burst_ctrl(req.ctrl);
            m = get_mem_content(req);
            burst_mem(m, req.iters);
            start_program();
            seq_item_port.item_done();
        end
    endtask

endclass
