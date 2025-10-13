#ifndef LAUNCHER_H
#define LAUNCHER_H

#include <stdint.h>

typedef struct {
    uint32_t dc_chmask;
    uint32_t rf_chmask;
    uint32_t li_chmask;
} launch_insn_t;

typedef struct {
    int num_dc_chs;
    int num_rf_chs;
    int num_li_chs;
    char chs[];
} launch_chs_t;

launch_insn_t launch_chs2insn(launch_chs_t *launch_chs);

int launch_program_stream(launch_insn_t *launch_insn);

#endif
