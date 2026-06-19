# Exact Linux Internals Source Map

Value Score: 75/100
Role: Linux source map
Proof Level: Source-map

Generated: 2026-05-12
Updated: 2026-05-16
Purpose: make the roadmap traceable. Each row says where to study the subject, not just which file is generally relevant.

## How To Read This

- `Primary` means use this first during the core mastery pass.
- `Support` means use it when the primary source is too shallow, too user-space-oriented, or missing a modern detail.
- `Future` means relevant after the core mechanism model works, or earlier if a target role/research problem explicitly needs it.
- This classification matters because source authority is not equal: current kernel docs/source should decide build-sensitive behavior, while books, slides, and older notes are best used as concept scaffolding or historical context.
- Packt chapter mappings were verified from local EPUB tables of contents.
- TLPI chapter mappings are against the local `The Linux Programming Interface.pdf`; the chapter list was cross-checked against Michael Kerrisk's official TLPI table of contents.
- Some PDF-only slide decks do not expose a clean TOC locally; for those I list the file and the exact topic/title that makes it relevant.

## Source Codes

| Code | Filename or source title | Use |
|---|---|---|
| KP24 | `Billimoria Kaiwan - Linux Kernel Programming, 2nd.Edition (Expert insight) - 2024.epub` and `.pdf` | Core kernel internals, modules, memory, scheduler, synchronization |
| KD22 | `Billimoria Kaiwan - Linux Kernel Debugging - 2022.epub` and `.pdf` | Debugging, tracing, sanitizers, lock debugging |
| TLPI | `The Linux Programming Interface.pdf` | Syscall semantics, process/file/signal/thread behavior from userspace ABI side |
| EBPF | `Liz Rice - Learning eBPF_ Programming the Linux Kernel for Enhanced Observability, Networking, and Security-O'Reilly Media (2023).pdf` | eBPF concepts, verifier, BTF/CO-RE, program types, BPF LSM |
| J-LIN-CONCEPT | `TheLinuxConceptJourney_v5_April2025.pdf` | Broad Linux concept bridge across processes, syscalls, memory, files, networking, and kernel boundaries |
| J-LIN-SEC | `TheLinuxSecurityJourney_v3_April2025.pdf` | Linux security model review: credentials, capabilities, namespaces, seccomp, LSMs, BPF/security hooks, and hardening |
| J-LIN-SEC-WB | `TheLinuxSecurityJourneyWorkbook_v1_June2025.pdf` | Active-recall drills for Linux security topics |
| J-AND-CONCEPT | `TheAndroidConceptJourney_v1_May2025 (1).pdf` | Android architecture and Linux-on-mobile concept bridge |
| J-NET | `TheNetworkingJourney_v2_May2025.pdf` | Networking concept bridge for packet flow, sockets, routing, filtering, DNS/TLS, and observability vocabulary |
| GAYET25 | `Gayet Thierry - Linux Kernel Programming - 2025.pdf` | Device model, VFS/block, network drivers, LSM, kernel memory/DMA, process management |
| IRQCOURSE | `[TutsNode.com] - Interrupts and Bottom Halves in Linux Kernel` | Interrupts, softirqs, tasklets, workqueues |
| PROCJ | `TheLinuxProcessJourney_v9_June2024.pdf` | Modern process/task walkthrough |
| DSJ | `TheLinuxKernelDataStructuresJourney_v2.0_April2024.pdf` | Kernel data structures, list/rbtree/maple-tree style orientation |
| MACROJ | `TheLinuxKernelMacroJourney_v1_Aug2024.pdf` | Kernel macro/data-structure reading support |
| CONT | `2020BookLinuxContainersAndVirtualizati.pdf` | Namespaces, cgroups, overlay/layered filesystems |
| LKL | `Fuzzing Linux Kernel in Userspace with LKL.pdf` | Kernel fuzzing in userspace with LKL |
| IOURING25 | `2025_Hexacon-Deja_Vu_in_Linux_io_uring_Breaking_Memory_Sharing_Again_After_Generations_of_Fixes.pdf` | Current io_uring research context |
| HITCON25 | `2025_HITCON-Compromising_Linux_the_Right_Way_0days_Novel_Techniques_and_Lessons_from_Failure.pdf` | Current Linux vulnerability research lessons |
| DW-LINUX | `Linux` | Hebrew Linux security articles by specific topic |
| DW134-185 | [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>) | Newer local Hebrew issue PDFs for Linux/eBPF/SLUB, Windows, firmware, and reversing case studies |
| KDOC-MM | `https://docs.kernel.org/mm/index.html` and linked MM pages | Current upstream Linux memory-management docs: process addresses, page tables, page cache, physical memory, reclaim, swap, OOM |
| KSRC-MM | Target kernel source tree: `include/linux/mm_types.h`, `mm/memory.c`, `mm/mmap.c`, `mm/filemap.c`, `mm/rmap.c`, `arch/<arch>/mm/fault.c` | Current source truth for address spaces and page faults |
| LKL-MM | `https://linux-kernel-labs.github.io/refs/heads/master/lectures/memory-management.html` | Guided teaching view of MM and page-fault concepts |
| LK26-HIST | `linux_kernel_v2.6_virtual memory manager` | Historical 2.6-era memory-manager material only |

