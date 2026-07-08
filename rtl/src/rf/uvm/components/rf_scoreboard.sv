class rf_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(rf_scoreboard)

    uvm_blocking_get_port #(rf_trace) exp_port;
    uvm_blocking_get_port #(rf_trace) act_port;

    rf_trace exp_q[$];
    rf_trace act_q[$];

    int unsigned pass_count = 0;
    int unsigned fail_count = 0;


    function new(string name = "rf_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("rf_scoreboard", "new is called\n", UVM_LOW);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("rf_scoreboard", "build_phase is called\n", UVM_LOW);
        exp_port = new("exp_port", this);
        act_port = new("act_port", this);
    endfunction


    virtual task run_phase(uvm_phase phase);

        rf_trace get_expect, get_actual, pop_expect;
        bit result;

        super.run_phase(phase);
        `uvm_info("rf_scoreboard", "run_phase is called\n", UVM_LOW);

        fork

            forever begin
                exp_port.get(get_expect);
                exp_q.push_back(get_expect);
            end

            forever begin

                act_port.get(get_actual);

                if (exp_q.size() > 0) begin
                    pop_expect = exp_q.pop_front();
                    result = get_actual.compare(pop_expect);
                    if (result) begin
                        `uvm_info("rf_scoreboard", "Compare SUCCESS\n", UVM_LOW);
                    end
                    else begin
                        `uvm_error("rf_scoreboard", "Compare FAILED");
                        $display("the expected packet is:");
                        pop_expect.print();
                        $display("the actual packet is:");
                        get_actual.print();
                        `uvm_fatal("rf_scoreboard", "Fatal due to compare failure");
                    end
                end
                else begin
                    `uvm_fatal("rf_scoreboard", "Received from DUT, while Expect Queue is empty");
                    $display("the unexpected trace is");
                    get_actual.print();
                end
            end

        join
    endtask

endclass
