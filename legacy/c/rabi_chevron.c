#include "rf.h"
#include "launch.h"
#include <stdint.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv) {

    assert(argc == 8);

    int rf_channel = atoi(argv[1]);
    double phase_deg = atof(argv[2]);
    uint32_t iters = atoi(argv[3]);
    uint32_t t_drive_ns = atoi(argv[4]);
    uint32_t dt_drive_ns = atoi(argv[5]);
    uint32_t t_idle_ns = atoi(argv[6]);
    uint32_t dt_idle_ns = atoi(argv[7]);

    rf_drive_t drv = (rf_drive_t) {
        .phase_deg = phase_deg,
        .iters = iters,
        .t_drive_ns = t_drive_ns,
        .dt_drive_ns = dt_drive_ns,
        .t_idle_ns = t_idle_ns,
        .dt_idle_ns = dt_idle_ns
    };

    rf_insn_t rf_insn = rf_drive2insn(drv);
    uint8_t rf_iptr_buf[1] = {0};

    launch_chs_t *launch_chs = (launch_chs_t *)malloc(
        sizeof(launch_chs_t) + sizeof(char)
    );
    launch_chs->num_dc_chs = 0;
    launch_chs->num_rf_chs = 1;
    launch_chs->num_li_chs = 0;
    launch_chs->chs[0] = rf_channel;
    launch_insn_t launch_insn = launch_chs2insn(launch_chs);

    free(launch_chs);

    int err = rf_program_stream(rf_channel, 1, 1, &rf_insn, 1, rf_iptr_buf);
    if (err) {
        printf("rf channel %d program failed", rf_channel);
        return -1;
    }

    err = launch_program_stream(&launch_insn);
    if (err) {
        printf("launch program failed\n");
        return -1;
    }

    return 0;

}
