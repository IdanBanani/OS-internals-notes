# Linux Internals Long-Term Mastery Roadmap

Value Score: 88/100
Role: Long-term Linux track router
Proof Level: Roadmap

Generated: 2026-05-12
Updated: 2026-05-16
Source filenames below are listed without absolute path prefixes.
Goal: long-term Linux internals mastery from an offensive security research perspective, without turning the plan into an operational malware or bypass playbook. The phases are ordered by dependency and research value, not by calendar pressure.

For exact file-to-subject correlation, use [source-map.md](<source-map.md>) in this folder. That file maps each interview topic to the specific filename/title, chapter, lesson range, or article.

For Linux memory management specifically, read [09-modern-linux-mm-reading-map.md](<09-modern-linux-mm-reading-map.md>) before older books. It explains what replaces *Understanding the Linux Kernel*, Chapter 9, and the `linux_kernel_v2.6_virtual memory manager` folder for current VMA/page-fault study.

For the newly added Hebrew Digital Whisper issues 134-185 PDFs, use [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>). Linux-relevant papers include glibc heap, PwnKit, eBPF, modprobe_path, GOT overwrite, Linux Process Hollowing, Linux persistence, Linux kernel exploitation, Android firmware, and SLUB. Treat them as case studies and verify current behavior against the target kernel/source.

For the Journey PDFs, use [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>). The Linux Concept, Linux Security, Linux Security Workbook, Kernel Data Structures, Kernel Macro, Android Concept, and Networking Journey files are useful as concept bridges and active-recall support, not as replacements for current kernel docs/source.

For dense terms that appear before they are fully taught, use [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>). It expands and routes Linux-heavy concepts such as VMA, PTE, TLB, COW, page cache, VFS, LSM, RCU, eBPF, io_uring, SLUB, DMA, and IOMMU to practical experiments and owner docs.

## Current Baseline

The modern interview target should be Linux 6.x/7.x era internals, not only classic Linux 2.6/3.x textbook internals.

Verified current anchors:

- Kernel.org lists stable `7.0.8` and mainline `7.1-rc3` on 2026-05-15, with longterm lines including `6.18`, `6.12`, `6.6`, `6.1`, `5.15`, and `5.10`: https://www.kernel.org/
- Scheduler: CFS knowledge is still useful, but current fair scheduling discussion must include EEVDF: https://docs.kernel.org/scheduler/sched-eevdf.html and https://docs.kernel.org/scheduler/sched-design-CFS.html
- Memory management: use the current kernel docs and source first, not 2.6-era chapters. `struct vm_area_struct`, `struct mm_struct`, VMA locking, page-table locking, folios, and the maple tree are current interview-grade topics: https://docs.kernel.org/mm/index.html, https://docs.kernel.org/mm/process_addrs.html, https://docs.kernel.org/mm/page_tables.html, https://docs.kernel.org/mm/page_cache.html, and https://docs.kernel.org/core-api/maple_tree.html
- Page-fault handler: study the target kernel source around `arch/<arch>/mm/fault.c`, `mm/memory.c`, `mm/mmap.c`, `mm/filemap.c`, and `mm/rmap.c`; use old Chapter 9 material only for the timeless concept that faults are VMA policy plus backing-object resolution plus PTE/TLB update.
- BPF/eBPF: verifier, BTF, maps, helpers, program types, kfuncs, and userspace ABI matter: https://docs.kernel.org/bpf/index.html, https://docs.kernel.org/bpf/verifier.html, https://docs.kernel.org/bpf/btf.html
- io_uring: shared submission/completion rings and syscall/API surface are relevant to modern performance and attack-surface reasoning: https://man7.org/linux/man-pages/man7/io_uring.7.html
- Security model: capabilities, namespaces, cgroups, seccomp, LSMs, and kernel self-protection are central:
  - https://man7.org/linux/man-pages/man7/capabilities.7.html
  - https://man7.org/linux/man-pages/man7/namespaces.7.html
  - https://man7.org/linux/man-pages/man7/cgroups.7.html
  - https://docs.kernel.org/userspace-api/seccomp_filter.html
  - https://docs.kernel.org/security/index.html
  - https://docs.kernel.org/security/self-protection.html
  - https://docs.kernel.org/security/lsm-development.html

## What Mastery Should Produce

For Linux internals/offensive research work, the critical skill is not memorizing every subsystem. It is being able to reason from an interface to the kernel path, data structures, locking/lifetime, security boundary, and observability method. If an interview appears, this same model becomes your answer structure; the roadmap should not be reduced to a cram sheet.

Use this repeated answer frame:

