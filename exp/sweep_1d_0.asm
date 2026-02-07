.program dc0
.dvsr 65535
.csup 65535
.ldac 65535
.repeat 1
    set cr 0x2
    swp v1=-3 v2=3 n=10 dt=50ms (arm)

.launch dc0
