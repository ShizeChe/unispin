.program rf0
.fnco 10MHz
.repeat 100
    idl t=19us (arm)
    ply phs=0 t=60ns
    idl t=80ns (t+8ns)
    ply phs=90 t=120ns
    idl t=80ns (t+8ns)
    ply phs=0 t=60ns
    idl t=12us

.program dc0
.repeat 100
    lvl v=0 t=2us (arm)
    lvl v=1 t=15us
    lvl v=2 t=2us
    idl t=400ns (t+16ns)
    lvl v=1 t=10us
    lvl v=0 t=2us

.program li0
.repeat 100
    idl t=19400ns (arm t+16ns)
    sam n=1000 t=10us
    idl t=2us

.launch rf0 dc0 li0

