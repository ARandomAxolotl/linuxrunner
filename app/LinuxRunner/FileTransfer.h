#pragma once
#include <stdbool.h>

// Single directory level; fd-relative access refuses symlinks and special files.
bool lr_valid_leaf(const char *name);
int lr_copy_in(int source_fd, int directory_fd, const char *name);
int lr_copy_out(int directory_fd, const char *name, int destination_fd);
