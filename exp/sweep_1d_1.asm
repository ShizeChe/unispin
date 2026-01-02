.program dc1
.repeat 1
    set cr 0x2
    swp v1=-5 v2=5 n=100 dt=1us (arm)

.launch dc1