1. Userspace entry: syscall, fault, interrupt, net packet, file operation, BPF hook, or device event.
2. Kernel objects: `task_struct`, `mm_struct`, `vm_area_struct`, `file`, `inode`, `dentry`, `cred`, `sk_buff`, BPF map/program, cgroup, namespace.
3. Lifetime model: refcount, RCU, lock, ownership, workqueue/deferred execution.
4. Failure modes: UAF, race, refcount overflow/underflow, OOB, type confusion, info leak, TOCTOU, missing permission check.
5. Boundary: credentials, capabilities, namespaces, cgroups, seccomp, LSM hook, user/kernel copy, fd rights.
6. Mitigation: KASLR, SMEP/SMAP/PAN, KPTI, stack canaries, hardened usercopy, slab freelist hardening, CFI, module signing, lockdown, BPF verifier.
7. Debug/trace proof: ftrace, perf, kprobes/uprobes, bpftrace, tracepoints, crash/drgn, `/proc`, `/sys`, kernel logs, source navigation.

## Long-Term Mastery Phases

Cadence rule: a phase is complete when you can explain the mechanism, map it to current kernel source or documentation, design a small experiment or trace, and state what the experiment does not prove.

### Phase 1 - Process Model, Scheduling, Signals, Futexes

Primary questions:

- What is a process vs thread in Linux?
- How do `fork`, `clone`, `execve`, `exit`, and `wait` change kernel state?
- What lives in `task_struct`, `thread_info`, `mm_struct`, `files_struct`, `signal_struct`, and `cred`?
- How does a context switch happen at the conceptual level?
- What changed from CFS to EEVDF, and why does latency/fairness matter?
- How do signals and futexes cross the userspace/kernel boundary?

Source files and references:

- `TheLinuxConceptJourney_v5_April2025.pdf`
- `TheLinuxProcessJourney_v6_Sep2023.pdf`
- Prefer newer if reading from `vmareastruct`: `TheLinuxProcessJourney_v9_June2024.pdf`
- `The Linux Programming Interface.pdf` for process, signal, thread, futex-adjacent syscall behavior
- `Gayet Thierry - Linux Kernel Programming - 2025.pdf`
- `Billimoria Kaiwan - Linux Kernel Programming, 2nd.Edition (Expert insight) - 2024.pdf`

Proof drills:

- Explain `fork` with copy-on-write and how it differs from `clone`.
- Explain `execve` from syscall entry to new userspace image.
- Explain why futexes are fast when uncontended and what happens on contention.
- Explain the difference between a signal pending on a thread and on a process.

### Phase 2 - Virtual Memory, Page Faults, Page Cache, Kernel Allocators

Primary questions:

- How does Linux represent a process address space?
- What are VMAs, and why did maple tree replace older VMA lookup structures?
- What happens on a page fault?
- How do anonymous memory, file-backed mappings, copy-on-write, `mmap`, `brk`, `mprotect`, and `munmap` relate?
- What is the page cache, and how does it interact with filesystems and I/O?
- How do `kmalloc`, `vmalloc`, slab/slub caches, and per-CPU allocations differ?
- What makes kernel heap bugs exploitable or non-exploitable in modern kernels?

Source files and references:

- `docs/03-linux/09-modern-linux-mm-reading-map.md`
- Current kernel docs: `mm/process_addrs`, `mm/page_tables`, `mm/page_cache`, `mm/physical_memory`, and `core-api/maple_tree`
- Target kernel source: `include/linux/mm_types.h`, `mm/mmap.c`, `arch/<arch>/mm/fault.c`, `mm/memory.c`, `mm/filemap.c`, `mm/rmap.c`
- `TheLinuxKernelDataStructuresJourney_v2.0_April2024.pdf`
- `TheLinuxProcessJourney_v9_June2024.pdf`
- `05_linux_memory.pdf`
- `08_linux_memory.pdf`
- `EN - From collision to exploitation_ Unleashing Use-After-Free vulnerabilities in Linux Kernel.pdf`
- `Memory Thinking for C  C++ Linux Diagnostics (Dmitry Vostokov) (Z-Library).pdf`

Historical only:

- `Understanding the Linux Kernel - 3rd Edition.pdf`
- `understanding the 2_6 linux kernel virtual memory manager.pdf`

Proof drills:

- Walk a user page fault into VMA lookup, permission checks, page allocation or file-backed page-cache lookup.
- Explain COW after `fork`.
- Explain why `copy_from_user` and `copy_to_user` are security boundaries.
- Explain RCU/refcount/lifetime risk in a kernel object that is shared across syscalls.

