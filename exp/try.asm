.program dc0
.repeat 1
    set cr 0x2 (dvsr=15)
    swp v1=-5 v2=5 n=100 dt=1ms (arm dvsr=15)

.launch dc0
