#ifndef EXP_H
#define EXP_H

#include "dc.h"
#include "rf.h"

#define EXPORT_INSN  1
#define EXPORT_TRACE 1

#define NUM_DC_CHANNELS 24
#define NUM_RF_CHANNELS 6
#define NUM_LI_CHANNELS 2

int sweep_1d(int *dc_chs, int num_chs, 
             double vstart, double vend, uint32_t num_points, uint32_t dt);

int sweep_2d(int *dc_chs1, int num_chs1, 
             double vstart1, double vend1, uint32_t num_points1,
             int *dc_chs2, int num_chs2, 
             double vstart2, double vend2, uint32_t num_points2, uint32_t dt);

int dc_pulse_table(int *dc_chs, int num_chs, dc_level_t *dcpt[], int *pt_lens[]);
int chirp(int rf_ch, rf_chirp_t *chp);
int rf_drive_table(int *rf_chs, int num_chs, rf_drive_t *rfdt[], int *dt_lens[]);

#endif
