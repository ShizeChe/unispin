.program dc0
.repeat 100
    lvl v=1 t=5us (arm)
    lvl v=2 t=5us
    lvl v=0 t=5us (v+0.05)
    lvl v=4 t=5us

.program li0
.repeat 100
    idl t=10us (arm)
    sam n=100 t=5us
    idl t=5us

.launch dc0 li0

