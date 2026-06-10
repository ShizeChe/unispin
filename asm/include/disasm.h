#ifndef DISASM_H
#define DISASM_H

#include "dc.h"
#include "rf.h"
#include "li.h"
#include "ex.h"
#include "launch.h"
#include <stdio.h>

// Read a bin file produced by write_bin, reconstruct program structs.
int  disassemble(FILE *fp,
                 dc_program_t *dc_programs[],
                 rf_program_t *rf_programs[],
                 li_program_t *li_programs[],
                 ex_program_t *ex_programs[],
                 launch_t **launch);

// Write an .asm source file from populated program structs.
void write_asm(FILE *out,
               dc_program_t *dc_programs[],
               rf_program_t *rf_programs[],
               li_program_t *li_programs[],
               ex_program_t *ex_programs[],
               launch_t *launch);

// Inspect a named channel via UIO (e.g. "dc3", "rf1").
int  inspect_named_channel(const char *name);

#endif