## Subject-To-Source Matrix

| Subject | Primary exact location | Support / modern correction | What to extract |
|---|---|---|---|
| Kernel build, config, source tree, Kconfig/Kbuild | KP24 chapters 1-3 | Kernel docs: `kbuild`, `admin-guide`, `process` | How to navigate source, config symbols, modules, debug vs production builds |
| Broad Linux concept review | J-LIN-CONCEPT | Use before the deeper track if the terms feel fragmented | One-pass vocabulary for process, syscall, memory, files, networking, and kernel/user boundaries |
| Kernel modules, module loading, module params, module signing/lockdown | KP24 chapters 4-5 | GAYET25 chapters 2-5 for driver/module context | LKM lifecycle, init/exit, `printk`, module params, taint, signing, lockdown |
| Process vs thread, `task_struct`, kernel stack, `current` | KP24 chapter 6 | PROCJ; TLPI chapters 6 and 29 | `task_struct` orientation, TGID/PID distinction, current task, user/kernel stack split |
| `fork`, `clone`, `execve`, `exit`, `wait` | TLPI chapters 24-28 | PROCJ; KP24 chapter 6 for kernel object view | The syscall semantics first; then map to kernel objects and COW |
| Process credentials and privilege model | TLPI chapters 8-9 and 39 | man7 capabilities; GAYET25 chapter 9 for LSM context; J-LIN-SEC for review | UID/GID, saved/effective IDs, capabilities, `cred` as security-critical state |
| Scheduling fundamentals | KP24 chapters 10-11 | Linux docs: CFS and EEVDF scheduler pages; TLPI chapter 35 for userspace APIs | Run queues, policies/priorities, CPU affinity, cgroup impact, EEVDF as current fair scheduler context |
| cgroups from scheduling/resource-control angle | KP24 chapter 11 | CONT chapter 4; man7 cgroups | CPU/resource control, fairness/throttling, why cgroups are not a complete security boundary |
| Virtual address space and VMA basics | KDOC-MM `mm/process_addrs`; KSRC-MM `include/linux/mm_types.h`; [09-modern-linux-mm-reading-map.md](<09-modern-linux-mm-reading-map.md>) | KP24 chapter 7; PROCJ; DSJ | VAS layout, `mm_struct`, `vm_area_struct`, `/proc/<pid>/maps`, user/kernel split, VMA locking |
| Modern VMA lookup / maple tree | KDOC-MM `mm/process_addrs`; Linux docs `core-api/maple_tree`; KSRC-MM `mm/mmap.c` | DSJ; PROCJ | Old red-black-tree descriptions are historical; current kernels use Maple Tree for VMA indexing |
| Page faults and COW | KSRC-MM `arch/<arch>/mm/fault.c`, `mm/memory.c`, `mm/filemap.c`, `mm/rmap.c`; KDOC-MM `mm/process_addrs` and `mm/page_tables` | LKL-MM; TLPI chapters 49-50 for mapping APIs; KP24 chapter 7 for a secondary overview | Explain fault path conceptually: architecture exception, VMA lookup/locking, permissions, anonymous/file-backed/swap/COW resolution, PTE/TLB update, `SIGSEGV`/`SIGBUS` |
| Kernel allocators: page allocator, slab/slub, `kmalloc`, `vmalloc` | KP24 chapters 8-9 | KD22 chapters 5-6 for debugging allocator bugs; GAYET25 chapter 10 | Which allocator to use, object lifetime, GFP flags/context constraints, slab debugging |
| KASLR and address-space randomization | KP24 chapter 7 | Linux self-protection docs | What KASLR changes and what info leaks can undermine conceptually |
| VFS, file descriptors, filesystems | TLPI chapters 4-5, 13-18 | GAYET25 chapter 6; Linux VFS docs | fd table -> `struct file` -> VFS -> inode/dentry/superblock -> page cache |
| `mmap`, page cache, file-backed mappings | KDOC-MM `mm/page_cache`; KSRC-MM `mm/mmap.c`, `mm/filemap.c`, `fs/proc/task_mmu.c`; TLPI chapters 49-50 | KP24 chapter 7; LKL-MM | File-backed vs anonymous memory, shared/private mappings, page cache and folio relationship, `/proc` reporting |
| ELF, program execution, dynamic linking | TLPI chapters 27, 41-42 | `DW111-3-BinaryFormats-HavingFunWithBinaryFormat.pdf` in DW-LINUX | Loader path, interpreter/dynamic linker, shared objects, vDSO-style concepts |
| Syscall ABI and syscall tracing | TLPI chapter 3 | KD22 chapter 4; EBPF chapter 4 | Difference between libc wrapper and syscall; where tracing hooks can observe |
| Signals | TLPI chapters 20-22 | KP24 chapter 6 for task/process background | Process-directed vs thread-directed signals, delivery, handlers, masks |
| Futexes | TLPI thread/sync chapters 29-33 plus futex man pages | Linux futex docs/man pages | Userspace fast path vs kernel wait/wake path; enough for interview reasoning |
| Threads and pthread synchronization | TLPI chapters 29-33 | KP24 chapters 12-13 for kernel locking contrast | Thread identity, mutex/condvar semantics, user-level vs kernel-level synchronization |
| Kernel synchronization: mutex vs spinlock | KP24 chapter 12 | KD22 chapter 8; IRQCOURSE lessons 078-079 for softirq locking context | Sleepability, interrupt context, lock ordering, common mistakes |
| Atomics, refcounting, rwlocks, per-CPU, RCU, memory barriers | KP24 chapter 13 | Linux RCU docs; KD22 chapter 8 | Lifetime, atomicity, lock-free/per-CPU/RCU reasoning, memory ordering at interview level |
| Interrupt entry and hard IRQ concepts | IRQCOURSE lessons 001-014 and 015-025 | KP24 chapter 6 for process vs interrupt context | Exceptions/traps/faults, interrupt handler lookup, `/proc/interrupts`, context constraints |
| `request_irq`, IRQ flags, IRQ affinity | IRQCOURSE lessons 026-033 | Linux driver API docs | Shared IRQs, handler return values, SMP affinity, handler registration |
| Disabling IRQs and interrupt context pitfalls | IRQCOURSE lessons 034-049 | KP24 chapter 12 on locking and interrupts | Local IRQ state, `in_interrupt`, allocation restrictions, why sleeping in IRQ context is wrong |
| Threaded IRQs | IRQCOURSE lessons 050-058 | Linux docs for threaded IRQs | Top half vs threaded handler, `IRQF_ONESHOT`, what can sleep where |
| Softirqs | IRQCOURSE lessons 059-079 | Linux networking/NAPI docs if going deeper | `ksoftirqd`, pending softirqs, context, local bottom-half disabling, locking with softirqs |
| Packet flow and networking concepts | J-NET | Linux networking docs/source, EBPF chapter 8, and [memory/filesystems/network Q&A](<../02-question-banks/03-memory-filesystems-network-qa.md>) | Packet receive path, sockets, routing, filtering hooks, DNS/TLS vocabulary, and observability terms |
| Tasklets | IRQCOURSE lessons 080-104 | Treat as legacy/historical; modern kernels are moving away from tasklets | Know what they were used for and why modern code often prefers other mechanisms |
| Workqueues and delayed work | IRQCOURSE lessons 105-143 | KD22 chapter 10 for workqueue stalls | Worker pools, queueing/canceling/flushing, delayed work, dedicated workqueues, WQ flags |
| eBPF overview and why it matters | EBPF chapters 1-3 | Official kernel BPF docs | BPF VM/registers/instructions, maps, helpers, loading/attaching at concept level |
| `bpf()` syscall and userspace ABI | EBPF chapter 4 | man pages and kernel BPF docs | Program/map lifecycle and where privilege checks/verifier fit |
| BTF, CO-RE, libbpf | EBPF chapter 5 | Official BTF docs | Why BTF makes portable BPF observability/security tools possible |
| BPF verifier | EBPF chapter 6 | Official verifier docs | What safety properties the verifier checks; why verifier bugs are security-sensitive |
| BPF program and attach types | EBPF chapter 7 | Official BPF program type docs | kprobe, tracepoint, XDP, tc, cgroup, LSM categories at a comparison level |
| eBPF networking | EBPF chapter 8 | Linux XDP/docs | Packet path attachment points and policy/observability uses |
| eBPF security and BPF LSM | EBPF chapter 9 | Linux LSM/BPF LSM docs; DW145 eBPF article | LSM attachment concept, not bypass recipes |
| Kernel tracing: printk, dynamic debug, kprobes, ftrace, perf | KD22 chapters 3-4 and 9 | EBPF chapter 7 for BPF tracing attach types | Choose the right tool for a hypothesis; know stability and overhead tradeoffs |
| KASAN, UBSAN, SLUB debug, kmemleak | KD22 chapters 5-6 | Linux dev-tools docs | Which bug classes each catches and how to interpret reports |
| Oops/panic/hangs/lockups | KD22 chapters 7 and 10 | KD22 chapter 12 for crash/kdump | Read an oops, map instruction/address to source, understand panic/lockup detectors |
| KCSAN and lock debugging | KD22 chapter 8 | KP24 chapters 12-13 | Race detection, lockdep-style thinking, false positives/triage |
| KGDB and crash/kdump | KD22 chapters 11-12 | Optional unless role asks for hands-on kernel debugging | Remote debugging, crash dump reasoning, static analysis/testing |
| Namespaces | CONT chapter 3 | man7 namespaces; kernel namespace docs | UTS/PID/mount/network/IPC/cgroup/time namespaces and what each isolates |
| Cgroups | CONT chapter 4; KP24 chapter 11 | man7 cgroups | Controllers, CPU/I/O control, resource isolation vs privilege isolation |
| Overlay/layered filesystems | CONT chapter 5 | Linux overlayfs docs | Container filesystem layering and its security implications |
| Seccomp | man7 seccomp and kernel seccomp filter docs | EBPF chapter 1 for historical seccomp-BPF context; J-LIN-SEC | Syscall filtering model; attack-surface reduction |
| LSM, SELinux/AppArmor/Landlock/BPF LSM | GAYET25 chapter 9 | Linux LSM docs; EBPF chapter 9; J-LIN-SEC | Hook model, policy-enforcement location, stacking at high level |
| Kernel self-protection/hardening | Linux self-protection docs | KP24 chapter 5 for module signing/lockdown; KP24 chapter 7 for KASLR; J-LIN-SEC and J-LIN-SEC-WB for recall | KASLR, SMEP/SMAP/PAN, KPTI, hardened usercopy, slab hardening, CFI, lockdown |
| Android architecture above Linux | J-AND-CONCEPT | [Android internals](<04-android-internals.md>) and AOSP/device-specific sources | Zygote, Binder, ART, SELinux, app UID sandboxing, low-memory policy, and native hardening |
| io_uring architecture and attack surface | IOURING25 | man7 io_uring; kernel io_uring docs | SQ/CQ rings, registered buffers/files, worker context, why shared memory and async state are hard |
| Kernel fuzzing workflow | LKL | KD22 chapters 5-8 for sanitizer triage | Fuzzer -> crash -> minimize -> root cause -> patch/test; LKL as userspace kernel harness concept |
| Current offensive Linux research framing | HITCON25; IOURING25 | DW-LINUX specific articles | Use these for case-study questions: bug class, primitive, constraints, mitigation, patch |
| Newer Hebrew Linux case studies | DW134-185 Linux section | Current kernel docs/source remain primary | Use glibc heap, PwnKit, eBPF, modprobe_path, GOT overwrite, Linux Process Hollowing, Linux persistence, kernel exploitation, Android firmware, and SLUB papers as support, then verify against the target kernel/config |

