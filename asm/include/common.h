#ifndef COMMON_H
#define COMMON_H

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdint.h>

#if DEBUG
#  define DBG(...) fprintf(stderr, __VA_ARGS__)
#else
#  define DBG(...) do { } while (0)
#endif

#define DC_UIO_BASE 4

#define RF_UIO_BASE 28

#define LI_UIO_BASE 34

#define LAUNCH_UIO 36

#define DC_CHANNELS RF_UIO_BASE - DC_UIO_BASE
#define RF_CHANNELS LI_UIO_BASE - RF_UIO_BASE
#define LI_CHANNELS LI_UIO_BASE - RF_UIO_BASE

void print_binary(FILE *f, uint32_t value);
int parse_time(char *str, uint32_t *t_ns);
int parse_time_double(char *str, double *t_ns);
int parse_freq(char *str, long double *f_hz);
uint64_t real2twos(long double min, long double max, unsigned n, long double x, int zext);
long double twos2real(long double max, long double min, unsigned n, uint64_t code);

#endif
