.program rf0
.fnco 10MHz
.repeat 200
    ply phs=0 t=12ns (arm t+12ns)
    idl t=60us

.program dc0
.repeat 200
    idl t=12ns (arm t+12ns)
    lvl v=1 t=10us
    lvl v=2 t=30us
    lvl v=1 t=10us
    lvl v=0 t=10us

.program li0
.repeat 200
    idl t=10012ns (arm t+12ns)
    sam n=1000 t=30us
    idl t=20us

.launch rf0 dc0 li0

