// Reference model: predicts the expected rf_trace for a rf_program.
//
// TODO: unimplemented. Should mirror rf_core's per-beat output sequence
// (KB/BC/idle handling per w_kbc_mode, default I/Q substitution while idle,
// sample-count/arm/marker propagation) the way dc_model::predict() mirrors
// dc_core. Until that's written, this just drains agt2mdl_pgm_fifo without
// publishing anything, so the scoreboard will flag every actual trace as
// unexpected.
class rf_model extends uvm_component;

    `uvm_component_utils(rf_model)

    uvm_blocking_get_port #(rf_program) pgm_port;
    uvm_analysis_port #(rf_trace) trc_ap;

    function new(string name = "rf_model", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("rf_model", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("rf_model", "build_phase is called\n", UVM_LOW);
        pgm_port = new("pgm_port", this);
        trc_ap = new("trc_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rf_program pgm;

        super.run_phase(phase);
        `uvm_info("rf_model", "run_phase is called\n", UVM_LOW);

        forever begin
            pgm_port.get(pgm);
            `uvm_info("rf_model", "got new program\n", UVM_LOW);
            `uvm_warning("rf_model", "predict() not implemented -- no expected trace published\n");
        end
    endtask

endclass
