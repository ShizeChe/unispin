`timescale 1ns / 1ps

module zcu216_dac
    (input  logic i_clk, i_dac_clk,
     input  logic [255:0] i_QIx8,
     output logic [13:0] o_I, o_Q,
     output real  o_vrf,
     
     input  logic i_nco_req,
     output logic o_nco_busy,
     input  logic [47:0] i_nco_freq,
     input  logic [17:0] i_nco_phase,
     input  logic [5:0] i_nco_en);

    // simulate DUC
    // if i_clk is 250MHz, simulated nco is 10MHz
    int dac_cycle;
    initial begin
        @(posedge i_clk);
        dac_cycle = 0;
        forever begin
            @(posedge i_dac_clk);
            dac_cycle = (dac_cycle == 7) ? 0 : (dac_cycle + 1);
        end
    end

    localparam IQ_WIDTH=14;

    function automatic real iq2real(input logic [IQ_WIDTH-1:0] iq);
        return $itor($signed(iq)) / (1.0 * (1 << (IQ_WIDTH-1)));
    endfunction

    logic [7:0][IQ_WIDTH-1:0] w_Ix8, w_Qx8;
    for (genvar i = 0; i < 8; i++) begin : QIx8_ASSIGN
        assign w_Ix8[i] = i_QIx8[32*i+2+IQ_WIDTH-1:32*i+2];
        assign w_Qx8[i] = i_QIx8[32*i+16+2+IQ_WIDTH-1:32*i+16+2];
    end

    real I, Q;
    real deg, deg_incr, rad, nco_i, nco_q;
    initial begin
        deg = 0;
        deg_incr = 1.8;
        @(posedge i_clk);
        forever begin
            @(negedge i_dac_clk);
            o_I = w_Ix8[dac_cycle];
            o_Q = w_Qx8[dac_cycle];
            I = iq2real(o_I);
            Q = iq2real(o_Q);
            deg = deg + deg_incr;
            rad = deg * 3.14159265358979323846 / 180.0;
            nco_i = $cos(rad);
            nco_q = $sin(rad);
            o_vrf = I * $cos(rad) - Q * $sin(rad);
        end
    end

    function automatic int get_busy_cycles(input logic [5:0] en);
        case (en)
            6'b111111: return 39;
            6'b111110: return 34;
            6'b111101: return 38;
            6'b111100: return 31;
            6'b111011: return 38;
            6'b111010: return 33;
            6'b111001: return 35;
            6'b111000: return 28;
            6'b110111: return 38;
            6'b110110: return 33;
            6'b110101: return 37;
            6'b110100: return 30;
            6'b110011: return 35;
            6'b110010: return 30;
            6'b110001: return 32;
            6'b110000: return 25;
            6'b101111: return 38;
            6'b101110: return 33;
            6'b101101: return 37;
            6'b101100: return 30;
            6'b101011: return 37;
            6'b101010: return 32;
            6'b101001: return 34;
            6'b101000: return 27;
            6'b100111: return 35;
            6'b100110: return 30;
            6'b100101: return 34;
            6'b100100: return 27;
            6'b100011: return 32;
            6'b100010: return 27;
            6'b100001: return 29;
            6'b100000: return 22;
            6'b011111: return 38;
            6'b011110: return 33;
            6'b011101: return 37;
            6'b011100: return 30;
            6'b011011: return 37;
            6'b011010: return 32;
            6'b011001: return 34;
            6'b011000: return 27;
            6'b010111: return 37;
            6'b010110: return 32;
            6'b010101: return 36;
            6'b010100: return 29;
            6'b010011: return 34;
            6'b010010: return 29;
            6'b010001: return 31;
            6'b010000: return 24;
            6'b001111: return 35;
            6'b001110: return 30;
            6'b001101: return 34;
            6'b001100: return 27;
            6'b001011: return 34;
            6'b001010: return 29;
            6'b001001: return 31;
            6'b001000: return 24;
            6'b000111: return 32;
            6'b000110: return 27;
            6'b000101: return 31;
            6'b000100: return 24;
            6'b000011: return 29;
            6'b000010: return 24;
            6'b000001: return 26;
            default:   return 30;
        endcase
    endfunction

    // nco update
    enum {IDLE, HOLD, BUSY} state;
    logic [47:0] freq, ifreq;
    logic [17:0] phase, iphase;
    logic [5:0] en, ien;
    int hold_cycles;
    int busy_cycles;

    function automatic real freq2real(input logic [47:0] freq);
        return $itor($signed(freq)) * 2.0e9 / (1.0 * (64'd1 << 48));
    endfunction

    function automatic real get_deg_incr(input real freq_hz);
        return freq_hz * 360.0 / 1.0e9 * 0.5;
    endfunction

    function automatic real phase2real(input logic [17:0] phase);
        return $itor($signed(phase)) * 360.0 / (1.0 * (1 << 18));
    endfunction

    function automatic logic [47:0] freq_en (
        input logic [47:0] freq, 
        input logic [47:0] ifreq, 
        input logic [5:0] ien
    );

        logic [47:0] new_freq = freq;

        if (ien[2]) begin
            new_freq[47:32] = ifreq[47:32];
        end

        if (ien[1]) begin
            new_freq[31:16] = ifreq[31:16];
        end

        if (ien[0]) begin
            new_freq[15:0] = ifreq[15:0];
        end

        return new_freq;

    endfunction

    function automatic logic [47:0] phase_en (
        input logic [17:0] phase, 
        input logic [17:0] iphase, 
        input logic [5:0] ien
    );

        logic [17:0] new_phase = phase;

        if (ien[4]) begin
            new_phase[17:16] = iphase[17:16];
        end

        if (ien[3]) begin
            new_phase[15:0] = iphase[15:0];
        end

        if (ien[5]) begin
            new_phase = 'h0;
        end

        return new_phase;

    endfunction

    assign o_nco_busy = (state == BUSY);

    initial begin

        state = IDLE;
        hold_cycles = 0;
        busy_cycles = 0;

        freq = 'h0;
        phase = 'h0;
        en = 'h0;

        forever begin

            @(negedge i_clk);

            if (state == IDLE) begin

                if (i_nco_req) begin

                    ifreq = i_nco_freq;
                    iphase = i_nco_phase;
                    ien = i_nco_en;

                    @(posedge i_clk);

                    state = HOLD;
                    hold_cycles = $urandom_range(1, 10);

                end

            end
            else if (state == HOLD) begin

                if (i_nco_req) begin

                    ifreq = i_nco_freq;
                    iphase = i_nco_phase;
                    ien = i_nco_en;

                    hold_cycles = $urandom_range(0, 10);

                end
                else if (
                    i_nco_freq !== ifreq ||
                    i_nco_phase !== iphase ||
                    i_nco_en !== ien
                ) begin

                    // failure to hold results in x
                    ifreq = 'hx;
                    iphase = 'hx;
                    ien = 'hx;

                    if (hold_cycles == 0) begin
                        state = BUSY;
                        busy_cycles = get_busy_cycles(ien);
                    end
                    else begin
                        hold_cycles--;
                    end

                end
                else begin

                    if (hold_cycles == 0) begin
                        state = BUSY;
                        busy_cycles = get_busy_cycles(ien);
                    end
                    else begin
                        hold_cycles--;
                    end

                end

            end
            else begin

                if (i_nco_req) begin

                    ifreq = i_nco_freq;
                    iphase = i_nco_phase;
                    ien = i_nco_en;

                    state = HOLD;
                    hold_cycles = $urandom_range(0, 10);

                end
                else if (
                    i_nco_freq !== ifreq ||
                    i_nco_phase !== iphase ||
                    i_nco_en !== ien
                ) begin

                    // failure to hold results in x
                    ifreq = 'hx;
                    iphase = 'hx;
                    ien = 'hx;

                    if (busy_cycles == 0) begin
                        @(posedge i_clk);
                        phase = phase_en(phase, iphase, ien);
                        freq = freq_en(freq, ifreq, ien);
                        deg += phase2real(phase);
                        deg_incr = get_deg_incr(freq2real(freq));
                        state = IDLE;
                    end
                    else begin
                        busy_cycles--;
                    end

                end
                else begin

                    if (busy_cycles == 0) begin
                        @(posedge i_clk);
                        phase = phase_en(phase, iphase, ien);
                        freq = freq_en(freq, ifreq, ien);
                        deg += phase2real(phase);
                        deg_incr = get_deg_incr(freq2real(freq));
                        $display("freq=%0h", freq);
                        $display("freq(real)=%0.6f", freq2real(freq));
                        $display("deg_incr=%0h", deg_incr);
                        state = IDLE;
                    end
                    else begin
                        busy_cycles--;
                    end

                end

            end

        end

    end

endmodule
