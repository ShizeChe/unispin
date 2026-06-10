#ifndef ASM_H
#define ASM_H

#include "dc.h"
#include "rf.h"
#include "li.h"
#include "ex.h"
#include "launch.h"
#include <stdio.h>
#include <stdint.h>

int      assemble(FILE *fp,
                  dc_program_t *dc_programs[],
                  rf_program_t *rf_programs[],
                  li_program_t *li_programs[],
                  ex_program_t *ex_programs[],
                  launch_t **launch);

uint64_t program_t(dc_program_t *dc_programs[],
                   rf_program_t *rf_programs[],
                   li_program_t *li_programs[],
                   ex_program_t *ex_programs[]);

int      write_sim(dc_program_t *dc_programs[],
                   rf_program_t *rf_programs[],
                   li_program_t *li_programs[],
                   ex_program_t *ex_programs[],
                   launch_t *launch);

void     write_bin(dc_program_t *dc_programs[],
                   rf_program_t *rf_programs[],
                   li_program_t *li_programs[],
                   ex_program_t *ex_programs[],
                   launch_t *launch,
                   FILE *op);

#endif
