// Reference model: predicts the expected dc_trace for a dc_program.
//
// Predicts one dc_eop_t + one DAC voltage per committed dc_core pipeline
// beat (not per clock cycle -- see dc_env's connect_phase). w_cycles_left /
// w_ldac_cycles are left '0 (pure countdown timers with no single "correct"
// value at this granularity -- checking them is the monitor's job) and
// w_spi_dout is left 'x (dc_tb never drives i_miso, so it isn't predictable
// yet); the scoreboard's compare() only checks the fields this model
// actually predicts.
class dc_model #(int MIN_HOLD_CYCLES) extends uvm_component;

    `uvm_component_param_utils(dc_model #(MIN_HOLD_CYCLES))

    uvm_blocking_get_port #(dc_program #(MIN_HOLD_CYCLES)) pgm_port;
    uvm_analysis_port #(dc_trace) trc_ap;

    // The DAC's committed output code. A real register that persists across
    // separate dc_program items (unlike the program content below, which
    // each dc_program fully reprograms), so it lives here rather than as a
    // predict()-local variable.
    protected logic [DC_DAC_WIDTH-1:0] dac_voltage;

    function new(string name = "dc_model", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("dc_model", "new is called\n", UVM_LOW);
        dac_voltage = '0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("dc_model", "build_phase is called\n", UVM_LOW);
        pgm_port = new("pgm_port", this);
        trc_ap = new("trc_ap", this);
    endfunction

    // Predicts the beat sequence for one full run of pgm (all pgm.iters
    // passes over the program), mirroring dc_core's data path:
    //  - each instruction unrolls into w_iters+1 beats, ramping the low
    //    DC_DAC_WIDTH bits of spi_din by w_dspi_din each beat;
    //  - w_modify applies a single +w_dspi_din step to the *base* value
    //    (spi_din or, for idle instructions, hold_cycles) of that program
    //    address, persisted for the next time that address is read;
    //  - consecutive w_idle beats always coalesce into a single eop entry:
    //    dc_core's iterate stage free-runs through idle beats (one per
    //    cycle) while the hold stage is still busy, so they merge unless
    //    interrupted by a non-idle beat. This holds for any realistic
    //    hold_cycles/dvsr/delay/cs_up configuration, since draining a prior
    //    SPI transaction or hold delay always takes far longer than
    //    free-running through an idle run.
    local function void predict(dc_program #(MIN_HOLD_CYCLES) pgm,
                                 output dc_eop_t eop_q[$],
                                 output logic [DC_DAC_WIDTH-1:0] v_q[$]);

        dc_insn_t prog[$];
        bit idle_pending;
        dc_eop_t idle_eop;

        prog = pgm.insns; // mutable copy, one cell per program address
        idle_pending = 1'b0;

        for (int pass = 0; pass < pgm.iters; pass++) begin
            for (int a = 0; a < prog.size(); a++) begin

                dc_insn_t insn;
                insn = prog[a];

                for (int sub = 0; sub <= insn.w_iters; sub++) begin

                    dc_eop_t beat;
                    logic [DC_DAC_WIDTH-1:0] cur_dac_bits, dac_before;

                    cur_dac_bits = insn.w_spi_din[DC_DAC_WIDTH-1:0] +
                        (DC_DAC_WIDTH'(sub) * insn.w_dspi_din);

                    beat.w_addr        = a;
                    beat.w_iter        = insn.w_iters - sub;
                    beat.w_marker      = insn.w_marker;
                    beat.w_ldac_cycles = '0;
                    beat.w_cycles_left = '0;
                    beat.w_spi_dout    = 'x;

                    if (insn.w_idle) begin
                        beat.w_spi_din = '0;
                        beat.w_spi_rd  = 1'b0;
                    end
                    else begin
                        beat.w_spi_din = {insn.w_spi_din[DC_SPI_DATA_WIDTH-1:DC_DAC_WIDTH],
                                          cur_dac_bits};
                        beat.w_spi_rd  = insn.w_spi_rd;
                    end

                    dac_before = dac_voltage;

                    if (insn.w_idle) begin
                        if (!idle_pending) begin
                            idle_pending = 1'b1;
                            idle_eop = beat;
                        end
                        // else: merges into idle_eop -- addr/iter/marker stay
                        // pinned to the run's first beat, matching s.r_ibuf
                    end
                    else begin
                        if (idle_pending) begin
                            eop_q.push_back(idle_eop);
                            v_q.push_back(dac_before);
                            idle_pending = 1'b0;
                        end

                        if (insn.w_strb_ldac)
                            dac_voltage = cur_dac_bits;

                        eop_q.push_back(beat);
                        v_q.push_back(dac_voltage);
                    end

                end

                if (insn.w_modify) begin
                    if (insn.w_idle) begin
                        prog[a].w_hold_cycles = insn.w_hold_cycles +
                            {{(DC_CYCLE_WIDTH-DC_DAC_WIDTH){1'b0}}, insn.w_dspi_din};
                    end
                    else begin
                        prog[a].w_spi_din[DC_DAC_WIDTH-1:0] =
                            insn.w_spi_din[DC_DAC_WIDTH-1:0] + insn.w_dspi_din;
                    end
                end

            end
        end

        if (idle_pending) begin
            eop_q.push_back(idle_eop);
            v_q.push_back(dac_voltage);
        end

    endfunction

    // Actively pulls each dc_program the driver consumed off pgm_fifo,
    // predicts its trace, and publishes it to whatever's connected to ap
    // (dc_scoreboard's exp_export).
    virtual task run_phase(uvm_phase phase);
        dc_program #(MIN_HOLD_CYCLES) pgm;
        dc_trace exp_trace;
        dc_eop_t eop_q[$];
        logic [DC_DAC_WIDTH-1:0] v_q[$];

        super.run_phase(phase);
        `uvm_info("dc_model", "run_phase is called\n", UVM_LOW);

        forever begin
            pgm_port.get(pgm);
            `uvm_info("dc_model", "got new program\n", UVM_LOW);

            exp_trace = dc_trace::type_id::create("exp_trace");
            predict(pgm, eop_q, v_q);
            exp_trace.eop_trace = eop_q;
            exp_trace.v_trace   = v_q;

            trc_ap.write(exp_trace);
        end
    endtask

endclass
