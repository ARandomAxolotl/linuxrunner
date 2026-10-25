#ifndef KERNEL_IPC_H
#define KERNEL_IPC_H

struct mm;
// Caller holds source->mem.lock through attachment and page-table copying.
// Parent records retain segment objects; no global IPC lock is needed here.
int ipc_shm_mm_copy(struct mm *source, struct mm *destination);
void ipc_shm_mm_release(struct mm *mm);

#endif
