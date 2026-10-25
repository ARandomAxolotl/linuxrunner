#pragma once
#include <stddef.h>
// Caller authenticates all .deb files before this parser is entered. No archive
// entry is extracted onto the host: guest metadata is retained in an output tar.
struct lr_debian_bootstrap_options {
    int (*progress)(void *, size_t, size_t);
    int (*cancel)(void *);
    void (*log)(void *, int severity, const char *message);
    void *context;
    int trace_entries;
};
int lr_debian_bootstrap_diagnosed(const char *const *,size_t,const char *,const struct lr_debian_bootstrap_options *,char *,size_t);
int lr_debian_bootstrap(const char *const *,size_t,const char *,int (*)(void *,size_t,size_t),void *,char *,size_t);
