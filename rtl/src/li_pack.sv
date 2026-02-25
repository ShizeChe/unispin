// `default_nettype none
`timescale 1ns / 1ps
`include "li.svh"

module li_pack
   #(parameter ADC_WIDTH=LI_ADC_WIDTH)
    (input  logic i_clk, i_rst,
     input  li_sample_stg_t s,
     output li_pack_stg_t p,
     input  logic i_stall);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            p.r_addr <= 'bx;
            p.r_QIx4 <= 'bx;
            p.r_validx4 <= 8'h0;
            p.r_last <= 1'b0;
        end
        else begin
            p.r_addr <= i_stall ? 'bx : s.r_addr;
            p.r_QIx4 <= i_stall ? 'bx : s.w_QIx4;
            p.r_validx4 <= i_stall ? 8'h0 : s.w_validx4;
            p.r_last <= i_stall ? 1'b0 : s.w_last;
        end
    end

    for (genvar i = 0; i < 4; i++) begin : SCAN_SHIFT_GEN

        if (i == 0) begin
            assign p.w_validx4_scan[i] = 2'd0;
        end
        else begin
            assign p.w_validx4_scan[i] = {1'b0, p.r_validx4[i-1]} + p.w_validx4_scan[i-1];
        end

        assign p.w_validx4_shftamt[i] = i - p.w_validx4_scan[i];
        assign p.w_QIx4_shftamt[i] = {p.w_validx4_shftamt[i], 5'b0000};

        assign p.w_validx4_shift[i] = p.r_validx4[i] ? {
            {(3-i){1'b0}}, p.r_validx4[i], {i{1'b0}}
        } >> p.w_validx4_shftamt[i] : 'h0;

        assign p.w_QIx4_shift[i] = p.r_validx4[i] ? {
            {(ADC_WIDTH*2*(3-i)){1'b0}}, p.r_QIx4[ADC_WIDTH*2*(i+1)-1:ADC_WIDTH*2*i], 
            {(ADC_WIDTH*2*i){1'b0}}
        } >> p.w_QIx4_shftamt[i] : 'h0;

    end

    assign p.w_validx4_packed = p.w_validx4_shift[0] | p.w_validx4_shift[1] |
        p.w_validx4_shift[2] | p.w_validx4_shift[3];
    assign p.w_QIx4_packed = p.w_QIx4_shift[0] | p.w_QIx4_shift[1] |
        p.w_QIx4_shift[2] | p.w_QIx4_shift[3];

    assign p.w_samples = {1'b0, p.w_validx4_scan[3]} + {2'b00, p.r_validx4[3]};

endmodule
