interface dc_input_if(input i_clk, input i_rst);
    logic [0:DC_SEQ_REGS-1][31:0] i_seq_regs;
    logic [0:DC_CTRL_REGS-1][31:0] i_ctrl_regs;
    logic o_armed;
endinterface

interface dc_output_if(input i_clk, input i_rst);
endinterface