## Hebrew DigitalWhisper Files By Topic

| Topic | Exact file |
|---|---|
| Linux kernel exploitation intro | `DW111-1-LinuxKernelPwn-First Steps to Linux Kernel Exploitation.pdf` |
| ELF / binary formats | `DW111-3-BinaryFormats-HavingFunWithBinaryFormat.pdf` |
| Android/Linux kernel LPE case study | `DW113-2-CVE-2019-2215-LinuxKernelLPE.pdf` |
| Syscall hijacking, historical/offensive context | `DW114-3-SyscallHijacking.pdf` |
| SMM vulnerability background | `DW120-1-SMMVulnIntro-CVE 2020 12890.pdf` |
| Kernel SO injection, historical/offensive context | `DW124-3-KernelSOInjector.pdf` |
| PCI/security hardware angle | `DW138-2-FunWithPCI.pdf` |
| eBPF intro | `DW145-3-eBPF_Zero-to-Hero.pdf` |
| Grsecurity/hardening historical context | `DW70-1-Grsecurity.pdf` |
| Dirty COW/race condition case study | `DW77-1-RaceCondition-dirtyc0w.pdf` |
| Docker/container background | `Docker - מנפצים את הקופסה השחורה.pdf` and `Am I Docker Containers deep dive.pdf` |
| SELinux practical Hebrew support | `SELinux - The Practical Way - חלק ב'.pdf` and `SELinux - Linux - The Secure Way - חלק א'.pdf` |
| Linux kernel SO injection / rootkit / keylogger historical context | `Linux kernel so Injector.pdf`, `פיתוח KeyLogger קרנלי בלינוקס.pdf`, and `פיתוח Rootkit בלינוקס - חלק ב'.pdf` |
| glibc `FILE` structure exploitation background | `על הדבש ועל הקובץ - Pwning FILE structs חלק א'.pdf` and `חלק ב' Pwning FILE structs - על הדבש ועל הקובץ.pdf` |
| WSL cross-OS boundary | `Windows Subsystem for Linux - המכונה שתמיד רציתם.pdf` |

