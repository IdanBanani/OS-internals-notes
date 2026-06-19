# Memory, Filesystems, and Network Stack Deep Questions, Scored

Value Score: 89/100
Role: Cross-platform subsystem Q&A
Proof Level: Conceptual, read after platform labs

Date: 2026-05-15

Purpose: fill the remaining depth gap in the existing Linux and Windows internals materials. The broader question banks cover memory, file systems, and networking, but memory deserved more Windows detail, and file systems/networking needed deeper end-to-end coverage on both platforms.

Dense-term companion: [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) expands and routes terms such as page cache, VMA/VAD, PTE/PFN, TLB, COW, section object, VFS, DMA/IOMMU, IRP/MDL, ETW, and eBPF to their practical evidence paths and owner docs.

Journey companion: [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) maps the local Networking, Linux Concept, Windows Concept, Windows Forensic, and security Journey PDFs. Use the Networking Journey when the packet-flow or socket-state questions feel too terse, and use the forensic/security journeys when translating mechanisms into observable evidence.

Paging/residency companion: [Paging, residency, page lists, and shared memory](<../05-topic-notes/paging-residency-page-lists-and-shared-memory.md>) answers the specific trap questions around nonpageable versus non-swappable, DLL/file-backed pages, pagefile-backed shared memory, PFN/PTE relationships, demand-zero faults, Windows standby/free/zero lists, Linux reclaim lists, and stale-byte security boundaries.

Runtime allocation companion: [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>) answers the `malloc`/`new`/UCRT versus `HeapAlloc`/`HeapCreate`/`VirtualAlloc` questions, including `VirtualFree`, LFH, segment heap, SEH/C++ unwinding, and compiler/runtime fingerprints.

Windows kernel-memory companion: [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>) answers file-system cache, section objects, `MapViewOfFile`, pagefile-backed mappings, paged/nonpaged pool, `SeLockMemoryPrivilege`, loader address reuse, and KASLR follow-ups.

Score meaning:

| Score range | Meaning |
|---|---|
| 95-100 | Core model. Missing this breaks many other explanations. |
| 90-94 | High-value senior interview and debugging depth. |
| 85-89 | Important subsystem depth. |
| 80-84 | Practical depth for specialist roles. |

## Priority Index

| Score | Area | Question |
|---:|---|---|
| 100 | Memory | How does virtual memory translate from a user address to a physical page, and where do Linux and Windows keep policy versus hardware state? |
| 99 | Memory | How do Linux VMAs compare to Windows VADs, why do `/proc/<pid>/maps` and VMMap categories look different, and why is this not only ELF versus PE? |
| 99 | Memory | How do low-level memory structures form a graph: VMA/VAD range policy, trees, PTEs, physical-page metadata, page cache, section objects, and loader metadata? |
| 98 | Memory | How do anonymous, file-backed, image-backed, mapped, private, shared, and COW memory differ across Linux and Windows? |
| 97 | Memory | What happens on a page fault on Linux versus Windows? |
| 96 | Memory | How do Linux page cache and Windows Cache Manager/section objects connect file I/O with memory mappings? |
| 95 | Memory | How do allocation, commitment, overcommit, pagefile/swap, working sets, and reclaim differ? |
| 94 | Memory | Why do TLB invalidation and page-table synchronization matter on both OSes? |
| 93 | Memory | How do kernel allocators differ: Linux buddy/SLUB/vmalloc versus Windows pool/MDLs/special pool? |
| 92 | Memory | How should you triage suspicious executable memory in Linux and Windows processes? |
| 91 | Memory | How do DMA, pinned pages, IOMMU, and MDLs affect memory correctness and security? |
| 90 | Memory | How do cross-process memory access APIs map between Windows access rights and Linux ptrace/procfs/process_vm controls? |
| 89 | Memory | Which `mmap`, `mprotect`, `madvise`, and Windows memory flags matter most for security analysis? |
| 100 | Filesystems | Walk a Linux `openat/read/write/mmap/close` path and a Windows `CreateFile/ReadFile/WriteFile/MapViewOfFile/CloseHandle` path. |
| 99 | Filesystems | What are the core runtime objects in Linux VFS versus Windows file I/O? |
| 98 | Filesystems | Why are path resolution, namespaces, reparse points, symlinks, and mount points security-sensitive? |
| 97 | Filesystems | How do Linux page cache/writeback and Windows Cache Manager/lazy writer/file mappings differ? |
| 96 | Filesystems | How do Linux filesystem drivers compare with Windows filesystem drivers and minifilters? |
| 95 | Filesystems | How do file permissions and sharing semantics differ between Linux and Windows? |
| 94 | Filesystems | What is the relationship between regular files, devices, pseudo-filesystems, registry, and object namespaces? |
| 93 | Filesystems | How do direct I/O, memory-mapped I/O, buffering, oplocks/leases, and coherency work conceptually? |
| 92 | Filesystems | How do filesystem events and telemetry differ: inotify/fanotify/audit/eBPF versus USN journal/ETW/Procmon/minifilters? |
| 91 | Filesystems | What filesystem details matter for malware, persistence, and forensic analysis? |
| 100 | Network | Walk a packet receive path on Linux and Windows from NIC interrupt/DMA to userspace socket. |
| 99 | Network | How do Linux `sk_buff`/socket state compare with Windows Winsock/AFD/NET_BUFFER_LIST concepts? |
| 98 | Network | How do Linux netfilter/nftables/eBPF/XDP/tc compare with Windows WFP/NDIS/Defender Firewall? |
| 97 | Network | How do socket APIs map to kernel networking state on Linux and Windows? |
| 96 | Network | How do async networking and completion models differ: epoll/io_uring/NAPI versus overlapped I/O/IOCP/WFP/NDIS? |
| 95 | Network | How do network namespaces/cgroups compare with Windows compartments, filtering layers, sessions, and per-process telemetry? |
| 94 | Network | How do offloads, RSS, interrupt moderation, and multi-queue NICs affect debugging and packet visibility? |
| 93 | Network | How do DNS, proxy, TLS, and credential integration differ as malware/spyware and defender surfaces? |
| 92 | Network | How do you triage suspicious network activity cross-platform? |
| 91 | Network | What network stack internals matter for rootkits, EDR, and stealth? |

## Best Answers

### 100 - Memory: Address Translation And Policy

Both Linux and Windows ultimately rely on the same hardware model: a user virtual address is translated through page tables into a physical frame, and the CPU caches translations in the TLB. The hardware state is the page table entry: present, writable, executable/NX, user/supervisor, dirty/accessed, and physical frame information.

