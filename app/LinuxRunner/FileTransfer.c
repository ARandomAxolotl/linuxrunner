#include "FileTransfer.h"
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>

bool lr_valid_leaf(const char *name) {
    return name && *name && strcmp(name, ".") && strcmp(name, "..") &&
        !strchr(name, '/') && !strchr(name, '\\') && strlen(name) <= 255;
}

static int copy_regular(int input, int output) {
    struct stat st;
    if (fstat(input, &st) < 0) return errno;
    if (!S_ISREG(st.st_mode)) return EINVAL;
    // Transfers are streamed; bound disk consumption as well as memory.
    const uint64_t limit = 512ULL * 1024 * 1024;
    if (st.st_size < 0 || (uint64_t)st.st_size > limit) return EFBIG;
    char buffer[65536];
    uint64_t total = 0;
    for (;;) {
        ssize_t count = read(input, buffer, sizeof(buffer));
        if (count < 0) { if (errno == EINTR) continue; return errno; }
        if (!count) break;
        total += (uint64_t)count;
        if (total > limit) return EFBIG;
        for (ssize_t offset = 0; offset < count;) {
            ssize_t written = write(output, buffer + offset, (size_t)(count - offset));
            if (written < 0) { if (errno == EINTR) continue; return errno; }
            if (!written) return EIO;
            offset += written;
        }
    }
    return fsync(output) < 0 ? errno : 0;
}

int lr_copy_in(int source_fd, int directory_fd, const char *name) {
    if (!lr_valid_leaf(name)) return EINVAL;
    // Stage under a random name, then publish exclusively without overwriting.
    char staging[80];
    snprintf(staging, sizeof(staging), ".import-%08x-%08x", arc4random(), arc4random());
    int output = openat(directory_fd, staging, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600);
    if (output < 0) return errno;
    int error = copy_regular(source_fd, output);
    close(output);
    if (!error && linkat(directory_fd, staging, directory_fd, name, 0) < 0) error = errno;
    unlinkat(directory_fd, staging, 0);
    return error;
}

int lr_copy_out(int directory_fd, const char *name, int destination_fd) {
    if (!lr_valid_leaf(name)) return EINVAL;
    int input = openat(directory_fd, name, O_RDONLY | O_NOFOLLOW | O_NONBLOCK);
    if (input < 0) return errno;
    int error = copy_regular(input, destination_fd);
    close(input);
    return error;
}
