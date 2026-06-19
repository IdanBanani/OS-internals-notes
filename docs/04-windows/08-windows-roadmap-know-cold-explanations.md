# Windows Roadmap Know-Cold Explanations

Value Score: 84/100
Role: Windows checklist explanation owner
Proof Level: Conceptual

Date: 2026-05-16

Purpose: expand the mechanism checkpoints in [Windows internals long-term mastery roadmap](<01-windows-long-term-mastery-roadmap.md>). The roadmap gives the study path; this file is the explanation layer. Use it when a checklist item feels like vocabulary rather than a model you can reason from.

## Module 1 - Architecture, Tools, And Native API Path

### User Mode Vs Kernel Mode

User mode is where normal application code runs. It cannot directly execute privileged CPU instructions, rewrite kernel page tables, access arbitrary physical memory, program devices, or trust user pointers as kernel pointers. Kernel mode is where the Windows kernel, executive subsystems, and drivers run with privileged CPU authority.

The important point is not "kernel mode is powerful." The important point is that every user-to-kernel transition is a trust-boundary crossing. A kernel service or driver must validate handles, object access, buffer lengths, pointer provenance, caller mode, IRQL, and object lifetime before using caller-controlled state.

Linux analogy: ring 3 versus ring 0 is the same hardware boundary. Windows just exposes it through Win32/Native APIs, Object Manager handles, IRPs, and drivers rather than mostly through POSIX syscalls and file descriptors.

### Win32 API Vs Native API Vs Syscall

Win32 is the documented compatibility API most applications target: `CreateProcessW`, `CreateFileW`, `VirtualAlloc`, `ReadFile`, `RegOpenKeyExW`, and similar calls. Many Win32 APIs do meaningful user-mode work before reaching the kernel: path normalization, parameter conversion, side-by-side policy, loader policy, COM/RPC mediation, or compatibility behavior.

The Native API is the lower-level `ntdll` interface, usually named `Nt*` or `Zw*`: `NtCreateUserProcess`, `NtCreateFile`, `NtAllocateVirtualMemory`, `NtCreateSection`, `NtMapViewOfSection`. It exposes object attributes, handles, sections, and NTSTATUS-style semantics more directly, but it is not the stable public contract for ordinary applications.

The syscall is the final CPU transition into kernel service dispatch. Syscall numbers and stubs are build-specific implementation details. A mature reversing answer distinguishes "the malware called `NtAllocateVirtualMemory`" from "this exact syscall number means allocation on every Windows build."

### `kernel32`, `kernelbase`, And `ntdll`

`kernel32.dll` is the traditional Win32 DLL many imports name. Modern Windows often forwards substantial implementation to `kernelbase.dll`, where common Win32 logic lives. `ntdll.dll` contains Native API stubs, user-mode loader code, exception dispatch glue, heap/runtime support, and the syscall transition stubs.

For reversing, import location does not prove kernel behavior by itself. A call may start in `kernel32`, pass through `kernelbase`, enter `ntdll`, and only then cross to the kernel. Some behavior never crosses the kernel directly because it is loader/runtime bookkeeping or calls another subsystem.

### System Service Dispatch

At a conceptual level, a user-mode syscall stub loads a service number and arguments according to the architecture ABI, executes the syscall instruction, and enters the kernel's system-service dispatcher. The kernel validates the transition state, locates the service implementation, probes/captures user arguments where needed, and returns status to user mode.

Do not overfit to SSDT folklore. For interviews, the useful model is: user-mode API layer -> Native API/syscall stub -> kernel service -> executive subsystem or driver path -> object/security/memory/I/O logic.

### Object Manager And Named Object Namespace

The Object Manager gives many Windows resources a common model: type, optional name, reference count, handle access, security descriptor, and namespace placement. Processes, threads, files, sections, events, mutexes, jobs, tokens, registry keys, device objects, drivers, and directories are typed objects, not all "files."

The namespace includes paths such as `\Device`, `\Driver`, `\KnownDlls`, `\BaseNamedObjects`, and symbolic links that expose devices or compatibility names. A named object can be found by path, but the security-relevant artifact after opening is usually a handle with a granted access mask.

Handles and kernel object pointers are different lifetime mechanisms. A handle is a process handle-table entry with a granted access mask and attributes. A kernel object pointer only keeps the object alive if the kernel code has acquired a counted reference, such as through `ObReferenceObject` or `ObReferenceObjectByHandle`; copying a raw pointer variable is not enough. For the focused follow-up, use [Windows object handles, references, and tokens](<../05-topic-notes/windows-object-handles-references-and-tokens.md>).

### OS Responsibility, Context Switch, And Kernel Authority

An OS schedules CPU time, manages virtual memory, arbitrates I/O, enforces security policy, tracks object lifetime, and exposes stable APIs to user programs. A context switch changes the running thread by saving one execution context, choosing another runnable thread, switching kernel scheduling state, and eventually restoring the new thread's registers, stack, address-space context where needed, and execution state.

Kernel mode allows privileged operations because the CPU and MMU enforce that distinction. It does not make arbitrary behavior correct. Kernel code still has to obey IRQL rules, locking rules, pageable-memory restrictions, object lifetime rules, and user-buffer validation rules.

## Module 2 - Processes, Threads, Objects, Handles, And Memory

### Process Object Vs Address Space Vs Executable Image

A Windows process is not just an EXE. The process object is an executive object that anchors identity, lifetime, security, handle table, threads, job/session relationships, quotas, and termination state.

The address space is the virtual-memory container: VADs, page tables, mapped views, private allocations, sections, image mappings, heaps, stacks, and loader-created regions. It is owned by the process, but it is a different concept from the process object.

The executable image is a file-backed PE image section mapped into the address space. Many processes can map the same executable file. A process can also have its original image unmapped, modified by copy-on-write, hollowed, or supplemented with private executable memory. That is why process identity, image path, VADs, loader lists, and image-load telemetry must be compared rather than treated as one fact.

### Thread Object, User Stack, Kernel Stack, And TEB

A thread is the actual scheduling unit. The process owns resources; threads execute code. A Windows thread has an executive/kernel thread object, scheduling state, wait/APC state, priority, affinity, and stack state.

The user stack is the stack used while executing user-mode code. The kernel stack is used when that thread is executing in kernel mode on a syscall, exception, interrupt-adjacent path, or driver path. The kernel stack must be resident when the thread is runnable, because high-IRQL code cannot safely fault in pageable stack memory.

The TEB is user-mode per-thread metadata. It includes stack bounds, TLS state, last-error storage, thread identity fields, and a pointer to the PEB. Debuggers and malware use it heavily, but it is user-mode state and should be cross-checked with kernel/debugger views.

### PEB, Loader Lists, Environment, And Process Parameters

