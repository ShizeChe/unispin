#ifndef LAUNCHER_H
#define LAUNCHER_H

#include <stdint.h>
#include "common.h"

#define LAUNCH_TOTAL_REGS 6
#define LAUNCH_UIO 30

typedef struct {
    uint32_t dc_chmask;
    uint32_t rf_chmask;
    uint32_t li_chmask;
    uint32_t ex_chmask;
} launch_t;

int launch_parse(char *line, launch_t *launch);
int launch_load(launch_t *launch);
int launch_read_regs(uint32_t *regs);

#endif
