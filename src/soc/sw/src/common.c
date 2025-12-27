#include "common.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

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