The PEB is user-mode per-process metadata created during process initialization. It points to loader data, process parameters, environment, heap/process flags, API-set mapping, command-line strings, and loaded-module lists.

Loader lists are useful but not authoritative. Manually mapped code, unlinked modules, corrupted loader state, or injected sections can make the PEB disagree with VADs, ETW image-load events, and debugger module views. A good answer says: use PEB/TEB as evidence, not as ground truth.

Process parameters are the normalized user-mode structure containing command line, image path, current directory, environment, and related startup state. They are important for telemetry and debugging, but user-mode tampering is possible.

### Handles, Access Masks, Object Types, And Reference Counts

A handle is a per-process table entry that refers to a kernel object and carries a granted access mask. The handle value itself is not a pointer and is not meaningful in another process unless duplicated or inherited.

The access mask is what later operations test. If a process has a handle to another process with `PROCESS_VM_READ`, it can request memory reads even if the original path/name is no longer relevant. If it has `PROCESS_DUP_HANDLE`, it may move authority elsewhere. This is why handle inheritance and duplication are security-sensitive.

Handle attributes such as inheritability and protect-from-close are per-handle state. `SetHandleInformation` can change the documented inheritance/protection flags, but it cannot grant new access rights. The granted access mask is kernel handle-table state created by open/duplicate paths; user mode can ask for or duplicate rights it is allowed to receive, but a normal API cannot rewrite an existing handle into a more powerful one. If an attacker can directly corrupt handle-table entries, that is already a kernel memory-corruption or trusted-kernel-code problem.

Inherited handles keep the same value and access in the child process, which is why argv/environment handoff examples work. The child still needs a convention or channel to learn which handle value is the pipe, event, job, section, or token it should use. For standard stream redirection, `STARTUPINFO` plus `GetStdHandle` is the channel; for arbitrary handles, use argv, environment, IPC, shared state, or a named object/open-by-name design. `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` should be treated as an inheritance allowlist, not a child-visible label list.

Object type controls valid operations and generic-access mapping. Reference counts keep objects alive while handles or kernel references exist. Closing a handle removes one reference; it does not necessarily destroy the object immediately.

### Sections, Views, Image Mapping, Private Memory, And Shared Memory

A section object is a Windows kernel object representing memory that can be mapped into one or more address spaces. Sections back mapped files, shared memory, and PE image mappings. A view is the actual range mapped into a process address space from a section.

Image mapping is not just "read file bytes into memory." A PE image section is mapped with image semantics: per-section protections, relocations, imports, copy-on-write behavior, and loader metadata. Modified image pages usually become private through COW.

Private memory usually comes from `VirtualAlloc`/`NtAllocateVirtualMemory` and consumes commit when committed. Shared memory usually means two or more processes map views of the same section object. For malware analysis, private RX/RWX pages, executable mapped sections, modified image pages, and code absent from loader lists are different clues.

### VADs, Page Faults, And Working Sets

VADs describe virtual address ranges and their policy: reserved or committed private memory, mapped section views, image mappings, protections, guard behavior, and backing. VADs answer "what should this range mean?"

PTEs answer "what translation exists right now?" A VAD can describe a valid range even when no physical page is resident. The first access may fault, and the memory manager resolves the fault by demand-zeroing a page, reading a file-backed page, resolving COW, paging data back in, or raising an exception.

The working set is the resident subset of a process's virtual memory. It is RAM residency, not virtual size and not commit size. A process can have a huge reserved address range, a smaller committed amount, and an even smaller resident working set.

Windows also has physical-page and backing-object layers below VADs. PFN database entries track physical-page state such as share/reference counts, modified/standby/free/zeroed-style page lists, and the PTE or prototype PTE relationship. Section objects, control areas, subsections, segments, prototype PTEs, file objects, and pagefile/private commit describe where contents come from and who can share them. This is why VMMap, `!vad`, `!pte`, working-set views, and PFN views can all be correct while showing different layers.

### Demand Paging, Page Tables, TLB, And Page Faults

Demand paging means the OS does not need every valid page to be physically resident before execution. It can create address-space metadata and populate PTEs on first access. A page fault is therefore often a normal event, not a bug.

Page tables are the hardware-facing translation structures. The TLB caches translations, so changing page tables is not enough; stale TLB entries must be invalidated or synchronized. This matters for `VirtualProtect`, COW, unmapping, executable permissions, and security boundaries.

Control registers and page-table memory are different layers. On x64, the currently active page-table root lives in `CR3`, while Windows also stores process address-space roots in kernel process structures used during scheduling and address-space switches. A physical or kernel write primitive can potentially corrupt PTE pages or those stored roots, but it cannot directly change the CPU's active `CR3` unless privileged code executes the relevant instruction or a trusted kernel path later loads the corrupted state. On arm64 Windows, TTBR-style translation roots fill the same role. VBS/HVCI, KPTI, PatchGuard-style integrity checks, TLB shootdowns, and multi-processor synchronization all make page-table tampering a system-level primitive, not an ordinary remote-write consequence.

The hardware does not create a process page directory. Windows receives early physical-memory and loader state from firmware/boot loader components, then the loader and early kernel establish bootstrap mappings before the full Memory Manager is running. Once the PFN database, page lists, and memory-manager allocators exist, creating a user process includes creating a process object and address space, allocating physical pages for the top-level page table, mapping the image/PEB/TEB/stack and other initial regions, and storing the page-table root in process state.

The root belongs to the process address space, not to a thread as the primary owner. In symbols, the classic field to know is `_KPROCESS.DirectoryTableBase` inside `_EPROCESS`'s process-control-block state; modern builds may have additional user/kernel root fields because of KVA shadow and virtualization-based protections. `_KTHREAD` is the scheduled thread state. When a thread is scheduled, the kernel uses its owning process state to decide whether an address-space switch and `CR3` load are needed.

There is not one global PML4 for the whole machine. In classic 4-level x64 paging, each process that still owns an active address space has a top-level PML4 root page, and each logical processor has one currently active root in `CR3` at a time. Here "active address space" means the process's virtual-memory container still exists and can be switched back to; the process may be running, ready, waiting, or suspended. It does not mean "currently on CPU," and it is not the same thing as an `_EPROCESS` object still being referenced after process exit.

It is also not exactly one PML4 per process in all Windows configurations. Threads in the same process normally share the process root, so roots are not per-thread. A process object can outlive address-space teardown because handles or kernel references still exist. KVA shadow/KPTI can give the same process a restricted user root and a fuller kernel root. Boot/system contexts and virtualization-based protection layers add more roots that are not ordinary user-process PML4s. In the classic non-KVA-shadow model, the user-space PML4 entries differ per process, while the kernel-space entries are normally populated consistently so the same high kernel virtual addresses work in every process context and point into shared kernel paging structures.

