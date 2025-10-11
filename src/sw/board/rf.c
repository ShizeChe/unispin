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

static inline void print_binary(FILE *f, uint32_t value) {
    for (int i = 31; i >= 0; --i) {
        fprintf(f, "%d\n", (value >> i) & 1);
    }
}

static inline uint32_t iptr2reg(uint8_t **iptr_buf, int n) {
    assert(1 <= n && n <= IPTR_PER_REG);
    uint32_t res = 0;
    for (int i = 0; i < n; i++) {
        res |= ((uint32_t)((*iptr_buf)[i])) << (i * IPTR_WIDTH);
        *iptr_buf++;
    }
    return res;
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

void rf_pack_stream(int stream_iters, int insn_len, rf_insn_t *rf_insn_buf, 
                    int iptr_len, uint8_t *rf_iptr_buf, uint32_t *rf_regs) {

    assert(insn_len <= INSN_PER_RF_CHANNEL);
    assert(iptr_len <= IPTR_PER_RF_CHANNEL);
    
    for (int i = 0; i < insn_len; i++) {

        uint64_t k = ((uint64_t)(rf_insn_buf[i].k << 28)) >> 28;
        uint64_t b = ((uint64_t)(rf_insn_buf[i].b << 28)) >> 28;
        uint64_t c = ((uint64_t)(rf_insn_buf[i].c << 28)) >> 28;
        uint32_t iters = rf_insn_buf[i].iters;
        uint32_t dkbcs = rf_insn_buf[i].dkbcs;
        uint32_t kbcs = rf_insn_buf[i].kbcs;
        uint32_t dzeros = rf_insn_buf[i].dzeros;
        uint32_t zeros = rf_insn_buf[i].zeros;

        rf_regs[8 * i + 7] = (uint32_t)(k >> 22);
        rf_regs[8 * i + 6] = ((uint32_t)(k << 10)) | ((uint32_t)(b >> 26));
        rf_regs[8 * i + 5] = ((uint32_t)(b << 6)) | ((uint32_t)(c >> 30));
        rf_regs[8 * i + 4] = ((uint32_t)(c << 2)) | (iters >> 8);
        rf_regs[8 * i + 3] = (iters << 24) | (dkbcs >> 6);
        rf_regs[8 * i + 2] = (dkbcs << 26) | (kbcs >> 4);
        rf_regs[8 * i + 1] = (kbcs << 28) | (dzeros >> 2);
        rf_regs[8 * i] = (dzeros << 30) | zeros;

    }
    for (int i = insn_len * 8; i < INSN_PER_RF_CHANNEL * 8; i++) {
        rf_regs[i] = 0;
    }

    uint8_t *iptr_buf = rf_iptr_buf;
    for (int i = 0; i < iptr_len / IPTR_PER_REG; i++) {
        rf_regs[insn_len + i] = iptr2reg(&iptr_buf, IPTR_PER_REG);
    }

    if (iptr_len % IPTR_PER_REG > 0) {

        rf_regs[insn_len + iptr_len / IPTR_PER_REG] = \
            iptr2reg(&iptr_buf, iptr_len % IPTR_PER_REG);

        for (int i = insn_len + iptr_len / IPTR_PER_REG + 1; 
                 i < REG_PER_RF_CHANNEL - 2; i++) {
            rf_regs[i] = 0; 
        }
    } else {
        for (int i = insn_len + iptr_len / IPTR_PER_REG; 
                 i < REG_PER_RF_CHANNEL - 2; i++) {
            rf_regs[i] = 0; 
        }
    }

    rf_regs[REG_PER_RF_CHANNEL - 2] = (((uint32_t)iptr_len - 1) << 10) | 
                                      ((uint32_t)stream_iters);
    rf_regs[REG_PER_RF_CHANNEL - 1] = 1;

}

int rf_program_stream(int rf_channel, int stream_iters, int insn_len, 
                      rf_insn_t *rf_insn_buf, int iptr_len, uint8_t *rf_iptr_buf,
                      int test) {

    uint32_t rf_regs[REG_PER_RF_CHANNEL];
    rf_pack_stream(stream_iters, insn_len, rf_insn_buf, iptr_len, rf_iptr_buf, 
                   rf_regs);
    
    if (test) {

        char fp[32];
        snprintf(fp, sizeof(fp), "regval/rf%d.txt", rf_channel);

        FILE *f = fopen(fp, "w");
        if (f == NULL) {
            perror("Error opening file");
            return 1;
        }

        for (int i = 0; i < REG_PER_RF_CHANNEL; i++) {
            print_binary(f, rf_regs[i]);
        }

        fclose(f);

    } else {

        char uio_path[32];
        snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", RF_UIO_BASE + rf_channel);

        int rf_fd = open(uio_path, O_RDWR);
        if (rf_fd < 0) {
            perror("open %s", uio_path);
            return 1;
        }

        void *rf_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, rf_fd, 0);
        if (rf_va == MAP_FAILED) {
            perror("dc0 mmap");
            close(rf_fd);
            return 1;
        }

        volatile uint32_t *rf_base = (volatile uint32_t *)((char *)rf_va);
        for (int i = 0; i < REG_PER_DC_CHANNEL; i++) {
            *(rf_base + i) = rf_regs[i];
        }

        __asm__ __volatile__("dsb oshst" ::: "memory");

    }

    return 0;
}

