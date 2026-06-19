# Linux Internals Deep Understanding Questions, Scored

Value Score: 91/100
Role: Linux active-recall owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-15

Purpose: a prioritized self-test for Linux internals. The existing project has strong topic notes; this file turns the most important deep-understanding checks into one scored order and includes full best-answer explanations for each question.

Dense-term companion: [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) expands and routes Linux terms such as VMA, PTE, TLB, COW, page cache, VFS, LSM, RCU, eBPF, io_uring, SLUB, DMA, and IOMMU to practical evidence paths and owner docs.

Source companion: [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>) points to newer Hebrew case-study PDFs for glibc heap, PwnKit, eBPF, modprobe_path, GOT overwrite, Linux Process Hollowing, Linux persistence, Linux kernel exploitation, Android firmware, and SLUB. Use those after the current kernel docs/source, not as replacements.

Journey companion: [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) points to the local Linux Concept, Linux Security, Linux Security Workbook, Kernel Data Structures, Kernel Macro, Android Concept, and Networking Journey PDFs. Use them as concept bridges and active-recall support beside this question bank.

Remote-attacker companion: [Remote-attacker low-level mechanisms](<../05-topic-notes/remote-attacker-low-level-mechanisms.md>) turns the Linux answers into the 0/1-click RCE+PE-to-agent scenario: client or service execution context, `cred`, fd/object authority, VMA/PTE memory, loader/path/IPC behavior, async lifetime, kernel extensions, credentials, communication, telemetry, containers, DMA, and boot trust. Vulnerability/exploitability reasoning is secondary to the security internals that determine what an authorized agent can do.

Vulnerability-research companion: [Vulnerability research and exploitation primitives](<../05-topic-notes/vulnerability-research-and-exploitation-primitives.md>) keeps the secondary exploitability track separate: Linux structures of interest, bug classes, primitives, mitigations, constraints, and safe authorized validation.

Score meaning:

| Score range | Meaning |
|---|---|
| 95-100 | Core mental model. Missing this breaks many other explanations. |
| 90-94 | Very high value for senior interviews, debugging, and research. |
| 85-89 | Important depth that distinguishes real understanding from memorization. |
| 80-84 | Practical depth for kernel/debugging/security roles. |
| 70-79 | Specialized or role-dependent. |

## Cross-Cutting Responsibility Map

Use [the low-level security component map](<../01-comparisons-and-maps/02-low-level-security-component-map.md>) alongside this question bank for the low-level checker/enforcer split. Linux answers should explicitly separate:

| Boundary | Linux checker/policy component | Lower-level enforcer |
|---|---|---|
| User-to-kernel transition | syscall/exception entry, syscall argument validation, `copy_from_user`, LSM/seccomp where relevant | CPU privilege level, syscall/SVC entry rules, SMEP/SMAP/PAN/PXN, page permissions |
| Process and file authority | VFS permission checks, `cred`, capabilities, namespaces, LSM hooks, fd table state | kernel object paths and MMU-backed memory access |
| Virtual memory isolation | `mm_struct`, VMAs, fault handlers, PTE updates, TLB shootdowns | MMU, TLB, NX, user/supervisor page bits, CR3/TTBR |
| Physical memory and DMA | memory manager, driver DMA APIs, pinned-page/GUP policy, IOMMU groups | MMU, IOMMU, DMA engine, device firmware |
| Boot and kernel integrity | Secure Boot/shim policy where used, module signing, lockdown, IMA/EVM/LSM policy where configured | UEFI firmware, TPM measured boot, CPU/hypervisor features where enabled |
| Kernel observability and tamper resistance | audit, tracepoints, eBPF verifier, LSM, module loader, read-only kernel mappings | kernel write-protection state, page permissions, hardware breakpoints/tracing where used |

## Top Priority Questions