Treat the local older Digital Whisper Linux papers as vocabulary and case-study support. Kernel module, rootkit, `modprobe_path`, allocator, and container details are highly version/config dependent; current kernel docs/source remain authoritative.

## Core Long-Term Reading Order With Exact Sources

The order below is dependency order, not a deadline. Move forward when you can connect the source, runtime evidence, and failure modes well enough to use the concept in a debugging or vulnerability-research discussion.

### Phase 1 - Processes And Scheduling

Read:

- J-LIN-CONCEPT if you need a fast vocabulary refresh before the deeper source work.
- KP24 chapter 6: process/thread internals.
- TLPI chapters 6, 24-28, 29, and 35: process creation, execution, threads, scheduling APIs.
- KP24 chapters 10-11: scheduler internals and cgroup scheduling angle.
- Linux docs: EEVDF scheduler page.

Skip:

- Full university OS scheduling lectures unless you cannot explain preemption, context switch, and run queues.

### Phase 2 - Memory Management

Read:

- [09-modern-linux-mm-reading-map.md](<09-modern-linux-mm-reading-map.md>): current replacement path for old 2.6/Chapter 9 memory-manager material.
- Kernel docs: `mm/process_addrs`, `mm/page_tables`, `mm/page_cache`, `mm/physical_memory`, and `core-api/maple_tree`.
- Target kernel source: `include/linux/mm_types.h`, `mm/mmap.c`, `arch/<arch>/mm/fault.c`, `mm/memory.c`, `mm/filemap.c`, and `mm/rmap.c`.
- DSJ and MACROJ from `journey` for source-reading vocabulary around embedded lists, containers, trees, and kernel macro idioms.
- KP24 chapter 7: secondary overview of virtual address-space layout and VMA basics.
- KP24 chapters 8-9: page/slab/vmalloc allocators.
- TLPI chapters 49-50: memory mapping and virtual-memory operations.
- DSJ and PROCJ only for modern data-structure orientation.
- Linux Kernel Labs memory-management lecture if you want a guided explanation before source reading.

