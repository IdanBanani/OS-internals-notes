# Modern Linux Memory Manager Reading Map

Value Score: 73/100
Role: Modern Linux MM source route
Proof Level: Source-map

Date: 2026-05-15

Purpose: replace the old habit of starting Linux memory-manager study from *Understanding the Linux Kernel*, Chapter 9, or the local `linux_kernel_v2.6_virtual memory manager` folder. Those sources are still useful for historical vocabulary, but they are not current enough for Linux 6.x/7.x VMA lookup, page-fault locking, page cache, folios, GUP/pinning, reclaim, or hardening.

## Short Answer

Yes. For process address space and page faults, use this order instead:

1. Current kernel documentation:
   - [Linux Memory Management Documentation](https://docs.kernel.org/mm/index.html)
   - [Process Addresses](https://docs.kernel.org/mm/process_addrs.html)
   - [Page Tables](https://docs.kernel.org/mm/page_tables.html)
   - [Page Cache](https://docs.kernel.org/mm/page_cache.html)
   - [Physical Memory](https://docs.kernel.org/mm/physical_memory.html)
   - [Maple Tree](https://docs.kernel.org/core-api/maple_tree.html)
2. Current kernel source for your target version:
   - `include/linux/mm_types.h`: `mm_struct`, `vm_area_struct`, `struct page`, folio-adjacent types.
   - `include/linux/mm.h`: MM helpers and fault-facing interfaces.
   - `mm/memory.c`: `handle_mm_fault()` and the architecture-independent fault machinery.
   - `arch/<arch>/mm/fault.c`: architecture page-fault entry, such as x86 `do_user_addr_fault()`.
   - `mm/mmap.c`: `mmap`, `brk`, VMA creation/splitting/merging, address-space modification.
   - `mm/filemap.c`: file-backed faults and page-cache interaction.
   - `mm/rmap.c`: reverse mapping, locking order, COW/reclaim relationships.
   - `mm/page_alloc.c`, `mm/slub.c`, `mm/vmalloc.c`: physical and kernel allocator background.
   - `fs/proc/task_mmu.c`: `/proc/<pid>/maps`, `smaps`, and user-visible memory-map reporting.
3. [Linux Kernel Labs: Memory Management](https://linux-kernel-labs.github.io/refs/heads/master/lectures/memory-management.html) for a guided teaching view.
4. TLPI chapters 49-50 for userspace `mmap`, `mprotect`, `msync`, `mlock`, and virtual-memory API semantics.
5. Old 2.6-era books only after the above, as history.

## Why Chapter 9 Is Not Enough

*Understanding the Linux Kernel*, Chapter 9, and the old 2.6 virtual memory manager material are good for:

- the basic VMA idea;
- `mm_struct` as the process address-space owner;
- the difference between VMA policy and PTE translation;
- why page faults can be normal demand-paging events.

They are weak or misleading for current kernels because:

- VMA indexing changed. Old material emphasizes VMA linked lists and red-black trees; current kernels use Maple Tree for VMA storage.
- Locking changed. Modern MM discussion uses `mmap_lock`, VMA locks, RCU-safe VMA lookup paths, rmap locks, and page-table locks. Old `mmap_sem` descriptions are not enough.
- Page cache terminology changed. Folios are now central to how current MM code talks about groups of base pages.
- Fault paths changed. The high-level invariant remains, but exact function names, flags, retry behavior, and locking rules have evolved.
- COW and GUP/pinning became much more important after years of Dirty COW-class and long-term pinning bugs.
- THP, hugetlb, memcg, NUMA balancing, memory compaction, migration, MGLRU, DAMON, userfaultfd, KSM, HMM, device memory, KPTI, hardened usercopy, and page-table checks are all outside a 2.6 mental model.

Use the old books for concept history. Do not use them as the authority for data structures, locking, or current page-fault source paths.

## Page Fault Reading Path

Use this as the current mental call graph. Verify exact names against the target kernel tree.

1. CPU raises a page-fault exception and records the faulting address and access type.
2. Architecture code in `arch/<arch>/mm/fault.c` classifies user/kernel, read/write/execute, protection/not-present, and special cases.
3. The kernel stabilizes the relevant address-space metadata, often through `mmap_lock` or a VMA-lock/RCU path.
4. VMA lookup finds the `vm_area_struct` in the `mm_struct` Maple Tree.
5. Policy is checked: range exists, access is allowed, stack growth is legal if relevant, and special mapping rules are respected.
6. `handle_mm_fault()` in `mm/memory.c` drives the architecture-independent resolution.
7. Resolution branches by fault type:
   - anonymous read fault, possibly shared zero page;
   - anonymous write fault, allocating a private page or folio;
   - file-backed fault through `vm_ops->fault`, often reaching `filemap_fault()`;
   - write-protect/COW fault, commonly through `do_wp_page()`-style logic;
   - swap, migration, huge-page, userfaultfd, or special mapping paths.
8. The kernel installs or updates PTE/PMD state, updates accounting, handles TLB implications, and resumes execution.
9. If the access is invalid or the backing object cannot satisfy it, userspace sees `SIGSEGV` or `SIGBUS`.

The interview-grade phrasing is:

> A page fault is hardware entry into the kernel, but resolution is a VMA policy decision followed by backing-object resolution and PTE/TLB state update.

## Process Address Space Reading Path

Read in this order:

1. `docs.kernel.org/mm/process_addrs.html`
   Focus on `mm_struct`, `vm_area_struct`, Maple Tree, `mmap_lock`, VMA locks, rmap locks, and page-table locks.
2. `include/linux/mm_types.h`
   Read `mm_struct` and `vm_area_struct` fields conceptually. Do not memorize offsets.
3. `mm/mmap.c`
   Follow how mappings are inserted, split, merged, unmapped, and protected.
4. `fs/proc/task_mmu.c`
   Connect internal VMAs to `/proc/<pid>/maps` and `smaps`.
5. `mm/memory.c`
   Connect VMA policy to page-table updates during faults.
6. `mm/rmap.c`
   Learn how the kernel finds mappings from a page/folio back to VMAs for reclaim, migration, COW, and unmapping.

## What To Focus On In Source

Do not try to read every line. Track these questions:

- Which object owns the address space: `mm_struct`.
- Which object describes a legal virtual range: `vm_area_struct`.
- Which structure indexes ranges: Maple Tree under the mm.
- Which locks stabilize the VMA and page tables.
- Which code decides whether a fault is legal.
- Which backing object supplies data: anonymous memory, page cache, swap, device memory, or special mapping.
- Which code changes the PTE and which path handles TLB consequences.
- Which user-visible interfaces expose the result: `/proc/<pid>/maps`, `/proc/<pid>/smaps`, page-fault counters, perf/ftrace/BPF tracepoints, oops logs.

## Old Material Triage

| Local material | Use now? | How to use it |
|---|---|---|
| `linux_kernel_v2.6_virtual memory manager/Understanding the Linux Kernel - 3rd Edition.pdf` | Historical only | Read Chapter 9 only for the VMA/PTE/page-fault concept. Ignore exact structures, locking, and code paths. |
| `linux_kernel_v2.6_virtual memory manager/understanding the 2_6 linux kernel virtual memory manager.pdf` | Historical only | Useful for old terminology and why Linux MM evolved, not for current source navigation. |
| `linux_kernel_v2.6_virtual memory manager/thesis.pdf` | Optional historical context | Read only if you want background, not interview-current facts. |
| `docs/03-linux/01-address-space-mm.md` | Primary local summary | Use as the repo's concise mental model after reading current kernel docs. |
| `docs/02-question-banks/01-linux-deep-understanding-qa.md` | Active recall | Use to test whether you can explain page faults and VMA/PTE/page-cache relationships without looking. |

## Practical Study Sequence

1. Read this file.
2. Read `docs.kernel.org/mm/process_addrs.html` and `docs.kernel.org/mm/page_tables.html`.
3. Read [01-address-space-mm.md](<01-address-space-mm.md>).
4. Open the target kernel source and skim `include/linux/mm_types.h`, `mm/mmap.c`, `arch/x86/mm/fault.c` or your target architecture's fault handler, and `mm/memory.c`.
5. Answer the Linux Q&A page-fault questions from [01-linux-deep-understanding-qa.md](<../02-question-banks/01-linux-deep-understanding-qa.md>).
6. Then read old Chapter 9 only to reinforce the timeless parts and deliberately mark what is obsolete.

## Bottom Line

The best up-to-date replacement is not one book chapter. It is:

`kernel docs -> current source -> Linux Kernel Labs/TLPI for teaching and ABI -> old books as historical context`

That path gives you the current structures and fault handler while preserving the classic conceptual model.
