.program rf0
.fnco 10MHz
.repeat 100
    idl t=19us (arm)
    ply phs=0 t=12ns (t+12ns)
    idl t=12us

.program dc0
.repeat 100
    lvl v=0 t=2us (arm)
    lvl v=1 t=15us
    lvl v=2 t=2us
    idl t=12ns (t+12ns)
    lvl v=1 t=10us
    lvl v=0 t=2us

.program li0
.repeat 100
    idl t=19012ns (arm t+12ns)
    sam n=1000 t=10us
    idl t=2us

.launch rf0 dc0 li0

