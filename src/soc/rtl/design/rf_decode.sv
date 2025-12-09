`timescale 1ns / 1ps

module rf_decode 
   #(parameter KBC_WIDTH=36,
     parameter NUM_SAMPLE_WIDTH=20,
     parameter INSN_WIDTH=KBC_WIDTH*2+NUM_SAMPLE_WIDTH*2+3)
    (input  logic [INSN_WIDTH-1:0] i_insn,
     output logic [KBC_WIDTH-1:0] o_k, o_b, o_c,
     output logic [NUM_SAMPLE_WIDTH-1:0] o_samples,
     output logic o_arm, 
     output logic o_idle,
     output logic o_insn_modified);

    logic [1:0] w_type;
    logic [KBC_WIDTH-1:0] w_kbc1, w_kbc2;
    logic [NUM_SAMPLE_WIDTH-1:0] w_dsamples;

    assign {o_arm, w_type, w_kbc1, w_kbc2, o_samples, w_dsamples} = i_insn;

    always_comb begin
        case (w_type)
            2'b00: begin
                o_k = 'd0;
                o_b = 'd0;
                o_c = 'd0;
                o_idle = 1'b1;
            end
            2'b01: begin
                o_k = w_kbc1;
                o_b = w_kbc2;
                o_c = 'd0;
                o_idle = 1'b0;
            end
            2'b10: begin
                o_k = 'd0;
                o_b = w_kbc1;
                o_c = w_kbc2;
                o_idle = 1'b0;
            end
            default: begin
                o_k = 'd0;
                o_b = 'd0;
                o_c = 'd0;
                o_idle = 1'b1;
            end
        endcase
    end

    assign o_insn_modified = {o_arm, w_type, w_kbc1, w_kbc2, o_samples + w_dsamples, w_dsamples};

endmodule
