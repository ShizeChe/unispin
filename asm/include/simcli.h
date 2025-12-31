#ifndef SIMCLI_H
#define SIMCLI_H

#define SOCKET "/tmp/tb_cmd.sock"

int sim_connect(const char *path);
int sim_sendf(const char*fmt, ...);
void sim_clos(void);

#endif
