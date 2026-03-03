.program dc0
.repeat 100
    lvl v=0 t=2us (arm)
    lvl v=1 t=15us (v+0.01)
    lvl v=2 t=2us
    lvl v=1 t=10us (v+0.01)
    lvl v=0 t=2us

.program li0
.repeat 100
    idl t=19us (arm)
    sam n=1000 t=10us
    idl t=2us

.launch dc0 li0