The translation sequence uses the active root, not a field lookup on every memory reference. On x64, the scheduler or syscall/trap path loads `CR3` from process/address-space state when the execution context changes. The CPU then translates each virtual address by using the physical PML4 base in the current `CR3` and indexing through the virtual-address bits: PML4E, PDPTE, PDE, and PTE for 4 KB pages, or stopping earlier for large pages. Whether the address is "user" or "kernel" is decided by the virtual-address range, the user/supervisor bits in the entries, the current privilege level, and policies such as SMEP/SMAP/KPTI, not by the CPU asking Windows for a different table mid-walk. On a miss or violation, the hardware raises a page fault and the Memory Manager resolves or rejects it.

Responsibility is split cleanly: the Memory Manager creates, populates, tears down, and repairs paging structures; the scheduler/context-switch and syscall/trap code choose when to load which root into `CR3`; the MMU performs the actual walk from the active root; the TLB caches the result. A kernel debugger or memory-forensics tool must supply the equivalent of the active root manually: target process root for target user VAs, and a full kernel root for kernel VAs.

Live paging-structure pages are resident. On x86 PAE, `CR3` names a page-directory-pointer table (PDPT). On x64 4-level paging, `CR3` names a page map level 4 table (PML4); with 5-level paging, it names a PML5. x64 still has a page-directory-pointer-table/PDPTE level below PML4, followed by page-directory pages and final PTE pages. Windows can page out ordinary private pages and can encode nonresident states in software PTEs, transition PTEs, prototype PTEs, or pagefile-backed state, but the paging-structure pages reachable from an address-space root cannot themselves be paged out while hardware may walk them. The Memory Manager may delete page tables for unmapped regions or destroyed processes and return those pages to the PFN allocator, but that is teardown, not swapping an active PML4, PDPT, page directory, or PTE page to disk.

Do not turn "non-swappable" into a C-structure superstition. Windows residency is primarily a page/allocation and execution-context property. Nonpaged or effectively pinned kernel state includes hardware-walkable page-table pages for live address spaces, the PFN database and core fault-resolution state, nonpaged pool allocations, pages locked by MDLs for I/O or DMA, large-page allocations, ready/running kernel stacks, per-processor/interrupt/scheduler state, and driver/kernel code or data that can be touched at elevated IRQL. Pageable pool and pageable driver code can exist in kernel virtual address space, but code running at high IRQL, under many spin locks, inside DPC/interrupt paths, or on fault-critical paths cannot safely touch it.

For `_EPROCESS` and `_KPROCESS`, the useful security mental model is that the core process object/control-block state is kernel control state, not ordinary pageable user memory. `_KPROCESS.DirectoryTableBase`, dispatcher/process lifetime state, active process linkage, and other core fields must be reachable to schedule, reference, wait on, and manage the process. But do not infer that every pointer reachable from `_EPROCESS` is nonpageable or equally resident: handle-table internals, section/file/image metadata, security objects, user-mode PEB/process-parameter memory, VAD-related allocations, and auxiliary subsystem state each have their own backing, lifetime, locks, and residency rules. In a debugger or exploit note, prove residency through pool type, PTE/PFN state, object type, IRQL contract, or documented allocation path, not just by field name.

The System process (`PID 4`) is also not the only process whose page-table root can translate ordinary kernel virtual addresses. On classic x64 Windows, the kernel virtual address region is mapped at the same high canonical addresses in every process's kernel address-space view, so a kernel VA such as an `_EPROCESS` or `_KPROCESS` address normally translates through any valid kernel-mode process root. Memory-forensics tools often use the System process directory table base because it is stable, always present, and clearly represents a kernel address-space context, not because other processes cannot map the kernel. The important rule is: use the target process root for target user VAs; use a kernel root for kernel VAs. With KVA shadow/KPTI, modern builds may have a restricted user CR3 and a fuller kernel CR3, so translating kernel VAs through a user-mode-only root can fail or show only minimal trampoline mappings. Session space, hyperspace/PTE space, VBS/secure-kernel memory, and build-specific root fields are additional caveats, but PID 4 is a convenience, not a unique hardware authority.

For a valid x64 Windows PTE/PDE, learn the bit roles, not only the names. The classic debugger mental model is: `Valid`, hardware write permission, owner/user, write-through/cache-disable, accessed, dirty, large page or PAT context, global, Windows software bits such as copy-on-write/prototype/software-write, page-frame number, high reserved or feature-specific bits, and NX/XD. Exact field names and high-bit availability vary with CPU physical-address width, Windows build, and features such as protection keys, so do not treat one `dt _MMPTE_HARDWARE` layout as universal.

| Bit or field | Meaning | Security effect if corrupted |
|---|---|---|
| `Valid` / present | Hardware may use this entry for translation. If clear, Windows interprets the entry as software state such as demand-zero, transition, prototype, pagefile, or invalid. | Setting it on attacker-controlled contents can create a real mapping; clearing it causes faults or hides a mapping from hardware until fault handling. Stale TLB entries may still need invalidation. |
| Hardware write/RW | Controls whether stores are allowed without a protection fault. | Setting it can make code, read-only data, page tables, or COW pages writable. Clearing it can force faults or break legitimate writes. |
| Owner/user | Intel's user/supervisor permission, often shown as owner in Windows PTE views. | Setting user access on a supervisor mapping can expose privileged memory if the mapping is reachable in the active user page tables. Clearing it breaks user-mode access. KPTI, SMEP, SMAP, and VBS/HVCI affect exploitability. |
| Write-through and cache-disable | Cache policy for normal memory or device-like mappings. | Wrong cache attributes can cause incoherency, severe slowdown, device bugs, or crashes. This is usually stability-sensitive, not a clean privilege primitive. |
| Accessed | Set by hardware when a translation is used; consumed by the memory manager for aging/working-set decisions. | Tampering can distort reclaim, working-set, or forensic evidence, but it is less direct than RW/NX/PFN changes. |
| Dirty | Set by hardware when a writable leaf mapping is written; used for modified-page/writeback accounting. | Tampering can confuse writeback, COW, modified-page tracking, and forensic interpretation. |
| Large page / page size | In a PDE/PDPTE leaf, maps a 2 MB or 1 GB range instead of pointing to a lower table. In a final 4 KB PTE, related low bits may have different PAT/cache meanings. | Setting it with a valid aligned PFN can remap a large physical range; setting it incorrectly usually causes reserved-bit faults or system crashes. |
| Global | Allows TLB entries to survive ordinary address-space switches when global pages are enabled. | Can make stale or privileged mappings persist longer across context switches; correct shootdown semantics become critical. |
| Windows software bits: COW, prototype, software write | Hardware generally ignores the available-to-software bits while the entry is valid, but Windows uses them to remember copy-on-write, section/prototype, and intended protection state. | Changing these can confuse the Memory Manager's fault path, sharing, and COW behavior. The COW bit alone does not enforce COW; the hardware RW bit must force a write fault. |
| PFN / page frame number | Physical frame or next paging-structure page selected by this entry. Old examples often show 36 PFN bits; modern systems depend on `MAXPHYADDR` and enabled features. | Changing it is the strongest class: alias a virtual address to attacker-chosen physical memory, page tables, tokens, code, or data. It must still be structurally valid and coherent with PFN database and TLB state. |
| Reserved or feature-specific high bits | Must be zero unless the CPU/OS feature defines them. Some old diagrams mark bits 48-62 reserved; that is not universal on modern systems. | Setting reserved bits normally produces reserved-bit page faults or bugchecks. Mis-decoding these bits is a common tooling and writeup error. |
| NX/XD | If enabled, prevents instruction fetch from the page. | Clearing NX can turn data into executable memory; setting NX can break code execution. DEP/W^X, CFG/CET, ACG/CIG, code integrity, SMEP, and user/supervisor policy still shape impact. |

