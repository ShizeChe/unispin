#include "dc.h"
#include <stdint.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv) {

    assert(argc == 10);

    int dc_channel1 = atoi(argv[1]);
    double vstart1 = atof(argv[2]);
    double vend1 = atof(argv[3]);
    uint32_t num_points1 = atoi(argv[4]);

    int dc_channel2 = atoi(argv[5]);
    double vstart2 = atof(argv[6]);
    double vend2 = atof(argv[7]);
    uint32_t num_points2 = atoi(argv[8]);

    uint32_t dt_ns = atoi(argv[9]);

    dc_sweep_t dc_sweep1 = (dc_sweep_t){
        .vstart = vstart1,
        .vend = vend1,
        .num_points = num_points1,
        .dt_ns = dt_ns * num_points2
    };

    dc_sweep_t dc_sweep2 = (dc_sweep_t){
        .vstart = vstart2,
        .vend = vend2,
        .num_points = num_points2,
        .dt_ns = dt_ns
    };

    dc_insn_t dc_insn1 = dc_sweep2insn(sweep1);
    dc_insn_t dc_insn2 = dc_sweep2insn(sweep2);

    int err = dc_program_stream(dc_channel1, 1, 1, &dc_insn1);
    if (err) {
        printf("dc channel %d program failed", dc_channel1);
        return -1;
    }
    err = dc_program_stream(dc_channel2, num_points1, 1, &dc_insn2);
    if (err) {
        printf("dc channel %d program failed", dc_channel2);
        return -1;
    }

    return 0;

}
