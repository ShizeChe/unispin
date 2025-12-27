#include "rf.h"
#include "common.h"
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>

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

static inline uint32_t iptr2reg(uint8_t **iptr_buf, int n) {
    assert(1 <= n && n <= IPTR_PER_REG);
    uint32_t res = 0;
    for (int i = 0; i < n; i++) {
        res |= ((uint32_t)((*iptr_buf)[i])) << (i * IPTR_BITS);
        (*iptr_buf)++;
    }
    return res;
}

rf_insn_t rf_chirp2insn(rf_chirp_t chp) {

    int64_t k = k_formula(chp.f_span_hz, chp.t_ns);
    int64_t b = b_formula(chp.f_span_hz, chp.f_nco_hz, chp.t_ns);

    uint32_t samples = (chp.t_ns * RF_DAC_GHZ + 4) / 8 * 8;

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
                       .iters = d.iters,
                       .dkbc_samples = dkbc_samples, 
                       .kbc_samples = kbc_samples,
                       .dzero_samples = dzero_samples, 
                       .zero_samples = zero_samples};
}

void rf_pack_stream(int stream_iters, int insn_len, rf_insn_t *rf_insn_buf, 
                    int iptr_len, uint8_t *rf_iptr_buf, uint32_t *rf_regs) {

    assert(insn_len <= INSN_PER_RF_CHANNEL);
    assert(iptr_len <= IPTR_PER_RF_CHANNEL);
    
    DBG("set 1\n");

    for (int i = 0; i < insn_len; i++) {

        uint64_t k = ((uint64_t)rf_insn_buf[i].k << 28) >> 28;
        uint64_t b = ((uint64_t)rf_insn_buf[i].b << 28) >> 28;
        uint64_t c = ((uint64_t)rf_insn_buf[i].c << 28) >> 28;
        uint32_t iters = rf_insn_buf[i].iters;
        uint32_t dkbcs = rf_insn_buf[i].dkbc_samples;
        uint32_t kbcs = rf_insn_buf[i].kbc_samples;
        uint32_t dzeros = rf_insn_buf[i].dzero_samples;
        uint32_t zeros = rf_insn_buf[i].zero_samples;

        DBG("insn%d: {\nk = %lx\nb = %lx\nc = %lx\niters = %d\ndkbcs = %d\nkbcs = %d\ndzeros = %d\nzeros = %d\n}",
               i, k, b, c, iters, dkbcs, kbcs, dzeros, zeros);

        rf_regs[8 * i + 7] = (uint32_t)(k >> 22);
        rf_regs[8 * i + 6] = ((uint32_t)(k << 10)) | ((uint32_t)(b >> 26));
        rf_regs[8 * i + 5] = ((uint32_t)(b << 6)) | ((uint32_t)(c >> 30));
        rf_regs[8 * i + 4] = ((uint32_t)(c << 2)) | (iters >> 8);
        rf_regs[8 * i + 3] = (iters << 24) | (dkbcs >> 6);
        rf_regs[8 * i + 2] = (dkbcs << 26) | (kbcs >> 4);
        rf_regs[8 * i + 1] = (kbcs << 28) | (dzeros >> 2);
        rf_regs[8 * i] = (dzeros << 30) | zeros;

        DBG("rf_regs: {\n[7] = %x\n[6] = %x\n[5] = %x\n[4] = %x\n[3] = %x\n[2] = %x\n[1] = %x\n[0] = %x\n",
               rf_regs[8 * i + 7], rf_regs[8 * i + 6], rf_regs[8 * i + 5], rf_regs[8 * i + 4],
               rf_regs[8 * i + 3], rf_regs[8 * i + 2], rf_regs[8 * i + 1], rf_regs[8 * i]);
        DBG("set rf_regs[%d]\n", 8 * i + 7);
        DBG("set rf_regs[%d]\n", 8 * i + 6);
        DBG("set rf_regs[%d]\n", 8 * i + 5);
        DBG("set rf_regs[%d]\n", 8 * i + 4);
        DBG("set rf_regs[%d]\n", 8 * i + 3);
        DBG("set rf_regs[%d]\n", 8 * i + 2);
        DBG("set rf_regs[%d]\n", 8 * i + 1);
        DBG("set rf_regs[%d]\n", 8 * i);

    }

    DBG("set 2\n");

    for (int i = insn_len * 8; i < INSN_PER_RF_CHANNEL * 8; i++) {

        rf_regs[i] = 0;

        DBG("set rf_regs[%d]\n", i);

    }

    uint8_t *iptr_buf = rf_iptr_buf;

    DBG("set 3\n");

    for (int i = 0; i < iptr_len / IPTR_PER_REG; i++) {

        rf_regs[INSN_PER_RF_CHANNEL * 8 + i] = iptr2reg(&iptr_buf, IPTR_PER_REG);

        DBG("set rf_regs[%d]\n", INSN_PER_RF_CHANNEL * 8 + i);

    }

    if (iptr_len % IPTR_PER_REG > 0) {

        DBG("set 4\n");

        rf_regs[INSN_PER_RF_CHANNEL * 8 + iptr_len / IPTR_PER_REG] = \
            iptr2reg(&iptr_buf, iptr_len % IPTR_PER_REG);

        DBG("set rf_regs[%d]\n", INSN_PER_RF_CHANNEL * 8 + iptr_len / IPTR_PER_REG);

        DBG("set 5\n");

        for (int i = INSN_PER_RF_CHANNEL * 8 + iptr_len / IPTR_PER_REG + 1; 
                 i < REG_PER_RF_CHANNEL - 2; i++) {

            rf_regs[i] = 0; 

            DBG("set rf_regs[%d]\n", i);

        }

    } else {

        DBG("set 6\n");

        for (int i = INSN_PER_RF_CHANNEL * 8 + iptr_len / IPTR_PER_REG; 
                 i < REG_PER_RF_CHANNEL - 2; i++) {

            rf_regs[i] = 0; 

            DBG("set rf_regs[%d]\n", i);

        }

    }

    rf_regs[REG_PER_RF_CHANNEL - 2] = (((uint32_t)iptr_len - 1) << 10) | 
                                      ((uint32_t)stream_iters);
    DBG("set 7\n");
    DBG("set rf_regs[%d]\n", REG_PER_RF_CHANNEL - 2);

    rf_regs[REG_PER_RF_CHANNEL - 1] = 1;

    DBG("set 8\n");
    DBG("set rf_regs[%d]\n", REG_PER_RF_CHANNEL - 1);

}

