.program rf0
.fnco 10MHz
.repeat 10
    ply phs=0 t=80ns (arm)
    ply phs=30 t=80ns
    ply phs=60 t=80ns
    ply phs=90 t=80ns
    ply phs=120 t=80ns
    ply phs=150 t=80ns
    ply phs=180 t=80ns
    idl t=60ns

.program li0
.repeat 10
    idl t=560ns (arm)
    sam n=10 t=60ns

.launch rf0 li0

