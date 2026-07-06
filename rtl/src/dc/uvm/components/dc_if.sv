interface dc_input_if(input i_clk, input i_rst);
    logic [0:DC_SEQ_REGS-1][31:0] i_seq_regs;
    logic [0:DC_CTRL_REGS-1][31:0] i_ctrl_regs;

    logic i_start;
    logic o_armed;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_armed;
        output i_rst, i_seq_regs, i_ctrl_regs, i_start;
    endclocking
endinterface

interface dc_output_if(input i_clk, input i_rst);
    logic o_empty; 
    dc_eop_t o_eop;

    clocking cb @(posedge i_clk);
        default input #1step output #0;
        input o_empty, o_eop;
        output i_rst;
    endclocking
endinterface

interface dc_dac_output_if;
    logic [19:0] vdigital;
endinterface
