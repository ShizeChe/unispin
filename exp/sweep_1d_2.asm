.program dc2
.repeat 1
    set cr 0x2
    swp v1=-10 v2=10 n=100 dt=1us (arm)
    swp v1=10 v2=-10 n=100 dt=1us

.program dc3
.repeat 1
    set cr 0x2
    swp v1=10 v2=-10 n=100 dt=1us (arm)
    swp v1=-10 v2=10 n=100 dt=1us

.launch dc2 dc3
