.program dc0
.repeat 100
    idl t=200ns (arm t+8ns)
    lvl v=1 t=2us
    lvl v=2 t=2us
    lvl v=3 t=2us

.program rf0
.fnco 10MHz
.repeat 100
    ply phs=0 t=60ns (arm)
    idl t=80ns (t+8ns)
    ply phs=0 t=60ns
    idl t=6us

.program li0
.repeat 100
    idl t=200ns (arm t+8ns)
    idl t=2us
    sam n=100 t=2us
    idl t=2us

.launch dc0 rf0 li0

