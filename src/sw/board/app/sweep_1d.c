#include "dc.h"
#include <stdint.h>
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv) {

    assert(argc == 6);

    int dc_channel = atoi(argv[1]);
    double vstart = atof(argv[2]);
    double vend = atof(argv[3]);
    uint32_t num_points = atoi(argv[4]);
    uint32_t dt_ns = atoi(argv[5]);

    dc_sweep_t dc_sweep = (dc_sweep_t){
        .vstart = vstart,
        .vend = vend,
        .num_points = num_points,
        .dt_ns = dt_ns
    };

    dc_insn_t dc_insn = dc_sweep2insn(dc_sweep);
    int err = dc_program_stream(dc_channel, 1, 1, &dc_insn);
    if (err) {
        printf("dc channel %d program failed\n", dc_channel);
        return -1;
    }

    return 0;

}
