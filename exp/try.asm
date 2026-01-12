.program dc6
.repeat 1
    set cr 0x2
    swp v1=-10 v2=10 n=109 dt=5us (arm dvsr=12)

.launch dc6
