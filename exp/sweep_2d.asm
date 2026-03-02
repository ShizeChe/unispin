.program dc0
.repeat 1
    swp v1=-5 v2=5 n=50 dt=100us (arm)

.program dc1
.repeat 50
    swp v1=-5 v2=5 n=50 dt=2us (arm)

.program li0
.repeat 2500
    idl t=1us (arm)
    sam n=10 t=1us

.launch dc0 dc1 li0