For non-leaf entries, the PFN points to the next page-table page, not to application data. Corrupting a non-leaf PML4E/PDPTE/PDE can redirect an entire address-space subtree, which is more powerful and more crash-prone than changing one final PTE. Any permission or PFN change also has a TLB story: without the right invalidation, one CPU may keep using the old translation while memory shows the new PTE.

Large pages are the middle case between "non-leaf pointer to another table" and "4 KB PTE leaf." On x64, a normal 4 KB page walk descends through PML4, PDPT, page directory, and page table. If a PDE has the large-page/page-size bit set, the PDE itself is the leaf for a 2 MB region: its PFN is a 2 MB-aligned physical base, its permissions apply to the whole 2 MB, and the low 21 virtual-address bits are the offset. If a PDPTE is a large-page leaf, it maps a 1 GB region with the low 30 bits as offset. There are no 512 final 4 KB PTEs to inspect for that range unless the OS splits the mapping.

The TLB caches the final translation together with the effective page size. A 4 KB translation covers one base page; a 2 MB translation covers the entire large page; a 1 GB translation covers the entire 1 GB leaf. On a TLB hit, the CPU does not consult the lower page-table hierarchy. On a TLB miss, the page walker stops at the large-page PDE/PDPTE and skips the lower table pages that a 4 KB mapping would need. CPU TLB organization is model-specific, but the stable reason large pages help is greater TLB reach plus fewer page-walk memory references.

Windows exposes large pages explicitly. User-mode large-page allocations normally use `VirtualAlloc` with `MEM_LARGE_PAGES`, `MEM_RESERVE`, and `MEM_COMMIT` together, require `SeLockMemoryPrivilege`, and must use size/alignment multiples of `GetLargePageMinimum`. Pagefile-backed section views can use `SEC_LARGE_PAGES` and, on Windows 10 version 1703 and later, `FILE_MAP_LARGE_PAGES` at map time. Large-page memory is resident/nonpageable and is not ordinary working-set memory, so it changes both performance and accounting.

Security and internals implications:

| Property | Why it matters |
|---|---|
| TLB efficiency | One translation covers a large range, reducing page walks and TLB pressure for server databases, runtimes, and hot buffers. |
| Coarse protection | RW/NX/user/cache/global bits apply to the whole large-page leaf. 4 KB guard/protect/COW behavior is not available without using small pages or splitting where the OS supports it. |
| Allocation constraints | Physical memory must be sufficiently contiguous and aligned; late allocations can fail or be expensive. |
| Privilege and residency | On Windows, explicit large pages require privilege and stay resident. Unexpected use is a strong triage signal. |
| Exploit blast radius | A PTE-style write to a large-page PDE/PDPTE changes megabytes or gigabytes of mapping. A wrong PFN or reserved bit is likely to crash quickly. |
| Detection pitfalls | VAD/protection views, `!pte`, working-set views, and final-PTE assumptions can disagree unless the analyst recognizes a large-page leaf. |

If a large page is split into smaller pages, stale TLB state is one of the correctness hazards. The old large-page translation must be invalidated before the system can rely on newly installed 4 KB PTE permissions; otherwise the CPU may keep using the old broad mapping temporarily.

Five-level x64 paging and 57-bit linear addresses matter mostly as layout and assumption changes. In 4-level x64, canonical addresses use 48 significant bits; with LA57, canonical addresses use 57 significant bits. A larger virtual-address space can give the OS more room for high-entropy ASLR, guard regions, sparse reservations, and kernel-region layout decisions, but it is not a standalone protection. Security reviewers should look for code that assumes all valid user pointers fit in the old range, masks or sign-extends the wrong top bits, compresses pointers unsafely, validates addresses with stale constants, or assumes a fixed four-level page-table geometry.

Not currently running does not mean the address space is gone. A waiting or suspended process may have most ordinary pages trimmed from its working set, but its process address-space root and live paging structures must remain available so the process can run again. When no thread from that process is running on a CPU, that process's root is not necessarily loaded in any CPU's `CR3`, but the live x64 PML4/PML5 root page remains an allocated physical page recorded in process memory-management state. During process termination, the Memory Manager tears down VADs, unmaps views, releases commit/backing references, and frees page-table pages when the address space is no longer needed. The process object may still be referenced by handles or visible in some lifetime state, but that is not the same as keeping a full swappable page directory.

### Resident Vs Committed Vs Reserved Memory

These three terms answer different questions:

| Term | Question it answers | Windows meaning | Linux translation |
|---|---|---|---|
| Reserved | Is a virtual address range set aside? | Address space is reserved so later allocations do not collide, but no private backing is promised. | A VMA or allocator arena can reserve address range; Linux does not expose an exact `MEM_RESERVE` equivalent because `mmap` creates mappings directly. |
| Committed | Has the OS promised private backing if the page is touched? | Commit consumes the system commit limit, backed by RAM plus pagefile capacity. | Linux has overcommit accounting and policies. A successful `malloc`/anonymous `mmap` may not mean RAM or swap is truly reserved until fault, depending on policy and flags. |
| Resident | Is a physical page in RAM now? | Part of the process working set or otherwise resident PFN state. | RSS/`smaps` residency. A mapping can be valid and even charged without its pages currently resident. |

This distinction is crucial for both Windows and Linux. On Windows, `VirtualAlloc(MEM_RESERVE)` can reserve a large address range without commit. `MEM_COMMIT` promises backing but still may not make every page resident until touched. On Linux, `malloc` may hand out user-space heap addresses from an arena without immediately faulting physical pages. Large `malloc` calls often use anonymous `mmap`; small allocations may come from a `brk`-backed heap arena. In both cases, the allocator's returned pointer is not proof that all pages are resident.

