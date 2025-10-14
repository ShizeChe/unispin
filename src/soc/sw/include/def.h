#ifndef DEFS_H
#define DEFS_H

#include <stdio.h>

#if DEBUG
#  define DBG(...) fprintf(stderr, __VA_ARGS__)
#else
#  define DBG(...) do { } while (0)
#endif

#define DC_UIO_BASE 4

#define RF_UIO_BASE 28

#define LI_UIO_BASE 35

#define LAUNCH_UIO 37

#endif