/*int rf_program_stream(int rf_channel, int stream_iters, int insn_len, */
/*                      rf_insn_t *rf_insn_buf, int iptr_len, uint8_t *rf_iptr_buf) {*/
/**/
/*    uint32_t rf_regs[REG_PER_RF_CHANNEL];*/
/*    rf_pack_stream(stream_iters, insn_len, rf_insn_buf, iptr_len, rf_iptr_buf, */
/*                   rf_regs);*/
/**/
/*#if TEST*/
/**/
/*    char fp[32];*/
/*    snprintf(fp, sizeof(fp), "dump/rf%d.txt", rf_channel);*/
/**/
/*    FILE *f = fopen(fp, "w");*/
/*    if (f == NULL) {*/
/*        fprintf(stderr, "fopen(\"%s\") failed: %s\n", fp, strerror(errno));*/
/*        return 1;*/
/*    }*/
/**/
/*    for (int i = 0; i < REG_PER_RF_CHANNEL; i++) {*/
/*        print_binary(f, rf_regs[i]);*/
/*    }*/
/**/
/*    fclose(f);*/
/**/
/*#else*/
/**/
/*    char uio_path[32];*/
/*    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", RF_UIO_BASE + rf_channel);*/
/**/
/*    int rf_fd = open(uio_path, O_RDWR);*/
/*    if (rf_fd < 0) {*/
/*        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));*/
/*        return 1;*/
/*    }*/
/**/
/*    void *rf_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, rf_fd, 0);*/
/*    if (rf_va == MAP_FAILED) {*/
/*        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));*/
/*        close(rf_fd);*/
/*        return 1;*/
/*    }*/
/**/
/*    volatile uint32_t *rf_base = (volatile uint32_t *)((char *)rf_va);*/
/*    for (int i = 0; i < REG_PER_DC_CHANNEL; i++) {*/
/*        *(rf_base + i) = rf_regs[i];*/
/*    }*/
/**/
/*    __asm__ __volatile__("dsb oshst" ::: "memory");*/
/**/
/*#endif*/
/**/
/*    return 0;*/
/*}*/