Examples:

- A process can reserve 1 GB, commit 4 MB, and have 64 KB resident.
- A Linux process can `mmap` a large anonymous range and see little RSS until it writes to pages.
- File-backed mappings may occupy virtual address space with little private commit because clean pages can be reloaded from the file.
- Freeing memory in a user allocator may not immediately reduce RSS or virtual size if the allocator keeps arenas for reuse.

Strong interview answer: virtual address existence, backing commitment, and physical residency are three separate layers. Confusing them causes bad memory triage on both Windows and Linux.

### Scheduler States, Priority, Quantum, And Synchronization

A ready thread can run but is not currently executing. A running thread is executing on a CPU. A waiting thread is blocked on an object, I/O, timer, synchronization primitive, or other wait reason. Windows scheduling considers priority, dynamic boosts, quantum expiration, affinity, processor groups, and wait completion.

Synchronization primitives are correctness tools for shared state. Mutexes, events, semaphores, critical sections, SRW locks, push locks, ERESOURCEs, spin locks, and interlocked operations have different sleepability, ownership, fairness, IRQL, and contention properties. Race-condition reasoning should name the shared object, ownership rule, lock or reference mechanism, and what invariant is violated.

### `CreateEvent` And Event Objects

`CreateEvent` creates or opens a waitable event object and returns a handle. The handle is Object Manager state: object type, optional name, security descriptor, namespace placement, reference/lifetime, and granted access. The synchronization behavior is dispatcher state: signaled or nonsignaled, wait blocks, wait lists, and wakeup rules.

Manual-reset events are broadcast/state signals: once signaled, all current and future waiters can pass until `ResetEvent`. Auto-reset events are single-waiter handoff signals: one waiter is released and the event resets as part of wait satisfaction. Events signal that a condition changed; they do not protect the data behind that condition and they do not count queued work items. Use a lock, counter, semaphore, condition variable, IOCP, or threadpool wait when those semantics are what the design actually needs.

## Module 3 - Security Model And Access Checks

### Primary Token Vs Impersonation Token

A process has a primary token that represents its default security context. A thread can temporarily use an impersonation token to act as a client or another identity. Access checks may use the thread token if impersonating; otherwise they use the process token.

This matters in services and IPC. A SYSTEM service that impersonates a low-privilege client should be checked as the client for appropriate operations. Bugs often come from using the wrong token, failing to revert impersonation, or assuming the process identity is always the effective identity.

### SIDs, Groups, Restricted Tokens, And Privileges

SIDs identify users, groups, services, AppContainer capabilities, logon sessions, and other principals. Tokens contain a user SID and group SIDs. Access checks compare these SIDs to ACEs in an object's DACL.

Privileges are special rights such as debug, backup, restore, take ownership, create token, or impersonate. They are not the same as group membership and are not generic "admin wins" switches. A privilege must be present, enabled where required, and relevant to the operation.

Restricted tokens remove or constrain authority by marking SIDs as deny-only or adding restricted SID checks. They are part of sandboxing and least-privilege design.

### Mandatory Integrity Control

Mandatory Integrity Control is a label-based policy layered on top of DACL checks. A lower-integrity subject may be blocked from writing to a higher-integrity object even if the DACL appears permissive.

The practical rule: DACL allowed is not the end of a Windows access check. Integrity level, AppContainer, PPL, privileges, and object-specific policies may still matter. The reason is that Windows separates discretionary policy, which the object owner can usually influence, from mandatory policy, which prevents lower-trust code from modifying higher-trust state even when the DACL is broad. Evidence lives in the subject token integrity SID and the object's mandatory label.

### DACL, SACL, Owner, ACE Ordering, And Access Masks

A security descriptor contains owner, group, DACL, and SACL. The DACL grants or denies access. The SACL controls auditing. The owner has special control authority but is not automatically granted every data access.

ACE ordering matters because explicit denies and allows are evaluated according to canonical rules. Access masks encode the requested rights. Generic rights are mapped to object-specific rights, so "read" means different exact bits on a file, process, token, registry key, or section.

### `SeAccessCheck` Conceptually

`SeAccessCheck` is the conceptual security-reference-monitor path that evaluates a token against a security descriptor for requested access. The model is:

1. Start with desired access.
2. Map generic rights to object-specific rights.
3. Consider privileges that apply.
4. Evaluate deny and allow ACEs against token SIDs.
5. Apply mandatory integrity and other policy constraints.
6. Return a granted access mask or deny the open/operation.

The result is commonly stored in the handle's granted access mask. Later operations test the handle, not the original path string.

### UAC Split Tokens

UAC does not mean an administrator is always running with full administrator authority. An interactive admin commonly receives a filtered medium-integrity token and can elevate to a linked high-integrity token through consent/credential flow.

That is why "the user is admin" is not a precise answer. You need to ask which token the process is actually using, which integrity level it has, which privileges are present/enabled, and whether elevation happened. The security mechanism is token filtering: powerful SIDs and privileges can be disabled or removed from the unelevated token, so a process launched by an administrator can still fail operations that require high integrity or an enabled privilege. Evidence is token elevation type, linked token state, integrity level, and process creation/elevation events.

### AppContainer And Capability SIDs

AppContainer is a lowbox isolation model. AppContainer processes have restricted identity and can access resources only through granted capabilities and brokered paths. Capability SIDs represent fine-grained authority such as access to certain resources or app-defined capabilities.

A mature answer treats AppContainer as additional token state and policy, not as a separate operating system. Access checks still revolve around tokens, SIDs, capabilities, object ACLs, and brokered APIs. The reason this matters after RCE is that code execution inside an AppContainer inherits a deliberately narrow protection domain; meaningful reach often depends on broker behavior, capability grants, filesystem/registry virtualization, and which handles or objects were already exposed.

### Protection Domains, ACLs Vs Capabilities, And TOCTOU

A protection domain is the set of resources and operations available to a subject. In Windows, a token plus privileges, integrity, AppContainer state, logon session, and protection level largely define that domain.

ACL-based security asks whether a subject is listed or matched by policy on the object. Capability-style security asks whether the subject holds an unforgeable authority artifact. Windows has both flavors: DACLs on securable objects and handles that carry granted authority once opened.

TOCTOU bugs happen when code checks one fact and later uses a different object or state. On Windows this often means checking a path string then opening a different reparse-target object, validating a user buffer then using it after it changes, or impersonating for a check but reverting before the actual privileged operation.

## Module 4 - Authentication, Credentials, And Identity Boundaries

### Logon Sessions And Token Creation

A logon session represents an authenticated identity instance on the machine. Successful authentication produces logon-session state and one or more tokens carrying user SID, groups, privileges, logon SID, integrity, and other claims.

