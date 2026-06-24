#include "common.h"
#include "asm.h"
#include "disasm.h"
#include "dc.h"
#include "rf.h"
#include "li.h"
#include "ex.h"
#include "launch.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <inttypes.h>

static void free_programs(dc_program_t *dc[], rf_program_t *rf[],
                          li_program_t *li[], ex_program_t *ex[],
                          launch_t *launch) {
    for (int i = 0; i < DC_CHANNELS; i++) { if (dc[i]) free(dc[i]); }
    for (int i = 0; i < RF_CHANNELS; i++) { if (rf[i]) free(rf[i]); }
    for (int i = 0; i < LI_CHANNELS; i++) { if (li[i]) free(li[i]); }
    for (int i = 0; i < EX_CHANNELS; i++) { if (ex[i]) free(ex[i]); }
    if (launch) free(launch);
}

int main(int argc, char *argv[]) {

    int   opt;
    char *file  = NULL;  /* -f: input .asm file */
    char *out   = NULL;  /* -o: output bin file */
    char *disf  = NULL;  /* -d: input bin file to disassemble */
    char *rdev  = NULL;  /* -r: channel name to inspect via UIO */
    int   sim   = 0;
    int   exe   = 0;

    while ((opt = getopt(argc, argv, "f:o:d:r:sx")) != -1) {
        switch (opt) {
            case 'f': file = optarg; break;
            case 'o': out  = optarg; break;
            case 'd': disf = optarg; break;
            case 'r': rdev = optarg; break;
            case 's': sim  = 1;      break;
            case 'x': exe  = 1;      break;
            default:
                fprintf(stderr,
                    "Usage: %s [-f file.asm] [-o out] [-s] [-x] [-r ch] [-d file.bin]\n",
                    argv[0]);
                return 1;
        }
    }

    if (file == NULL && disf == NULL && rdev == NULL) {
        fprintf(stderr,
            "Usage: %s [-f file.asm] [-o out] [-s] [-x] [-r ch] [-d file.bin]\n",
            argv[0]);
        return 1;
    }

    dc_program_t *dc_programs[DC_CHANNELS] = {NULL};
    rf_program_t *rf_programs[RF_CHANNELS] = {NULL};
    li_program_t *li_programs[LI_CHANNELS] = {NULL};
    ex_program_t *ex_programs[EX_CHANNELS] = {NULL};
    launch_t     *launch                   = NULL;

    /* -f: assemble .asm → bin */
    if (file != NULL) {
        FILE *fp = fopen(file, "r");
        if (fp == NULL) { perror(file); return 1; }
        assemble(fp, dc_programs, rf_programs, li_programs, ex_programs, &launch);
        fclose(fp);

        const char *binpath = out ? out : "out.bin";
        FILE *op = fopen(binpath, "w");
        if (op == NULL) { perror(binpath); return 1; }
        write_bin(dc_programs, rf_programs, li_programs, ex_programs, launch, op);
        fclose(op);

        printf("program t: %"PRIu64" ns\n",
               program_t(dc_programs, rf_programs, li_programs, ex_programs));
    }

    /* -s: send to simulator */
    if (sim) {
        printf("simulate\n");
        write_sim(dc_programs, rf_programs, li_programs, ex_programs, launch);
    }

    /* -x: load onto hardware via UIO */
    if (exe) {
        for (int ch = 0; ch < DC_CHANNELS; ch++)
            if (dc_programs[ch]) dc_store_insns(ch, dc_programs[ch]);
        for (int ch = 0; ch < RF_CHANNELS; ch++)
            if (rf_programs[ch]) rf_store_insns(ch, rf_programs[ch]);
        for (int ch = 0; ch < LI_CHANNELS; ch++)
            if (li_programs[ch]) li_store_insns(ch, li_programs[ch]);
        for (int ch = 0; ch < EX_CHANNELS; ch++)
            if (ex_programs[ch]) ex_store_insns(ch, ex_programs[ch]);
        if (launch) launch_load(launch);
    }

    free_programs(dc_programs, rf_programs, li_programs, ex_programs, launch);
    launch = NULL;
    for (int i = 0; i < DC_CHANNELS; i++) dc_programs[i] = NULL;
    for (int i = 0; i < RF_CHANNELS; i++) rf_programs[i] = NULL;
    for (int i = 0; i < LI_CHANNELS; i++) li_programs[i] = NULL;
    for (int i = 0; i < EX_CHANNELS; i++) ex_programs[i] = NULL;

    /* -d: disassemble bin → stdout (or -o file) */
    if (disf != NULL) {
        FILE *fp = fopen(disf, "r");
        if (fp == NULL) { perror(disf); return 1; }
        disassemble(fp, dc_programs, rf_programs, li_programs, ex_programs, &launch);
        fclose(fp);

        const char *asmpath = out ? out : "out.asm";
        FILE *aout = fopen(asmpath, "w");
        if (aout == NULL) { perror(asmpath); return 1; }
        write_asm(aout, dc_programs, rf_programs, li_programs, ex_programs, launch);
        fclose(aout);
        printf("disassembled to %s\n", asmpath);

        free_programs(dc_programs, rf_programs, li_programs, ex_programs, launch);
    }

    /* -r: inspect a live channel via UIO */
    if (rdev != NULL)
        return inspect_named_channel(rdev);

    return 0;
}
