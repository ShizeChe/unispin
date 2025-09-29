#include "rf.h"
#include <math.h>
#include <string.h>

static inline int64_t round_clamp(long double x) {
    // Clamp to representable interval first
    long double xc = fminl((long double)RF_KBC_MAX, fmaxl((long double)RF_KBC_MIN, x));
    // Round to nearest (ties away from zero, per llroundl)
    int64_t rx = (int64_t)llroundl(xc);
    // Defensive clamp (in case of odd libm modes)
    if (rx > RF_KBC_MAX) rx = RF_KBC_MAX;
    if (rx < RF_KBC_MIN) rx = RF_KBC_MIN;
    return rx;
}

static inline int64_t k_formula(uint64_t f_span_hz, uint64_t t_ns) {
    long double f_span_ghz      = (long double)f_span_hz * 1e-9L;
    long double f_span_over_dac = f_span_ghz / (long double)RF_DAC_GHZ;
    long double t_times_f_dac   = (long double)t_ns * (long double)RF_DAC_GHZ;

    // 2^(N+1) safely
    long double two_pow = ldexpl(1.0L, RF_KBC_BITS + 1);

    long double k = two_pow / t_times_f_dac * f_span_over_dac;

    return round_clamp(k);
}

static inline int64_t b_formula(uint64_t f_span_hz, uint64_t f_nco_hz, uint64_t t_ns) {
    long double f_span_ghz          = (long double)f_span_hz * 1e-9L;
    long double f_nco_ghz           = (long double)f_nco_hz * 1e-9L;
    long double f_span_over_dac     = f_span_ghz / (long double)RF_DAC_GHZ;
    long double f_span_nco_over_dac = (f_span_ghz + f_nco_ghz) / (long double)RF_DAC_GHZ;
    long double t_times_f_dac       = (long double)t_ns * (long double)RF_DAC_GHZ;

    // 2^N safely
    long double two_pow = ldexpl(1.0L, RF_KBC_BITS);

    long double first_term = two_pow / t_times_f_dac * f_span_over_dac;
    long double second_term = two_pow * f_span_nco_over_dac;
    long double b = first_term - second_term;

    return round_clamp(b);
}

int rf_program_stream(int rf_channel, int stream_len, rf_insn_t *rf_stream) {
    (void) rf_channel; (void) stream_len; (void) rf_stream;
    return 0;
}

rf_insn_t rf_chirp2insn(rf_chirp_t chp) {

    int64_t k = k_formula(chp.f_span_hz, chp.t_ns);
    int64_t b = b_formula(chp.f_span_hz, chp.f_nco_hz, chp.t_ns);

    uint32_t samples = (chp.t_ns * RF_DAC_GHZ + 4) / 8;

    return (rf_insn_t){.k = k, .b = b, .c = 0, .iters = 0,
                       .dkbc_samples = 0, .kbc_samples = samples,
                       .dzero_samples = 0, .zero_samples = 0};
}

rf_insn_t rf_drive2insn(rf_drive_t d) {

    long double two_pow = ldexpl(1.0L, RF_KBC_BITS);
    long double angle = remainderl(d.phase_deg, 360.0L);
    angle = (angle == 180.0L) ? -180.0 : angle;
    long double c = angle / 360.0L * two_pow;

    uint32_t kbc_samples = d.t_drive_ns * RF_DAC_GHZ;
    uint32_t dkbc_samples = d.dt_drive_ns * RF_DAC_GHZ;
    uint32_t zero_samples = d.t_idle_ns * RF_DAC_GHZ;
    uint32_t dzero_samples = d.dt_idle_ns * RF_DAC_GHZ;

    zero_samples = (kbc_samples + zero_samples + 4) / 8 * 8 - kbc_samples;
    dzero_samples = (dkbc_samples + dzero_samples + 4) / 8 * 8 - dkbc_samples;

    return (rf_insn_t){.k = 0, .b = 0, .c = round_clamp(c), 
                       .iters = 0,
                       .dkbc_samples = dkbc_samples, 
                       .kbc_samples = kbc_samples,
                       .dzero_samples = dzero_samples, 
                       .zero_samples = zero_samples};
}