The OS policy lives above that. Linux stores virtual-address policy in `mm_struct` and VMAs: legal ranges, permissions, backing file, flags, and operations. Windows stores comparable range policy in VADs, section objects, views, protection state, and commit accounting. In both systems, good memory reasoning separates "is this address range legal and what should it mean?" from "does a PTE currently translate it?"

The hardware does not decide where a process's top-level page table lives. It only defines the register and table format: x86/x64 uses `CR3`; arm64 uses TTBR-style translation-table base registers. Privileged software must allocate physical pages for the root and lower-level tables, fill them with valid entries, then load the root register. Before paging is enabled, early boot code runs using physical/firmware-defined execution mode and builds a minimal bootstrap page table from physical pages reserved for the kernel.

Bootstrapping is a chicken-and-egg problem solved by staged allocators:

| Stage | What happens |
|---|---|
| Firmware/boot loader | Provides or passes a physical memory map and loads the kernel plus boot data into known physical ranges. |
| Early kernel | Uses simple reserved-memory/boot allocators, not the full VM system, to build initial kernel page tables. On x86 this means preparing aligned page-table pages, loading `CR3`, and enabling paging/long mode with the required control bits. |
| Kernel memory-manager init | Builds the real physical-page database/allocator, direct map, kernel mappings, and bookkeeping for future page-table pages. |
| First schedulable kernel context | Uses the initial kernel address space, not a user process address space created by `fork`/`CreateProcess`. |
| Later user processes | The kernel allocates a fresh address-space root from physical pages, initializes kernel/shared portions and empty user portions, maps the executable/stack/loader state, stores the root in process memory-management state, and loads it on context switch. |

Linux names this around `init_mm`, the kernel's initial page tables, and each user address space's `mm_struct->pgd`. The `pgd` pointer is a kernel virtual address for a page-table page; the hardware root loaded into `CR3` is the physical address derived from it, with architecture-specific tag bits where applicable. Kernel threads normally have no user `mm`; they borrow an active address space as needed, while the kernel half remains shared according to the architecture and KPTI policy.

Linux's chicken-and-egg answer is staged. The first top-level tables are created by architecture boot code using statically reserved or boot-allocated physical pages before the normal page allocator and ordinary processes exist. That early code fills enough mappings for the kernel to run and then loads the physical root into `CR3`. Later, after `memblock`, the buddy allocator, page metadata, and the MM subsystem exist, ordinary user address spaces are made by allocating an `mm_struct`, allocating a top-level `pgd` page through architecture helpers, initializing required kernel/shared entries, and storing the kernel pointer in `mm->pgd`. The physical CR3 value is derived from `mm->pgd` during context switch or PTI entry/exit; Linux normally does not store a raw user-visible physical PML4 address in a process object.

For Linux, the precise counting unit is the `mm_struct`, not "process" if that means PID, thread, or `task_struct`. Threads created with `CLONE_VM` share an `mm_struct` and therefore share the address-space root. `fork()` without `CLONE_VM` creates a separate `mm_struct` and separate root for the child. `execve()` can keep the same task/PID while replacing the old `mm` with a new address space. Kernel threads usually have `task->mm == NULL` and run with a borrowed `active_mm` or kernel memory context. A zombie or dying task can still be observable after the user address space has been released.

So the Linux version of "live address space" is: an `mm_struct` whose page-table hierarchy still exists and may be loaded again. It may be associated with sleeping, stopped, frozen, or runnable tasks, and it need not currently be loaded in any CPU's `CR3`. On x86 PTI/KPTI systems, one Linux memory context can also have related full-kernel and restricted-user page-table views, because user mode runs with most kernel mappings absent and kernel entry switches to the full kernel view.

Windows stores the address-space root in process state, classically visible as `_KPROCESS.DirectoryTableBase`/related fields, not in `_KTHREAD` as the owning concept. Threads (`_KTHREAD`/`_ETHREAD`) are scheduled execution contexts that belong to a process; when a thread from a different process runs, the scheduler/address-space switch path loads the root for that process. Modern Windows can also maintain separate user/kernel roots for KVA shadow and VBS-related designs, so debugger field names and counts vary by build, but the concept remains process address space first, thread execution second.

How many top-level tables exist? System-wide, many. The normal case is: one process that still owns an active address space has at least one top-level root page for that address space. "Active address space" here means the Memory Manager has not torn down the process's virtual-memory container: the process may be running, ready, waiting, or suspended, but its user/kernel mappings still exist and can be loaded again on a context switch. It does not mean the process is currently executing on a CPU.

Do not say "exactly one PML4 per process" because the process object and the hardware root are not the same lifetime or cardinality. Threads in the same process usually share the process root, so it is not one per thread. A terminating process object may still be referenced by handles after its address space is already in teardown or gone. Modern KVA-shadow systems can keep a restricted user root and a fuller kernel root variant for the same process. The kernel also has boot/system contexts that are not ordinary user processes. Per logical CPU at an instant, only one root is active in `CR3` for the currently executing context.

In classic x64, the same active PML4 translates both user and kernel virtual addresses; the VA bits select the user or kernel half, and the PTE permission bits decide whether the current privilege level may use the mapping. The per-process user half is different; the kernel half is normally consistent across processes and points into shared kernel mappings.

The CPU does not fetch `_KPROCESS.DirectoryTableBase` for every memory access. Windows stores the root there so the scheduler, process-attach paths, and KVA-shadow syscall/trap paths know what physical PML4/PML5 root to load into `CR3`. After `CR3` is loaded, the MMU walks from that active physical root. A debugger doing manual translation is imitating this: choose the target process root for user addresses, choose a full kernel root for kernel addresses, mask out non-address `CR3` bits such as PCID/flags where relevant, and then walk the paging hierarchy.

Live page-table pages are not ordinary pageable user data. "Page-table page" here means any page in the walkable paging hierarchy, not only the final PTE page. Be precise with x86 terminology: in x86 PAE mode, `CR3` names a page-directory-pointer table (PDPT); in x64 4-level paging, `CR3` names a page map level 4 table (PML4); with 5-level paging, `CR3` names a PML5. x64 still has a page-directory-pointer-table/PDPTE level below PML4, followed by page-directory pages and final PTE pages. If a paging-structure page is part of the active hierarchy that the MMU may walk from `CR3`/TTBR, that page must be resident in physical memory. The MMU cannot take a "page fault on the page table page" and ask the OS to swap in the structure it needs in order to translate the fault path. What can be swapped out is the data/code page described by a non-present PTE; the PTE then holds OS-defined swap/pagefile/prototype/transition state rather than a present PFN.

On Windows, other nonpaged or effectively pinned kernel state includes the PFN database, nonpaged pool objects, ready/running kernel stacks, per-processor scheduler/interrupt state, MDL-locked I/O or DMA buffers, large-page allocations, and kernel/driver code or data that can be touched at elevated IRQL. `_EPROCESS`/`_KPROCESS` should be treated as core process-control state, not pageable user memory, but that does not make every object reachable from an `_EPROCESS` pointer nonpageable. A mature dump answer asks what allocation/backing owns the specific target.

