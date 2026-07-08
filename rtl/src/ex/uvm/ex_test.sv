class ex_base_test extends uvm_test;

    `uvm_component_utils(ex_base_test)

    ex_env env;

    function new(string name = "ex_base_test", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("ex_base_test", "new is called\n", UVM_LOW);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("ex_base_test", "build_phase is called\n", UVM_LOW);
        env = ex_env::type_id::create("env", this);
        uvm_config_db#(uvm_object_wrapper)::set(
            this,
            "env.agt.sqr.main_phase",
            "default_sequence",
            ex_rand_sequence::type_id::get()
        );
    endfunction


    virtual function void report_phase(uvm_phase phase);

        uvm_report_server server;
        int err_num;
        super.report_phase(phase);
        `uvm_info("base_test", "report_phase is called\n", UVM_LOW);

        server = get_report_server();
        err_num = server.get_severity_count(UVM_ERROR);

        if (err_num != 0) begin
            $display("TEST CASE FAILED");
        end
        else begin
            $display("TEST CASE PASSED");
        end

    endfunction

endclass
