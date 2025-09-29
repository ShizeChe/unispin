#include "rf.h"
#include <math.h>
#include <string.h>


int rf_program_stream(int rf_channel, int stream_len, rf_insn_t *rf_stream) {
    (void) rf_channel; (void) stream_len; (void) rf_stream;
    return 0;
}

rf_insn_t rf_chirp2insn(rf_chirp_t rf_chirp) {
    (void) rf_chirp;
    return (rf_insn_t){.k = 0, .b = 0, .c = 0, .iters = 0,
                       .dkbc_samples = 0, .kbc_samples = 4,
                       .dzero_samples = 0, .zero_samples = 4};
}

rf_insn_t rf_chirp2insn(rf_drive_t rf_drive) {
    (void) rf_drive;
    return (rf_insn_t){.k = 0, .b = 0, .c = 0, .iters = 0,
                       .dkbc_samples = 0, .kbc_samples = 4,
                       .dzero_samples = 0, .zero_samples = 4};
}