The System process (`PID 4`) directory table base is commonly used to translate kernel virtual addresses in memory forensics because it is stable and always available, but it is not the only root that can translate ordinary kernel VAs. Kernel addresses are normally mapped in the kernel half of every process address space. Use the target process root for target user addresses; use a kernel-mode root for kernel addresses. KVA shadow/KPTI means a restricted user root may not contain the full kernel map, so the practical distinction is kernel root versus user root, not "PID 4 versus all other processes."

Five-level x86-64 paging, often discussed as LA57 or 57-bit linear addresses, changes address-space geometry rather than creating a new security boundary. In 4-level mode, canonical addresses effectively use 48 significant bits: bits 63:48 must sign-extend bit 47. In 5-level mode, canonical addresses use 57 significant bits: bits 63:57 must sign-extend bit 56. That can give the OS more room for ASLR/KASLR, guard gaps, sparse reservations, sanitizers, and separated kernel regions, but only if the CPU, firmware/kernel configuration, OS policy, ABI, and allocator actually use the larger space. It also creates bug classes in code that assumes "valid x64 pointer" means 48-bit canonical, masks off the top 16 bits, hard-codes user/kernel split constants, compresses pointers too aggressively, or assumes a folded middle page-table level.

Kernels can still reclaim page-table memory in controlled ways. If a range is unmapped, a process exits, or an address-space subtree no longer has valid mappings, the kernel can tear down those page-table pages and return them to the physical allocator. That is reclamation of unused translation structures, not demand-paging a live page directory to disk. Windows and Linux differ in details, but both preserve the same invariant: hardware-walkable translation pages must be in RAM while they are reachable by the active or switchable address-space root.

Do not collapse "not running" into "dead":

| Process/address-space state | Page-table implication |
|---|---|
| Runnable but not currently scheduled | No CPU may currently have that process's root in `CR3`, but the process still has an address-space root that may be loaded on the next context switch. On x64, the live PML4/PML5 root page remains allocated in physical RAM, not on disk. |
| Sleeping, suspended, or swapped/trimming pressure | Ordinary working-set pages may be reclaimed or paged out, but the live translation hierarchy cannot be swapped out like user data. The scheduler can stop running the process; it cannot put the still-live PML4 on disk and expect the MMU to fault it back in. |
| `execve` or image replacement | Old user mappings and page-table subtrees are torn down or replaced as the address space is rebuilt; unused page-table pages can be freed. |
| Process exit with remaining references/zombie-style metadata | User mappings are torn down as part of exit/rundown, but small process/task metadata may remain for wait/reaping or handles. The full user address-space page-table hierarchy is not kept just because a PID/name is still observable. |
| Last address-space reference gone | Remaining page-table pages and backing references can be released to the kernel's physical allocator. |

Do not look for one universal "page permission bitset." The system has several bit families:

| Layer | Linux examples | Windows examples | Who consumes/enforces it |
|---|---|---|---|
| Range policy | VMA `vm_flags`: read/write/exec/shared, may-read/may-write/may-exec, grow-down, locked, I/O/PFNMAP, huge-page, don't-copy, don't-dump, soft-dirty style tracking. | VAD protection and type: private/mapped/image, reserve/commit, guard/noaccess, copy-on-write, section view, image/mapped backing, commit charge. | Kernel memory manager and fault path. This says what the range is allowed to become. |
| Hardware translation | PTE/PMD/etc. present/valid, PFN, writable, user/supervisor, NX/execute-disable or UXN/PXN, accessed/young, dirty, global, cache/memory type, huge/block mapping, architecture-specific software bits. | Hardware PTE bits plus Windows software PTE states for valid, demand-zero, transition, pagefile, prototype, COW, and protection encoding. | CPU MMU and TLB enforce the currently installed translation. |
| Physical page record | `struct page`/folio flags, refcount, mapcount, LRU/reclaim, dirty/writeback, locked, slab, swap-backed, page-cache state, pins. | PFN database state, reference/share counts, page-list state such as active/standby/modified/free/zeroed, PTE backpointer, working-set relationship. | Kernel reclaim, COW, migration, paging, DMA pinning, crash-dump and forensic paths. |
| Shared/backing metadata | `address_space`, inode/file, page cache, swap entries, anon_vma/rmap, VMA ops. | Section object, segment, control area, subsection, prototype PTEs, file object, pagefile/private commit. | Kernel backing-object logic; decides where page contents come from and who else can see them. |
| Cached enforcement | TLB entries, page-walk caches, I-cache/D-cache state. | Same hardware concepts. | CPU uses cached translations/instructions until invalidation/coherency rules are satisfied. |
| Lower translation | IOMMU page tables, KVM EPT/NPT or arm stage-2 tables. | DMA remapping, Hyper-V/VBS second-level translation. | Devices and hypervisors can enforce an additional mapping layer below guest/OS page tables. |

The separation exists because the kernel needs richer policy than hardware PTEs can express. A VMA/VAD can exist before any resident page exists; a single physical page can be mapped by many processes; a PTE can be invalid but still encode swap, transition, prototype, or demand-zero state; page-cache and section state must survive individual mappings; and physical-page lifetime/reclaim/pinning is not owned by one virtual address. Security bugs often appear when two layers disagree: VAD says `RX` but a PTE is writable, VMA says private but a shared backing object is still writable, page record says pinned while the VMA is torn down, or a hypervisor/IOMMU table allows access the guest OS thought impossible.

For Windows/x64, a valid PTE/PDE bitfield is security-critical because each bit changes either enforcement or Memory Manager interpretation. `Valid`, RW, owner/user, NX, PFN, large-page, global, accessed, dirty, cache policy, and Windows software bits such as COW/prototype/software-write are not trivia: they decide whether hardware translates, whether user mode can reach the page, whether stores or instruction fetches are allowed, which physical frame is touched, how much memory one entry maps, how TLBs retain it, and how faults/COW/section sharing are resolved. A malicious or buggy change can create writable code, executable data, privileged memory exposure, physical aliases, broken COW, stale TLB behavior, or misleading forensic views. Exact high-bit layout varies by CPU physical-address width and features, so "bits 48-62 reserved" is only a specific simplified case, not a universal modern rule.

Large and huge pages are not "normal pages but bigger"; they change where the page walk stops and what the TLB caches. In ordinary 4 KB x64 translation, the CPU walks `PML4 -> PDPT -> page directory -> page table -> PTE`, and the low 12 virtual-address bits are the offset inside the 4 KB page. With a 2 MB large page, the page-directory entry is a leaf: the PS/large-page bit is set, there is no final page-table page for that 2 MB range, and the low 21 virtual-address bits are the offset. With a 1 GB page, the PDPT entry is the leaf and the low 30 bits are the offset.