Skip:

- `Understanding the Linux Kernel - 3rd Edition.pdf` Chapter 9 as a primary source.
- `understanding the 2_6 linux kernel virtual memory manager.pdf` except as historical context.

### Phase 3 - Syscalls, Files, ELF, VFS

Read:

- TLPI chapters 3-5, 13-18: syscall model, file I/O, buffering, filesystems, attributes, directories.
- TLPI chapters 27, 41-42: program execution and shared libraries.
- GAYET25 chapter 6: VFS/block-driver angle.
- DW111-3 Hebrew binary-format article if you want ELF reinforcement.

Skip:

- Broad Linux command-line books; they do not answer kernel-internals interview questions.

### Phase 4 - Interrupts, Bottom Halves, Workqueues, Locking

Read/watch:

- IRQCOURSE lessons 015-049 for hard IRQ handling and interrupt-context constraints.
- IRQCOURSE lessons 050-058 for threaded IRQs.
- IRQCOURSE lessons 059-079 for softirqs.
- IRQCOURSE lessons 105-143 for workqueues.
- KP24 chapters 12-13 for mutex/spinlock/atomic/refcount/RCU/per-CPU/memory-barrier concepts.
- KD22 chapter 8 for lock/race debugging.

Skip:

- Deep tasklet implementation unless asked; know lessons 080-104 only as legacy background.

