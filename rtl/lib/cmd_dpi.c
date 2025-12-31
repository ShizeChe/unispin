// cmd_socket_dpi.c
#define _POSIX_C_SOURCE 200809L
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <poll.h>

#include "svdpi.h"

static int listen_fd = -1;
static int conn_fd   = -1;

// Create a listening Unix socket
int cmd_open(const char *path)
{
    struct sockaddr_un addr;

    if (listen_fd >= 0) close(listen_fd);
    if (conn_fd   >= 0) close(conn_fd);

    listen_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (listen_fd < 0) return -1;

    unlink(path);  // remove old socket file

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, path, sizeof(addr.sun_path)-1);

    if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        return -1;

    if (listen(listen_fd, 1) < 0)
        return -1;

    return 0;
}

// Block until a client connects
/*int cmd_accept(void)*/
/*{*/
/*    if (listen_fd < 0) return -1;*/
/**/
/*    conn_fd = accept(listen_fd, NULL, NULL);*/
/*    return (conn_fd >= 0) ? 0 : -1;*/
/*}*/

int cmd_accept_poll(int timeout_ms)
{
    if (listen_fd < 0) return -1;
    if (conn_fd >= 0) return 0;   // already connected

    struct pollfd pfd;
    pfd.fd = listen_fd;
    pfd.events = POLLIN;
    pfd.revents = 0;

    int pr = poll(&pfd, 1, timeout_ms);
    if (pr == 0) return 1;              // timeout, no pending connection
    if (pr < 0) {
        if (errno == EINTR) return 1;   // treat interrupt like timeout
        return -1;
    }

    conn_fd = accept(listen_fd, NULL, NULL);
    if (conn_fd < 0) {
        if (errno == EINTR) return 1;
        return -1;
    }
    return 0; // connected
}

// Block until a full line is read
// Returns:
//   1 = line read
//   0 = connection closed
//  -1 = error
/*int cmd_getline(char *out, int out_sz)*/
/*{*/
/*    if (conn_fd < 0) return -1;*/
/**/
/*    int pos = 0;*/
/*    while (pos < out_sz - 1) {*/
/*        char c;*/
/*        ssize_t r = read(conn_fd, &c, 1);*/
/*        if (r == 1) {*/
/*            if (c == '\n') {*/
/*                out[pos] = '\0';*/
/*                return 1;*/
/*            }*/
/*            out[pos++] = c;*/
/*        } else if (r == 0) {*/
/*            // peer closed*/
/*            close(conn_fd);*/
/*            conn_fd = -1;*/
/*            return 0;*/
/*        } else {*/
/*            if (errno == EINTR) continue;*/
/*            return -1;*/
/*        }*/
/*    }*/
/*    out[pos] = '\0';*/
/*    return 1;*/
/*}*/
int cmd_getline(const svOpenArrayHandle line_buf)
{
    if (conn_fd < 0) return -1;

    // Get pointer + size of SV byte array
    unsigned char *out = (unsigned char *)svGetArrayPtr(line_buf);
    int n = (int)svSize(line_buf, 1); // number of elements in dimension 1

    if (!out || n <= 0) return -1;

    // Clear buffer
    memset(out, 0, (size_t)n);

    int pos = 0;
    while (pos < n - 1) {
        unsigned char c;
        ssize_t r = read(conn_fd, &c, 1);
        if (r == 1) {
            if (c == '\n') {
                out[pos] = 0;
                return 1;
            }
            out[pos++] = c;
        } else if (r == 0) {
            close(conn_fd);
            conn_fd = -1;
            return 0; // disconnected
        } else {
            if (errno == EINTR) continue;
            return -1;
        }
    }

    out[pos] = 0;
    return 1;
}