The TLB caches the final translation result with its page size. A 4 KB TLB entry covers one 4 KB page; a 2 MB large-page TLB entry covers the whole 2 MB range; a 1 GB entry covers the whole 1 GB range. On a TLB hit, the CPU does not walk the lower page-table levels at all. On a TLB miss, the hardware walk checks upper entries and stops as soon as it finds a valid large-page leaf, so a 2 MB mapping skips the final page-table page and a 1 GB mapping skips both page-directory and final page-table levels. Actual Intel/AMD cores may have separate or shared TLB structures for different page sizes, so do not assume identical entry counts; the stable concept is larger TLB reach and fewer page-walk memory references.

That has direct internals and security consequences:

| Consequence | Why it matters |
|---|---|
| Fewer page-table pages | One higher-level entry covers what would otherwise require hundreds of lower-level entries. This reduces page-table memory and page-walk cost. |
| Fewer TLB entries for large working sets | One cached translation covers 2 MB or 1 GB instead of 4 KB, increasing TLB reach for hot large memory regions. |
| Coarser permissions | RW/NX/user/cache/global bits apply to the whole large-page leaf. Fine-grained protection, COW, guard pages, or forensic attribution may require splitting the mapping or may be impossible for explicit huge-page mappings. |
| Larger corruption blast radius | Flipping RW/NX/PFN/user bits in a huge-page PMD/PDE affects megabytes or gigabytes, not one 4 KB page. |
| Alignment and physical-contiguity pressure | Large pages require aligned virtual and physical ranges. Explicit huge/large-page APIs can fail under fragmentation and can pin or reserve memory. |
| Different evidence | Tools may show a large-page or huge-page VMA/VAD/PTE state instead of a normal page-table page. If you inspect only final PTEs, you can miss that the translation stopped earlier. |

Splitting a large mapping back into 4 KB mappings is also a TLB correctness event. The OS must invalidate the old large-page translation before relying on new fine-grained 4 KB permissions; otherwise a CPU could keep using a stale 2 MB or 1 GB TLB entry while memory now contains smaller PTEs with different protections.

Linux and Windows expose different policy layers above the same hardware idea. Linux has explicit HugeTLB pages through `MAP_HUGETLB`, hugetlbfs, and SysV shared memory, and also Transparent Huge Pages (THP), where the kernel opportunistically backs anonymous or shmem/tmpfs ranges with huge mappings and can split/fallback when needed. Modern Linux also has multi-size THP, where some larger-than-base pages remain PTE-mapped rather than PMD-mapped. Windows large pages are explicit: `MEM_LARGE_PAGES` or `SEC_LARGE_PAGES`/`FILE_MAP_LARGE_PAGES`, require large-page alignment and privilege, are reserved and committed together, and are resident/nonpageable. Treat suspicious large executable mappings, large writable shared mappings, or unexpected locked resident regions as high-signal triage items, but not automatically malicious.

### 99 - Memory: VMAs Versus VADs

Linux VMAs and Windows VADs are the closest memory-management analogy because both describe ranges in a process address space. They answer questions like: is this range valid, what permissions are allowed, is it private or backed by something, and what fault handler/backing object should resolve missing pages?

The differences matter. Linux analysis often starts with `/proc/<pid>/maps` and VMA flags/backing files. Windows analysis starts with VADs plus whether a region is private, mapped, or image-backed, and whether it is reserved, committed, guarded, or protected. VADs also tie naturally into section objects and image mappings, which are central to Windows loader and injection triage.

VMMap-style categories are not explained mostly by ELF versus PE. ELF and PE matter for loader-created image regions: executable segments, shared libraries/DLLs, relocations, imports, TLS, and copy-on-write image pages. The rest of the process map comes from allocator arenas, heaps, stacks, guard pages, anonymous mappings, shared memory, mapped data files, JIT code, memfd/deleted mappings, device mappings, runtime metadata such as vDSO/vvar or PEB/TEB/KUSER_SHARED_DATA, and reservation/commit policy. A strong answer separates binary-loader format from memory-manager policy and allocator behavior.

### 99 - Memory: Structure Graph Beneath VMAs And VADs

The useful memory model has layers. The range-policy layer says which virtual address ranges are valid and what they are supposed to mean. On Linux this is `mm_struct` plus `vm_area_struct` entries indexed by the current kernel's VMA data structure, now Maple Tree in modern kernels. On Windows this is the process VAD tree. That layer is different from page tables, which are the hardware-facing translation state.

Below range policy, resident pages are described by physical-page metadata: Linux `struct page`/folios, page-cache or anonymous state, map counts, LRU/reclaim state, and pins; Windows PFN database entries, page lists, share counts, working-set state, and modified/standby state. Backing objects are another layer: Linux `address_space`, inode/file, page cache, swap, and VMA operations; Windows section objects, control areas, subsections, segments, file objects, image sections, and pagefile/private commit. Loader metadata is yet another view: ELF runtime linker data on Linux and PEB loader lists on Windows. A senior answer keeps these layers separate and then explains how a fault or mapping operation moves between them.

### 98 - Memory: Backing Types And COW

Linux commonly distinguishes anonymous memory, file-backed mappings, shared mappings, private mappings, and COW state. Anonymous memory backs heap, stack, and private allocations. File-backed memory points to page-cache pages. A private file mapping can initially share file-backed cache pages and become anonymous after a write fault.

Windows uses similar hardware ideas but different labels. Private memory usually comes from `VirtualAlloc` and commit charge. Mapped memory comes from section views, often created by file mappings. Image-backed memory comes from PE image sections and carries loader semantics. COW occurs for image and mapped pages when a process modifies a shared page. For malware analysis, private executable memory, modified image pages, and mapped sections between unrelated processes are high-value clues.

### 97 - Memory: Page Fault Flow

On Linux, a page fault enters the architecture fault handler, locates the current task's `mm_struct`, finds the VMA, checks permissions, and resolves the fault as anonymous, file-backed, swapped, COW, stack growth, or invalid. The kernel installs or updates PTEs and may send `SIGSEGV` or `SIGBUS` if the access cannot be satisfied.

On Windows, the memory manager handles the fault by consulting VADs, PTE/prototype PTE state, section objects, pagefile or mapped-file backing, and working-set state. It may demand-zero a page, read from a mapped file/image, resolve COW, page in from the pagefile, or raise an access violation/in-page error. The conceptual model is the same: hardware fault -> range policy -> backing object -> PTE update or exception.

### 96 - Memory: File Cache And Mappings

