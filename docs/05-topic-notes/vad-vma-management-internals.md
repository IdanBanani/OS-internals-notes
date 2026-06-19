# VAD and VMA Management Internals

Value Score: 86/100
Role: VAD/VMA focused owner
Proof Level: Conceptual

Date: 2026-05-19

Scope: one focused map for Windows VADs and Linux VMAs: what object owns a user virtual range, how ranges are indexed, how they are split/merged/protected, how faults walk from policy to PTEs, and which structures prove backing, sharing, residency, and suspicious executable memory.

Use this after:

- [Linux vs Windows internals](<../01-comparisons-and-maps/01-linux-vs-windows-internals.md>)
- [Process memory access and memory API flags](<../01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md>)
- [Paging, residency, page lists, and shared memory](<paging-residency-page-lists-and-shared-memory.md>)

## Source Anchors

Linux current anchors:

- [Linux kernel Process Addresses](https://docs.kernel.org/mm/process_addrs.html): `mm_struct`, `vm_area_struct`, Maple Tree, VMA locks, rmap locks, and page-table locking.
- [Linux kernel Maple Tree](https://docs.kernel.org/core-api/maple_tree.html): current VMA range index. Do not center current Linux study on old VMA rbtree material.
- [Linux kernel Page Tables](https://docs.kernel.org/mm/page_tables.html): generic page-table hierarchy and PFN vocabulary.
- [Linux kernel Page Cache](https://docs.kernel.org/mm/page_cache.html): page-cache and folio vocabulary.
- Target source tree: `include/linux/mm_types.h`, `mm/mmap.c`, `mm/memory.c`, `mm/filemap.c`, `mm/rmap.c`, `fs/proc/task_mmu.c`, and `arch/<arch>/mm/fault.c`.

Windows public anchors:

- [VirtualAlloc](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc): reserve, commit, reset, write-watch, large pages, and protection inputs.
- [VirtualQuery](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualquery): user-visible region coalescing by state, allocation origin, and protection.
- [File Mapping](https://learn.microsoft.com/en-us/windows/win32/memory/file-mapping): file mapping objects and per-process views.
- [File-backed and page-file-backed sections](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/file-backed-and-page-file-backed-sections): section backing, COW sections, page-file-backed shared memory.
- Local Windows Internals-style sources listed in [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>).

Important caveat: Linux structure names are source-level contracts for a specific kernel tree, but fields still move. Windows VADs, control areas, prototype PTEs, and many Memory Manager fields are private implementation details. Public symbols and WinDbg make them inspectable, not stable public API.

## Core Invariant

Do not collapse these layers:

| Layer | Linux | Windows | Question answered |
|---|---|---|---|
| Range policy | `vm_area_struct` in an `mm_struct` Maple Tree | VAD nodes in process address-space state | Is this virtual range legal, with which policy? |
| Mapping API input | `mmap`, `brk`, ELF loader, `mprotect`, `mremap`, `munmap`, `madvise` | `VirtualAlloc`, `VirtualProtect`, `MapViewOfFile`, `NtMapViewOfSection`, `VirtualFree` | What operation created or changed the range? |
| Backing object | `struct file`, `address_space`, page cache, shmem/tmpfs, `anon_vma`, swap | section object, control area, subsection, segment, file object, pagefile/private commit, prototype PTEs | Where do bytes come from and who can share them? |
| Hardware translation | PGD/P4D/PUD/PMD/PTE entries | hardware PTEs plus software/prototype/transition/pagefile PTE states | What translation or fault state exists now? |
| Physical page metadata | `struct page` / folio, refcount, mapcount, LRU, dirty/writeback, pins | PFN database, working set, standby/modified/free/zeroed state, share/reference counts | Which RAM page is involved and can it be reclaimed? |
| User-visible evidence | `/proc/<pid>/maps`, `smaps`, `pagemap`, perf/ftrace/BPF, source | `VirtualQueryEx`, VMMap, `!address`, `!vad`, `!pte`, ETW image/memory events | What can an analyst observe? |

The high-value sentence:

> A VMA or VAD says what a range should mean; a PTE says what the CPU or fault path sees right now.

That explains why a legal range can have no resident pages, why a writable VMA/VAD can temporarily have read-only COW PTEs, and why loader metadata can disagree with memory-manager truth.

## Structure Graphs

### Linux

```text
task_struct
  -> mm_struct
       -> mm_mt Maple Tree of VMAs
       -> pgd top-level page-table pointer
       -> mmap_lock and mm accounting
       -> layout fields: brk, mmap_base, stack/code/data bounds
       -> vm_area_struct nodes
            -> vm_start / vm_end / vm_flags / vm_page_prot
            -> vm_file / vm_pgoff / vm_ops / vm_private_data
            -> anon_vma and anon_vma_chain
            -> shared interval-tree node for file rmap
            -> optional mempolicy, userfaultfd, anon-name, config fields
            -> page tables
                 -> PTE/PMD/etc.
                      -> PFN
                           -> struct page / folio
                                -> page cache, anonymous, swap, pinned, LRU state
```

Current Linux stores VMAs in `mm_struct` through a Maple Tree, not the old rbtree-centered model many older books emphasize. Reverse mappings still use their own structures: file-backed VMAs are reachable through `address_space->i_mmap`, and anonymous/COW relationships use `anon_vma` and chains.

### Windows

```text
_EPROCESS
  -> process address-space / Memory Manager state
       -> VAD balanced tree root
            -> _MMVAD_SHORT / _MMVAD-style node
                 -> starting and ending VPN fields
                 -> protection, type, commit, private/no-change/guard-style flags
                 -> lock/reference/event fields, by build
                 -> for mapped/image views: subsection/prototype-PTE relationship
                      -> _SUBSECTION
                           -> _CONTROL_AREA
                                -> _SEGMENT
                                -> _FILE_OBJECT for file/image-backed mappings
                      -> prototype PTEs
                 -> process PTEs
                      -> valid, transition, demand-zero, prototype, pagefile, COW states
                           -> PFN database entry when resident
```

On Windows, treat the exact fields as symbol-versioned. Use commands like `dt nt!_MMVAD_SHORT`, `dt nt!_MMVAD`, `dt nt!_CONTROL_AREA`, and `dt nt!_SUBSECTION` against the target build. The stable concept is not the offset; it is the graph: process VAD tree -> private allocation or section view -> PTE/prototype-PTE/PFN/backing state.

## What A VMA Stores

The current Linux docs divide `struct vm_area_struct` fields by role. The field names below are the ones to search first in the target kernel, but configuration can add or remove members.

| Field or group | Meaning |
|---|---|
| `vm_start`, `vm_end` | Inclusive start and exclusive end of the virtual range. |
| `vm_mm` | Owning `mm_struct`. |
| `vm_page_prot` | Architecture-specific page-table protection derived from VMA flags. |
| `vm_flags` / internal mutable flags | Policy bits: read, write, exec, shared, may-read/write/exec, stack growth, dump, lock, PFN/special mapping, huge-page hints, soft-dirty-like tracking, and more. |
| `vm_file` | File backing, or `NULL` for anonymous mappings. |
| `vm_pgoff` | Page offset into file, original address-space offset for some remaps, or PFN-like meaning for special mappings. |
| `vm_ops` | VMA operations, especially fault behavior for file/device/special mappings. |
| `vm_private_data` | Driver or subsystem private data associated with this VMA. |
| `anon_vma`, `anon_vma_chain` | Anonymous/COW reverse mapping and ancestry relationships. |
| `shared.rb`, `shared.rb_subtree_last` | File-backed reverse-mapping interval-tree placement. |
| Optional fields | NUMA policy/state, userfaultfd context, anonymous mapping names, swap readahead metadata, and config-specific state. |

The VMA is not a page table. It is a policy object that the fault path, `mprotect`, `munmap`, reclaim, rmap, procfs reporting, and core-dump logic all consult.

## What A VAD Stores

Windows VADs are private. Do not memorize offsets. Memorize these categories and verify with symbols:

| VAD category | Typical meaning |
|---|---|
| Tree node | Balanced-tree linkage used to find the range containing a virtual address. Modern symbols commonly expose an `RTL_BALANCED_NODE`-style node. |
| Range bounds | Starting and ending virtual page numbers, sometimes split into low/high fields. |
| Protection | Initial/current range protection policy, separate from current PTE permissions. |
| VAD type | Private allocation, mapped view, image map, large page, AWE/device/special cases, write-watch, or other build-specific type. |
| Commit/accounting | Commit charge or commit-related bits for private committed memory and some view cases. |
| Flags | Private memory, no-change, guard-like behavior, delete-in-progress, secured/no-change state, preferred NUMA node, and build-specific options. |
| Lock/reference/event state | Per-VAD synchronization or event fields visible in some builds. |
| Section view metadata | For mapped/image views, pointers or relationships to subsection/prototype PTE/control-area state. |

The VAD answers the same first-order question as a VMA: "Should this process have this virtual range, with which intended protections and backing semantics?" Windows then needs section objects, prototype PTEs, PFN database entries, and working-set state to answer sharing and residency.

## Range Creation

### Linux Creation Paths

Common creators:

- ELF loader creates executable, data, interpreter, shared-library, stack, vdso/vvar, and related VMAs.
- `mmap()` creates anonymous, file-backed, shared, private, fixed, huge, stack-like, device, or shmem VMAs.
- `brk()` grows or shrinks the classic heap VMA.
- `fork()` duplicates VMA metadata and shares many pages initially with COW PTEs.
- `clone(CLONE_VM)` shares the same `mm_struct`, so threads see the same VMA map.
- `execve()` replaces the old user address space with a new mm layout.

High-level source path:

```text
sys_mmap / mmap syscall wrapper
  -> do_mmap() / mmap_region()-style logic in mm/mmap.c
       -> choose address, validate flags, consult file ops
       -> create or modify vm_area_struct
       -> merge with neighbors when legal
       -> insert into mm->mm_mt
       -> update accounting
```

No physical page is required just because a VMA exists. Physical pages usually appear on page fault, read-ahead, prefault, `mlock`, huge-page paths, or driver-specific behavior.

### Windows Creation Paths

Common creators:

- `VirtualAlloc` / `NtAllocateVirtualMemory` reserve and/or commit private address ranges.
- PE image loading creates image-section views for EXE/DLL mappings.
- `CreateFileMapping` / `NtCreateSection` creates a section object.
- `MapViewOfFile` / `NtMapViewOfSection` maps a section view into one process address space.
- Heap managers, JITs, stacks, shared-memory APIs, and runtimes call these lower primitives underneath.

High-level private allocation:

```text
VirtualAlloc / NtAllocateVirtualMemory
  -> reserve address range and/or commit pages
       -> create, split, or update VAD
       -> record protection and commit policy
       -> leave PTEs demand-zero or otherwise nonresident until fault
```

High-level section view:

```text
CreateFileMapping / NtCreateSection
  -> section object backed by file, image file, or pagefile
MapViewOfFile / NtMapViewOfSection
  -> VAD for the view
       -> subsection/control-area/prototype-PTE relationship
       -> process PTEs can refer to prototype PTEs for shared pages
```

Windows separates reserve, commit, protection, and residency more explicitly than Linux user APIs. A reserved VAD can consume address space without committed private backing. A committed private range consumes commit promise but still may not have resident physical pages.

## Splitting, Merging, And Protection Changes

### Linux

Operations that often split or merge VMAs:

- `mmap()` next to a compatible neighbor can merge VMAs.
- `mprotect()` on a subrange can split one VMA into up to three VMAs.
- `munmap()` can delete a full VMA or punch out the middle, forcing split.
- `mremap()` can move, grow, or adjust range metadata.
- `madvise()` can change behavior or zap pages without necessarily deleting the VMA.

Merge eligibility is strict. Adjacent ranges must have compatible flags, backing file, offsets, policies, userfaultfd/anon-name/NUMA state, and subsystem-specific constraints. This is why `/proc/<pid>/maps` line count can change after a small `mprotect`.

Protection changes update policy and then reconcile current PTEs. For example, making a range read-only may clear writable PTE bits and require TLB invalidation. Making a range writable may leave individual PTEs read-only if they are COW or write-protected for tracking.

### Windows

Operations that often split or update VADs:

- `VirtualProtect` / `NtProtectVirtualMemory` changes protection policy and can split a VAD around a subrange.
- `VirtualFree(..., MEM_DECOMMIT)` keeps the reservation but removes private committed backing for pages.
- `VirtualFree(..., MEM_RELEASE)` removes the whole reserved region and its VAD.
- `UnmapViewOfFile` / `NtUnmapViewOfSection` removes section views and releases references.
- Loader operations map and unmap image views as process modules are loaded/unloaded.

The important distinction is:

| Operation | Range policy | Backing/accounting | PTE effect |
|---|---|---|---|
| Reserve | VAD exists | address space reserved, no private commit | no valid page required |
| Commit | VAD or existing VAD records committed private pages | commit charge/promise exists | often demand-zero PTE state until touch |
| Decommit | VAD reservation may remain | private commit released | PTEs invalidated or reset to noncommitted state |
| Release/unmap | VAD removed | references/commit/view released | PTEs zapped and TLB handled |
| Protect | VAD protection changes, maybe split | backing unchanged | valid PTE permissions updated or fault-time policy changed |

`VirtualQueryEx` reports coalesced regions with matching state/type/protection. That report is user-mode evidence derived from memory-manager state; it is not the private VAD layout itself.

## Page Fault Resolution

### Linux Fault Path

Conceptual current path:

```text
CPU page fault
  -> arch/<arch>/mm/fault.c
       -> classify user/kernel, read/write/execute, present/protection/etc.
       -> stabilize VMA via lock_vma_under_rcu() or mmap_lock fallback
       -> locate VMA in mm Maple Tree
       -> check address, access, growth, and special mapping policy
       -> handle_mm_fault()
            -> anonymous fault
            -> file-backed fault via vm_ops->fault / filemap_fault()
            -> write-protect / COW fault
            -> swap, migration, THP, hugetlb, userfaultfd, device/special path
       -> install/update PTE or PMD
       -> accounting, rmap, LRU/page-cache updates
       -> TLB/cache handling as required
       -> resume or deliver SIGSEGV/SIGBUS
```

Common cases:

| Fault shape | Mechanism |
|---|---|
| Anonymous read fault | Can map a shared read-only zero page on supported configurations. |
| Anonymous write fault | Allocates a zero-filled private page or folio and maps it writable if policy allows. |
| File-backed fault | Uses VMA `vm_file`/`vm_ops` and page cache to find or read the page. |
| COW write fault | Allocates a private copy, updates PTE and rmap, preserves other mappings. |
| Swap fault | Decodes a swap entry from non-present PTE state and brings data back. |
| Protection fault | Denied if VMA/PTE policy disallows the access. |
| Stack growth | Allowed only under stack-growth policy and guard/gap constraints. |

### Windows Fault Path

Conceptual path:

```text
CPU page fault
  -> kernel trap/exception dispatch
       -> Memory Manager fault handler
       -> locate VAD for the faulting user VA
       -> check access against VAD policy, protection, guard/noaccess, section rules
       -> inspect process PTE
            -> demand-zero private page
            -> transition/standby soft fault
            -> prototype PTE for mapped/image section
            -> pagefile-backed private page
            -> COW/image-private split
            -> guard page or invalid access
       -> update PTE, PFN, working set, prototype/control-area state
       -> TLB/cache handling as required
       -> resume or raise access violation / in-page error
```

Common cases:

| Fault shape | Mechanism |
|---|---|
| Demand-zero private | Committed private page first touched; Memory Manager supplies a zeroed page and updates PTE/PFN state. |
| Transition/soft fault | Page is still resident on standby/transition state; the PTE can be made valid again without disk I/O. |
| File/image-backed | VAD leads through subsection/control area/prototype PTEs to file or image backing. |
| Pagefile-backed | Private dirty contents are read from paging storage. |
| COW | Shared prototype/image/file page is copied into a private page for this process. |
| Guard page | First access consumes or reports guard semantics and typically raises a guard-page exception. |
| Invalid access | No VAD, wrong protection, impossible backing, or failed in-page operation raises an exception. |

The Windows VAD tells the fault path whether the address range is legitimate and what class of backing should apply. The current PTE tells the fault path which concrete case it is resolving.

## Locking And Lifetime

### Linux Locking Model

Current Linux MM uses several lock classes:

| Lock | Role |
|---|---|
| `mmap_lock` | Address-space-wide read/write semaphore. Writers change VMA topology or broad metadata. |
| VMA lock | VMA-granular lock; page faults can use read-side VMA locking through RCU lookup. Write-side VMA locking requires mmap write ownership. |
| rmap locks | Stabilize VMAs reached from a folio through `anon_vma` or file `address_space` reverse mappings. |
| page-table locks | Serialize changes to PTE/PMD-level state. |
| folio/page locks and LRU/reclaim locks | Protect physical-page/page-cache/reclaim state. |

Key rules:

- Stabilizing a VMA does not lock the physical memory it describes.
- Updating VMA topology is different from updating a PTE.
- Reclaim and migration often work from page/folio back toward mappings, so rmap state matters.
- Freeing page-table pages has stricter requirements than merely zapping leaf PTEs.

### Windows Locking Model

Windows Memory Manager locking is private and build-specific, but the conceptual split is stable:

| Locking area | What it protects |
|---|---|
| Process address-space/VAD synchronization | VAD tree topology, range insertion/removal/splitting, protection changes. |
| Working-set synchronization | Which pages are resident in a process working set and related aging/trimming state. |
| PFN/database synchronization | Physical-page state, share/reference counts, modified/standby/free transitions. |
| Section/control-area synchronization | Mapped-file/image/pagefile-backed sharing, prototype PTEs, subsection lifetime. |
| Page-table/PTE synchronization | Valid, transition, prototype, pagefile, and hardware PTE updates plus TLB shootdowns. |

Do not use one old lock name as universal truth. In a real dump or debugger session, let symbols, stack traces, and the target Windows build show the exact fields and lock types.

## Backing And Sharing

### Linux Backing Categories

| Mapping | VMA clues | Backing path |
|---|---|---|
| Anonymous private | `vm_file == NULL`, private flags | demand-zero, anonymous folios, swap if evicted dirty |
| File private | `vm_file != NULL`, `MAP_PRIVATE` semantics | page cache initially, private anonymous copy after COW writes |
| File shared | `vm_file != NULL`, shared flags | page cache, dirty writeback to file according to filesystem rules |
| Shmem/tmpfs/POSIX shm/memfd | file-like object but RAM/swap-backed semantics | shmem page cache, swap-like backing, often deleted/unlinked names |
| Device/PFN/special | special VMA flags and `vm_ops` | driver-defined fault/mapping behavior, often not normal page cache |
| Huge mappings | hugetlb or THP-related state | explicit pool or opportunistic huge folios/PMD mappings |

### Windows Backing Categories

| Mapping | VAD/tool clue | Backing path |
|---|---|---|
| Private reserve/commit | MEM_PRIVATE, private VAD, commit | demand-zero/pagefile-backed private memory |
| Image | MEM_IMAGE, image VAD/view | section object created with image semantics, control area/subsections/prototype PTEs |
| File-mapped data | MEM_MAPPED, mapped section | file-backed section, control area/subsections/prototype PTEs |
| Pagefile-backed section | mapped section without explicit disk file | page files; shared memory between processes |
| COW image/file private page | image/mapped VAD with private modified page evidence | original prototype/file page plus process-private copy |
| Large pages/AWE/device/special | special VAD type and API flags/privileges | special Memory Manager path with different paging/reclaim behavior |

Prototype PTEs are the Windows sharing indirection to understand. Process PTEs for section-backed memory can point to shared prototype PTEs. That is how many processes map the same DLL image or file-mapping page while the Memory Manager still knows who shares, who dirtied, and who COWed the page.

## Reserve, Commit, Resident

| Concept | Linux | Windows |
|---|---|---|
| Range exists | VMA covers the address. | VAD covers the address. |
| Backing promised/accounted | Overcommit policy, memcg, mapping type, `MAP_NORESERVE`, shmem/swap rules. | Commit charge for private committed memory; file/image clean pages often backed by the file instead. |
| Page resident | RSS/page tables/folio state show RAM presence. | Working set/PFN/PTE state shows RAM presence. |
| Query view | `/proc/<pid>/maps`, `smaps`, `pagemap` where permitted. | `VirtualQueryEx`, VMMap, `!address`, `!vad`, `!pte`. |

Linux does not expose a one-to-one `MEM_RESERVE` / `MEM_COMMIT` vocabulary, but the concepts still exist as separate questions. Windows exposes those concepts directly, but a committed page is still not necessarily resident.

## Why VMA/VAD And PTEs Disagree

These disagreements are normal:

- Range exists but no PTE is valid yet: lazy allocation or demand paging.
- VMA/VAD says writable but PTE is read-only: COW, write-protect tracking, or dirty/accessed emulation.
- VMA/VAD says executable but page is nonresident: executable file/image page will fault in later.
- PTE is valid but VMA/VAD changed recently: TLB and shootdown ordering must be handled correctly.
- Loader says module exists but memory says private/executable anomaly: manual mapping, unlinking, hollowing, COW patching, or legitimate JIT/protector behavior.
- File backing says clean source exists but page is private dirty: COW or modified mapped data.

Good analysis asks which layer changed, who owns that layer, and what lower layer enforces the final access.

## Debugging Workflows

### Linux

Use this order:

1. Identify the process and `mm_struct` owner: thread group versus individual task.
2. Read `/proc/<pid>/maps` for range, permissions, file path, and deleted/memfd clues.
3. Read `/proc/<pid>/smaps` for RSS, shared/private clean/dirty, anonymous, huge-page, and swap clues.
4. If kernel source is available, inspect:
   - `include/linux/mm_types.h` for `struct mm_struct` and `struct vm_area_struct`.
   - `mm/mmap.c` for insertion, merge, split, unmap, and protect logic.
   - `mm/memory.c` for `handle_mm_fault()` and COW/demand-zero paths.
   - `mm/filemap.c` for file-backed faults.
   - `mm/rmap.c` for reverse mapping and reclaim/migration relationships.
   - `fs/proc/task_mmu.c` for how `/proc` reports VMA state.
5. On a built kernel with debug info, use `pahole -C vm_area_struct vmlinux` and `pahole -C mm_struct vmlinux` for exact layout.
6. Use tracing carefully: perf, ftrace, BPF tracepoints/kprobes, page-fault counters, and mm tracepoints.

Useful local searches:

```powershell
rg -n "struct vm_area_struct|struct mm_struct" include/linux/mm_types.h
rg -n "handle_mm_fault|do_mmap|mmap_region|vma_merge|vma_modify|do_vmi_align_munmap" mm
rg -n "show_map_vma|smaps|pagemap" fs/proc/task_mmu.c
```

### Windows

Use this order:

1. Start with user-visible views: VMMap, Process Explorer, `VirtualQueryEx`, module lists, image-load ETW, and thread starts.
2. In WinDbg with symbols:
   - `!process 0 1` to locate processes.
   - `.process /r /p <EPROCESS>` when inspecting a target process address space in a dump.
   - `!address` for a region summary.
   - `!vad` or `!vad 1` for VAD tree details.
   - `!pte <va>` for PTE state.
   - `dt nt!_MMVAD_SHORT`, `dt nt!_MMVAD`, `dt nt!_CONTROL_AREA`, `dt nt!_SUBSECTION`, `dt nt!_MMPTE`, and `dt nt!_MMPFN` for exact build layouts.
3. Compare VAD type/protection/backing with:
   - PEB loader lists and `lm`.
   - ETW image-load history.
   - backing file path and file ID.
   - private/shared working-set evidence.
   - modified image pages or executable private pages.
4. Treat public APIs as stable semantics and private structures as build-specific evidence.

Typical suspicious Windows memory questions:

- Is this executable region private, mapped, or image-backed?
- Does the VAD protection match current PTE permissions?
- Is a DLL page now private due to COW modification?
- Does PEB loader metadata agree with VAD/image-section evidence?
- Is executable memory backed by a named file, pagefile-backed section, or private allocation?
- Is a thread start address inside a known image VAD or an anonymous/private executable range?

## Cross-Platform API Translation

| Intent | Linux | Windows |
|---|---|---|
| Reserve/create anonymous range | `mmap(MAP_ANONYMOUS | MAP_PRIVATE)` or `brk` | `VirtualAlloc(MEM_RESERVE)` and/or `MEM_COMMIT` |
| Commit/touch private memory | often lazy until fault, with overcommit/memcg policy | `VirtualAlloc(MEM_COMMIT)`, still lazy resident until fault |
| Map a file | `mmap(fd, MAP_SHARED/MAP_PRIVATE)` | `CreateFileMapping` + `MapViewOfFile` |
| Map shared anonymous memory | `MAP_SHARED | MAP_ANONYMOUS`, POSIX shm, SysV shm, memfd/tmpfs | pagefile-backed section, named file mapping object |
| Change protection | `mprotect` | `VirtualProtect` / `NtProtectVirtualMemory` |
| Release mapping | `munmap` | `VirtualFree(MEM_RELEASE)` or `UnmapViewOfFile` |
| Discard/decommit/reset | `madvise`, `munmap`, mapping-specific behavior | `VirtualFree(MEM_DECOMMIT)`, `MEM_RESET`, `MEM_RESET_UNDO` |
| Query ranges | `/proc/<pid>/maps`, `smaps`, `pmap` | `VirtualQueryEx`, VMMap, `!address`, `!vad` |

## Security And Forensics Patterns

| Pattern | Linux evidence | Windows evidence | Interpretation |
|---|---|---|---|
| Private executable memory | anonymous `r-x`/`rwxp`, JIT names, memfd/deleted paths | MEM_PRIVATE RX/RWX VAD, write-to-execute transition | JIT, unpacking, shellcode, code cache, or legitimate runtime. |
| Modified mapped image | private dirty pages in file-backed executable mapping | image VAD with private/COW modified pages | Hotpatching, hooks, unpacking, instrumentation, or benign relocation/data changes depending on page. |
| Hidden/manual mapped module | executable mapping not in `link_map`, deleted/memfd path, PE/ELF headers in anonymous memory | PE-like bytes in private/mapped VAD absent from PEB loader lists and ETW | Manual map, reflective loader, unlinked module, packer, or custom loader. |
| Shared-section staging | shmem/memfd/tmpfs mapping in multiple processes | pagefile-backed or file-backed section mapped into multiple processes | IPC, shared cache, or injection/staging primitive. |
| Hollowing/image mismatch | `/proc` path and mapped bytes disagree, deleted/replaced inode issues | process image path, VAD image, PEB, ETW, and file bytes disagree | Process replacement or disk-memory mismatch. |
| W to X transition | `mprotect` audit/eBPF/perf trace plus maps change | `VirtualProtect`/ETW/Sysmon plus VAD/PTE change | JIT or payload activation. Need caller/context. |

The safe conclusion is always cross-view. A single RWX or RX-private mapping is a lead, not a verdict.

## Study Checklist

You understand this topic when you can answer these without notes:

1. Why can a VMA/VAD exist without a resident physical page?
2. Why are VMA/VAD permissions not always identical to current PTE permissions?
3. Why did modern Linux move VMA indexing to Maple Tree?
4. Which locks stabilize Linux VMA metadata, rmap traversal, and page-table updates?
5. How does Linux find a VMA during a page fault, and what happens after lookup?
6. What is a Windows section object, and how do control areas/subsections/prototype PTEs relate to mapped views?
7. What is the difference between Windows private, mapped, and image-backed VADs?
8. Why can clean file/image pages be discarded while private dirty pages need swap/pagefile-style backing?
9. What evidence proves a mapped executable page has become private through COW?
10. Why are Windows VAD field offsets not something to memorize across builds?
11. How does `VirtualQueryEx` differ from `!vad` and `!pte`?
12. What exact structures would you inspect for a suspicious executable region on Linux and Windows?

## Bottom Line

Linux VMAs and Windows VADs are the range-policy layer. They are the right first object when asking whether a virtual address range should exist, what its intended protection is, and what kind of backing should resolve faults. They are not resident pages, they are not the whole backing object, and they are not the final hardware enforcement state. The full mechanism is:

```text
API or loader intent
  -> VMA/VAD range policy
  -> backing object or private commit state
  -> PTE/prototype-PTE state
  -> PFN/folio physical-page metadata
  -> TLB/MMU enforcement
  -> observable tool views
```

Keep those layers separate and most VAD/VMA confusion becomes a solvable graph walk.
