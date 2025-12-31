#include "common.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include <math.h>
#include <stdbool.h>

void print_binary(FILE *f, uint32_t value) {
    for (int i = 31; i >= 0; --i) {
        fprintf(f, "%d", (value >> i) & 1);
    }
    fprintf(f, "\n");
}

int parse_time(char *str, uint32_t *t_ns) {
    // Split numeric prefix and unit suffix
    // Accept: 1us, 0.5ms, 10ns, 2s, etc.
    char *endptr = NULL;
    double val = strtod(str, &endptr);
    if (endptr == str || val < 0) return -1; // no number

    const char *unit = endptr;
    if (*unit == '\0') return -1; // must have a unit

    double scale = 0.0;
    if (strcmp(unit, "ns") == 0) scale = 1.0;
    else if (strcmp(unit, "us") == 0) scale = 1e3;
    else if (strcmp(unit, "ms") == 0) scale = 1e6;
    else if (strcmp(unit, "s")  == 0) scale = 1e9;
    else return -1;

    *t_ns = (uint32_t) llround(val * scale);
    return 0;
}

int parse_time_double(char *str, double *t_ns) {
    // Split numeric prefix and unit suffix
    // Accept: 1us, 0.5ms, 10ns, 2s, etc.
    char *endptr = NULL;
    double val = strtod(str, &endptr);
    if (endptr == str || val < 0) return -1; // no number

    const char *unit = endptr;
    if (*unit == '\0') return -1; // must have a unit

    double scale = 0.0;
    if (strcmp(unit, "ns") == 0) scale = 1.0;
    else if (strcmp(unit, "us") == 0) scale = 1e3;
    else if (strcmp(unit, "ms") == 0) scale = 1e6;
    else if (strcmp(unit, "s")  == 0) scale = 1e9;
    else return -1;

    *t_ns = llround(val * scale);
    return 0;
}

int parse_freq(char *str, long double *f_hz) {
    char *endptr = NULL;
    long double val = strtold(str, &endptr);
    if (endptr == str || val < 0) return -1; // no number

    const char *unit = endptr;
    if (*unit == '\0') return -1; // must have a unit

    long double scale = 0.0;
    if (strcmp(unit, "Hz") == 0) scale = 1.0;
    else if (strcmp(unit, "KHz") == 0) scale = 1e3;
    else if (strcmp(unit, "MHz") == 0) scale = 1e6;
    else if (strcmp(unit, "GHz")  == 0) scale = 1e9;
    else return -1;

    *f_hz = llroundl(val * scale);
    return 0;
}

uint64_t mask_nbits(unsigned n) {
    return (n >= 64) ? ~0ULL : ((1ULL << n) - 1ULL);
}

uint64_t real2twos(long double min, long double max,
    unsigned n, long double x, int zext) {

    if (n < 2 || n > 63) return 0;
    if (!(min < max)) return 0;
    if (!isfinite((double)min) || !isfinite((double)max) || !isfinite((double)x))
        return 0;

    int64_t kmin = -(int64_t)(1ULL << (n - 1));
    int64_t kmax = (int64_t)((1ULL << (n - 1)) - 1ULL);

    if (x <= min)
        return (zext ? (((uint64_t)kmin) & mask_nbits(n)) : ((uint64_t)kmin));
    if (x >= max)
        return (zext ? (((uint64_t)kmax) & mask_nbits(n)) : ((uint64_t)kmax));

    long double span_x = (max - min);
    long double span_k = (long double)((uint64_t)kmax - (uint64_t)kmin);

    long double k_real = (long double)kmin + (x - min) * (span_k / span_x);

    int64_t k = (int64_t)llroundl(k_real);

    if (k < kmin) k = kmin;
    if (k > kmax) k = kmax;

    return (zext ? (((uint64_t)k) & mask_nbits(n)) : ((uint64_t)k));
}

long double twos2real(long double min, long double max,
    unsigned n, uint64_t code) {

    if (n < 2 || n > 63) return 0.0L;
    if (!(min < max)) return 0.0L;

    uint64_t m = mask_nbits(n);
    code &= m;

    // sign-extend n-bit code to int64_t
    int64_t k = (int64_t)code;
    if (code & (1ULL << (n - 1))) {
        k |= (int64_t)~m;
    }

    const int64_t kmin = -(int64_t)(1ULL << (n - 1));
    const int64_t kmax = (int64_t)((1ULL << (n - 1)) - 1ULL);

    // Linear inverse: kmin -> min, kmax -> max
    const long double span_x = (max - min);
    const long double span_k = (long double)((uint64_t)kmax - (uint64_t)kmin); // 2^n - 1

    return min + ((long double)(k - kmin)) * (span_x / span_k);
}