Linux page cache unifies regular file I/O and file-backed mappings. A file page read through `read` and the same page mapped through `mmap` are often the same cached physical page. Dirty pages are later written back according to filesystem and writeback policy.

Windows splits the roles across the Cache Manager, Memory Manager, and section objects. Cached file I/O and mapped file views interact through shared cache maps and section/control-area-like state. Image sections are special because they map executable PE images with image semantics. The important transition for a Linux reader is that Windows section objects are the bridge between file objects, mapped views, image loading, and shared memory.

The Windows flow is: `CreateFile` opens a file object; `CreateFileMapping`/`NtCreateSection` creates a section or file mapping object with maximum protection and optional image semantics; `MapViewOfFile`/`NtMapViewOfSection` maps a view into a process; the VAD records that view; page faults later instantiate pages through section/prototype-PTE, Cache Manager, image, pagefile, or COW state. The original file handle can be closed while the section/view keeps backing state alive.

Data-file mappings and PE image mappings must not be collapsed. A data-file mapping views file bytes as data and shared writable views can dirty cached file data. A PE image section is image-aware: PE headers and sections shape alignment/protection, clean image pages can be shared, writes usually create private COW pages, and user-mode loader work supplies imports, API-set resolution, TLS callbacks, `DllMain`, and PEB loader-list evidence. Therefore "mapped" can mean ordinary file data, pagefile-backed shared memory, or an image section, and each has different security consequences.

### 95 - Memory: Commit, Overcommit, Swap, Working Sets

Linux can overcommit memory depending on policy. A successful allocation or mapping does not always mean physical memory or swap is reserved immediately; faults and reclaim decide later. Linux reclaim balances anonymous memory, page cache, swap, dirty writeback, and memcg pressure.

For Linux, separate four views:

| View | Meaning |
|---|---|
| Virtual size / VMA coverage | Address ranges exist in the process address space. They may come from the loader, `brk`, `mmap`, stacks, shared memory, or file mappings. |
| Allocator state | `malloc` may return memory from an existing arena, extend the `brk` heap, or use anonymous `mmap` for larger regions. This is user-space bookkeeping layered over kernel VMAs. |
| Commit-style accounting | Anonymous private memory may be charged or permitted according to overcommit policy, `MAP_NORESERVE`, memcg limits, and mapping type. This is not a simple "RAM was allocated" statement. |
| Residency | RSS/working-set-like views show pages currently in RAM. Untouched, swapped-out, reclaimed, or clean file-backed pages may not be resident. |

This is why a Linux process can call `malloc`, receive a pointer, and still show little RSS growth until it touches pages. A large anonymous `mmap` can occupy virtual address space without every page being physically present. A file-backed mapping can be huge but mostly nonresident because clean pages can be faulted from the file as needed.

Windows makes commitment a first-class accounting concept. `VirtualAlloc` can reserve address space without commit, and commit consumes a system-wide commitment limit backed by RAM plus pagefile capacity. Windows also manages process working sets: the resident pages currently assigned to a process. Reclaim trims working sets and pages data to the pagefile or mapped files. This is why Windows tooling often talks about reserved, committed, private bytes, working set, and shareable pages.

Strong cross-platform answer: reserved/mapped address space, committed/accounted backing, and resident physical memory are separate layers. Windows exposes reserve and commit explicitly through `VirtualAlloc`; Linux exposes mappings and relies heavily on lazy faulting plus overcommit/accounting policy. Both systems can have memory that is valid but not resident.

### 94 - Memory: TLB And Synchronization

Both OSes must maintain coherence between page tables and CPU TLBs. Changing a PTE does not automatically invalidate cached translations on all CPUs. If permissions or physical mappings change, stale TLB entries can preserve old access behavior.

Linux and Windows both perform local invalidations and cross-CPU shootdowns when needed. The exact implementation differs, but the reasoning is universal: page-table update, memory ordering, and TLB invalidation are one correctness story. This matters for security because stale writable/executable mappings or stale physical aliases can defeat intended isolation.

### 93 - Memory: Kernel Allocators

Linux starts from the buddy allocator for physical pages. SLUB/slab allocators build object caches for small kernel allocations, `kmalloc` allocates slab-backed physically contiguous memory within limits, and `vmalloc` provides virtually contiguous memory backed by non-contiguous pages. GFP flags encode context and reclaim/sleep constraints.

Windows kernel allocations commonly use pool allocation APIs and pool tags for ownership/debugging. Nonpaged memory is needed when code may run at IRQLs where paging is impossible; paged memory can be reclaimed under appropriate conditions. MDLs describe locked physical pages for I/O. Driver Verifier and special pool help catch overruns, UAF, and bad IRQL usage. For vulnerability analysis, both OSes require allocator, object lifetime, and reuse reasoning.

Do not mix user allocator behavior with kernel allocator behavior. In user mode, Linux `malloc` is allocator metadata over `brk` and anonymous `mmap`, while Windows process heaps are allocator metadata over VM manager reservation/commit. In kernel mode, Linux allocation choice is constrained by GFP flags, sleepability, reclaim, zones, slab cache type, `vmalloc`, per-CPU state, and interrupt context. Windows allocation choice is constrained by paged versus nonpaged memory, pool tags/types, MDLs, IRQL, pageable-code rules, and verifier settings. The security question changes accordingly: user maps explain process memory evidence; kernel allocations explain object lifetime, context legality, UAF/reuse, and whether the code could legally fault or block.

### 92 - Memory: Executable Memory Triage

On Linux, inspect `/proc/<pid>/maps`, `smaps`, deleted mappings, anonymous executable regions, memfd-backed executable mappings, JIT regions, modified shared-library pages, and dynamic linker state. A region that is `rwxp`, anonymous executable, deleted-file-backed, or inconsistent with expected modules deserves attention.

On Windows, inspect VADs, VMMap/`!address`, PEB loader lists, image-load ETW, thread starts, section mappings, and memory protections. Private RX/RWX memory, image-like memory missing from loader lists, executable mapped sections shared between unrelated processes, or modified image pages can indicate packing, injection, JIT, or manual mapping. The conclusion depends on context and expected runtime behavior.

DLLs and shared libraries are not automatically shared in the simplistic sense. Clean text/image pages mapped from the same backing file or image section are often physically shared, but writable data, TLS, relocation-touched pages, hooks, inline patches, private dirty COW pages, and manually mapped DLL-shaped memory are process-private. Shared also does not mean resident: the mapping can exist while the physical page is not in a working set/RSS yet.

If a process overwrites a writable page inside a normally loaded DLL or shared object, the effect is usually local to that process. Windows image writes normally create private COW image pages; Linux shared-library writable segments are normally private mappings as well. Cross-process writes affect the target process's copy, not every process using the module. Old glibc `__malloc_hook` and `__free_hook` overwrites followed this model: the hook variables were in libc's writable data for the exploited process, not one globally writable libc page shared by the whole system.

