.program rf0
.fnco 10MHz
.repeat 10
    ful bc 0x010000000 0x0 t=80ns (arm)
    ful bc 0x020000000 0x0 t=80ns
    ful bc 0x030000000 0x0 t=80ns
    idl t=60ns

.program li0
.repeat 10
    idl t=240ns (arm)
    sam n=10 t=60ns

.launch rf0 li0

