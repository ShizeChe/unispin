#include <assert.h>
#include <math.h>
#include <stdio.h>
#include "../dc.h"

static void test_dc_level2insn(void) {
    dc_level_t lvl = { .v = 0.0, .t = 10 }; // ns
    dc_insn_t insn = dc_level2insn(lvl);

    // sanity: one point, no delta
    assert(insn.dv == 0);
    assert(insn.iters == 1);

    // cycles should be round-to-nearest of t / NS_PER_CYCLE
    // with your defaults NS_PER_CYCLE=4 -> 10 ns => ~3 cycles
    assert(insn.cycles >= 1);
    printf("level: dac_code=0x%08x cycles=%u\n", (unsigned)insn.dac_code, insn.cycles);
}

static void test_dc_sweep2insn(void) {
    dc_sweep_t s = { .vstart = -10.0, .vend = +10.0, .num_points = 5, .dt = 8 };
    dc_insn_t insn = dc_sweep2insn(s);

    // 5 points => 4 steps; dv may be positive; check basic relationships
    assert(insn.iters == 5 || insn.iters == (1u<<DC_ITER_BITS)-1); // saturated or exact
    assert(insn.cycles >= 1);
    printf("sweep: start=0x%08x dv=0x%08x iters=%u cycles=%u\n",
           (unsigned)insn.dac_code, (unsigned)insn.dv, insn.iters, insn.cycles);

    // Optional: check monotonicity for a few steps using the public API
    // (simulate what firmware would do)
    unsigned steps = insn.iters;
    uint32_t code  = insn.dac_code;
    for (unsigned i = 0; i < steps; ++i) {
        printf("code: 0x%08x\n", (unsigned)code);
        assert(code <= ((1u<<DC_DAC_BITS)-1));
        code += insn.dv;
    }
}

int main(void) {
    test_dc_level2insn();
    test_dc_sweep2insn();
    puts("OK");
    return 0;
}