Tokens are the authorization artifact used after authentication. Authentication proves identity; token creation turns that identity into local authority. Confusing those two leads to weak answers about Kerberos, NTLM, LSASS, and service accounts. The reason is that later object opens do not re-run the whole authentication protocol; they evaluate the token and object policy. Evidence includes logon session identifiers, token AuthenticationId/logon SID, process token lineage, and Security logon events.

### LSASS Role

LSASS hosts Local Security Authority services and authentication packages. It participates in logon, credential material handling, security policy, audit policy, and token creation flows. It is high-value because it sits near identity and credential boundaries.

Modern answers should not reduce LSASS to "dump passwords." You must mention PPL/LSA protection, Credential Guard, authentication packages/SSPs, logon sessions, handle access attempts, event visibility, and policy state. The deeper mechanism is that LSASS is a trusted broker for turning remote/local authentication into local tokens and for holding or mediating credential material; therefore the interesting question is which secrets or token-creation paths are actually reachable under the current protection and virtualization policy.

### Authentication Packages And SSPs

Authentication packages implement logon protocols and credential processing. SSPs provide security support for authenticated communication. Examples include Kerberos, NTLM, Negotiate, and package/provider components loaded into LSASS depending on configuration.

For analysis, unexpected authentication-package or SSP modules in LSASS are serious because they operate in a trusted credential-processing process. The reason is not just module location; it is authority. Code loaded into LSASS can observe or influence authentication flows, credential handling, and security-context creation, so module signer, load path, registry configuration, protection level, and load-time evidence all matter.

### NTLM Vs Kerberos

NTLM is challenge-response based and does not provide the same ticket-based mutual-authentication and delegation model as Kerberos. Kerberos uses a KDC, tickets, service principals, ticket-granting tickets, and service tickets.

Interview depth does not require packet-by-packet memorization. It requires knowing which authority is local versus domain, what LSASS stores or uses, what artifacts appear in logs, how service identity matters, and why replay/relay/delegation questions differ by protocol. The "why" is that NTLM proves knowledge through a challenge flow but lacks Kerberos's ticket and service-principal structure; Kerberos can express domain-issued service access and delegation policy, while NTLM commonly raises relay and downgrade concerns in different places.

### PPL And Why LSASS Access Changed

Protected Process Light restricts which processes can open invasive handles to protected processes. LSASS can run as PPL when LSA protection is enabled. That means an admin process with `SeDebugPrivilege` may still be blocked from normal memory access if it lacks an appropriate protection/signer level.

This changes old assumptions. "Run as admin and read LSASS memory" is no longer a mature Windows answer. You need to check PPL state, Credential Guard state, handle access, driver paths, telemetry, and policy.

### Credential Guard And VBS Isolation

Credential Guard uses virtualization-based security to isolate certain credential secrets away from the normal Windows kernel. The point is not just "LSASS is harder to read." The trust model changes: some secrets are protected by a separate VBS/secure-kernel boundary, so compromising a normal admin process or even some kernel paths may not expose the same material.

Correct analysis asks which credential type is protected, whether Credential Guard is enabled, which OS edition/policy applies, and what authentication fallback or cached material remains.

### Auditing And Event Visibility

Windows identity behavior leaves evidence across Security Event Log, ETW providers, LSASS-adjacent events, logon/session events, process creation, handle access auditing if configured, authentication protocol events, and endpoint product telemetry.

No single event proves the whole story. Strong triage correlates logon session, token/user, process, service, network, and object-access views. The reason is that each telemetry layer observes a different boundary: authentication, token use, object open, process start, network flow, or provider-specific behavior. Missing evidence can mean benign configuration, unsupported provider coverage, loss, or tampering, so the correct answer is correlation rather than blind trust in one log.

### Trusted Computing Base, Isolation, Local Vs Domain

The trusted computing base is the set of components whose correctness is required for a security property. For local authentication that includes local policy, SAM/LSASS paths, token creation, kernel access checks, and configured protections. For domain authentication it also includes domain controllers, KDC behavior, trust relationships, SPNs, time synchronization, and network reachability.

Isolation boundaries can be process, kernel, hypervisor, credential-isolation, AppContainer, session, desktop, network, or domain boundaries. A good answer names which boundary is being crossed.

## Module 5 - Kernel, I/O, Drivers, And Telemetry

### Driver Objects, Device Objects, And Symbolic Links

A driver object represents a loaded kernel driver and its dispatch table. A device object represents a device or logical endpoint created by a driver. A symbolic link exposes a device object under a user-openable namespace path such as a DOS device name.

User mode often reaches a driver through `CreateFile` on a device symbolic link, receiving a file handle. Later calls such as `DeviceIoControl`, `ReadFile`, or `WriteFile` become IRPs sent to the driver stack.

### IRPs And Major Function Dispatch

An IRP is the I/O request packet that carries an operation through the I/O manager and driver stack. Major function codes describe the operation class: create, close, read, write, device control, cleanup, power, PnP, and others.

Each driver stack layer can inspect, pass down, complete, pend, cancel, or transform a request. Vulnerability analysis asks: who owns the buffer, who validates length and access, what runs at what IRQL, who completes the IRP, and what object lifetime is assumed?

### IOCTLs And User/Kernel Buffer Risks

IOCTLs are custom driver control operations. The IOCTL code encodes device type, function, buffering method, and access bits. Buffering methods matter:

| Method | Risk model |
|---|---|
| `METHOD_BUFFERED` | I/O manager copies data through a system buffer; driver must still validate lengths and output size. |
| Direct I/O | MDLs describe locked user pages for transfer; driver must respect direction, length, and mapping rules. |
| `METHOD_NEITHER` | Driver receives user pointers and must probe, capture, validate, and handle races carefully. |

Common bug classes include trusting user pointers, integer overflow in size calculations, missing access checks, TOCTOU on buffers, bad MDL use, completion-after-free, and writing more output than the caller supplied.

### Kernel Callbacks

Windows provides supported callback mechanisms for process, thread, image-load, registry, and object-handle events. Security products use them for visibility and policy. They are also high-value targets because they sit on sensitive transitions.

The mature framing is not "callbacks are hooks, hooks are bad." The question is who registered them, what driver owns them, what altitude/order applies where relevant, whether they are signed/expected, and whether telemetry matches lower-level state. The reason callbacks matter is that they are policy chokepoints on kernel-mediated transitions; changing, suppressing, or abusing them can alter what is observed or allowed without patching the original subsystem. Evidence includes registered callback owners, driver signer/path, callback order, object-handle operation traces, and independent memory/state views.

### Minifilters And WFP

File-system minifilters attach to the file-system stack at altitudes. They can observe or affect opens, reads, writes, renames, deletes, and metadata operations. Antivirus, EDR, encryption, backup, and DLP tools commonly use minifilters.

