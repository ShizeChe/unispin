#include "launch.h"
#include <stdint.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

static inline void print_binary(FILE *f, uint32_t value) {
    for (int i = 31; i >= 0; --i) {
        fprintf(f, "%d", (value >> i) & 1);
    }
    fprintf(f, "\n");
}

launch_insn_t launch_chs2insn(launch_chs_t *launch_chs) {

    uint32_t dc_chmask = 0;
    uint32_t rf_chmask = 0;
    uint32_t li_chmask = 0;

    for (int i = 0; i < launch_chs->num_dc_chs; i++) {
        int dc_ch = launch_chs->chs[i];
        dc_chmask |= 1U << dc_ch;
    }

    int rf_base = launch_chs->num_dc_chs;
    for (int i = 0; i < launch_chs->num_rf_chs; i++) {
        int rf_ch = launch_chs->chs[rf_base + i];
        rf_chmask |= 1U << rf_ch;
    }

    int li_base = launch_chs->num_dc_chs + launch_chs->num_rf_chs;
    for (int i = 0; i < launch_chs->num_li_chs; i++) {
        int li_ch = launch_chs->chs[li_base + i];
        li_chmask |= 1U << li_ch;
    }

    return (launch_insn_t){
        .dc_chmask = dc_chmask,
        .rf_chmask = rf_chmask,
        .li_chmask = li_chmask,
    };

}

int launch_program_stream(launch_insn_t *launch_insn) {

#if TEST
    
    char fp[32];
    snprintf(fp, sizeof(fp), "dump/launch.txt");

    FILE *f = fopen(fp, "w");
    if (f == NULL) {
        fprintf(stderr, "fopen(\"%s\") failed: %s\n", fp, strerror(errno));
        return 1;
    }

    print_binary(f, launch_insn->dc_chmask);
    print_binary(f, launch_insn->rf_chmask);
    print_binary(f, launch_insn->li_chmask);
    print_binary(f, 1);

    fclose(f);

#else

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", LAUNCH_UIO);

    int launch_fd = open(uio_path, O_RDWR);
    if (launch_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *launch_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, launch_fd, 0);
    if (launch_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(dc_fd);
        return 1;
    }

    volatile uint32_t *launch_base = (volatile uint32_t *)((char *)launch_va);
    *launch_base = launch_insn->dc_chmask;
    *(launch_base + 1) = launch_insn->rf_chmask;
    *(launch_base + 2) = launch_insn->li_chmask;
    *(launch_base + 3) = 1;

    __asm__ __volatile__("dsb oshst" ::: "memory");

#endif

    return 0;
}
