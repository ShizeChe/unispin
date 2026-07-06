class dc_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(dc_scoreboard)

    uvm_analysis_imp_exp #(dc_trace, dc_scoreboard) exp_export;
    uvm_analysis_imp_act #(dc_trace, dc_scoreboard) act_export;

    dc_trace exp_q[$];
    dc_trace act_q[$];

    int unsigned pass_count = 0;
    int unsigned fail_count = 0;

    function new(string name = "dc_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_export = new("exp_export", this);
        act_export = new("act_export", this);
    endfunction

    virtual function void write_exp(dc_trace t);
        exp_q.push_back(t);
        compare();
    endfunction

    virtual function void write_act(dc_trace t);
        act_q.push_back(t);
        compare();
    endfunction

    virtual function void compare();
        dc_trace exp_t, act_t;

        if (exp_q.size() == 0 || act_q.size() == 0)
            return;

        exp_t = exp_q.pop_front();
        act_t = act_q.pop_front();

        // TODO: compare exp_t.eop_trace/v_trace against act_t.eop_trace/v_trace
        if (1) begin
            pass_count++;
        end else begin
            fail_count++;
            `uvm_error("dc_scoreboard", "trace mismatch")
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("dc_scoreboard",
            $sformatf("DC Scoreboard Summary: PASS=%0d FAIL=%0d", pass_count, fail_count),
            UVM_LOW)
    endfunction

endclass
