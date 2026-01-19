.program dc0
.dvsr 20
.csup 20
.ldac 20
.repeat 1
    set cr 0x2
    swp v1=-10 v2=10 n=109 dt=1us (arm)

.launch dc0