Windows Filtering Platform is the network filtering framework. Callouts can classify and act at multiple layers such as ALE authorization, transport, stream, and packet paths. Defender Firewall and many endpoint products use WFP rather than raw packet hacks.

The shared reason these frameworks matter is that they are supported extension points at high-value I/O boundaries. A minifilter sees file intent before it becomes only bytes on disk; WFP sees network authorization and flow classification before it becomes only packets. Good analysis identifies altitude/layer, owner, signer, policy, and whether the observed file or network behavior agrees with lower-level artifacts.

### ETW Providers, Consumers, And Kernel Telemetry

ETW is a structured tracing infrastructure, not just text logging. Providers emit events. Consumers subscribe through sessions. Kernel and user providers can report process, thread, image, file, registry, network, stack, and provider-specific events.

EDR and diagnostic tools often combine ETW with callbacks, minifilters, WFP, AMSI, memory scanning, and handle/process inspection. Missing ETW where lower-level evidence exists can indicate configuration gaps, tampering, or provider limitations. The mechanism reason is that ETW depends on provider emission and consumer/session configuration; it is broad and efficient, but it is still a reporting path rather than the object or memory state itself. Strong answers always compare ETW to handles, VADs, file IDs, registry state, and network flow evidence.

### PatchGuard And Old Kernel-Hooking Assumptions

PatchGuard is kernel patch protection for selected critical structures and code paths on x64 Windows. It makes old assumptions like "just patch SSDT/IDT/GDT/kernel code" brittle and crash-prone. HVCI, driver signing, and vulnerable-driver blocklists further change the model.

Modern kernel extensibility should use supported mechanisms: drivers, callbacks, minifilters, WFP, ETW, and documented APIs. Rootkit analysis still needs to know old techniques historically, but not treat them as normal modern practice. The "why" is that Microsoft moved the stable extension contract away from arbitrary mutation of kernel control structures; unsupported mutation collides with integrity monitoring, signing policy, virtualization-based protections, and crash/recovery behavior.

### Interrupts, IRQL, DPCs, APCs

Interrupts transfer control from hardware/device events. ISRs run at device interrupt IRQL and should do minimal urgent work. DPCs defer follow-up work to `DISPATCH_LEVEL`. APCs run in the context of a specific thread under specific conditions; user APCs require alertable waits.

IRQL constrains code. At high IRQL, code cannot block, cannot touch pageable memory safely, and must use appropriate locks and allocation flags. Many driver crashes are really IRQL bugs.

APCs split into user APCs, normal kernel APCs, and special kernel APCs. Normal kernel APCs run in kernel mode at `PASSIVE_LEVEL`; special kernel APCs run in kernel mode at `APC_LEVEL` and are used for mechanics such as I/O completion. Treat "special kernel APC = IRQL 1" as a shorthand for "`APC_LEVEL`, between passive execution and dispatch-level/DPC constraints"; the named IRQL and allowed DDIs matter more than the number.

### Blocking I/O, DMA, Filesystem Cache, Journaling

Blocking I/O waits until completion; nonblocking or overlapped I/O returns before completion and reports later through events, APCs, IOCP, or polling. Kernel code must know whether it can wait in the current context.

DMA lets devices read/write memory without CPU copying. Windows often describes locked transfer buffers through MDLs. DMA is a security issue because a buggy or malicious device/driver can corrupt memory unless the IOMMU/DMA remapping and driver APIs constrain it.

The filesystem cache and Cache Manager decouple application I/O from disk I/O. Journaling and metadata consistency protect filesystem structures across crashes, but they do not mean every application write is durable unless flush/fsync-style semantics are used.

Cached file data lives in RAM while resident and can move through system cache, standby, and modified/writeback states. Memory-mapped files use section views and page faults to bring file-backed pages into memory; cached `ReadFile`/`WriteFile` paths and mapped views can therefore meet in Cache Manager/Memory Manager state. Clean file-cache pages can be discarded and reread; dirty cached or mapped file pages need writeback to the file, not private pagefile storage.

## Module 6 - Mitigations And Exploit Reasoning

### DEP/NX, ASLR, CFG, CET, ACG, And CIG

DEP/NX marks data pages non-executable. ASLR randomizes locations to make addresses harder to predict. CFG restricts indirect calls to valid targets. CET adds hardware-backed shadow-stack and indirect-branch protections where supported. ACG restricts dynamic code generation in some process policies. CIG restricts loading unsigned or improperly signed code into protected contexts.

These mitigations do different jobs. DEP blocks simple injected-code execution. ASLR raises the need for leaks. CFG/CET constrain control-flow redirection. ACG/CIG constrain code creation/loading policy. None of them universally stops data-only attacks or logic bugs.

### KASLR And Kernel Pointer Disclosure

KASLR randomizes kernel image and allocation placement. Kernel pointer leaks reduce or defeat that randomness by revealing code or object addresses. Modern exploit reasoning often begins with: can the attacker disclose enough layout to use a write primitive reliably?

KASLR does not protect against every data-only corruption. It mainly frustrates address-dependent control-flow and object-targeting assumptions. The reason a leak changes the game is that many primitives are only useful when they can target the right object, table, or gadget address; without layout knowledge, a write may crash instead of producing controlled impact. Evidence of a leak is not just a printed pointer; it is any disclosure that collapses enough entropy to make the target stable.

### Pool/Heap Concepts

Windows kernel pool is allocator-managed kernel memory, historically divided into paged and nonpaged categories with pool tags for ownership/debugging. Nonpaged memory is required where page faults are illegal. Special Pool, Driver Verifier, cookies, metadata hardening, and allocation changes affect exploitability.

Paged pool is the cheaper choice when all later access happens in contexts where paging and required waits are legal. Nonpaged pool is required when the object can be touched at `DISPATCH_LEVEL`, from DPC/interrupt-adjacent paths, under spin locks, by DMA/MDL paths, or anywhere a page fault is illegal. Modern APIs such as `ExAllocatePool2` make the flags explicit, but the real design decision is the lifetime access path, not just the allocation site.

Modern nonpaged pool should normally be non-executable. "Resident" means the page must stay in RAM; it does not imply that CPU instruction fetches should be allowed. NX nonpaged pool makes ordinary kernel data a worse target for injected-code execution, while still leaving data-only corruption, type confusion, object-pointer replacement, and control-data attacks relevant.

Do not infer that every kernel object or object-adjacent allocation is nonpaged. Object headers, bodies, handle tables, names, security descriptors, file/section/VAD metadata, cache-manager state, and type-specific extension data can have different allocation and residency rules. The right question is which component allocated the memory, what IRQL or fault path will touch it, and what pool/backing contract that path requires.

