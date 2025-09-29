#include "exp.h"
#include <assert.h>

static inline int non_overlap(int *arr1, int arr1_len, int *arr2, int arr2_len) {
    for (int i = 0; i < arr1_len; i++) {
        for (int j = 0; j < arr2_len; j++) {
            if (arr1[i] == arr2[j]) return 0;
        }
    }
    return 1;
}

static inline int no_rep(int *arr, int arr_len) {
    for (int i = 0; i < arr_len; i++) {
        for (int j = i + 1; j < arr_len; j++) {
            if (arr[i] == arr[j]) return 0;
        }
    }
    return 1;
}

int sweep_1d(int *dc_chs, int num_chs, 
             double vstart, double vend, uint32_t num_points, uint32_t dt) {

    assert(no_rep(dc_chs, num_chs));

    dc_insn_t insn = dc_sweep2insn(
        (dc_sweep_t){
            .vstart = vstart,
            .vend = vend,
            .num_points = num_points,
            .dt = dt
        }
    );

    for (int i = 0; i < num_chs; i++)
        dc_program_stream(dc_chs[i], 1, &insn);

    return 0;
}

int sweep_2d(int *dc_chs1, int num_chs1, 
             double vstart1, double vend1, uint32_t num_points1,
             int *dc_chs2, int num_chs2, 
             double vstart2, double vend2, uint32_t num_points2, uint32_t dt) {

    assert(no_rep(dc_chs1, num_chs1));
    assert(no_rep(dc_chs2, num_chs2));
    assert(non_overlap(dc_chs1, num_chs1, dc_chs2, num_chs2));

    dc_insn_t insn1 = dc_sweep2insn(
        (dc_sweep_t){
            .vstart = vstart1,
            .vend = vend1,
            .num_points = num_points1,
            .dt = dt * num_points2
        }
    );

    dc_insn_t insn2 = dc_sweep2insn(
        (dc_sweep_t){
            .vstart = vstart2,
            .vend = vend2,
            .num_points = num_points2,
            .dt = dt
        }
    );

    for (int i = 0; i < num_chs1; i++)
        dc_program_stream(dc_chs1[i], 1, &insn1);

    for (int i = 0; i < num_chs2; i++)
        dc_program_stream(dc_chs2[i], 1, &insn2);

    return 0;
}