The security distinction is "shareable", "currently shared", and "shared writable." Shareable means the range has a backing object that another process could map if it has authority. Currently shared means two PTEs presently point at the same physical page. Shared writable means one process can change data another process later observes, which is the boundary-sensitive case.

Control comes from the backing object and authority path, not from any arbitrary process. On Linux, file permissions, fds, `shm_open`/SysV shm ownership, `memfd` fd possession, namespaces, capabilities, and LSM policy decide who can map or write. On Windows, file mapping or section object DACLs, maximum section protection, handle granted access, inheritance, duplication, and Object Manager namespaces decide who can map or write. A process normally cannot force another process's private heap, stack, or COW page to become shared; it needs a shared object, a suitable fd/handle, debugger/cross-process authority, or kernel/driver authority.

### 91 - Memory: DMA, Pins, IOMMU, MDLs

DMA lets devices access memory without CPU copying. Linux represents long-term page access through pinned pages and DMA mapping APIs; Windows commonly uses MDLs to describe locked pages for I/O. In both systems, pinned/locked pages constrain reclaim, migration, COW, and paging.

The IOMMU restricts device-visible physical memory and prevents arbitrary device bus mastering. This is a security boundary: without DMA remapping, a malicious or buggy device/driver can corrupt or read memory outside its intended buffers. Memory management is therefore not only CPU page tables; device translation and page lifetime matter too.

### 90 - Memory: Cross-Process Access Rights

Windows cross-process memory access starts with a process handle. The handle is not just a pointer-like token; it carries granted access rights. `ReadProcessMemory` needs `PROCESS_VM_READ`. `WriteProcessMemory` needs `PROCESS_VM_WRITE` and `PROCESS_VM_OPERATION`. `VirtualAllocEx` and `VirtualProtectEx` need `PROCESS_VM_OPERATION`. Remote thread, handle duplication, query, suspend/resume, and terminate operations use separate rights such as `PROCESS_CREATE_THREAD`, `PROCESS_DUP_HANDLE`, query rights, `PROCESS_SUSPEND_RESUME`, and `PROCESS_TERMINATE`.

Linux has no exact `PROCESS_VM_READ` bit. The closest explicit copy APIs are `process_vm_readv` and `process_vm_writev`, but permission is checked through ptrace-style rules: credentials, dumpable state, user namespaces, `CAP_SYS_PTRACE`, Yama/LSM policy, and procfs visibility can all matter. `ptrace` and `/proc/<pid>/mem` are alternative interfaces into the same broad authority problem. A pid or pidfd is therefore not the same as a Windows process handle with memory rights.

The cross-platform answer is: first identify the authority artifact, then the range policy. On Windows, look for handle opens and granted access masks. On Linux, look for ptrace relationships, procfs access, capabilities, namespaces, and LSM decisions. In both systems, the memory copy still depends on the target range being valid and accessible according to VMA/VAD and PTE state.

### 89 - Memory: Security-Relevant Memory Flags

For `mmap`, the core Linux flags are protections and sharing semantics. `PROT_READ`, `PROT_WRITE`, `PROT_EXEC`, and `PROT_NONE` map conceptually to Windows `PAGE_READONLY`, `PAGE_READWRITE`, `PAGE_EXECUTE_READ`, `PAGE_EXECUTE_READWRITE`, and `PAGE_NOACCESS`. `MAP_PRIVATE` means copy-on-write; `MAP_SHARED` means updates can be visible through the shared backing object; `MAP_ANONYMOUS` creates zero-filled non-file-backed memory; `MAP_FIXED` forces address placement and can be dangerous; `MAP_FIXED_NOREPLACE` avoids clobbering an existing mapping; `MAP_NORESERVE`, `MAP_POPULATE`, `MAP_LOCKED`, `MAP_HUGETLB`, and `MAP_GROWSDOWN` all affect commitment, fault timing, residency, page size, or stack-like growth.

Windows spreads the same ideas across multiple knobs. `VirtualAlloc` and `VirtualAllocEx` use allocation flags such as `MEM_RESERVE`, `MEM_COMMIT`, `MEM_RESET`, `MEM_TOP_DOWN`, and `MEM_LARGE_PAGES`. `VirtualProtect` and `VirtualProtectEx` use page protections such as `PAGE_READWRITE`, `PAGE_EXECUTE_READ`, `PAGE_EXECUTE_READWRITE`, `PAGE_NOACCESS`, `PAGE_GUARD`, and CFG-related target flags. File and section views use `CreateFileMapping`, `MapViewOfFile`, and access flags such as `FILE_MAP_READ`, `FILE_MAP_WRITE`, `FILE_MAP_COPY`, and `FILE_MAP_EXECUTE`.

For `madvise`, do not force a one-to-one Windows translation. `MADV_WILLNEED` is roughly analogous to prefetching with `PrefetchVirtualMemory`; `MADV_DONTNEED` and `MADV_FREE` resemble discard/reset style APIs such as `DiscardVirtualMemory` or `MEM_RESET`; `MADV_HUGEPAGE`/`MADV_NOHUGEPAGE` belong near huge-page policy; fork and dump advice values often have no direct Windows twin. The security habit is to ask what the flag changes: permissions, COW, sharing, residency, dump visibility, fault timing, or backing-object behavior.

Defensive triage should treat certain combinations as high-signal rather than inherently malicious: anonymous executable memory, `RWX`, `RW -> RX` transitions, executable `memfd` or deleted mappings, executable shared mappings, private dirty pages inside library/DLL image ranges, Windows executable pagefile-backed sections, `VirtualAllocEx`/`WriteProcessMemory`/`VirtualProtectEx` chains, and unusual guard/noaccess/large-page/dump-suppression behavior. The answer must still explain backing object, authority, expected runtime behavior, and actual control flow.

### 100 - Filesystems: End-To-End File Path

On Linux, `openat` resolves a pathname through the VFS using a directory fd, mount namespace, dentries, inodes, symlinks, and filesystem operations. It checks permissions through credentials, mode bits, ACLs, capabilities, and LSM hooks, then installs a `struct file` in the fd table. `read` and `write` use that `struct file`, usually interact with the page cache, and may reach filesystem and block-layer code. `mmap` creates VMAs backed by the file's address-space/page cache. `close` drops the fd reference.

On Windows, `CreateFile` normalizes a Win32 path into an NT object path and opens a file/device through the Object Manager and I/O manager. The returned handle refers to a `FILE_OBJECT` with granted access and share state. `ReadFile`/`WriteFile` issue I/O through the file-system stack and filters; `CreateFileMapping`/`MapViewOfFile` create section views; `CloseHandle` drops the handle reference. The core difference is Linux fd/VFS/page-cache flow versus Windows handle/FILE_OBJECT/IRP/cache-manager/section flow.

