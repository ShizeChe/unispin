// Reference model: predicts the expected li_trace for a li_program.
//
// TODO: unimplemented. Should mirror li_core's per-beat sample-packing
// sequence (stride/sample-count stepping, ADC sample capture off i_QIx4,
// tag/valid/last packing) the way dc_model::predict() mirrors dc_core.
// Until that's written, this just drains agt2mdl_pgm_fifo without
// publishing anything, so the scoreboard will flag every actual trace as
// unexpected.
class li_model extends uvm_component;

    `uvm_component_utils(li_model)

    uvm_blocking_get_port #(li_program) pgm_port;
    uvm_analysis_port #(li_trace) trc_ap;

    function new(string name = "li_model", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("li_model", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("li_model", "build_phase is called\n", UVM_LOW);
        pgm_port = new("pgm_port", this);
        trc_ap = new("trc_ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        li_program pgm;

        super.run_phase(phase);
        `uvm_info("li_model", "run_phase is called\n", UVM_LOW);

        forever begin
            pgm_port.get(pgm);
            `uvm_info("li_model", "got new program\n", UVM_LOW);
            `uvm_warning("li_model", "predict() not implemented -- no expected trace published\n");
        end
    endtask

endclass
