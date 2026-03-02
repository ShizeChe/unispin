.program dc0
.repeat 1
    swp v1=-5 v2=5 n=100 dt=5us (arm)

.program li0
.repeat 100
    idl t=4us (arm)
    sam n=10 t=1us

.launch dc0 li0

