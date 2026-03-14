.program rf0
.fnco 10MHz
.repeat 10
    chp f1=-5MHz f2=5MHz t=100us (arm)
    idl t=10us

.program li0
.repeat 10
    idl t=100us (arm)
    sam n=1000 t=10us

.launch rf0 li0