### Phase 3 - Syscalls, ELF, VFS, File Descriptors, io_uring

Primary questions:

- How does syscall entry differ from a normal function call?
- What is stable userspace ABI and why does the kernel care so much about it?
- How do file descriptors map to `struct file`, inode/dentry/superblock, and filesystem operations?
- What is the VFS layer?
- How do `/proc`, `/sys`, `debugfs`, and `tracefs` differ?
- How does io_uring change the userspace/kernel interaction model?
- What should you be able to prove about ELF loading, dynamic linker state, vDSO, and memory mappings?

Source files and references:

- `The Linux Programming Interface.pdf`
- `Practical Binary Analysis.pdf`
- `DW111-3-BinaryFormats-HavingFunWithBinaryFormat.pdf`
- `2025_Hexacon-Deja_Vu_in_Linux_io_uring_Breaking_Memory_Sharing_Again_After_Generations_of_Fixes.pdf`
- `Gayet Thierry - Linux Kernel Programming - 2025.pdf`

Proof drills:

- Walk `openat -> read -> close` through fd table, `struct file`, VFS, filesystem, page cache.
- Explain what makes io_uring an interesting attack surface without giving an exploit recipe.
- Explain how `/proc/<pid>/maps`, `/proc/<pid>/fd`, and `/proc/<pid>/status` reflect kernel objects.

### Phase 4 - Concurrency, Interrupts, Bottom Halves, RCU, Workqueues

Primary questions:

- What is preemption in kernel context?
- When do you use a spinlock, mutex, rwsem, seqlock, atomic, completion, waitqueue, or RCU?
- How do hard IRQ, softirq, tasklets, workqueues, timers, and kthreads differ?
- What is NAPI at a high level?
- Why are memory barriers and per-CPU data hard to reason about?
- What are common race bug shapes in kernel code?

Source files and references:

- `Interrupts and Bottom Halves in Linux Kernel`
- `Billimoria Kaiwan - Linux Kernel Debugging - 2022.pdf`
- `TheLinuxKernelMacroJourney_v1_Aug2024.pdf`
- `Racing_Against_the_Lock__Exploiting_Spinlock_UAF_in_the_Android_Kernel.pdf`

Proof drills:

- Explain why sleeping under a spinlock is bad.
- Explain RCU read-side critical sections and deferred freeing.
- Explain a race-to-UAF shape and what fixes usually look like: locking, refcounting, object state machine, or RCU.

### Phase 5 - Linux Security Model And Kernel Hardening

Primary questions:

- How do `uid`, `gid`, supplementary groups, `cred`, capabilities, and file capabilities interact?
- What do namespaces isolate, and what do they not isolate?
- How do cgroups relate to resource control rather than security boundaries?
- What does seccomp filter?
- Where do LSM hooks sit conceptually?
- What are AppArmor/SELinux/Landlock/BPF LSM at a high level?
- What is kernel lockdown, module signing, IMA/EVM, and why do they matter?
- What hardening features raise exploit cost in current kernels?

Source files and references:

- `TheLinuxSecurityJourney_v3_April2025.pdf`
- `TheLinuxSecurityJourneyWorkbook_v1_June2025.pdf`
- `Liz Rice - Learning eBPF_ Programming the Linux Kernel for Enhanced Observability, Networking, and Security-O'Reilly Media (2023).pdf`
- `DW145-3-eBPF_Zero-to-Hero.pdf`
- `DW70-1-Grsecurity.pdf` as historical context only
- `2018_oakland_linuxmalware.pdf` for taxonomy/academic context only, not tactics
- `musing-on-decades-of-linux-kernel-secres.pdf`

Proof drills:

- Explain why root inside a user namespace is not the same as initial-namespace root.
- Explain seccomp as attack-surface reduction.
- Explain why BPF is both a security tool and a historically sensitive kernel attack surface.
- Explain KASLR, SMEP/SMAP/PAN, KPTI, hardened usercopy, slab hardening, stack canaries, and CFI at the level of what class of primitive they frustrate.

### Phase 6 - Debugging, Tracing, Fuzzing, Source Navigation

Primary questions:

- How do you debug a kernel crash or warning?
- What are `dmesg`, oops, panic, taint flags, KASAN, UBSAN, KCSAN, KFENCE, lockdep?
- How do ftrace, perf, kprobes, uprobes, tracepoints, bpftrace, and BPF differ?
- What are BTF and CO-RE useful for?
- What does syzkaller do conceptually?
- What is LKL useful for in fuzzing/research?

Source files and references:

- `Kaiwan N Billimoria - Linux Kernel Debugging_ Leverage proven tools and advanced techniques to effectively debug Linux kernels and kernel modules-Packt Publishing (2022).pdf`
- `Billimoria Kaiwan - Linux Kernel Debugging - 2022.pdf`
- `Fuzzing Linux Kernel in Userspace with LKL.pdf`
- `LPC2024_ KUnit for Userspace.pdf`
- `linux-kernel-debugging.pdf`

Proof drills:

- Given a kernel warning, describe your first five triage steps.
- Explain how you would use tracepoints or bpftrace to validate a hypothesis.
- Explain what sanitizer you would choose for a race, UAF, OOB write, or uninitialized read.

### Phase 7 - Offensive Research Synthesis And Scenario Review

Primary questions:

- Given a bug report, can you identify the object lifetime, reachable interface, primitive, constraints, mitigation impact, and observability?
- Can you compare two subsystems by attack surface and complexity?
- Can you explain exploitability at a conceptual level without relying on a recipe?
- Can you propose a patch direction and tests?

Source files and references:

- `2025_HITCON-Compromising_Linux_the_Right_Way_0days_Novel_Techniques_and_Lessons_from_Failure.pdf`
- `2025_Hexacon-Deja_Vu_in_Linux_io_uring_Breaking_Memory_Sharing_Again_After_Generations_of_Fixes.pdf`
- `BSidesLJ_GuideToLinuxKernelExploitation.pdf`
- `Hexacon - Attacking the Linux Kernel.pdf`
- `exploiting-the-linux-kernel.pdf`
- `DW111-1-LinuxKernelPwn-First Steps to Linux Kernel Exploitation.pdf`
- `DW113-2-CVE-2019-2215-LinuxKernelLPE.pdf`
- `DW77-1-RaceCondition-dirtyc0w.pdf`

Proof drills:

- Explain an exploit primitive taxonomy: info leak, arbitrary read, arbitrary write, control-flow redirection, object replacement, refcount/lifetime abuse.
- Explain why a bug that looks severe may not be exploitable under modern hardening.
- Explain how you would responsibly validate impact in a lab kernel.
- Explain the patch: where the invariant should be enforced, how to avoid regressions, and what test/sanitizer would catch it.

## Minimal Theory Coverage

This roadmap is enough for theoretical OS internals coverage if you study the following topics actively, not passively:

- Process/thread model, context switching, scheduling, synchronization.
- Virtual memory, address translation, page faults, COW, page cache, allocators.
- Filesystems and I/O: VFS, file descriptors, inodes/dentries, block/page-cache path.
- IPC and userspace ABI: signals, pipes, sockets, shared memory, futexes, syscalls, ELF.
- Concurrency theory as used in real kernels: races, deadlocks, lock ordering, atomicity, RCU, memory ordering.
- Security boundaries: credentials, capabilities, namespaces, cgroups, seccomp, LSM, user/kernel memory boundary.
- Debugging theory: crash analysis, tracing, sanitizers, and source-to-runtime correlation.

Do not make full academic OS textbook completion a gate before practical progress. Use OSTEP/Tanenbaum/Stallings/Silberschatz only as targeted backup when you cannot explain a concept in your own words.

## Later Depth Expansion

Save these for after the core mechanism model is working:

- Full Bootlin kernel labs under `bootlin`.
- Device driver development books unless the interview is driver-heavy.
- Full embedded Linux material unless the role is embedded/Android/kernel driver focused.
- Academic OS course exams and lecture dumps.
- Historical Linux 2.6/3.x internals books. They help with lineage but can mislead on current data structures, locking, mitigations, and scheduler/memory details.

## Support Sources, Not First-Pass Gates

- `The Linux Programming Interface.pdf`: excellent userspace ABI/syscall reference, not kernel implementation.
- OSTEP/Remzi folders: good theory refresh, but only selected chapters.
- `book tenenbaum`: useful theoretical background, but too broad to drive the Linux internals track.
- `linux containers virt`: useful if container isolation is central to the role.
- `16151-exploiting-arm-linux-systems.pdf`: useful if ARM/Android comes up, otherwise secondary.

## Final Readiness Checklist

Before claiming readiness, be able to whiteboard these flows:

- `fork -> COW page fault -> execve`
- `openat/read` through fd table, VFS, page cache
- `mmap` and later page fault
- signal delivery to a multithreaded process
- futex uncontended vs contended path
- packet receive at a high level: driver/NAPI/sk_buff/socket
- BPF program loading: userspace API, verifier, maps, attach point
- seccomp/namespaces/cgroups as container-adjacent controls
- UAF/race bug lifecycle: root cause, primitive, mitigation impact, patch direction, test
