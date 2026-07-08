class ex_rand_sequence extends uvm_sequence #(ex_program);

    `uvm_object_utils(ex_rand_sequence);

    ex_program pgm;

    function new(string name = "ex_rand_sequence");
        super.new(name);
        `uvm_info("ex_rand_sequence", "new is called\n", UVM_LOW);
    endfunction


    virtual task body();
        int i = 0;
        uvm_phase phase;

        phase = get_starting_phase();

        if (phase != null)
            phase.raise_objection(this);
        else
            `uvm_info("ex_rand_sequence", "starting phase is null\n", UVM_LOW);

        repeat (3) begin
            // `uvm_do macro creates a new pgm, randomizes it, and sends it to
            // sequencer
            `uvm_info("ex_rand_sequence", $sformatf("send %0dth pgm\n", i++), UVM_LOW);
            `uvm_do(pgm);
        end

        #100000;

        if (phase != null)
            phase.drop_objection(this);
        else
            `uvm_info("ex_rand_sequence", "starting phase is null\n", UVM_LOW);

    endtask

endclass
