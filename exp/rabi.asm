.program rf0                   # program for RF channel 0
.fnco 10MHz                    # baseband signal is 10MHz
.repeat 100                    # this program repeats 100 times
    idl t=19us (arm)           # idle for 19us
    ply phs=0 t=8ns (t+8ns)   # play the baseband signal for 12ns, and increment the duration by 8ns every iteration
    idl t=12us                 # idle for 12us 

.program dc0                   # program for DC channel 0
.repeat 100                    # this program repeats 100 times
    lvl v=0 t=2us (arm)        # output 0V for 2us
    lvl v=1 t=15us             # output 1V for 15us
    lvl v=2 t=2us              # output 2V for 2us
    idl t=8ns (t+8ns)         # idle for 12ns, and increment the duration by 8ns every iteration
    lvl v=1 t=10us             # output 1V for 10us
    lvl v=0.5 t=2us              # output 0V for 2us

.program li0                   # program for LI (lockin-in) channel 0
.repeat 100                    # this program repeats 100 times
    idl t=19us (arm)           # idle for 19us
    idl t=8ns (t+8ns)         # idle for 12ns, and increment the duration by 8ns every iteration
    sam n=1000 t=10us          # sample 1000 samples spanning 10us
    idl t=2us                  # idle for 2us

.launch rf0 dc0 li0            # launch RF channel 0, DC channel 0, Li channel 0

