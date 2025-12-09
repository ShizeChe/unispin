`timescale 1ns / 1ps

module rf_decode 
   #(parameter KBC_WIDTH=36,
     parameter NUM_SAMPLE_WIDTH=20,
     parameter INSN_WIDTH=KBC_WIDTH*2+NUM_SAMPLE_WIDTH+3)
    (input  logic [INSN_WIDTH-1:0] i_insn,
     output logic [KBC_WIDTH-1:0] o_k, o_b, o_c,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_samples,
     output logic o_arm, 
     output logic o_idle);

    logic [1:0] w_type;

    always_comb begin

        w_type = i_insn[INSN_WIDTH-1:INSN_WIDTH-2];

        case (w_type)
            2'b00: begin
                o_k = 'd0;
                o_b = 'd0;
                o_c = 'd0;
                o_samples = i_insn[NUM_SAMPLE_WIDTH-1:0];
                o_arm = i_insn[INSN_WIDTH-3];
                o_idle = 1'b1;
            end
            2'b01: begin
                o_c = 'd0;
                {o_arm, o_k, o_b, o_samples} = i_insn[KBC_WIDTH*2+NUM_SAMPLE_WIDTH:0];
                o_idle = 1'b0;
            end
            2'b10: begin
                o_k = 'd0;
                {o_arm, o_b, o_c, o_samples} = i_insn[KBC_WIDTH*2+NUM_SAMPLE_WIDTH:0];
                o_idle = 1'b0;
            end
            default: begin
                o_k = 'd0;
                o_b = 'd0;
                o_c = 'd0;
                o_samples = 'd8;
            end
        endcase
    end

endmodule
