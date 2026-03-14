.program rf0
.fnco 10MHz
.repeat 1
    ful kb 0xD6C 0xFD70A4427 t=100us (arm)
    idl t=10us

.program li0
.repeat 1
    idl t=100us (arm)
    sam n=1000 t=10us

.launch rf0 li0

