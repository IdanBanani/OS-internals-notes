# Paging, Residency, Page Lists, and Shared Memory

Value Score: 89/100
Role: Paging/residency owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-18

Scope: cross-platform memory-management notes for the confusing boundary between pageable, swappable, reclaimable, file-backed, pagefile/swap-backed, pinned, standby/cache, free, zeroed, PFN/PTE metadata, and demand-zero faults. The goal is to make the security invariants explicit: which bytes can be discarded, which bytes must be written somewhere, which metadata decides ownership, and when stale contents can leak.

Primary source anchors:

- Windows: [file-backed and page-file-backed sections](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/file-backed-and-page-file-backed-sections), [file mapping](https://learn.microsoft.com/en-us/windows/win32/memory/file-mapping), [driver pageable sections](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/making-drivers-pageable), [MmProbeAndLockPages](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-mmprobeandlockpages), [ExAllocatePool2](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-exallocatepool2), [POOL_FLAGS](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/pool_flags), and Windows Internals-style PFN/PTE material.
- Linux: [memory-management concepts](https://docs.kernel.org/admin-guide/mm/concepts.html), [page tables](https://docs.kernel.org/mm/page_tables.html), [memory allocation guide](https://docs.kernel.org/core-api/memory-allocation.html), [unevictable LRU](https://docs.kernel.org/mm/unevictable-lru.html), and current MM source around `mm/memory.c`, `mm/filemap.c`, `mm/page_alloc.c`, `mm/rmap.c`, and `mm/vmscan.c`.

Placement rule: this file owns residency, backing, page-table lifetime, PTE/PFN metadata, and stale-byte reasoning. The low-level component map should only summarize these as enforcement state; the critical-terms glossary should only give quick definitions.

## Offensive Priority Index

| Score | Section | Why it matters |
|---:|---|---|
| 100 | Core model; why pagefile/swap mostly matters for writable private data | Prevents bad reasoning about backing, residency, reclaim, and stale data. |
| 100 | Shared memory backing; section/tmpfs/pagefile-backed memory | Shared memory is often a cross-process authority and data-transfer primitive. |
| 99 | PFN/PTE relationship; page lists; standby/cache/free/zeroed pages | Explains what is still in RAM, what is reusable, and what metadata proves ownership. |
| 98 | Demand-zero faults and stale-byte security boundaries | Central to info-leak reasoning, use-after-free intuition, and allocator/page reuse. |
| 97 | Nonpageable, pinned, locked, unevictable memory | Important for drivers, DMA, high-IRQL constraints, and kernel exploit constraints. |
| 95 | Linux versus Windows list names and implementation differences | Useful after the invariant model is clear. |

## Core Model

Do not collapse these words:

| Term | Precise meaning | Security consequence |
|---|---|---|
| Resident | The page contents are currently in RAM. | A resident page can be used without disk I/O, but it may still be evictable. |
| Pageable | The OS may remove the page from a working set and later fault it back. | Page faults are normal; high-IRQL or interrupt-like paths cannot depend on pageable memory. |
| Swappable/pagefile-backed | Dirty anonymous/private contents can be written to swap or pagefile when evicted. | Contents must be protected as process-private state, not discarded. |
| File-backed | Contents come from a regular file or image file. Clean pages can be discarded and reread. | Clean file-backed pages do not need pagefile/swap writes. Dirty shared mappings may write back to the file. |
| Pagefile-backed section / anonymous shared | Shared memory with no explicit existing file. | It is shared through an OS object, but its backing is swap/pagefile/tmpfs-style storage, not a DLL or data file. |
| Reclaimable | The OS can repurpose the physical page after preserving or discarding contents according to backing rules. | Reclaim changes timing, fault behavior, and page reuse. |
| Pinned, locked, or unevictable | The OS must keep the physical page resident until the pin/lock is released. | DMA, MDLs, `mlock`, GUP pins, and nonpaged allocations create lifetime obligations. |
| Nonpageable | Kernel memory/code that must not fault in the contexts that access it. | Windows high-IRQL code and many driver paths require nonpaged memory; Linux kernel direct-map/logical memory is not swapped like user pages. |

The useful interview sentence:

> Backing answers where bytes come from if RAM is reclaimed; residency answers whether bytes are in RAM now; pinning answers whether the OS is allowed to reclaim the page at all.

## Why Pagefile/Swap Mostly Matters For Writable Private Data

Pagefile/swap is needed when the OS must preserve bytes that cannot be reconstructed from some cleaner source.

Clean file-backed and image-backed pages already have a durable identity: file plus offset plus mapping semantics. If a clean DLL code page is reclaimed, Windows can discard the RAM page and later reread the bytes from the DLL image section. Linux can do the same for clean executable/shared-library pages through the page cache. Writing those clean bytes to pagefile/swap would waste I/O and storage because the backing file is already the better copy.

Private writable data is different. A heap page, stack page, anonymous mapping, or copy-on-written image/data page may contain bytes that exist only because this process wrote them. If the OS evicts that page and later the process touches it again, the OS must reproduce those exact private bytes. On Windows, commit charge represents that promise and pagefile-backed storage may be used when RAM pressure requires it. On Linux, dirty anonymous memory may be written to swap if reclaim chooses to evict it and swap is available.

The word "writable" is still shorthand. A read-only private page can be pagefile/swap-relevant if its current contents are private dirty state whose protection was later changed to read-only. A writable file mapping may be file-backed rather than pagefile-backed if writes belong to the file/cache object. The precise rule is:

> Pagefile/swap is for private dirty contents with no ordinary file backing that can reconstruct them. Clean file-backed contents can be discarded; dirty shared file-backed contents belong to file/cache writeback; demand-zero contents can be recreated as zeros until they are modified.

## Nonpageable Versus Non-Swappable

Nonpageable is the stronger operational constraint. It means code that touches the memory cannot tolerate a page fault, usually because the current context cannot sleep or run the fault path.

Windows examples:

- Nonpaged pool.
- Ready/running kernel stacks and interrupt/scheduler-critical state.
- Driver code/data that can run at `DISPATCH_LEVEL` or above.
- MDL-locked pages after `MmProbeAndLockPages`.
- Hardware-walkable page-table pages for live address spaces.
- Core Memory Manager state such as the PFN database.

Windows pageable driver sections are allowed, but only for code/data reached at safe IRQL. Microsoft documents that code at `IRQL >= DISPATCH_LEVEL` must be resident; a fault there is a bugcheck-class failure.

Linux examples:

- Live page-table pages.
- Kernel stacks for runnable contexts.
- Slab/page allocator metadata, scheduler state, interrupt state, and most core kernel text/data.
- DMA or long-term pinned pages.
- `mlock`/`SHM_LOCK` and other unevictable pages.

Non-swappable is narrower. Clean executable or DLL/shared-library pages are often not written to swap/pagefile because the original image file is the backing store. They may still be evicted from RAM and reread later. That makes them pageable/reclaimable, but not "swapped" in the anonymous-memory sense.

## Shared Memory Backing

Shared memory is not always backed by a pre-existing file.

Windows section objects can be:

| Section kind | Backing | Example |
|---|---|---|
| Image-backed | PE image file with image-section semantics. | EXE/DLL mappings. |
| File-backed data | A regular file. | `CreateFileMapping(file_handle, ...)`. |
| Pagefile-backed | The system paging files; no explicit file chosen by the caller. | `CreateFileMapping(INVALID_HANDLE_VALUE, ...)` shared between processes. |

Linux has similar categories with different names:

| Mapping kind | Backing | Example |
|---|---|---|
| File-backed | inode plus page cache. | `mmap(fd, MAP_SHARED)` or executable/shared-library mappings. |
| Anonymous private | no file; swap if evicted after dirty. | heap, stack, `MAP_PRIVATE | MAP_ANONYMOUS`. |
| Anonymous/shared shmem | tmpfs/shmem/swap-like backing rather than a normal persistent file. | `MAP_SHARED | MAP_ANONYMOUS`, POSIX shm on tmpfs, SysV shm. |

DLL deletion nuance: a loaded DLL is not protected because the OS needs to write clean image pages to the pagefile. Clean image pages can be discarded and reread from the DLL file. Normal Windows delete/overwrite attempts fail because image-section and file-sharing semantics keep the file object/section relationship alive while the image is mapped. Exact rename/delete behavior depends on handles, share modes, POSIX delete semantics, filesystem behavior, and build policy, but the important memory-manager point is: the DLL file is the clean-page backing store.

Linux normally allows unlinking a mapped or executing file because directory entry removal is separate from the inode and open/mapped references. The file data remains alive until the last reference is gone.

## PTEs, PFNs, and Physical Page Metadata

A PTE is the current or potential virtual-to-physical translation record. When valid/present, it contains a physical page frame number plus permissions and architecture bits. When invalid/nonpresent, OS software may encode a demand-zero, transition, prototype, pagefile/swap, or other software state.

A PFN is a physical page frame number. It is an index into physical memory at page granularity.

Windows has a PFN database: an array of physical-page records, one per RAM page used by the Memory Manager. A PFN entry tracks page state and relationships such as:

- active, standby, modified, free, zeroed, bad, or related list state
- reference/share counts
- whether I/O/writeback is in progress
- the PTE or prototype PTE that describes the page
- original PTE contents needed when the page leaves RAM

The relationship is bidirectional in the normal resident case:

```text
virtual address -> PTE -> PFN number -> PFN database entry -> owning PTE/prototype PTE/backing state
```

Prototype PTEs are the important Windows sharing indirection. Instead of each process PTE independently owning all state for a shared page, process PTEs can refer to prototype PTEs associated with a section object. That is how image-backed and mapped shared pages keep one coherent backing relationship across many processes.

Linux has the same conceptual layers but different structures:

- PTE/PMD/PUD/PGD hierarchy: hardware-facing translation.
- `struct page` / folio: physical-page metadata.
- `address_space` and page cache: file-backed identity.
- swap entries and swap cache: anonymous page eviction identity.
- reverse mapping: from physical page back to VMAs/PTEs that map it.

Security relevance: if a bug corrupts PTE state, PFN/page metadata, or reverse-map/prototype state, it can create false sharing, stale access, bad writeback, hidden executable memory, or a page that the kernel believes is unmapped while hardware or another metadata path still exposes it.

## Hardware-Walkable Page Tables

Page tables are memory too, but live translation-table pages are not ordinary pageable user data. The hardware page-table walker reads them through physical addresses starting from an address-space root such as x86 `CR3` or arm64 `TTBR0_EL1`/`TTBR1_EL1`. If a table page is still reachable from an active or switchable root, the OS must keep it resident and structurally valid. It can free or repurpose a lower-level table only after invalidating the parent entry, synchronizing with other CPUs, and flushing stale TLB entries.

For ordinary x86-64 four-level paging with 4 KiB pages:

| Level | Entries per table page | Coverage per entry |
|---|---:|---:|
| PML4 | 512 | 512 GiB |
| PDPT | 512 | 1 GiB through a page directory, or a 1 GiB large page when supported/enabled |
| Page directory | 512 | 2 MiB through a page table, or a 2 MiB large page when supported/enabled |
| Page table | 512 | 4 KiB |

A process does not allocate a fully populated hierarchy. It needs at least a top-level root, then lower-level pages only for virtual ranges that are mapped. Kernel portions may be shared across processes, while KPTI/KVA-shadow designs can give a process separate user and kernel roots. PCID on x86 and ASID on arm64 tag TLB entries by address-space identity so context switches do not always require flushing every cached translation.

Common hardware PTE bits on x86 include present, read/write, user/supervisor, cache-control bits, accessed, dirty, PAT/page-size, global, NX/XD, and protection-key bits where supported. When the hardware-present bit is clear, the remaining bits are no longer a valid hardware translation; the OS can encode software states such as demand-zero, prototype/file-backed, copy-on-write, transition/standby, or pagefile/swap-backed state. A protection failure is the result of an attempted access that violates the valid PTE's permissions; it is not itself a stable backing state.

Reverse mappings are the other direction: from a physical page back to the PTEs, VMAs/VADs, section/prototype PTEs, or address-space metadata that map it. Linux calls this rmap in many paths. Windows uses PFN database fields and prototype-PTE relationships. Reverse mapping/backpointer state lets the kernel revoke mappings, collect dirty/accessed evidence, write back or swap the correct object, and invalidate all aliases before reusing a physical page.

## Demand-Zero Faults

Demand-zero means the virtual range is legal, but no private physical page exists yet. On first access, the OS supplies zeros.

Windows:

- `VirtualAlloc` committed private pages commonly start as demand-zero PTEs.
- On first write/read requiring a real page, the Memory Manager supplies a zeroed page, updates the PTE, and charges/accounting already reflects the committed promise.
- It prefers a page from the zeroed list. If needed, it can take another available page and zero it before exposing it.

Linux:

- Anonymous VMAs often start as policy ranges with no private page.
- A read fault can map a shared read-only zero page on architectures/configurations that use one.
- A write fault allocates a real zero-filled page and maps it writable.
- If that anonymous page later becomes cold and dirty, reclaim may write it to swap.

Use-after-free distinction:

- Demand-zero and page zeroing protect one allocation boundary from seeing stale bytes from a previous allocation in another security context.
- They do not automatically prevent use-after-free inside the same allocator layer. A freed heap/slab object can be reallocated inside the same process or kernel cache with stale references still pointing at the same virtual address or same physical slot.
- If the page never returned to the page allocator, the OS page-zeroing invariant may not run. Object-level allocators may or may not zero fields on allocation/free.

## Windows Page Lists and Soft Faults

At a simplified level:

| Windows page state/list | In RAM? | Contains useful old data? | Reuse behavior |
|---|---:|---:|---|
| Active/valid | Yes | Yes | Mapped in a working set or otherwise actively used. |
| Standby | Yes | Yes | Removed from a working set but kept as cache; can be soft-faulted back without disk I/O. |
| Modified | Yes | Yes | Dirty page removed from working set; must be written to backing store before clean reuse. |
| Free | Yes | May contain stale bytes | Available for use where contents will be overwritten or zeroed before exposure. |
| Zeroed | Yes | No | Available for demand-zero/user-visible allocation without extra zeroing. |
| Bad | Yes/no as hardware page | Not usable | Excluded because of memory error or firmware/OS decision. |

The standby list is still RAM. A fault on a standby page is a soft fault/transition fault: the page did not have to be read from disk because its contents were still resident. The Memory Manager can relink it into the relevant working set and make the PTE valid again.

The free and zeroed lists are also RAM, not pagefile. The pagefile stores evicted modified private/pagefile-backed contents; it is not a holding area for free RAM frames.

## Linux Reclaim and Cache Lists

Linux does not use the same named Windows lists, but the ideas map:

| Linux concept | Rough role |
|---|---|
| Active/inactive file LRUs | File-backed page-cache pages ranked for reclaim/refault. |
| Active/inactive anon LRUs | Anonymous pages ranked for reclaim/swap. |
| Unevictable LRU | Pages hidden from normal reclaim, such as `mlock` or locked shared-memory cases. |
| Buddy free lists/per-CPU page lists | RAM frames available for allocation. |
| Page cache | Resident file-backed data that can often be dropped if clean or written back if dirty. |
| Swap cache | Resident page associated with a swap entry, useful around swap-in/swap-out races and reuse. |

Linux "free pages" are physical RAM pages. Swap is disk/storage backing for evicted anonymous memory; it is not where free pages live.

## Non-Zero Free Pages and Security

The statement "the OS can allocate from the non-zero free list safely" is conditionally true.

Safe cases:

- A disk read fills the entire page before any user or untrusted consumer can read it.
- A file-backed clean page is reconstructed from the trusted backing file plus correct hole/EOF zero-fill handling.
- A kernel allocation is used only after the kernel initializes all fields that can be observed by untrusted code.
- An allocation is for internal kernel-only state and stale bytes never influence policy, pointer targets, sizes, flags, or output.

Unsafe cases:

- The kernel copies an uninitialized pool/slab buffer to user mode, network, disk, or device output.
- Padding bytes in a structure are not initialized before disclosure.
- A short read, sparse-file hole, EOF tail, or partial I/O leaves stale bytes in the remainder of a page.
- A stale field influences a later branch, size, function pointer, reference count, object type, or access check.

Windows has moved newer pool APIs toward zero-by-default. `ExAllocatePool2` zeroes memory unless `POOL_FLAG_UNINITIALIZED` is requested; Microsoft explicitly warns not to opt out for data copied to untrusted destinations. Linux commonly offers explicit zeroing APIs and flags such as `kzalloc`, `__GFP_ZERO`, and hardening options like `init_on_alloc`/`init_on_free`, but many kernel allocation paths still rely on the caller to initialize what matters.

Security invariant:

> A nonzero physical page is fine if its old bytes are overwritten or kept inside a trusted boundary before observation. It is a vulnerability if stale bytes cross a trust boundary or control a security-relevant decision.

## Page Fault Types to Name Clearly

| Fault shape | What happened | Disk I/O? |
|---|---|---:|
| Demand-zero fault | Legal anonymous/private range first touched; OS supplies zeros. | No. |
| Minor/soft/transition fault | Page is already resident but PTE is not currently valid for this process/working set. | No. |
| File-backed major fault | Page must be read from the file/page cache miss path. | Usually yes. |
| Swap/pagefile fault | Dirty private or pagefile-backed page must be read from swap/pagefile. | Yes. |
| COW fault | Write to copy-on-write mapping; OS allocates private page and copies/zeros as needed. | Usually no unless source page must first be faulted in. |
| Protection fault | Access violates range/PTE policy, such as write to read-only or execute on NX. | No, unless fault path first resolves a nonresident page before rejecting. |

## Debugging and Forensics Checks

Windows:

- VMMap: classify private, image, mapped, shareable, committed, and working-set state.
- RAMMap: inspect standby, modified, zeroed, free, and file-backed resident pages.
- WinDbg: use `!vad`, `!address`, `!pte`, `!memusage`, `!process`, `!handle`, and PFN/PTE inspection with symbols.
- Process Explorer: correlate working set, private bytes, handles, DLL/image paths, and protection state.

Linux:

- `/proc/<pid>/maps`, `smaps`, `pagemap` where permitted, and `numa_maps`.
- `/proc/meminfo`, `/proc/vmstat`, `free`, `vmstat`, `slabtop`, `perf`, `bpftrace`, ftrace.
- Source-level checks around `do_fault`, `handle_mm_fault`, `filemap_fault`, `do_wp_page`, `try_to_unmap`, and reclaim paths.

Cross-check rule:

> One view rarely owns the truth. Compare range policy, current PTE state, physical-page metadata, backing object, loader/file identity, and telemetry.

## Online Reading List

Use these when the local notes need external depth.

| Source | Best use |
|---|---|
| [MaskRay - All about thread-local storage](https://maskray.me/blog/2021-02-14-all-about-thread-local-storage), [GOT](https://maskray.me/blog/2021-08-29-all-about-global-offset-table), [PLT](https://maskray.me/blog/2021-09-19-all-about-procedure-linkage-table) | ELF loader/linker internals that affect memory mappings, relocation, TLS, and hardening. |
| [Google Project Zero - TLB issue in `mremap`](https://googleprojectzero.blogspot.com/2019/01/taking-page-from-kernels-book-tlb-issue.html) | Linux page-table movement, stale TLBs, page allocator behavior, and exploitability. |
| [Google Project Zero - Linux kernel memory corruption](https://googleprojectzero.blogspot.com/2021/10/how-simple-linux-kernel-memory.html) | Object lifetime, page allocator reuse, UAF-to-page-table reasoning, and mitigation discussion. |
| [Google Project Zero - Windows kernel memory disclosure diffing](https://googleprojectzero.blogspot.com/2017/10/using-binary-diffing-to-discover.html) | Uninitialized kernel memory and why zeroing/padding matters. |
| [Windows Internals blog - KASLR leaks restriction](https://windows-internals.com/kaslr-leaks-restriction/) | Modern Windows kernel address exposure and security policy changes. |
| [Windows Internals blog - Secure Pool](https://windows-internals.com/secure-pool/) and [KDP Pool](https://windows-internals.com/goodbye-secure-pool-hello-kdp-pool/) | VBS/KDP-backed protection for sensitive kernel data. |
| [CodeMachine - Prototype PTEs](https://codemachine.com/articles/prototype_ptes.html) | Windows shared memory and section/prototype-PTE mental model. |
| [Rayanfam - Inside Windows PFN](https://rayanfam.com/topics/inside-windows-page-frame-number-part1/) | Practical Windows PFN database study with debugger orientation. |
| [Linux kernel docs - MM index](https://docs.kernel.org/mm/index.html), [page tables](https://docs.kernel.org/mm/page_tables.html), [memory concepts](https://docs.kernel.org/admin-guide/mm/concepts.html) | Current Linux terminology and source-oriented MM study. |
| [LWN - On pages and folios](https://lwn.net/Articles/1064861/), [swap-table work](https://lwn.net/Articles/1056405/) | Current Linux MM evolution explained at kernel-community level. |
| [Trail of Bits - Linux `mseal`](https://blog.trailofbits.com/2024/10/25/a-deep-dive-into-linuxs-new-mseal-syscall/) | User-space VMA sealing as exploit mitigation and memory-policy hardening. |
| [Trail of Bits - Meltdown/Spectre overview](https://blog.trailofbits.com/2018/01/30/an-accessible-overview-of-meltdown-and-spectre-part-1/) | Hardware permission, caching, and speculative side-channel foundations. |
| [Microsoft MSRC - uninitialized kernel pool memory](https://www.microsoft.com/en-us/msrc/blog/2020/07/solving-uninitialized-kernel-pool-memory-on-windows/) and [uninitialized stack memory](https://msrc.microsoft.com/blog/2020/05/solving-uninitialized-stack-memory-on-windows/) | Why automatic initialization changed Windows security engineering. |

## Active Recall Prompts

1. Why can a clean DLL page be evicted without writing it to the pagefile?
2. Why is a page on the Windows standby list still a RAM page?
3. Why are free and zeroed page lists not "in swap"?
4. Why is pagefile-backed shared memory still shared memory even without an existing DLL or data file?
5. Why can a demand-zero fault be normal and security-critical at the same time?
6. Why does page zeroing not eliminate use-after-free bugs inside an allocator?
7. Why can a nonzero free page be safe for a disk read but unsafe for a kernel output buffer?
8. What does the PTE know that the VAD/VMA does not?
9. What does the PFN database or `struct page` know that one PTE does not?
10. Why do prototype PTEs or reverse maps matter for shared-memory security?