### 99 - Filesystems: Runtime Objects

Linux runtime filesystem objects include `struct file` for an open file description, dentries for name-cache entries, inodes for filesystem objects, superblocks for mounted filesystems, address_space/page cache for file data, and file/filesystem operation tables. The fd is just a per-process integer pointing toward this object graph.

Windows runtime objects include handles, `FILE_OBJECT`, device objects, driver objects, IRPs, file-system driver state, cache-map state, and section objects for mapped files/images. The handle is the authority-bearing entry point. The Windows file path also crosses the Object Manager namespace before reaching a filesystem device.

### 98 - Filesystems: Path Resolution Security

Linux path resolution is affected by root/current directory, mount namespace, bind mounts, symlinks, hard links, procfs magic links, overlayfs layers, and racing renames. Security bugs often come from checking one path and opening another, or from resolving paths with more privilege than intended. `openat`/`openat2`-style constraints help anchor resolution.

Windows path resolution has Win32 normalization, NT object paths, device symbolic links, reparse points, junctions, symlinks, DOS device names, short names, and registry/object namespace interactions. Security bugs appear when code trusts a normalized-looking string but the actual opened object is different. On both OSes, robust code checks the object actually opened and uses safe resolution constraints.

### 97 - Filesystems: Cache And Writeback

Linux page cache stores file data pages used by both buffered I/O and file-backed `mmap`. Writes dirty cache pages; writeback later sends data to the filesystem/block layer. `fsync`, barriers, journaling, and filesystem policy determine durability.

Windows Cache Manager performs analogous caching for file I/O and cooperates with the Memory Manager for mapped files and sections. Lazy writer behavior, mapped views, image sections, and file-system cache maps determine when data reaches storage. The concepts are similar, but Windows analysis often sees Cache Manager plus section object behavior, while Linux analysis sees page cache plus address_space/writeback.

### 96 - Filesystems: Drivers And Minifilters

Linux filesystem drivers plug into VFS through superblock, inode, dentry, address-space, and file operations. Other pseudo-filesystems such as procfs, sysfs, debugfs, and tracefs expose kernel state through filesystem-like interfaces. Filesystem modules are one part of a broader VFS model.

Windows file systems are drivers in a layered I/O stack. File-system minifilters attach at altitudes and can inspect or modify file operations. Antivirus, EDR, encryption, backup, and DLP tools often use minifilters. This makes Windows file I/O analysis a stack question: which filters saw the IRP, which one changed behavior, and what file object/stream/context was involved?

### 95 - Filesystems: Permissions And Sharing

Linux file authorization usually starts with credentials, mode bits, ACLs, capabilities, mount flags, and LSM policy. Once an fd is open, later operations use the open file description and mode. Advisory locks exist, but ordinary opens do not usually enforce mandatory share denial in the Windows sense.

Windows file opens include both access checks and share-mode checks. A caller asks for desired access and declares which future sharing it permits. Another open can fail because sharing rules conflict even if the DACL allows access. This is a major Linux-to-Windows transition point: ACL permission and sharing compatibility are separate questions.

### 94 - Filesystems: Files, Devices, Pseudo-State, Registry

Linux exposes devices and kernel state through `/dev`, `/proc`, `/sys`, debugfs, tracefs, cgroups, and normal filesystems. This makes shell tools powerful because many resources are file-shaped even when they are not disk files.

Windows uses files for storage but also has the Object Manager namespace and the registry. Devices appear under NT object paths and symbolic links; registry keys are securable configuration objects; named events/sections/mutexes live in object namespaces. The closest Windows equivalent to `/proc` is not one filesystem but a combination of APIs, ETW, WMI, handles, debugger extensions, and object namespaces.

### 93 - Filesystems: Direct I/O, mmap, Oplocks, Coherency

Linux direct I/O attempts to bypass the page cache, but alignment, filesystem support, and coherency with cached mappings must be handled carefully. Memory-mapped I/O uses page faults and page cache state, while buffered I/O uses read/write paths through cache. Leases and locks can coordinate access but have specific semantics.

Windows has cached and noncached I/O, mapped views, section objects, oplocks, byte-range locks, and share modes. Oplocks let clients cache while allowing coordinated invalidation when another opener conflicts. Coherency is not "one file equals one buffer"; it is a contract between cache manager, memory manager, filesystem, and open handles.

### 92 - Filesystems: Events And Telemetry

Linux options include inotify/fanotify for filesystem events, auditd for policy/security events, eBPF/ftrace for deeper kernel tracing, and filesystem-specific logs. `/proc` and `/sys` provide live state. Each tool has visibility limits and overhead tradeoffs.

Windows options include ETW file I/O providers, Procmon, Sysmon, USN journal, minifilter telemetry, handle inspection, and Event Log. Procmon is especially useful because it resolves many file/registry operations into semantic events. Strong triage correlates high-level events with handles, object paths, file IDs, signatures, and memory mappings.

### 91 - Filesystems: Malware And Forensics

On Linux, filesystem-relevant artifacts include modified service units, cron entries, shell profiles, SSH keys, preload files, writable library paths, deleted-but-mapped executables, memfd execution, suspicious `/proc` inconsistencies, and kernel module or BPF artifacts.

On Windows, artifacts include services, scheduled tasks, Run keys, COM hijacks, IFEO, DLL side-loading paths, ADS in some cases, prefetch/amcache/shimcache-style evidence, USN journal, MFT metadata, mapped image mismatch, and unsigned modules. Across both systems, compare disk, memory, startup configuration, and telemetry because malware often makes one view lie.

### 100 - Network: Receive Path

On Linux, a NIC DMA-writes packet data into buffers prepared by the driver. Interrupts or NAPI polling notify the kernel. The driver builds `sk_buff` objects and passes packets through the network stack: XDP/tc/netfilter hooks where applicable, protocol processing, routing, socket lookup, receive queue insertion, and wakeup of a blocked reader or readiness notification through poll/epoll/io_uring.

On Windows, the NIC and miniport driver use NDIS data structures such as NET_BUFFER/NET_BUFFER_LIST conceptually, with interrupts/DPCs and receive indication up the stack. WFP callouts can classify/filter at multiple layers. AFD/TCPIP/Winsock-facing state eventually makes data available to user-mode sockets through blocking, overlapped I/O, IOCP, or event mechanisms. Both paths are DMA -> driver -> packet object -> protocol stack -> socket -> wakeup/completion.

### 99 - Network: Packet And Socket Objects