### Phase 5 - Security Boundaries

Read:

- TLPI chapters 8-9 and 39: users/groups, process credentials, capabilities.
- CONT chapters 3-5: namespaces, cgroups, layered filesystems.
- GAYET25 chapter 9: LSM.
- EBPF chapter 9: BPF LSM and security attachment concept.
- J-LIN-SEC for a full Linux security-model review and J-LIN-SEC-WB for active recall after the first pass.
- Official docs/man pages for seccomp, namespaces, cgroups, capabilities, LSM, and kernel self-protection.

Skip:

- Old rootkit/syscall-hooking material except to explain why it is detectable, brittle, or blocked by modern hardening.

### Phase 6 - Debugging, Tracing, Fuzzing

Read:

- KD22 chapters 3-4: printk/dynamic debug/kprobes.
- KD22 chapters 5-6: KASAN/UBSAN/SLUB debug/kmemleak.
- KD22 chapters 7-8: oops decoding and lock debugging/KCSAN.
- KD22 chapters 9-12: ftrace/perf/LTTng, panic/hang triage, KGDB, crash/kdump/testing.
- LKL fuzzing deck for fuzzing workflow.

Skip:

- Full KGDB setup unless hands-on debugging is expected.

### Phase 7 - eBPF, io_uring, Research Synthesis

Read:

- EBPF chapters 1-7: core BPF model, `bpf()` syscall, BTF/CO-RE, verifier, attach types.
- EBPF chapters 8-9: networking and security attachment points.
- IOURING25 for current io_uring attack-surface reasoning.
- HITCON25 for modern case-study framing.
- Selected DW-LINUX case studies: DW111-1, DW113-2, DW77-1.

Outcome:

- For every case study, write a five-line answer: entry point, kernel object/lifetime issue, primitive, mitigation impact, patch/test direction.

## Gaps Where Local Material Is Not Enough

Use official docs for these, because books/slides age quickly:

- EEVDF scheduler details.
- Maple tree/VMA locking details.
- Current BPF verifier and BTF details.
- Current io_uring interface details.
- LSM stacking/Landlock/BPF LSM details.
- Kernel self-protection/hardening status.
