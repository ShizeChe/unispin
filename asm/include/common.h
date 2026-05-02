#ifndef COMMON_H
#define COMMON_H

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include <stdio.h>
#include <stdint.h>

#if DEBUG
#  define DBG(...) fprintf(stderr, __VA_ARGS__)
#else
#  define DBG(...) do { } while (0)
#endif

// bram_sequencer register offsets (n = REG_PER_INSN for the channel type)
#define BRAM_PCST_ADDR      0
#define BRAM_PCST           1
#define BRAM_PCST_STRB      2
#define BRAM_IST_ADDR       3
#define BRAM_IST_LO         4
#define BRAM_IST_STRB(n)    (4 + (n))
#define BRAM_ITERS(n)       (5 + (n))
#define BRAM_DEPTH(n)       (6 + (n))
#define BRAM_START(n)       (7 + (n))
#define BRAM_HALT(n)        (8 + (n))
#define BRAM_SEQ_TOTAL(n)   (11 + (n))

void print_binary(FILE *f, uint32_t value);
int parse_time(char *str, uint32_t *t_ns);
int parse_time_double(char *str, double *t_ns);
int parse_freq(char *str, long double *f_hz);
uint64_t real2twos(long double min, long double max, unsigned n, long double x, int zext);
long double twos2real(long double max, long double min, unsigned n, uint64_t code);

#endif
