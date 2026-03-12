.program dc0
.repeat 100
    lvl v=0 t=2us (arm)
    lvl v=1 t=15us
    lvl v=2 t=2us
    idl t=488ns (t+8ns)
    lvl v=1 t=10us
    lvl v=0 t=2us

.program dc1
.repeat 100
    lvl v=0 t=2us (arm)
    lvl v=1 t=15us
    lvl v=2 t=2us
    idl t=488ns (t+8ns)
    lvl v=1 t=10us
    lvl v=0 t=2us

.program rf0
.fnco 10MHz
.repeat 100
    idl t=19us (arm)
    ply phs=0 t=120ns
    idl t=60ns
    idl t=4ns (t+4ns)
    ply phs=0 t=120ns
    idl t=120ns
    idl t=4ns (t+4ns)
    idl t=60ns
    idl t=12us

.program rf1
.fnco 10MHz
.repeat 100
    idl t=19us (arm)
    idl t=120ns
    ply phs=0 t=60ns
    idl t=4ns (t+4ns)
    idl t=120ns
    ply phs=0 t=120ns
    idl t=4ns (t+4ns)
    ply phs=90 t=60ns
    idl t=12us

.program ex0
.repeat 100
    idl t=19us (arm)
    idl t=180ns
    lvl v=1 t=4ns (t+4ns)
    idl t=240ns
    lvl v=1 t=4ns (t+4ns)
    idl t=60ns
    idl t=12us

.program li0
.repeat 100
    idl t=19us (arm)
    idl t=488ns (t+8ns)
    sam n=1000 t=10us
    idl t=2us

.launch rf0 rf1 dc0 dc1 ex0 li0

