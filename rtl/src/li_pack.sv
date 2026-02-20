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
            p.r_Ix8 <= 'bx;
            p.r_Qx8 <= 'bx;
            p.r_validx8 <= 8'h0;
            p.r_last <= 1'b0;
        end
        else begin
            p.r_addr <= i_stall ? 'bx : s.r_addr;
            p.r_Ix8 <= i_stall ? 'bx : s.w_Ix8;
            p.r_Qx8 <= i_stall ? 'bx : s.w_Qx8;
            p.r_validx8 <= i_stall ? 8'h0 : s.w_validx8;
            p.r_last <= i_stall ? 1'b0 : s.w_last;
        end
    end

    for (genvar i = 0; i < 8; i++) begin : SCAN_SHIFT_GEN

        if (i == 0) begin
            assign p.w_validx8_scan[i] = 3'd0;
        end
        else begin
            assign p.w_validx8_scan[i] = {2'b00, p.r_validx8[i-1]} + p.w_validx8_scan[i-1];
        end

        assign p.w_validx8_shftamt[i] = i - p.w_validx8_scan[i];
        assign p.w_IQx8_shftamt[i] = {p.w_validx8_shftamt[i], 4'b0000};

        assign p.w_validx8_shift[i] = p.r_validx8[i] ? {
            {(7-i){1'b0}}, p.r_validx8[i], {i{1'b0}}
        } >> p.w_validx8_shftamt[i] : 'h0;

        assign p.w_Ix8_shift[i] = p.r_validx8[i] ? {
            {(ADC_WIDTH*(7-i)){1'b0}}, p.r_Ix8[ADC_WIDTH*(i+1)-1:ADC_WIDTH*i], 
            {(ADC_WIDTH*i){1'b0}}
        } >> p.w_IQx8_shftamt[i] : 'h0;

        assign p.w_Qx8_shift[i] = p.r_validx8[i] ? {
            {(ADC_WIDTH*(7-i)){1'b0}}, p.r_Qx8[ADC_WIDTH*(i+1)-1:ADC_WIDTH*i],
            {(ADC_WIDTH*i){1'b0}}
        } >> p.w_IQx8_shftamt[i] : 'h0;

    end

    assign p.w_validx8_packed = p.w_validx8_shift[0] | p.w_validx8_shift[1] |
        p.w_validx8_shift[2] | p.w_validx8_shift[3] | p.w_validx8_shift[4] |
        p.w_validx8_shift[5] | p.w_validx8_shift[6] | p.w_validx8_shift[7];

    assign p.w_Ix8_packed = p.w_Ix8_shift[0] | p.w_Ix8_shift[1] |
        p.w_Ix8_shift[2] | p.w_Ix8_shift[3] | p.w_Ix8_shift[4] |
        p.w_Ix8_shift[5] | p.w_Ix8_shift[6] | p.w_Ix8_shift[7];

    assign p.w_Qx8_packed = p.w_Qx8_shift[0] | p.w_Qx8_shift[1] |
        p.w_Qx8_shift[2] | p.w_Qx8_shift[3] | p.w_Qx8_shift[4] |
        p.w_Qx8_shift[5] | p.w_Qx8_shift[6] | p.w_Qx8_shift[7];

    assign p.w_samples = {1'b0, p.w_validx8_scan[7]} + {3'b000, p.r_validx8[7]};

endmodule