At interview level, know the difference between user heap, kernel pool, stack, image mappings, mapped sections, and MDL-described pages. Exploitability depends on object size class, lifetime, reuse, adjacency, type confusion potential, and available primitives.

For the full follow-up set covering section objects, `Nt`/`Zw`, `SeLockMemoryPrivilege`, `kernel32` address reuse, PEB/TEB ASLR discovery, DLL sharing, and KASLR, use [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>). For handle/object reference counts, handle-entry fields, token APIs, and NX pool residency caveats, use [Windows object handles, references, and tokens](<../05-topic-notes/windows-object-handles-references-and-tokens.md>).

### Bug Classes And Primitive Taxonomy

Core memory-safety bug classes:

- Use-after-free: stale reference to freed object.
- Race: state changes between check and use or across threads/CPUs.
- Type confusion: memory interpreted as the wrong type.
- Integer overflow: arithmetic wraps and causes undersized allocation or bad bounds.
- Out-of-bounds: read/write outside intended object.

Primitive taxonomy:

- Info leak: reveals addresses or secrets.
- Read primitive: attacker can read chosen memory.
- Write primitive: attacker can write chosen or constrained memory.
- Control-flow primitive: attacker redirects execution.
- Data-only primitive: attacker changes security-relevant data without hijacking control flow.

Modern exploit reasoning maps bug -> primitive -> constraints -> target boundary -> mitigations -> telemetry -> patch.

### Why Old DEP/ASLR Material Is Insufficient

Classic DEP/ASLR bypass writeups often assume easier module leaks, RWX memory, predictable heaps, unprotected kernel structures, or control-flow hijack as the main goal. Modern Windows adds CFG, CET, ACG, CIG, PPL, VBS/HVCI, KASLR, pool hardening, code integrity, and richer telemetry.

The result is that exploitability is often about constraints: can the bug be reached, can it survive hardening, can it produce a useful primitive, can it cross the intended boundary, and can it avoid or explain telemetry?

### CFI Vs Data-Only, Races, And Boundary Validation

Control-flow integrity tries to prevent invalid control transfers. Data-only attacks modify meaningful data while leaving control flow valid: tokens, privileges, access masks, flags, object pointers, configuration, or policy state.

Race bugs are about time and ownership. The fix may be lock ordering, reference acquisition, object state transitions, copying user data once, or moving checks closer to use.

Kernel/user boundary validation means treating user pointers, lengths, handles, object names, IOCTL buffers, and process-controlled state as untrusted until captured and checked in the right context.

## Module 7 - Malware Analysis, EDR Framing, And Scenario Review

### PE Loading, Imports, API Sets, And Loader Behavior

PE loading maps an image section, applies relocations if needed, resolves imports, handles API-set redirection, initializes TLS, calls loader-managed callbacks, and runs `DllMain` before ordinary code paths. Imports show one static dependency view, but code can dynamically resolve APIs with `LoadLibrary`, `GetProcAddress`, `LdrLoadDll`, export parsing, or API hashing.

API sets are contract names resolved by the loader to implementation DLLs. A suspicious import name is not always the final module path. Loader behavior must be correlated with VADs, ETW image-load events, KnownDLLs, signatures, and PEB loader lists.

### DLL Loading And Injection Concepts

DLL loading is normal when the loader maps expected signed dependencies from expected paths. It becomes suspicious when path search, side-loading, unsigned modules, unexpected directories, reflective/manual mapping, private executable memory, or thread starts point outside normal module state.

Injection is not one technique. It is a family of behaviors that cause code or data from one context to execute in another: remote thread starts, APCs, section mapping, process hollowing-like image replacement, thread context manipulation, or loader abuse. The defensive explanation should name memory evidence and telemetry, not implementation steps.

### AMSI, ETW, EDR Visibility, And Memory Scanning

AMSI lets content-aware engines inspect script or dynamic content before execution in participating hosts. ETW reports structured runtime events from providers. EDR visibility often combines ETW, callbacks, minifilters, WFP, AMSI, process/thread events, image loads, handle access, memory scans, and cloud reputation.

Memory scanning inspects current process memory for code, signatures, configuration, shellcode-like regions, unbacked executable pages, or mismatches with disk. It catches a different class of evidence than API hooks or logs.

### Anti-Analysis And Packing

Packing compresses, encrypts, virtualizes, or stages code so static imports and bytes are misleading. Anti-analysis checks for debuggers, instrumentation, timing changes, VM artifacts, breakpoints, unusual exception behavior, or tool modules.

The mature answer is to turn anti-analysis into OS evidence: exceptions, timing APIs, PEB/TEB fields, unusual memory protections, loader anomalies, self-modifying code, and discrepancies between disk and memory. The reason this works is that anti-analysis logic must interact with real mechanisms: exception dispatch, debug objects/ports, performance counters, module lists, memory protections, or API results. Those interactions leave artifacts even when the original static bytes are intentionally misleading.

### User-Mode Hooks, Kernel Callbacks, ETW, AMSI, And Memory Scanning

| Mechanism | Where it observes | Strength | Blind spot |
|---|---|---|---|
| User-mode hooks | API calls inside a process | Rich call context | Can be bypassed by lower-level paths or direct syscalls; hook tampering possible |
| Kernel callbacks | Process/thread/image/registry/object transitions | Sees kernel-mediated events | Limited to registered callback points |
| ETW | Provider-emitted structured events | Broad, efficient telemetry | Provider/session configuration and tampering matter |
| AMSI | Script/content scanning path | Content-aware | Only works for participating hosts and content paths |
| Memory scanning | Current memory state | Finds unbacked/modified code and artifacts | May miss transient behavior and needs interpretation |

Strong EDR discussion compares independent views. If loader metadata, VADs, ETW, thread starts, and memory bytes disagree, that disagreement is often the signal.

### Invariants Security Products Rely On

Security products rely on invariants such as: process creation produces events, image loading produces loader and memory evidence, handles carry authority, executable memory has backing/protection metadata, registry/file changes pass through observable paths, and network flows cross filterable layers.

Malware often tampers with metadata, not physics. It may unlink loader lists, alter memory protections, spoof parent metadata, duplicate handles, patch user-mode functions, or disable telemetry. Defenders respond by cross-checking views from different layers.

### Responsible Bypass Discussion

A responsible discussion of bypass research names the mechanism, assumption, detection gap, and mitigation direction. It should avoid presenting an operational playbook. For example: "This technique relies on telemetry being collected only at API layer X; lower-level event Y or memory view Z would catch the same behavior" is the right level for an interview.

The reason this distinction matters is that security-internals research is valuable when it identifies a fragile assumption and a stronger invariant. A bypass writeup that only lists steps teaches procedure; a mature explanation says which boundary was trusted, why that boundary was incomplete, what independent evidence remains, and what engineering change would reduce the gap.