Linux `sk_buff` is the central packet buffer metadata object. Sockets have kernel `sock` state, protocol-specific control blocks, receive/send queues, timers, and namespace/cgroup/security context. User fd state points to a socket file object, but the networking stack state is below VFS.

Windows uses Winsock in user mode, AFD as a kernel interface layer at a high level, TCP/IP drivers, NDIS packet abstractions, and WFP classification state. NET_BUFFER_LIST is a useful conceptual counterpart to packet-buffer metadata, though not a one-to-one `sk_buff` clone. The right analogy is packet metadata plus protocol/socket state, not exact structure matching.

### 98 - Network: Filtering Frameworks

Linux filtering may happen through nftables/netfilter hooks, tc, XDP/eBPF, cgroup hooks, LSM/BPF hooks, and socket-level controls. XDP can run very early near driver receive paths; tc and netfilter operate at later layers. eBPF provides programmable observability and policy with verifier constraints.

Windows filtering commonly uses WFP for layered network policy and NDIS filters closer to adapter paths. Defender Firewall and many EDR products build on WFP. The conceptual mapping is hook layer, packet/flow metadata, policy decision, and action. The implementation vocabulary differs, but both systems support packet filtering, connection policy, telemetry, and security products in the network path.

### 97 - Network: Socket APIs To Kernel State

On Linux, sockets are file descriptors, so `socket`, `bind`, `listen`, `accept`, `connect`, `send`, and `recv` operate through fd-backed socket state. Readiness is exposed through `poll`/`select`/`epoll` and newer `io_uring` operations. `select()` is still useful for small portable tools and for understanding readiness, but modern scalable services usually prefer `epoll` or an `io_uring` design because `select()` has fixed bitmap and O(n) scanning constraints. Credentials, namespaces, cgroups, LSMs, and netfilter can affect behavior.

On Windows, Winsock sockets are not plain NT file handles in the Unix sense, even though they integrate with handle-like waiting and I/O models. Winsock calls reach provider/AFD/TCPIP layers and can use blocking, nonblocking, overlapped, event, or IOCP patterns. The important transition is from fd readiness to Windows completion and wait models.

### 96 - Network: Async And Completion

Linux historically centers scalable network readiness around epoll: tell me when this fd can make progress. NAPI reduces interrupt overhead in receive paths, and io_uring can submit/complete socket operations through shared rings. The model often remains fd/readiness oriented even when optimized.

Windows heavily uses overlapped I/O and IOCP: issue operations and receive completions. This completion model scales across files, sockets, pipes, and devices. WFP/NDIS operate in kernel network paths, while user-mode code may see completion packets rather than readiness bits. This changes how you debug stalls: was the operation issued, did the kernel complete it, did the completion reach the port, and is a worker consuming it?

### 95 - Network: Isolation And Attribution

Linux network namespaces create separate network stacks with their own interfaces, routing tables, firewall state, and sockets. Cgroups can help attribute or control traffic, and eBPF/cgroup hooks can enforce policy. Container networking depends heavily on namespaces, veth pairs, bridges, NAT, and firewall rules.

Windows has compartments, interfaces, firewall profiles/rules, WFP layers, AppContainer capability policy, service SIDs, and per-process telemetry rather than Linux-style network namespaces as the default mental model. Attribution often comes from ETW, WFP, Sysmon, and APIs that map sockets/connections to processes. The deep point is isolation of network view versus attribution of traffic owner.

### 94 - Network: Offloads And Hardware Scaling

Modern NICs do checksum offload, segmentation offload, receive-side scaling, interrupt moderation, multi-queue receive/transmit, and sometimes timestamping or filtering. Linux and Windows both use these hardware features through different driver frameworks.

These features can confuse debugging. Packet captures may show checksums that look wrong before hardware fills them. Large segments may be split by hardware later. RSS means packets for one system are handled across queues/CPUs. Interrupt moderation changes latency and event timing. A strong answer accounts for hardware offload before blaming the OS stack.

### 93 - Network: DNS, Proxy, TLS, Credentials

Linux applications often use resolver libraries, `/etc/resolv.conf` or systemd-resolved, environment proxy variables, NSS, Kerberos/GSSAPI, browser profiles, and keyrings. Windows applications may use WinHTTP/WinINet proxy settings, DNS Client behavior, SSPI, Credential Manager, DPAPI, browser stores, and enterprise policy.

For malware and spyware, these are high-value because they carry command-and-control, credentials, session tokens, and enterprise routing policy. For defenders, DNS telemetry, proxy logs, TLS inspection metadata where lawful/available, process attribution, and credential-store access are key. Network behavior is not only packets; it is also name resolution, proxy selection, authentication, and secret storage.

### 92 - Network: Triage Workflow

Cross-platform network triage starts with process identity, socket/connection list, destination, protocol, DNS history, proxy path, TLS/server identity, bytes/timing, parent process, loaded modules, and persistence. Then correlate with packet capture, host telemetry, firewall/WFP/netfilter logs, and memory/module state.

On Linux use `ss`, `/proc/net`, lsof, audit/eBPF, conntrack, firewall logs, and packet capture. On Windows use ETW, Sysmon network events, GetExtendedTcpTable/netstat-style views, WFP/firewall logs, Procmon, DNS Client logs, and packet capture. Suspicious signals include trusted processes with unusual modules, DNS-only channels, rare ports, domain-generation patterns, and process/network attribution mismatches.

### 91 - Network: Rootkits, EDR, Stealth

Linux stealth may target `/proc/net`, netfilter hooks, eBPF programs, kernel modules, packet capture blind spots, or injected network daemons. EDR-like tools may use eBPF, audit, netfilter, or kernel modules for visibility. Cross-view checks compare `/proc`, packet capture, firewall state, BPF program lists, and memory.

Windows stealth and EDR commonly involve WFP callouts, NDIS filters, ETW providers, injected user-mode network clients, service-host abuse, or driver-based filtering. Because supported filtering points are used by both defenders and attackers, ownership, signing, policy, telemetry consistency, and memory forensics matter. The right question is not "is there a hook?" but "who installed this filtering/visibility point, what layer is it at, and do independent views agree?"

## Remaining Gaps After This File

| Gap | Why it remains |
|---|---|
| Filesystem-specific implementation details such as ext4, XFS, Btrfs, NTFS, and ReFS internals | These require separate filesystem-specific notes. This file focuses on OS-level VFS/I/O/cache concepts. |
| TCP congestion control, retransmission internals, and deep protocol tuning | Important for network specialists, but beyond OS-internals transition scope. |
| Hands-on lab commands | This file is conceptual. A separate lab file should map each answer to commands and tools on Linux and Windows. |
| Version-specific Windows internals and private fields | These vary by build and should be studied through symbols/WinDbg on the target OS version. |
