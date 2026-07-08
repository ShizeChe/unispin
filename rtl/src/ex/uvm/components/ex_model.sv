// Reference model: predicts the expected ex_trace for a ex_program.
//
// TODO: unimplemented. Should mirror ex_core's per-beat output sequence
// (sample-count stepping, w_real replication across the realx16 word) the
// way dc_model::predict() mirrors dc_core. Until that's written, this just
// drains agt2mdl_pgm_fifo without publishing anything, so the scoreboard
// will flag every actual trace as unexpected.
class ex_model extends uvm_component;

    `uvm_component_utils(ex_model)

    uvm_blocking_get_port #(ex_program) pgm_port;
    uvm_analysis_port #(ex_trace) trc_ap;

    function new(string name = "ex_model", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("ex_model", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("ex_model", "build_phase is called\n", UVM_LOW);
        pgm_port = new("pgm_port", this);
        trc_ap = new("trc_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ex_program pgm;

        super.run_phase(phase);
        `uvm_info("ex_model", "run_phase is called\n", UVM_LOW);

        forever begin
            pgm_port.get(pgm);
            `uvm_info("ex_model", "got new program\n", UVM_LOW);
            `uvm_warning("ex_model", "predict() not implemented -- no expected trace published\n");
        end
    endtask

endclass
