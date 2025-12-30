#include "common.h"
#include "launch.h"
#include <stdint.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>


int launch_parse(char *line, launch_t *launch) {

    launch->dc_chmask = 0;
    launch->rf_chmask = 0;
    launch->li_chmask = 0;

    char tmp[256];
    snprintf(tmp, sizeof(tmp), "%s", line + 7);

    char *save = NULL;

    for (char *tok = strtok_r(tmp, " \t\r\n", &save); tok != NULL;
         tok = strtok_r(NULL, " \t\r\n", &save)) {

        if (strncmp(tok, "dc", 2) == 0) {

            char *endp = NULL;
            uint32_t ch = strtoul(tok + 2, &endp, 0);

            assert(ch < DC_CHANNELS);

            if (endp == tok + 2 || *endp != '\0') 
                return -1;

            launch->dc_chmask |= 1U << ch;

        } else if (strncmp(tok, "rf", 2) == 0) {

            char *endp = NULL;
            uint32_t ch = strtoul(tok + 2, &endp, 0);

            assert(ch < RF_CHANNELS);

            if (endp == tok + 2 || *endp != '\0') 
                return -1;

            launch->rf_chmask |= 1U << ch;

        } else if (strncmp(tok, "li", 2) == 0) {

            char *endp = NULL;
            uint32_t ch = strtoul(tok + 2, &endp, 0);

            assert(ch < LI_CHANNELS);

            if (endp == tok + 2 || *endp != '\0') 
                return -1;

            launch->li_chmask |= 1U << ch;

        } else {
            // unknown flag/token inside parens
            return -1;
        }

    }

    return 0;
    
}

int launch_load(launch_t *launch) {

    char uio_path[32];
    snprintf(uio_path, sizeof(uio_path), "/dev/uio%d", LAUNCH_UIO);

    int launch_fd = open(uio_path, O_RDWR);
    if (launch_fd < 0) {
        fprintf(stderr, "open(\"%s\") failed: %s\n", uio_path, strerror(errno));
        return 1;
    }

    void *launch_va = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, launch_fd, 0);
    if (launch_va == MAP_FAILED) {
        fprintf(stderr, "mmap() %s failed: %s\n", uio_path, strerror(errno));
        close(launch_fd);
        return 1;
    }

    volatile uint32_t *launch_base = (volatile uint32_t *)((char *)launch_va);
    *(launch_base + LAUNCH_TOTAL_REGS - 1) = 0;
    *(launch_base) = launch->dc_chmask;
    *(launch_base + 1) = launch->rf_chmask;
    *(launch_base + 2) = launch->li_chmask;
    *(launch_base + LAUNCH_TOTAL_REGS - 1) = 1;

#if EXE
    __asm__ __volatile__("dsb oshst" ::: "memory");
#endif

    return 0;
}

