#include "common.h"
#include "simcli.h"
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

static int   g_fd = -1;
static FILE *g_fp = NULL;

int sim_connect(const char *path)
{
    struct sockaddr_un addr;

    g_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (g_fd < 0) return -1;

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path)-1);

    if (connect(g_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(g_fd);
        g_fd = -1;
        return -1;
    }

    g_fp = fdopen(g_fd, "w");   // now you can fprintf()
    if (!g_fp) {
        close(g_fd);
        g_fd = -1;
        return -1;
    }

    // Make it line-buffered so every '\n' flushes automatically
    setvbuf(g_fp, NULL, _IOLBF, 0);

    return 0;
}

int sim_sendf(const char *fmt, ...)
{
    if (!g_fp) return -1;

    va_list ap;
    va_start(ap, fmt);
    vfprintf(g_fp, fmt, ap);
    va_end(ap);

    // If you *don’t* set line buffering, do: fflush(g_fp);
    return 0;
}

void sim_close(void)
{
    if (g_fp) {
        fclose(g_fp);   // also closes g_fd
        g_fp = NULL;
        g_fd = -1;
    } else if (g_fd >= 0) {
        close(g_fd);
        g_fd = -1;
    }
}