| Score | Area | Deep-understanding question | Strong answer must cover | Current coverage |
|---:|---|---|---|---|
| 100 | Virtual memory | What exactly happens from a user access to an unmapped-but-valid address until execution resumes or a signal is delivered? | CPU page fault, trap frame, `mm_struct`, VMA lookup, permissions, anonymous/file-backed/COW fault, page allocation or page-cache lookup, PTE update, TLB implications, `SIGSEGV`/`SIGBUS` cases. | Strong: [modern Linux MM reading map](<../03-linux/09-modern-linux-mm-reading-map.md>), `OS-Internals-01`, `OS-Internals-02`, README Phase 2. |
| 99 | Process model | How do `fork`, `clone`, `execve`, `posix_spawn`, `exit`, and `wait` change kernel state? | `task_struct`, thread group, `mm_struct`, `files_struct`, `cred`, COW, fd inheritance, image replacement, `posix_spawn` as API contract rather than `execve` twin, zombies, reparenting, exit status, `SIGCHLD`. | Good: README Phase 1, partial in project files. |
| 98 | Kernel structure graph | How do `task_struct`, embedded `list_head` fields, PID lookup, `sched_entity`, `mm_struct`, VMA indexes, refcounts, and RCU turn textbook process theory into real kernel state? | One task can be linked into several relationships at once; process/thread group is shared resources; PID lookup differs from list walking; scheduler placement differs from process enumeration; current kernels use Maple Tree for VMAs while older material mentions VMA rbtrees; lifetime requires refcounts/RCU/locks. | Added deeper comparison in [Linux vs Windows internals](<../01-comparisons-and-maps/01-linux-vs-windows-internals.md>). |
| 98 | VFS/files | Walk `openat -> read -> close` from userspace to storage or page cache. | syscall ABI, fd table, `struct file`, path lookup, dentries/inodes/superblock, permission checks, VFS operation, page cache, filesystem/block layer, lifetime/refcounts. | Good in README/source map; needs active drill. |
| 97 | Memory objects | What is the difference between VMA, PTE, page/folio, page cache entry, and anonymous page? | Policy range vs translation entry vs physical page metadata vs cached file page vs anonymous backing, COW transitions, reclaim effects. | Strong: `OS-Internals-01`, `OS-Internals-02`, FAQ. |
| 96 | User/kernel boundary | Why are `copy_from_user`, `copy_to_user`, syscall argument validation, and compat paths security boundaries? | User pointers are untrusted, faulting copies, TOCTOU, access checks, hardened usercopy, 32-bit compat ABI, structure size/layout validation. | Partial: roadmap and exploit reasoning files. |
| 95 | Lifetime/concurrency | Given a kernel object reachable from syscalls, how do you reason about lifetime and races? | Ownership, refcounts, locks, RCU, state machines, workqueues, deferred free, UAF, double free, race-to-use, patch direction. | Strong: FAQ and primitives file; broader subsystem examples needed. |
| 94 | Scheduler | How does Linux decide what runs next, and what changed from classic CFS thinking to EEVDF-era fair scheduling? | runnable tasks, scheduling classes, run queues, virtual runtime/deadline idea, preemption, wakeups, latency/fairness, cgroups, CPU affinity. | Partial: README references; not deep in topic files. |
| 93 | TLB/MMU | Why is changing a PTE not enough, and what must happen with TLBs and shootdowns? | TLB caching, stale translations, per-CPU state, invalidation, shootdowns, ordering, permission changes, security impact of stale mappings. | Strong: `OS-Internals-01`, FAQ. |
| 92 | Page cache/reclaim | Why is the page cache central to Linux performance and correctness? | file I/O, `mmap`, page cache as file-backed memory, dirty/writeback, reclaim, rmap, memory pressure, memcg, COW interactions. | Strong: `OS-Internals-02`. |
| 91 | Allocators | How do buddy, per-CPU pagesets, SLUB, `kmalloc`, typed caches, and `vmalloc` differ? | physical pages vs slab objects vs virtual contiguity, GFP flags, context constraints, cache reuse, fragmentation, debugging/hardening. | Strong: `OS-Internals-02`. |
| 90 | Credentials/security | How do UID/GID, capabilities, `cred`, file capabilities, namespaces, seccomp, and LSMs combine into an access decision? | effective/saved IDs, capabilities, user namespaces, VFS checks, seccomp syscall filtering, LSM hook policy, `cred` lifetime. | Good roadmap; scattered. |
| 90 | Interrupts/entry | How do interrupts, exceptions, traps, syscalls, softirqs, and workqueues differ? | asynchronous vs synchronous entry, privilege transition, hard IRQ context, deferred work, sleepability constraints, kernel stack/trap frame. | Strong: `OS-Internals-03`, README Phase 4. |
| 89 | Attacker tunables | Which Linux OS/process/thread/environment tunables matter in remote exploit chains, and what authority is required to change them? | env/argv/cwd, loader/runtime variables, rlimits, dumpability, ptrace/core settings, capabilities, namespaces/cgroups/seccomp, memory layout sysctls, BPF/JIT, network sysctls, LSM/audit policy, kernel-helper paths. | Expanded in [attacker-relevant structures](<../05-topic-notes/attacker-relevant-structures-and-components.md#attacker-tunable-state-os-process-thread-and-environment-parameters>). |
| 89 | Signals/futexes | Why are signals and futexes subtle in multithreaded processes? | process vs thread-directed signals, masks, pending sets, signal delivery on return to userspace, futex user fast path, kernel wait/wake, priority/robust futexes at concept level. | Partial: README; needs question drill. |
| 89 | Event/wait/monitoring model | Why is Windows `CreateEvent` not cleanly equivalent to one Linux primitive? | futexes, eventfd/timerfd/signalfd, poll/epoll, wait queues, completions, inotify/fanotify/fsnotify, netlink/audit, perf/ftrace/tracepoints/kprobes/uprobes, eBPF/BPF attach points, fd vs address vs kernel-internal authority. | Added after Windows event/dispatcher comparison pass. |
| 89 | `mmap` semantics | Why is `MAP_PRIVATE` a transition story rather than simply "private memory"? | file-backed sharing before write, COW fault, anonymous page after write, page cache aliasing, reclaim, dirty state. | Strong: `OS-Internals-02`, FAQ. |
| 88 | RCU | What problem does RCU solve, and why is it not just a faster lock? | read-side critical sections, grace periods, deferred free, pointer publication, update-side synchronization, memory ordering, UAF failure modes. | Good but scattered. |
| 88 | Refcounts | Why do refcount bugs often become security bugs? | object lifetime, overflow/underflow, stale pointers, refcount_t vs atomic_t, ownership transfer, release paths. | Good in primitives/FAQ. |
| 87 | Namespaces/cgroups | What do namespaces isolate, what do cgroups control, and why are neither a complete security boundary alone? | PID/mount/net/user/ipc/uts/cgroup/time namespaces, resource controllers, user namespace root, capabilities, LSM/seccomp need. | Good roadmap; no dedicated Q bank before this. |
| 87 | BPF | What makes eBPF both powerful and risky? | `bpf()` syscall, verifier, maps, helpers, program/attach types, BTF/CO-RE, JIT, privilege model, observability/security uses, verifier bugs. | Good source map; partial in notes. |
| 86 | io_uring | Why is io_uring hard to reason about from a security perspective? | shared SQ/CQ rings, registered files/buffers, async workers, object lifetime, pinned memory, cancellation, cross-thread/process interactions. | Good roadmap/source map; partial detail. |
| 86 | Page pinning | Why can pinned pages break normal MM assumptions? | GUP, DMA, COW/migration/reclaim conflicts, long-term pins, page lifetime, writeback hazards. | Strong: `OS-Internals-02`, FAQ. |
| 85 | ELF loading | What happens when Linux executes a dynamically linked ELF? | `execve`, ELF headers/program headers, interpreter, `ld-linux`, mappings, stack/env/auxv, relocations, GOT/PLT, constructors, vDSO/vvar. | Strong: `OS-Internals-03`; memory overview file. |
| 85 | Observability | Which Linux tracing/debugging tool would you choose for a syscall path, memory bug, race, performance issue, or crash? | `strace`, ftrace, perf, kprobes/uprobes, tracepoints, bpftrace, KASAN/KCSAN/KFENCE/lockdep, crash/drgn, `/proc`/`sysfs`. | Good README/source map. |
| 84 | Networking | Walk a packet receive path at a high level. | NIC interrupt/polling, NAPI, DMA buffers, `sk_buff`, protocol stack, socket receive queue, wakeups, filtering hooks. | Gap/partial. |
| 84 | Block I/O | How does file I/O become block I/O, and where can caching hide disk operations? | page cache, writeback, filesystem, bio/request queue, scheduler, block device, flush/barrier, direct I/O contrast. | Gap/partial. |
| 83 | Device drivers | How does a userspace operation reach a Linux device driver? | `/dev` node, VFS, `struct file`, `file_operations`, ioctl/read/write/mmap, driver-private data, permissions, lifetime. | Moderate via README/source map. |
| 83 | LSM/seccomp | Where do LSM and seccomp decisions happen, and why are they complementary? | seccomp filters syscalls/args, LSM mediates object operations, hook points, stacking, Landlock/AppArmor/SELinux/BPF LSM concept. | Moderate. |
| 82 | Kernel hardening | How do KASLR, SMEP/SMAP/PAN, KPTI, stack canaries, hardened usercopy, slab hardening, CFI, lockdown, and module signing degrade primitives? | Map each mitigation to the primitive it frustrates; note info leaks and data-only attacks. | Strong in primitives file; scattered. |
| 82 | Filesystem namespaces | Why is path resolution security-sensitive? | symlinks, bind mounts, mount namespaces, lookup races, `openat2`-style constraints, permissions, LSM hooks, TOCTOU. | Gap/partial. |
| 81 | Page fault vs exception | Why is "page fault" not synonymous with "bug"? | demand paging, swapped page, COW, stack growth, permission fault, invalid VMA, machine checks vs normal MM events. | Strong; keep source-current with [modern Linux MM reading map](<../03-linux/09-modern-linux-mm-reading-map.md>). |
| 81 | Kernel stacks | What lives on a kernel stack, and why do entry paths care? | per-thread kernel stacks, interrupt stacks/IST where relevant, pt_regs, syscall/exception frames, overflow risk, context constraints. | Strong: `OS-Internals-03`. |
| 80 | Memory ordering | Why are atomics not enough without memory-ordering reasoning? | CPU reordering, compiler reordering, barriers, lock acquire/release semantics, RCU publication, per-CPU data. | Moderate. |
| 80 | Containers | What is the difference between a container escape, namespace escape, cgroup bypass, and host-kernel exploit? | boundary type, shared kernel, user namespace, capabilities, LSM/seccomp, mount/net namespace, runtime configuration. | Good roadmap; partial notes. |
| 79 | Android | Why does Android change Linux internals reasoning? | Zygote, Binder, ART, SELinux domains, ashmem/memfd, low-memory handling, Scudo, app sandbox. | Strong: `OS-Internals-04`. |
| 78 | Architecture | Which internals assumptions change between x86-64 and arm64? | syscall/exception ABI, page table levels, PAN/SMAP analogs, PAC/BTI/MTE, TBI, cache/TLB details, page size. | Strong: `OS-Internals-05`. |
| 78 | Crash triage | Given a kernel oops, what are your first five steps? | decode faulting IP, call trace, taint, registers, object/lifetime hypothesis, symbols/source, sanitizers/logs, reproducer. | Good roadmap/source map. |
| 77 | Fuzzing | What does a good kernel fuzzing workflow look like? | interface model, generator, sanitizers, crash collection, minimization, root cause, patch, regression test, syzkaller/LKL concepts. | Moderate. |
| 76 | Module/rootkit history | Why is syscall-table hooking an incomplete modern Linux rootkit model? | module signing/lockdown, LSM/BPF/netfilter/VFS hooks, eBPF, kernel self-protection, cross-view detection. | Partial; comparison doc covers cross-platform. |
| 75 | Power/firmware/DMA | Why do DMA and IOMMU matter to kernel security? | device bus mastering, DMA remapping, scatter/gather, pinned pages, driver trust, physical memory isolation. | Gap/partial. |

## Best Answers

### 100 - Virtual Memory

A user access to an unmapped-but-valid address first faults in hardware. The CPU cannot complete the load/store/instruction fetch, records fault state, switches into the kernel through the architecture exception path, and the kernel sees the faulting address, access type, and register state. The kernel then looks up the current task's `mm_struct` and searches the VMA tree/maple tree for a `vm_area_struct` that covers the address.

If no VMA covers the address, or the access violates VMA permissions, the fault is normally fatal and becomes `SIGSEGV`. If the VMA is valid, the kernel resolves the fault according to backing: anonymous memory may allocate a zeroed page; file-backed memory may find or read a page-cache page; a write to a COW mapping may allocate a private page and copy data; swapped memory may be read back. The kernel installs or updates the PTE, applies correct permissions, handles accounting, and ensures stale TLB state is not used. If the backing object cannot satisfy the access, such as a truncated mapped file, the result can be `SIGBUS` rather than `SIGSEGV`.

### 99 - Process Model

`fork` creates a new task that is initially a near-copy of the parent. The child gets its own `task_struct`, shares or copies selected structures depending on clone flags, and usually gets a new address space that initially points at the same physical pages through copy-on-write mappings. File descriptors, signal state, credentials, namespaces, and other resources are inherited or shared according to kernel rules and clone flags.

`clone` is the more general primitive: it can create threads by sharing `mm_struct`, `files_struct`, signal handlers, and other resources, or create process-like children with less sharing. `execve` does not create a new PID; it replaces the current image, tears down most old mappings, builds a new userspace stack, maps the executable and interpreter, resets parts of signal/thread state, and applies credential transitions such as setuid/file capabilities.

`posix_spawn` is different from `execve`: it is a POSIX API for creating a new process that runs a program, commonly implemented by libc using an optimized fork/vfork/clone plus exec-like path and file actions. It is closer to the user-level contract "start this program with these attributes" than to the raw image-replacement primitive. That distinction matters for tracing, because you may see clone/fork/vfork-like behavior plus `execve`, not a single kernel syscall named `posix_spawn`.

`exit` tears down the task, releases references, records exit status, and may leave a zombie until the parent waits. `wait` collects that status and lets the kernel finally release the zombie task's remaining process accounting.

### 98 - Kernel Structure Graphs

Linux process theory becomes concrete through a graph, not one PCB-shaped record. `task_struct` is the central schedulable task, but process-wide behavior is split across shared structures such as `mm_struct`, `files_struct`, `signal_struct`, `sighand_struct`, `cred`, namespace pointers, cgroup state, and filesystem context. Threads are tasks that share selected structures with other tasks in the same thread group.

Embedded `list_head` fields link the same task into different relationships: global task iteration, parent/child lists, sibling lists, thread-group lists, and subsystem-specific queues. PID lookup is another path through `struct pid` and namespace-aware indexes. Scheduler placement is separate again: runnable tasks are represented through scheduler entities on per-CPU run-queue state. Modern kernels index VMAs with Maple Tree, while older VMA explanations often mention red-black trees. A correct answer separates enumeration, lookup, scheduling, address-space range lookup, and lifetime. Locks, refcounts, and RCU decide whether a pointer remains valid while another CPU exits, unlinks, re-parents, or frees the object.

### 98 - VFS And Files

`openat` enters the kernel through the syscall ABI and begins with path resolution relative to a directory file descriptor and the caller's mount namespace. The VFS walks dentries and inodes, follows allowed symlinks/mounts, checks permissions through DAC/capabilities/LSM hooks, and asks the filesystem to open the object. On success, the kernel allocates a `struct file`, installs it into the process fd table, and returns a small integer fd.

`read` uses that fd to find the open file description, checks the file mode and current offset, then calls through VFS/file operations. For a normal cached file, the read path is often satisfied from the page cache; otherwise the filesystem and block layer may issue I/O. `close` removes the fd table reference, decrements the `struct file` reference count, and final cleanup happens only when the last reference is gone. The important model is fd table entry -> `struct file` -> path/dentry/inode/superblock/filesystem operations -> page cache/block device.

### 97 - Memory Objects

A VMA is a policy range: it says that a range of virtual addresses is legal and describes permissions, backing, flags, and operations. A PTE is a concrete translation entry for one page-sized part of that range: it tells the MMU whether a page is present, writable, executable, user-accessible, dirty, accessed, and which physical frame it maps.

A `struct page` or folio describes physical memory managed by the kernel. A page-cache entry is file-backed cached data associated with an inode/address-space; it may be mapped into many processes. An anonymous page has no ordinary file backing and usually belongs to heap, stack, or COW-private data. The subtle part is transition: a `MAP_PRIVATE` file page can start as a shared page-cache mapping and become an anonymous private page after a write fault.

### 96 - User/Kernel Boundary

User pointers and syscall arguments are untrusted because userspace can pass invalid addresses, race memory changes, point into unmapped memory, or craft values that confuse kernel structure parsing. `copy_from_user` and `copy_to_user` are not just memcpy; they must tolerate faults, enforce user/kernel address boundaries, and interact with hardening such as hardened usercopy.

Argument validation also includes sizes, flags, alignment, object ownership, and permissions. Compat paths add risk because 32-bit userspace structures may differ from 64-bit kernel structures in pointer size, padding, and layout. Many kernel bugs come from trusting user-controlled lengths, doing checks before a user-controlled object changes, or forgetting that a userspace pointer can fault halfway through an operation.

### 95 - Lifetime And Concurrency

Start by identifying the object, all references to it, the locks or RCU rules protecting it, and the state transitions that make it visible or dead. Then ask which syscall, interrupt, workqueue, timer, or callback can still reach it. A safe design has a clear ownership model: references are acquired before use, released exactly once, and final freeing is delayed until no concurrent reader can still observe the object.

Races happen when visibility, lifetime, and state changes are not atomic as a group. A lock may protect fields but not lifetime; RCU may protect lookup but not mutation; a refcount may keep memory alive but not guarantee the object is in the right state. Strong fixes usually enforce an invariant at the ownership boundary: take a reference under the lookup lock, use RCU grace periods for deferred free, serialize state transitions, or make invalid states unreachable.

### 94 - Scheduler

Linux schedules runnable tasks through scheduling classes. Normal fair scheduling historically centered on CFS and virtual runtime: tasks that received less CPU became more eligible. Modern fair scheduling discussion includes EEVDF-style virtual deadline reasoning, which tries to combine fairness with better latency behavior by considering eligible tasks and virtual deadlines rather than only a simple leftmost virtual-runtime choice.

A strong answer should describe run queues, wakeups, preemption, priorities, CPU affinity, scheduling classes, cgroup resource control, and why scheduling is policy over hardware execution. The scheduler is not just "pick next task"; it also decides when to preempt, where to wake a task, how to balance CPUs, and how to account for fairness and latency under cgroup constraints.

### 93 - TLB And MMU

The CPU does not read page tables on every memory access. It caches translations in the TLB, so changing a PTE in memory does not guarantee the CPU immediately observes the new mapping or permissions. If a page is unmapped, remapped, made read-only, made executable/non-executable, or moved, stale TLB entries can preserve the old behavior until invalidated.

On SMP systems, the problem is per-CPU. Other CPUs may be running the same address space and may hold stale translations, so the kernel sometimes needs TLB shootdowns. Correctness is therefore page table update plus ordering plus invalidation. This matters for security because stale writable or executable mappings can undermine the intended permission change.

### 92 - Page Cache And Reclaim

The page cache is where file I/O and memory management meet. Reads and writes of regular files often go through cached pages, and file-backed `mmap` uses the same cache as the backing store for mapped pages. That means a file page can be visible through `read`, through an mmap in one process, and through another process mapping the same file.

Reclaim decides which physical pages can be reused under memory pressure. Clean file-backed pages can often be dropped and reread; dirty pages need writeback; anonymous pages may need swap; pinned pages may not be movable or reclaimable. Reverse mapping, memcg accounting, PSI, and COW state matter because reclaim must know who maps a page and whether discarding or writing it is legal.

### 91 - Allocators

The buddy allocator manages physical pages in power-of-two orders and is the base for page allocations. Per-CPU pagesets reduce contention for common page allocation/free paths. SLUB and other slab allocators build object caches on top of pages so the kernel can allocate small objects efficiently with reuse and cache locality.

`kmalloc` returns physically contiguous slab-backed memory suitable for many kernel objects and DMA constraints up to limits. Typed caches are slab caches dedicated to a specific object type, improving locality and constructor/debug behavior. `vmalloc` returns virtually contiguous memory backed by non-contiguous physical pages, so it is useful for large allocations but has different performance and adjacency properties. GFP flags encode context: interrupt/atomic contexts cannot sleep, while process context may reclaim or block.

### 90 - Credentials And Security

Linux access decisions start from `cred`: real/effective/saved UIDs and GIDs, supplementary groups, capabilities, securebits, namespace context, and LSM security blobs. File operations combine process credentials with inode metadata, mode bits, POSIX ACLs, mount flags, capabilities, and LSM hooks. File capabilities and setuid/setgid can change credentials during `execve`.

Namespaces and cgroups are not generic permission systems. User namespaces change how IDs and capabilities are interpreted; mount/PID/net namespaces isolate views; cgroups control resources. Seccomp filters syscall numbers and arguments to reduce attack surface, while LSMs mediate object operations at hook points. A complete answer explains that final authority is the composition of credentials, namespace context, object metadata, capabilities, seccomp, and LSM policy.

### 90 - Interrupts And Entry

Syscalls are intentional synchronous user-to-kernel transitions. Exceptions are synchronous CPU events caused by the current instruction, such as page faults or invalid opcodes. Interrupts are asynchronous hardware events, such as timers or devices. All require careful entry code that saves state, switches privilege level, and observes context constraints.

Hard IRQ handlers must do minimal work and cannot sleep. Softirqs, tasklets historically, workqueues, threaded IRQs, timers, and kthreads exist to defer work to safer contexts. Workqueues run in process context and can sleep; softirqs run in a more constrained context. The key is not memorizing names, but knowing which context can block, which locks are allowed, and how work moves from urgent interrupt handling to deferred processing.

### 89 - Attacker Tunables

A Linux remote attack rarely starts with authority to change system policy. It starts with input to a daemon. If that input reaches a child process, parser, archive extractor, shell wrapper, or runtime, then environment variables, argv, current directory, `PATH`, temp paths, umask, rlimits, and loader/runtime variables become relevant. With service-code execution, the attacker can tune that process and its children; if the daemon has capabilities or runs as root, sysctls, namespaces, cgroups, network policy, tracing, and service configuration become remotely reachable through the compromised service.

Separate normal API tunables from privileged and kernel-only state. A process can often alter its own mappings, dumpability, scheduler hints, signal handlers, and child environment. Root or specific capabilities are needed for system-wide hardening knobs such as `kernel.randomize_va_space`, ptrace/core policy, BPF/JIT access, network forwarding/filtering, audit, module loading, and LSM-adjacent policy. A kernel primitive changes the model again: credential objects, PTEs, helper paths, LSM hooks, and telemetry state may be modified without going through the policy owner. Defenders should record the prerequisite that made each state change possible.

### 89 - Signals And Futexes

Signals are subtle because they can be directed at a process or a specific thread, are affected by per-thread masks, and are usually delivered at controlled return-to-userspace points. A signal handler interrupts normal user control flow, but delivery still depends on kernel state, pending sets, masks, and which thread is eligible.

Futexes are subtle because the fast path is in userspace: if the lock word changes atomically without contention, no syscall is needed. The kernel participates only when a thread must wait or wake others based on a user memory address. Correctness depends on the user atomic operation, the kernel wait queue, wakeup ordering, robust-list behavior, and avoiding lost wakeups. In multithreaded programs, the kernel and userspace jointly implement the synchronization protocol.

### 89 - Event Wait And Monitoring Model

Linux does not have one direct equivalent to Windows `CreateEvent` plus dispatcher waits. The closest answer depends on which part of the Windows behavior you mean. If you mean "wait until a userspace lock word changes," the Linux answer is futex-backed synchronization. If you mean "make a waitable notification object that composes with other I/O," the answer may be `eventfd`, `timerfd`, or `signalfd`. If you mean "wait across many I/O sources," the answer is usually `poll`, `select`, or `epoll`. If you mean "kernel code sleeps until a condition changes," the answer is wait queues or completions.

The authority model differs. A Windows event is a securable Object Manager object reached by handle, optional name, namespace, DACL, and granted access mask. A Linux futex is a protocol around a userspace memory address. An `eventfd` is an fd with counter-like semantics. `epoll` is a readiness multiplexer over fds. A kernel completion is an internal synchronization object, not a user-visible named object. Treating these as synonyms hides the object that carries authority and lifetime.

Linux filesystem and subsystem notifications are separate again. `inotify` watches filesystem events from a userspace-facing watch perspective. `fanotify`/`fsnotify` can provide broader filesystem notification and, with the right privileges and mode, permission-style mediation. Netlink and audit expose structured subsystem/security events. These are event streams, not generic dispatcher objects; visibility depends on mount namespaces, watched paths or marks, queue limits, privileges, and policy configuration.

`select()` is mostly legacy-but-still-recognizable. It is fine for tiny portable tools and teaching the readiness model, but it is a poor default for modern high-fd-count services. The reasons are the fixed `fd_set` bitmap model, common `FD_SETSIZE` limits, destructive fd sets that must be rebuilt before each call, and O(n) scanning up to `nfds`. `pselect()` is important because it addresses signal-mask races around waiting, not because it makes `select()` scalable. `poll()` removes the fixed bitmap interface but still scans; `epoll` is the usual Linux readiness primitive for many fds; `io_uring` is a different submission/completion model.

Tracing and monitoring add another layer. ftrace and tracepoints observe kernel paths with known hook points; kprobes and uprobes instrument kernel or user functions dynamically; perf events sample or count performance and trace events; eBPF/BPF programs attach to tracepoints, kprobes, uprobes, XDP, tc, cgroups, LSM hooks, and other attach points, using maps and helpers under verifier and privilege constraints. BPF can be observability, packet processing, filtering, or policy depending on attach type.

The security answer is to name the event source, authority object, lifetime rule, and evidence. Is the wakeup tied to an fd, a memory address, an inode/path watch, a socket/netlink channel, a BPF program/map, or a kernel wait queue? Is it a notification, a readiness hint, a completion, or a permission decision? Evidence comes from fd tables, `/proc`, tracefs/debugfs, audit logs, BPF program/map inventory, perf/ftrace output, watched inodes/marks, and subsystem-specific state.

### 89 - `mmap` Semantics

`MAP_PRIVATE` does not mean the process immediately owns a private copy of the whole file range. Initially, the mapping may point at shared file-backed page-cache pages. On a write fault, the kernel allocates an anonymous page, copies the original data, updates the PTE to point to the private page, and marks it writable for that process.

That transition matters for correctness and security. Reads can observe file-backed cache state, writes become private anonymous state, and reclaim/writeback behavior differs before and after COW. Missing this leads to wrong assumptions about aliasing, dirty data, and whether a modification affects the file or only the process.

### 88 - RCU

RCU solves the problem of very frequent reads over shared pointer-based data where taking a conventional lock on every read would be too expensive. Readers enter an RCU read-side critical section and can dereference protected pointers without blocking writers in the usual way. Writers publish a new version or remove an object, then wait for a grace period before freeing memory that old readers might still hold.

RCU is not a faster mutex. It does not automatically protect arbitrary mutation, and it does not make object lifetime safe unless updates and frees follow the RCU protocol. The hard parts are pointer publication, memory ordering, update-side serialization, and making sure removed objects are not freed before all pre-existing readers are gone.

### 88 - Refcounts

Refcounts encode object lifetime. If code can use an object after the last reference is dropped, a UAF is possible. If a reference is leaked, resources remain alive forever. If a refcount underflows or overflows, the object may be freed while still reachable or kept alive with corrupted ownership state.

Security bugs appear because kernel objects often carry authority: files, credentials, sockets, mappings, message objects, and task state. A stale reference can let an attacker reinterpret freed memory as a different object type or operate on an object after its security state changed. Robust code acquires references under the same lock or RCU protection that made the object visible and releases them on every error path.

### 87 - Namespaces And Cgroups

Namespaces isolate views. PID namespaces change process numbering and reparenting view; mount namespaces change the filesystem view; network namespaces change interfaces/routes/socket tables; IPC/UTS/cgroup/time namespaces isolate other specific global-looking resources; user namespaces change ID mapping and capability interpretation. They are not all equal, and none makes a separate kernel.

Cgroups control and account for resources: CPU, memory, I/O, pids, and related controllers. They are important for containers but are not a complete security boundary. A container boundary usually depends on namespaces, cgroups, capabilities, seccomp, LSM policy, filesystem restrictions, and runtime configuration. A kernel vulnerability crosses all containers because the kernel is shared.

### 87 - BPF

eBPF is powerful because it lets users load small verified programs into kernel-controlled hook points for tracing, networking, security, and observability. Programs interact with maps, helpers, BTF type information, CO-RE relocation, and attach points such as tracepoints, kprobes, XDP, tc, cgroups, and LSM hooks.

It is risky because it is a programmable kernel interface with a complex verifier and many helper interactions. The verifier must prove safety properties such as bounded memory access and controlled pointer use before JIT or interpretation. Bugs in verifier reasoning, helper semantics, or lifetime management can become serious kernel attack surface. Defensive use and attack-surface risk come from the same power: BPF runs close to sensitive kernel state.

### 86 - io_uring

io_uring changes the syscall model by sharing submission and completion rings between userspace and the kernel. It also supports registered files, registered buffers, async workers, cancellation, polling, and many operation types. That means state can outlive the submitting thread and can be completed by workers under complex lifetime rules.

Security reasoning is hard because requests, buffers, files, credentials, and rings interact asynchronously. Registered buffers may pin pages; fixed files may extend file lifetime; cancellation races can leave stale references; workers may execute later in a different context. A strong answer treats io_uring as an object-lifetime and shared-memory protocol, not just a faster way to call `read` or `write`.

### 86 - Page Pinning

Pinned pages create an external promise that a physical page must remain available for some user, often DMA or direct I/O. Normal memory management wants to migrate pages, reclaim them, COW them, write them back, or drop clean cache pages. A long-term pin can block or complicate those operations.

This is especially subtle with COW and file-backed pages. If a page is pinned while another path expects to create a private copy or write back data, the MM must preserve correctness for both the pinner and the mapping owner. That is why `get_user_pages`-style APIs are security- and correctness-sensitive, particularly with DMA and long-term pins.

### 85 - ELF Loading

When a dynamically linked ELF is executed, `execve` validates the file, reads ELF headers, maps loadable program segments, and notices the interpreter path for dynamically linked programs. The kernel prepares the initial userspace stack with argv, envp, and auxiliary vector entries, maps the interpreter, and transfers control to it rather than directly to the program's main code.

The dynamic linker maps dependencies, applies relocations, resolves symbols according to ELF rules, sets up GOT/PLT behavior, handles TLS and constructors, and eventually jumps to the program entry/CRT path. Sections are mostly link-time metadata; program headers and mappings drive runtime loading. vDSO/vvar mappings provide fast kernel-provided data/functions for selected operations without a syscall.

### 85 - Observability

Choose the tool based on the question. `strace` is good for syscall-level userspace behavior. `/proc`, `/sys`, debugfs, and tracefs expose live kernel state. ftrace and tracepoints are good for low-overhead kernel path observation; kprobes/uprobes are useful for dynamic instrumentation; perf is strong for performance and sampling; bpftrace/eBPF can correlate events with programmable filters.

For bugs, sanitizers and debugging tools matter. KASAN targets memory safety, KCSAN races, lockdep locking mistakes, KFENCE low-overhead heap bugs, UBSAN undefined behavior, and crash/drgn/kdump help with postmortem state. A senior answer picks the narrowest tool that proves or disproves the hypothesis without distorting the system too much.

### 84 - Networking

A receive path usually begins with the NIC DMAing packet data into buffers prepared by the driver. An interrupt or polling mechanism notifies the kernel. Modern Linux often uses NAPI to switch from interrupt-driven receive to polling under load, reducing interrupt overhead.

The driver builds or fills `sk_buff` structures and hands them into the networking stack. The packet passes through protocol processing, routing/filtering hooks, socket lookup, and eventually a socket receive queue. A waiting userspace thread may be woken. Along the way, netfilter, tc, XDP/eBPF, namespaces, cgroups, and offload metadata may affect behavior.

### 84 - Block I/O

Cached file I/O may not immediately become disk I/O. Reads can be served from the page cache, and writes can dirty cache pages that are written back later. The filesystem translates file offsets and metadata into block operations when needed, then the block layer builds bios/requests and submits them to the device queue/driver.

Direct I/O bypasses much of the page cache but introduces alignment, pinning, and device constraints. Flushes, barriers, FUA, writeback, journaling, and filesystem consistency rules determine when data is durable. The main lesson is that application `write` returning does not always mean bytes are on stable storage unless the API and flags require that.

### 83 - Device Drivers

Userspace usually reaches a Linux character device through a device node under `/dev`. Opening the node goes through VFS permission checks and creates a `struct file` whose operations point to driver callbacks. Later `read`, `write`, `ioctl`, `poll`, or `mmap` calls dispatch through that file's `file_operations`.

The driver often stores per-open state in `file->private_data` and must validate user pointers, lengths, commands, and permissions. Lifetime is shared between device objects, module references, open files, ongoing I/O, and removal paths. Many driver bugs come from trusting ioctl data, racing teardown with active file operations, or using the wrong allocation/locking rule for the current context.

### 83 - LSM And Seccomp

Seccomp is syscall filtering. It reduces attack surface by allowing, denying, trapping, or otherwise controlling syscalls based on number and limited argument inspection. It does not understand every object-level policy decision.

LSMs mediate operations at security hooks throughout the kernel: file opens, inode operations, task operations, network operations, BPF, and more depending on the hook. SELinux, AppArmor, Landlock, and BPF LSM-style policies can decide based on object labels or rules. They are complementary: seccomp limits which syscalls can be attempted, while LSMs decide whether specific object operations are authorized.

### 82 - Kernel Hardening

Each mitigation attacks a primitive. KASLR makes addresses harder to know; SMEP/SMAP or PAN prevent direct execution/access of userspace from kernel context; KPTI separates user/kernel page tables to reduce leakage/attack surface; stack canaries catch some stack corruptions; hardened usercopy restricts bad user/kernel copies; slab freelist hardening makes heap grooming harder; CFI restricts indirect call targets; lockdown and module signing restrict arbitrary kernel modification.

These mitigations do not erase bugs. They force the attacker or researcher to obtain better primitives, such as information leaks, data-only writes, valid object substitution, or logic abuse. A mature answer says which primitive is degraded and what residual paths may remain, without treating mitigation names as magic.

### 82 - Filesystem Namespaces

Path resolution is security-sensitive because the pathname is not just a string. It is resolved through a mount namespace, root/current directory, dentries, inodes, symlinks, bind mounts, overlay layers, and permissions. Attackers often exploit mismatches between what code checked and what code later opened.

Races and policy confusion appear around symlinks, rename, bind mounts, magic links, procfs paths, and container mount setups. APIs such as `openat` and `openat2` help anchor resolution to a directory and constrain traversal. Correct code checks the object actually opened, not merely a path string examined earlier.

`readlink` belongs in this model because it reports the target bytes of a symlink or procfs magic link without opening the final object and without appending a NUL terminator. Attackers care when code treats a `readlink` string as authoritative, truncates it, races it, or uses `/proc/<pid>/fd/N` and `/proc/self/exe` paths without checking the final opened object. Defensive code should prefer fd/handle identity checks after open.

### 81 - Page Fault Versus Exception

A page fault is a CPU exception, but it is not necessarily a bug. It is the normal mechanism behind demand paging, lazy allocation, COW, stack growth, swapping, and file-backed mmap reads. Many successful memory accesses begin with a page fault that the kernel resolves transparently.

It becomes fatal when the address has no valid VMA, permissions do not allow the access, the backing object cannot supply the page, or the fault happens in a context where it cannot be handled. User-visible results differ: invalid access often becomes `SIGSEGV`, while certain mapped-file backing failures can become `SIGBUS`.

### 81 - Kernel Stacks

Each running task has a kernel stack used while executing in kernel mode. Entry paths place register state and frames there or in architecture-specific exception/interrupt stack areas. Syscalls, page faults, and exceptions must preserve enough state to resume or deliver a signal.

Kernel stacks are small compared with user stacks, so deep recursion and large stack allocations are dangerous. Interrupt and exception handling may use special stacks on some architectures to avoid corrupting normal task stacks in severe conditions. Stack contents are central to debugging because they connect the current CPU state to the call path that produced it.

### 80 - Memory Ordering

Atomics make individual operations indivisible, but they do not automatically give the ordering needed for a whole protocol. CPUs and compilers may reorder independent loads/stores unless locks, barriers, or acquire/release semantics constrain them. On multicore systems, another CPU can observe updates in a surprising order.

Kernel code relies on well-defined ordering in locks, RCU pointer publication, wait/wake paths, ring buffers, per-CPU data, and device interaction. A correct lock-free or low-lock design must say not only "this counter is atomic" but also "readers cannot observe the pointer before the object is initialized" and "free cannot happen before all readers are done."

### 80 - Containers

A container escape can mean several different things. A namespace escape means breaking out of an isolated view such as mount, PID, or network namespace. A cgroup bypass means escaping resource accounting or limits. A runtime misconfiguration may expose host files, sockets, devices, or capabilities. A host-kernel exploit compromises the shared kernel and therefore crosses container boundaries.

Containers are composed from namespaces, cgroups, capabilities, seccomp, LSMs, filesystem layers, and runtime policy. Root inside a user namespace is not necessarily initial-namespace root, but excessive capabilities, writable host mounts, privileged devices, or kernel bugs can collapse the boundary.

### 79 - Android

Android is Linux plus a different process, IPC, runtime, and policy model. Zygote preloads framework/runtime state and forks app processes, which makes COW sharing central to memory behavior. ART, DEX/OAT/VDEX artifacts, and managed/native boundary behavior matter in addition to ELF and libc.

Binder is the central IPC and authority surface for system services. Apps run with per-app UIDs, SELinux domains, seccomp-like restrictions, and Android-specific permission policy. Low-memory handling, memcg/PSI, Scudo, hardened allocators, and vendor/system separation change both debugging and exploitability assumptions.

For thread/process memory-access interviews, be explicit that Android SELinux and app UIDs isolate processes and object accesses, not threads inside one process. Same-process native threads share one virtual address space; cross-process memory requires Binder-transferred fds, shared mappings, debugger-style authority, privileged service/kernel paths, or a vulnerability. See [Mobile OS and coding interview traps Q&A](<07-mobile-os-and-coding-interview-traps-qa.md#100---processes-threads-and-mobile-sandbox-memory>) for the full Android/iOS version.

### 78 - Architecture

x86-64 and arm64 differ in syscall/exception ABI, register state, page-table format, privilege model names, memory-ordering expectations, and hardening features. x86-64 discussions often mention SMEP/SMAP, KPTI, IST, and canonical addresses. arm64 discussions include PAN, BTI, PAC, MTE, TBI, different exception levels, and sometimes 16 KB page configurations on Android.

These differences affect exploitability, debugging, and performance. A pointer-tagging or PAC-aware bug on arm64 is not reasoned about exactly like an x86-64 bug. Page size changes can alter allocator behavior, object packing, and fault granularity.

### 78 - Crash Triage

First, identify the faulting instruction, fault address, registers, call trace, task context, and kernel taint/config. Second, map the instruction to source and ask what object or pointer was being used. Third, classify the likely bug: null deref, UAF, OOB, refcount, race, bad user pointer, lock misuse, or hardware/device problem.

Then look for reproduction context, recent warnings, sanitizer output, lockdep/KASAN/KCSAN reports, and relevant subsystem logs. A strong triage does not jump directly from crash to exploitability. It establishes the violated invariant, the object lifetime, and the smallest test or trace needed to prove the root cause.

### 77 - Fuzzing

A good fuzzing workflow starts by choosing an interface and modeling inputs: syscalls, ioctls, netlink, filesystems, BPF, or protocol packets. The fuzzer runs an instrumented kernel with sanitizers and collects crashes, hangs, leaks, and warnings. Crashes are minimized, reproduced, symbolized, and mapped back to the violated invariant.

The real work is after the crash: root cause analysis, primitive assessment, patch design, and regression testing. syzkaller is strong for syscall-level stateful fuzzing, while LKL or userspace harnessing can make some kernel code easier to fuzz quickly. Sanitizers improve signal quality but do not replace source-level reasoning.

### 76 - Module And Rootkit History

Syscall-table hooking is historically important but incomplete as a modern model. Kernel lockdown, module signing, read-only kernel memory, CFI-style defenses, and distro hardening make naive patching more fragile and visible. Many legitimate and malicious visibility points now live in subsystem hooks rather than direct syscall replacement.

Modern Linux monitoring or stealth may involve LSM hooks, eBPF programs, tracepoints/kprobes, netfilter, filesystem hooks, VFS/procfs manipulation, kernel modules where allowed, or compromised drivers. Detection also uses cross-view checks: `/proc` versus kernel memory, module lists versus memory scans, BPF program lists, audit logs, and offline forensics.

### 75 - Power, Firmware, DMA

DMA matters because devices can read or write system memory without the CPU copying bytes. A buggy or malicious device/driver can corrupt memory, leak secrets, or bypass normal CPU permission checks unless an IOMMU restricts device-visible mappings. Scatter/gather lists, pinned pages, and DMA mapping APIs describe what memory a device may access.

The IOMMU provides address translation and isolation for devices, similar in spirit to an MMU for device DMA. Firmware and boot policy matter because early code configures platform tables, device trust, secure boot state, and sometimes DMA protections. For security, devices are not passive peripherals; they are bus masters that must be contained.

## Highest-Value Gaps To Fill Next

| Priority | Gap | Why it matters |
|---:|---|---|
| 1 | Linux networking receive/transmit path and `sk_buff` lifecycle | Common senior kernel topic and important attack/observability surface. |
| 2 | Block layer, writeback, direct I/O, and filesystem consistency | Completes the VFS/page-cache story. |
| 3 | Scheduler/EEVDF beyond high-level references | Current kernels moved beyond old CFS-only explanations. |
| 4 | VFS path-resolution security, `openat2`, mount namespaces, overlayfs | Important for containers, sandboxing, and filesystem bugs. |
| 5 | eBPF/io_uring as full standalone deep dives | Modern high-value surfaces with complex lifetime rules. |
| 6 | DMA/IOMMU/device-driver security | Underrepresented but important for driver and hardware-facing roles. |
