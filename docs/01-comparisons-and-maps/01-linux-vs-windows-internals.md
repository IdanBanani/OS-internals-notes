# Linux vs Windows Internals Comparison

Value Score: 85/100
Role: Cross-platform translation map
Proof Level: Conceptual, read after labs

Date: 2026-05-15

Scope: high-signal analogies, differences, and transition guidance between Linux and Windows internals for interview prep, reversing, debugging, malware analysis, and OS research. The goal is to transfer Linux intuition safely while making the Windows mechanisms explicit enough to reason from first principles.

Dense-term companion: [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) expands and routes abbreviations such as IOMMU, page cache, VMA/VAD, PTE/PFN, IRP/MDL, LSM, RCU, eBPF, io_uring, ETW, AMSI, PPL, VBS/HVCI, CFG, and CET. Use it before treating a comparison row as something you understand.

Windows source companion: [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>) uses the local Windows 11 Internals subtitle set and PDFs to explain the Windows terms used throughout this comparison.

Windows object companion: [Windows object handles, references, and tokens](<../05-topic-notes/windows-object-handles-references-and-tokens.md>) expands the handle/fd analogy into handle-table entries, granted access, object pointer references, token APIs, and object residency caveats.

Windows IPC companion: [Windows IPC named pipes, RPC, ALPC, and security](<../05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>) expands the Unix socket/fd-passing analogy into named-pipe endpoints, RPC binding/auth/QoS, ALPC message attributes, and Windows impersonation traps.

Journey companion: [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) maps the local Linux, Windows, Android, networking, security, forensics, and workbook Journey PDFs into the study path. Use it when a comparison topic needs a gentler concept bridge or active-recall drill source.

## Mental Model

Linux is built around a Unix process/file model: processes form a real parent-child tree, file descriptors are central, many kernel objects are exposed as files or pseudo-files, and `fork`/`exec` shape process creation.

Windows is built around an object-manager model: processes, threads, files, sections, events, tokens, jobs, desktops, registry keys, and many other things are kernel objects referenced through handles. Parentage exists, but it is weaker than in Unix. Lifetime and authority are usually controlled by handles, access masks, tokens, and job objects, not by the process tree alone.

## Why The Designs Diverged

Linux inherits the Unix design center: small composable tools, hierarchical filesystems, byte streams, process trees, `fork`/`exec`, text-oriented administration, and a privileged superuser later refined with groups, capabilities, namespaces, cgroups, and LSMs. Its core abstractions were optimized for portability, interactive timesharing, pipes, shells, and a simple programming model where "open a thing, get an integer descriptor, read/write/ioctl it" scales across many resources.

Windows NT was designed around different pressures: a portable kernel, multiple user-mode personalities, strong per-object security, enterprise identity, GUI sessions, asynchronous I/O, installable filesystems/drivers, network servers, backward compatibility, and long-term binary compatibility for applications. That pushed the design toward typed kernel objects, handles with granted access, security descriptors, access tokens, section objects, IRP-based I/O, the registry, and a stable Win32 API above a less-stable Native API and syscall layer.

The result is not "Unix versus GUI." It is two different answers to "how do we make resources nameable, securable, shareable, waitable, observable, and compatible for decades?"

### Why Table

| Design choice | Why Linux tends this way | Why Windows tends this way |
|---|---|---|
| File descriptors everywhere | Unix wanted a small uniform I/O interface for files, pipes, terminals, sockets, and devices. | NT wanted a broader typed object model where many non-file resources can share naming, lifetime, waiting, auditing, and security. |
| Strong process tree | Shells, terminals, job control, `wait`, and `fork`/`exec` made parent-child lifecycle central. | Processes are securable objects. Lifetime is reference-counted by handles, and grouping/lifecycle policy is delegated to jobs, services, sessions, and explicit managers. |
| `fork` plus `exec` | Copy current execution context cheaply, then replace the image. This fits shells and POSIX process control. | Create a process from an image section with explicit attributes. This fits Win32 compatibility, handles, tokens, GUI/session state, threads, and subsystem-managed process parameters. |
| UID/GID plus capabilities | Simple identity model refined over time with capability splitting and LSM policy. | Enterprise/network security needed rich identities: SIDs, groups, privileges, impersonation, ACLs, integrity levels, service SIDs, AppContainer, and protection levels. |
| VFS and pseudo-files | Expose kernel and device state through filesystem-like interfaces that compose with shell tools. | Expose state through typed APIs, ETW, handles, WMI, debugger extensions, object namespaces, and management frameworks. |
| ELF dynamic linking | Symbol resolution and interposition are first-class Unix linking features. | PE/DLL loading emphasizes explicit import/export tables, compatibility, side-by-side policy, API sets, loader notifications, and per-process patching of IATs. |
| Text config under `/etc` | Human-editable files compose with shell tools, packages, and version control. | Registry hives provide structured, ACL-protected, per-machine/per-user configuration, policy, COM/service registration, and centralized management. |
| Kernel modules and subsystem hooks | Linux grew many subsystem-specific extension points plus eBPF as a constrained programmable layer. | Windows uses layered drivers, IRPs, minifilters, WFP, callbacks, ETW providers, signing policy, PatchGuard, and HVCI to balance extension and integrity. |
| `strace`-style syscall truth | Linux syscalls are a stable public ABI and often map closely to visible operations. | Win32 is the stable contract; many important behaviors happen before or around Native API calls, so ETW/Procmon often explains intent better than raw syscalls. |

## Transition Strategy for Linux Internals Readers

The fastest transition is to stop looking for exact Unix names and instead translate each operation into four questions:

- What object is being operated on?
- What authority is required?
- Which user-mode API layer is being used?
- What kernel subsystem eventually owns the decision?

On Linux, those answers often converge on process credentials, file descriptors, VFS objects, `task_struct`, `mm_struct`, syscalls, and pseudo-files under `/proc` or `/sys`. On Windows, they usually converge on handles, access masks, tokens, Object Manager objects, section objects, the I/O manager, the memory manager, the security reference monitor, ETW, and the PEB/TEB in user mode.

### First Windows Concepts To Relearn

| Linux instinct | Windows correction |
|---|---|
| "The process tree owns lifecycle." | Process parentage is mostly metadata. Handles, jobs, SCM, sessions, and tokens control lifecycle and authority. |
| "A syscall is the OS API." | Win32 is the documented app API, Native API is lower-level, and syscall numbers are private/build-specific details. |
| "Everything important is a file descriptor." | Many things are Object Manager objects referenced by handles with per-handle granted access masks. |
| "Open permissions are mostly path and mode bits." | Access checks combine token, desired access, object security descriptor, integrity level, privileges, and sometimes protection policy. |
| "`fork` copies the process and `exec` replaces it." | Normal Windows creation builds a new process around an image section and creates an initial thread. |
| "`mmap` is the common memory abstraction." | Windows splits reserve/commit/protect and uses section objects/views heavily for file, shared, and image mappings. |
| "`/proc` is the live state API." | Windows state is spread across Win32/Native APIs, ETW, WMI, Object Manager namespaces, debugger extensions, handles, and memory-manager structures. |
| "Shared libraries are ELF objects resolved by `ld-linux`." | DLLs are PE images loaded by the Windows loader, with IAT/EAT, API sets, TLS callbacks, `DllMain`, and side-by-side policy. |
| "Root is the final simple privilege." | SYSTEM, Administrators, privileges, integrity levels, service SIDs, AppContainer, PPL, and token impersonation create several authority layers. |
| "Kernel modules and syscalls explain most kernel attack/defense behavior." | Windows drivers, minifilters, WFP, callbacks, PatchGuard, HVCI, VBS, ETW, and PPL are central to modern behavior. |

### OS Layer Stack

| Layer | Linux mental model | Windows mental model |
|---|---|---|
| Application/framework | App, libc, language runtime, desktop toolkit | App, Win32, COM, .NET, UWP/WinRT where relevant, CRT/language runtime |
| Common user-mode OS API | libc/POSIX wrappers, libpthread, libdl | `kernel32`, `kernelbase`, `advapi32`, `user32`, `gdi32`, `ws2_32`, `shell32`, `ole32` |
| Lower user-mode API | raw syscall wrappers, vDSO, dynamic linker, subsystem libraries | `ntdll` Native API stubs, loader routines, user-mode portions of subsystem DLLs |
| Kernel entry | `syscall` ABI into syscall table | `ntdll` syscall stub into system service dispatch |
| Kernel core | scheduler, VFS, MM, networking, LSM, namespaces, cgroups | Executive, Object Manager, I/O manager, Memory Manager, Configuration Manager, Security Reference Monitor, Process Manager |
| Drivers/extensions | kernel modules, filesystem/network/device drivers, eBPF, LSM hooks | WDM/WDF drivers, file-system minifilters, registry/process/image callbacks, WFP/NDIS filters, ETW providers |
| Observability | `/proc`, `/sys`, audit, eBPF, ftrace, perf, journald | ETW, Event Log, WMI, Sysmon, Procmon, Process Explorer, WinDbg, object namespace and handle inspection |

### Translation Rules

- Translate Linux "descriptor" questions into Windows "handle plus object type plus granted access" questions.
- Translate Linux "UID/capability" questions into Windows "token SID/group/privilege/integrity/AppContainer/PPL" questions.
- Translate Linux "path in a filesystem namespace" questions into Windows "Win32 path, NT object path, device object, reparse point, registry, or named object namespace" questions.
- Translate Linux "VMA and `mmap`" questions into Windows "VAD, reserve/commit, protection, section object, and mapped view" questions.
- Translate Linux "shared object loader" questions into Windows "PE image, loader lock, IAT/EAT, API set, TLS callback, and `DllMain`" questions.
- Translate Linux "daemon supervision" questions into Windows "SCM service, service SID, session 0, service control protocol, scheduled task, or job object" questions.
- Translate Linux "kernel module hook" questions into Windows "driver object/device object/IRP path, minifilter, WFP, registry/process/image callback, or vulnerable signed driver" questions.

## Common Hardware Substrate

Linux and Windows expose very different user-mode APIs, kernel object models, and administration surfaces, but on the same machine they usually rely on almost identical hardware mechanisms. Most deep OS internals differences are about policy, data structures, and abstractions layered on top of the same CPU, MMU, interrupt, DMA, bus, firmware, and device mechanisms.

### CPU Privilege and Execution Modes

Both rely on hardware-enforced privilege separation.

- User code runs in an unprivileged mode: ring 3 on x86/x64, EL0 on ARM64.
- Kernel code runs in privileged mode: ring 0 on x86/x64, EL1 on ARM64.
- Privileged instructions, control registers, page-table management, interrupt control, and many MSRs are restricted to kernel/hypervisor levels.
- User-to-kernel transitions use hardware-defined mechanisms: `syscall`/`sysret`, `sysenter`/`sysexit`, interrupts, exceptions, or ARM exception calls.

The exact syscall ABI and dispatch tables differ, but the underlying hardware idea is the same: controlled transition from user mode to privileged kernel mode.

### Interrupts, Exceptions, and Traps

Both kernels depend on the same hardware event model.

- CPU exceptions: page fault, general protection fault, invalid opcode, divide error, breakpoint, debug exception.
- Hardware interrupts: timer, storage, network, USB, GPU, and other device interrupts.
- Software interrupts or trap-like transitions for debugging and system entry.
- Interrupt descriptor/vector tables: IDT on x86/x64, exception vector tables on ARM64.
- Per-CPU interrupt state and interrupt priority/masking rules.

Linux and Windows name and route these differently, but both must save CPU state, enter kernel handlers, dispatch the event, possibly schedule work later, and return or terminate the faulting context.

### Virtual Memory, MMU, Page Tables, and TLB

The MMU is one of the strongest common foundations.

- Per-process virtual address spaces.
- Page tables translating virtual addresses to physical frames.
- Hardware page permissions: present, writable, user/supervisor, executable/NX, dirty, accessed, cache policy.
- TLB caching of virtual-to-physical translations.
- Page faults for invalid, not-present, protected, or demand-loaded pages.
- Copy-on-write and shared file/image mappings.
- ASLR, DEP/NX, guard pages, and memory-mapped files/images.

Linux talks about VMAs, `mmap`, and `mm_struct`. Windows talks about VADs, sections, views, reserve/commit, and the PEB. Underneath, both kernels program page tables and handle page faults from the same MMU.

### CPU Caches, Coherency, and Atomic Operations

Both kernels are built around the same multicore memory realities.

- L1/L2/L3 caches.
- Cache-line sharing and false sharing.
- Hardware cache coherency protocols.
- Memory barriers/fences.
- Atomic read-modify-write operations such as compare-and-swap, exchange, fetch-add, bit operations.
- Per-CPU data to reduce contention.
- Spinlocks and lock-free algorithms built on atomic primitives.

Linux and Windows have different lock types and scheduler policies, but both must obey the same CPU memory-ordering and cache-coherency rules.

This matters because many "kernel race" bugs are really broken assumptions about visibility, ordering, and ownership across cores; the OS abstraction cannot make stale cache lines or missing barriers disappear.

### Timers and Time Sources

Both need hardware time for scheduling, profiling, timeouts, and accounting.

- Local APIC timers or architectural per-core timers.
- HPET or platform timers where applicable.
- TSC/invariant TSC on modern x86 systems.
- Periodic and tickless scheduling modes.
- High-resolution timers.
- Timer interrupts used to drive preemption, accounting, and timeouts.

The kernel timer wheel/queue implementations differ, but the hardware time sources are mostly the same.

This matters for security because timers drive preemption, race windows, timeout cleanup, profiling, sandbox limits, and anti-analysis timing checks; a timing artifact is often evidence of a lower-level scheduling or clock-source mechanism.

### Symmetric Multiprocessing and Scheduling Hardware

Both support the same physical CPU topology.

- Multiple logical processors.
- SMT/hyper-threading.
- Core, package, NUMA node, and cache topology.
- CPU affinity.
- Inter-processor interrupts.
- Per-CPU run queues or scheduling state.
- Processor groups or CPU sets when systems become large.

Scheduling policy is OS-specific, but both kernels must understand the same topology and send cross-CPU interrupts for rescheduling, TLB shootdowns, and synchronization.

The "why" is that a process is not running on an abstract CPU; it runs on a concrete core with cache, NUMA, interrupt, and sibling-thread effects that change latency, race reliability, and memory-visibility assumptions.

### DMA, IOMMU, and Device Isolation

Both kernels must control devices that can access memory directly.

- DMA lets devices read/write system memory without CPU copying.
- IOMMU/VT-d/AMD-Vi remaps and restricts device DMA.
- DMA remapping protects the kernel and other processes from malicious or buggy devices.
- Scatter/gather lists describe non-contiguous physical memory for devices.
- Bounce buffers may be needed for addressing or isolation constraints.

Linux exposes this through DMA APIs and IOMMU groups. Windows exposes it through WDM/WDF DMA abstractions and platform security features. The hardware problem is the same: devices are powerful bus masters and must be contained.

### PCIe, Device Enumeration, and Interrupt Delivery

Most modern devices are discovered and driven through common bus mechanisms.

- PCI/PCIe configuration space.
- BARs for MMIO regions.
- MSI/MSI-X interrupt delivery.
- ACPI-described platform devices.
- USB, NVMe, SATA, network, Bluetooth, GPU, and other device classes.
- Plug and Play style discovery, resource assignment, and driver binding.

Linux and Windows driver models are very different, but both must enumerate devices, map MMIO, configure interrupts, and coordinate power/resource ownership.

This is a trust boundary because MMIO and interrupts let device-controlled state enter kernel control flow; correct drivers must validate device state just as carefully as they validate user input.

### Firmware, Boot, and Platform Tables

Both rely on platform firmware before the kernel fully owns the machine.

- UEFI firmware loads the boot manager/bootloader.
- ACPI tables describe devices, interrupt routing, power states, NUMA topology, and platform configuration.
- SMBIOS/DMI exposes system inventory information.
- Secure Boot can verify early boot components.
- TPM can support measured boot, key sealing, attestation, and disk-encryption trust decisions.

The boot chains and policy choices differ, but UEFI, ACPI, and TPM are shared platform foundations.

### Virtualization Hardware

Modern Linux and Windows both use CPU virtualization extensions.

- Intel VT-x / AMD-V for guest execution.
- EPT / NPT nested page tables for guest physical memory translation.
- VM exits for privileged events.
- IOMMU support for device assignment and isolation.
- Second-level address translation for hypervisors, containers with stronger isolation, WSL2, VBS, Hyper-V, KVM, and cloud virtualization.

The hypervisors differ, but the CPU mechanisms are shared.

This matters because VBS, Hyper-V, KVM, WSL2, cloud guests, and sandboxed environments all rely on second-level translation and VM-exit policy to decide what the guest kernel can really control.

### Storage and Filesystem Hardware Interfaces

The filesystems differ, but storage hardware concepts are common.

- Block devices.
- NVMe submission/completion queues.
- SATA/SCSI command models.
- DMA-backed I/O.
- Flushes, barriers, FUA, write caching, discard/TRIM.
- Interrupt or polling completion paths.

Linux filesystems and NTFS/ReFS differ significantly, but both must turn file operations into block I/O, caching, writeback, and crash-consistency decisions over similar hardware.

The practical invariant is that "write returned" does not always mean "stable on media"; cache, flush, barrier, filesystem journal, and storage-controller behavior all shape durability and forensic evidence.

### Network Hardware

Both kernels interact with similar NIC mechanisms.

- RX/TX descriptor rings.
- DMA buffers.
- Interrupt moderation.
- MSI-X queue interrupts.
- Receive-side scaling / multi-queue NICs.
- Checksum offload, segmentation offload, large receive offload.
- Packet filtering and hardware timestamping on capable devices.

The Linux networking stack and Windows NDIS stack differ, but both are built around packet queues, DMA, interrupts, offloads, and per-CPU scaling.

This matters when attributing network behavior: offloads, queue steering, proxy layers, filtering frameworks, and packet capture points may each observe a different boundary in the same flow.

### Power Management and Thermal Control

Both kernels coordinate with the same platform power mechanisms.

- CPU C-states and P-states.
- Frequency scaling and turbo behavior.
- Sleep states and resume.
- Device power states.
- Thermal sensors and throttling.
- Battery and ACPI power events.

The policy engines differ, but both must negotiate with firmware and hardware to balance performance, latency, heat, and battery life.

Power state is security-relevant because sleep/resume, device power transitions, timer coalescing, and throttling change timing, device state, and what persistence or forensic artifacts survive a transition.

## Hardware Mechanism Mapping

| Hardware mechanism | Linux-facing concept | Windows-facing concept | What is mostly the same |
|---|---|---|---|
| CPU privilege modes | user/kernel mode, rings, capabilities only after kernel check | user/kernel mode, tokens checked by kernel/security reference monitor | Hardware prevents user code from executing privileged operations |
| Syscall entry | libc -> syscall ABI -> kernel syscall table | Win32/Native API -> `ntdll` stub -> system service dispatch | Controlled CPU transition from user to kernel |
| Page tables/MMU | `mm_struct`, VMAs, `mmap`, page fault handler | VADs, sections/views, `VirtualAlloc`, page fault handler | Virtual-to-physical translation and page faults |
| TLB | TLB flush/shootdown | TLB flush/shootdown | Per-CPU translation cache invalidation |
| Interrupts | IRQ handlers, softirq/tasklet/workqueue | ISRs, DPCs, work items | Hardware event enters kernel, deferred work handles slower processing |
| Timers | scheduler tick, hrtimers, tickless kernel | clock/timer interrupts, high-resolution timers | Hardware time drives preemption and timeouts |
| Atomic ops | futexes, spinlocks, atomics | dispatcher locks, push locks, interlocked operations | CPU atomic instructions and memory barriers |
| DMA | DMA API, IOMMU groups | DMA adapters, map registers, IOMMU/DMA remapping | Devices access memory under OS/IOMMU control |
| PCIe/MMIO | PCI core, BAR mapping, drivers | PnP manager, resource descriptors, drivers | Device discovery, MMIO mapping, interrupt assignment |
| Firmware tables | UEFI, ACPI, SMBIOS | UEFI, ACPI, SMBIOS | Firmware describes platform topology and boot state |
| Virtualization | KVM, namespaces plus virtualization options | Hyper-V, VBS, WSL2, containers | VT-x/AMD-V, EPT/NPT, IOMMU |

## Where Hardware Similarity Does Not Mean OS Similarity

- Same MMU, different memory manager: Linux VMAs and Windows VADs/sections lead to different debugging and telemetry.
- Same syscall instruction, different ABI stability: Linux syscall numbers are part of a public ABI; Windows SSNs are not a stable application contract.
- Same interrupts, different deferred-execution model: Linux softirqs/workqueues are not Windows DPCs/APCs, even if they solve related problems.
- Same DMA hardware, different driver contracts: Linux driver APIs and Windows WDM/WDF contracts differ sharply.
- Same UEFI/ACPI/TPM, different boot trust policy: Secure Boot, BitLocker, measured boot, kernel lockdown, and VBS are OS-policy dependent.

## Source and Symbol Structure Names

The comparison uses some structure names, but a serious internals study should separate **Linux source-level structs** from **Windows symbol/WDK/debugger-visible structs**.

Linux kernel structures are visible in source code, but layouts change by kernel version, architecture, and config. Windows kernel source is not public; many Windows names below come from WDK headers, public symbols, WinDbg type information, and Windows Internals research. Treat undocumented Windows layouts as build-specific.

| Area | Linux source structures | Windows structures / symbols | Why it matters |
|---|---|---|---|
| Process identity and lifetime | `task_struct`, `pid`, `upid`, `signal_struct`, `sighand_struct`, `nsproxy` | `_EPROCESS`, `_KPROCESS`, `_CLIENT_ID`, `_PEB` | Linux parentage is in `task_struct` relationships such as parent/children. Windows parentage is mostly metadata in process structures; object lifetime is handle/reference based. |
| Threads and scheduling | `task_struct`, `thread_info`, `pt_regs`, `sched_entity`, `rq`, `cfs_rq` | `_ETHREAD`, `_KTHREAD`, `_KTRAP_FRAME`, `_KAPC_STATE`, `_KPCR`, `_KPRCB` | Linux tasks are the scheduler unit. Windows has explicit process/thread split, with dispatcher state on `KTHREAD` and per-CPU state in `KPCR`/`KPRCB`. |
| Address space and mappings | `mm_struct`, `vm_area_struct`, `maple_tree`, `page`, `folio`, `address_space` | `_MMVAD`, `_MMVAD_SHORT`, `_CONTROL_AREA`, `_SUBSECTION`, `_SEGMENT`, `_MMPTE`, `_MMPFN` | Linux VMAs and Windows VADs are the key memory-map analogy. Both ultimately describe virtual ranges backed by files, images, shared memory, or private committed memory. |
| Executable image and loader state | ELF headers, `linux_binprm`, user-mode `link_map`, `r_debug` | `_PEB`, `_TEB`, `_PEB_LDR_DATA`, `_LDR_DATA_TABLE_ENTRY`, `_RTL_USER_PROCESS_PARAMETERS`, `_IMAGE_NT_HEADERS`, `_IMAGE_IMPORT_DESCRIPTOR`, `_IMAGE_TLS_DIRECTORY` | Linux ELF loader state and Windows PEB loader lists both explain loaded modules, imports, TLS/pre-entry behavior, and debugger module views. |
| File descriptors and handles | `files_struct`, `fdtable`, `file`, `path`, `dentry`, `inode`, `super_block`, `file_operations` | `_HANDLE_TABLE`, `_HANDLE_TABLE_ENTRY`, `_OBJECT_HEADER`, `_OBJECT_TYPE`, `_FILE_OBJECT` | Linux FDs point toward `struct file`; Windows handles point to Object Manager objects with granted access and object headers. |
| Security credentials | `cred`, `group_info`, `user_namespace`, LSM blobs | `_TOKEN`, `_SID`, `_SEP_TOKEN_PRIVILEGES`, `_SECURITY_DESCRIPTOR`, `_ACL`, ACE structures | Linux credentials are UID/GID/capability/LSM based. Windows authorization centers on access tokens and security descriptors. |
| IPC and synchronization | `pipe_inode_info`, `socket`, `sock`, `sk_buff`, `futex_q`, `wait_queue_head`, `semaphore`, `mutex` | `_KEVENT`, `_KMUTANT`, `_KSEMAPHORE`, `_ERESOURCE`, `_EX_PUSH_LOCK`, `_KWAIT_BLOCK`, `_ALPC_PORT` | Both kernels need wait queues and synchronization objects, but Windows exposes many waitable dispatcher objects through handles. |
| I/O and drivers | `device`, `device_driver`, `bus_type`, `pci_dev`, `usb_device`, `request_queue`, `request`, `bio` | `_DRIVER_OBJECT`, `_DEVICE_OBJECT`, `_FILE_OBJECT`, `_IRP`, `_IO_STACK_LOCATION`, `_MDL`, `_KINTERRUPT`, `_KDPC` | Linux driver callbacks center around subsystem-specific structs. Windows I/O manager paths center around device objects and IRPs. |
| Networking | `net_device`, `napi_struct`, `sk_buff`, `sock`, `net`, `rtnl_link_ops` | NDIS structures such as `NET_BUFFER`, `NET_BUFFER_LIST`, miniport/adapter state, WFP callout/filter structures | The packet path differs, but both need NIC queues, packet buffers, offload metadata, and per-CPU scaling. |
| Containers and grouping | `cgroup`, `css_set`, `pid_namespace`, `mnt_namespace`, `net`, `ipc_namespace`, `uts_namespace`, `user_namespace` | `_EJOB`, silo-related kernel structures, `_TOKEN`, AppContainer/lowbox token state | Linux containers are namespace/cgroup heavy. Windows grouping and isolation use jobs, silos, sessions, AppContainer tokens, and sometimes Hyper-V isolation. |
| Timers and deferred work | `timer_list`, `hrtimer`, `work_struct`, `tasklet_struct`, softirq state | `_KTIMER`, `_KDPC`, `_KAPC`, work queues, threadpool/user APC state | Similar hardware events, different deferred execution models. Linux softirq/workqueue intuition only partially maps to Windows DPC/APC/work items. |

### Structure Names To Search First

For Linux source reading, start with:

- `struct task_struct` for process/thread relationships.
- `struct mm_struct` and `struct vm_area_struct` for address spaces.
- `struct files_struct`, `struct fdtable`, and `struct file` for file descriptors.
- `struct cred` for identity and authorization context.
- `struct inode`, `struct dentry`, and `struct super_block` for VFS.
- `struct sk_buff`, `struct sock`, and `struct net_device` for networking.
- `struct cgroup`, `struct css_set`, and namespace structs for containers.

For Windows debugger/symbol work, start with:

- `dt nt!_EPROCESS`, `dt nt!_KPROCESS`, `dt nt!_ETHREAD`, `dt nt!_KTHREAD`.
- `dt ntdll!_PEB`, `dt ntdll!_TEB`, `dt ntdll!_PEB_LDR_DATA`.
- `dt nt!_HANDLE_TABLE`, `dt nt!_OBJECT_HEADER`, `dt nt!_OBJECT_TYPE`.
- `dt nt!_TOKEN`, plus security descriptors and SID/ACL structures from headers/symbols.
- `dt nt!_MMVAD_SHORT`, `dt nt!_CONTROL_AREA`, `dt nt!_MMPTE`.
- `dt nt!_FILE_OBJECT`, `dt nt!_DEVICE_OBJECT`, `dt nt!_DRIVER_OBJECT`, `dt nt!_IRP`.
- `dt nt!_KTRAP_FRAME`, `dt nt!_KPCR`, `dt nt!_KPRCB`, `dt nt!_KDPC`, `dt nt!_KAPC`.

### Important Caveats

- Do not assume a structure with a similar job has a similar layout. `task_struct` and `_EPROCESS` are conceptual peers, not layout peers.
- Linux source names are authoritative for a specific kernel tree, but fields move over time.
- Windows public symbols are excellent for debugging, but many fields are undocumented and can change between builds.
- WDK structures such as `_IRP`, `_IO_STACK_LOCATION`, `_DEVICE_OBJECT`, `_DRIVER_OBJECT`, `UNICODE_STRING`, `OBJECT_ATTRIBUTES`, and `CLIENT_ID` are safer study anchors than private memory-manager or scheduler structs.
- ReactOS can help with Windows-like concepts, but it is not authoritative for modern Windows internals.

## From Textbook Objects To Kernel Structure Graphs

Textbook OS terms such as process control block, thread control block, page table, process table, open-file table, and scheduling queue are useful starting points, but real kernels implement them as graphs of structures. A "process" is not one record. It is a schedulable entity, an address space, credentials, file/handle state, namespaces or sessions, security labels, parent or job relationships, loader metadata, and many lookup indexes tied together by pointers, embedded list nodes, trees, locks, and reference counts.

The practical skill is to ask which structure answers which question:

| Question | Linux structure path | Windows structure path |
|---|---|---|
| What is scheduled? | `task_struct` plus `sched_entity` on a per-CPU run queue. | `_ETHREAD` / `_KTHREAD` on dispatcher scheduler state. |
| What is the process container? | A thread group: tasks sharing `mm_struct`, `signal_struct`, `files_struct`, and related state. | `_EPROCESS`, which contains or points to executive, memory-manager, security, handle, and process-wide state. |
| What is the address space? | `task_struct->mm` points to `mm_struct`; VMAs live in the mm's VMA index. | The process object owns address-space state; VADs describe user virtual ranges. |
| What backs a memory range? | `vm_area_struct` points through file, anonymous, page-cache, or `vm_ops` state; PTEs point to physical pages when resident. | VADs describe the range; section/control-area/subsection state backs mapped or image views; PTEs/PFN database describe resident translation state. |
| What authority is used? | `cred`, capabilities, namespaces, LSM blobs, fd mode and object metadata. | `_TOKEN`, privileges, integrity, security descriptors, handle granted access, protection policy. |
| How is the object found quickly? | PID hashes/IDRs, fd tables, XArrays, VMA Maple Tree, lists under RCU, per-CPU queues. | Handle tables, object directories, process/thread ID lookup, VAD trees, dispatcher queues, active lists. |
| What keeps it alive? | Refcounts, RCU grace periods, locks, task and object lifetime rules. | Object references, handles, rundown protection, push locks, dispatcher references, memory-manager references. |

### Embedded List Nodes: `list_head` And `LIST_ENTRY`

Both kernels use the same low-level trick everywhere: a generic list node is embedded inside the real object. The list pointer is not the process, thread, VMA, driver, or file object. It is a small field inside that larger object. Code recovers the containing object with `container_of()` on Linux or `CONTAINING_RECORD`-style logic on Windows.

| Concept | Linux | Windows | Why it matters |
|---|---|---|---|
| Generic doubly linked list node | `struct list_head` | `LIST_ENTRY` | Both are usually circular doubly linked lists with a sentinel head. |
| Process enumeration example | `task_struct::tasks` participates in global task iteration under locking/RCU rules. | `_EPROCESS.ActiveProcessLinks` links processes in the active process list. | Unlinking one field changes one enumeration path, not the whole truth of process existence. |
| Parent/child example | `task_struct` has parent/child/sibling relationship nodes and thread-group links. | Parentage is metadata; grouping is more often jobs, sessions, handles, and service state. | Linux lineage is structural and lifecycle-relevant; Windows lineage is weaker. |
| Thread list example | Threads are `task_struct` objects connected by thread-group state. | Process/thread structures contain list entries for process thread lists and scheduler/wait state. Exact private field names vary by build. | A thread can be visible through thread lists, scheduler state, handles, ETW, and stacks. |
| Driver/kernel-object example | Modules, devices, LRU pages, timers, work items, and many subsystem objects embed list nodes. | Drivers, devices, IRPs, DPCs, timers, APCs, and many executive objects embed list entries. | The same object can be on several lists at once through different embedded fields. |

This is where many "OS theory to practice" mistakes happen. If a debugger shows a pointer to `ActiveProcessLinks` or a Linux `list_head`, that pointer is to the embedded linkage field. The owning process object is at an offset around it. A rootkit-style unlink, a corruption bug, or a stale iterator can affect one list without destroying the object, its address space, its handles, its scheduler state, or its memory mappings.

### Balanced Trees: VMAs, VADs, Scheduler Timelines

Lists are good for insertion and ordered walking, but they are poor for "find the range containing this address" or "find the next runnable entity by ordering key." Real kernels therefore use trees, arrays, radix-like indexes, and per-CPU queues alongside linked lists.

| Use case | Linux | Windows | Practical interpretation |
|---|---|---|---|
| User virtual memory ranges | Modern Linux stores VMAs for an `mm_struct` in a Maple Tree. Older code and older study material often discuss a VMA red-black tree. | Windows stores VADs in a balanced tree rooted in process memory-manager state. Debugger symbols often expose VAD nodes through private `_MMVAD*` types. | VMA and VAD are the range-policy layer. They are not PTEs and are not physical pages. |
| Scheduler ordering | Fair scheduling has historically used `sched_entity` nodes in a per-run-queue red-black tree. Current scheduler details evolve, but the key idea is ordered runnable entities, not a single global process list. | Windows schedules threads using per-processor dispatcher/scheduler state, priority queues, ready lists, wait blocks, quantum/priority logic, and `_KTHREAD` state. | A task/thread can exist but not be runnable; runnable state lives in scheduler data, not merely in the process object. |
| Timers and deferred work | Linux uses timer wheels, hrtimer rbtrees, workqueues, softirq state, and per-CPU structures depending on mechanism. | Windows uses `_KTIMER`, `_KDPC`, APCs, work items, timer queues, and per-CPU dispatcher state. | Time-ordered work is usually indexed separately from process/thread enumeration. |
| File/page/cache indexes | Linux uses XArray/radix-like indexes, page-cache state, inode/address_space structures, and lists for reclaim/LRU. | Windows uses Cache Manager and Memory Manager structures, section/control-area state, prototype PTEs, and PFN database state. | File-backed memory is found through cache/mapping structures, not by walking "processes." |
| Handle/fd lookup | Linux fd numbers index an fd table that points to `struct file`. | Windows handle values index a per-process handle table entry with granted access and an object reference. | Lookup tables carry authority and lifetime; they are not just convenience arrays. |

Correction to a common shorthand: `task_struct` itself is not "the rbtree process node." A task embeds or references several linkage objects. For example, process iteration, parent/child linkage, thread-group linkage, PID lookup, and scheduler placement are separate relationships. Similarly, `vm_area_struct` used to be strongly associated with red-black VMA trees in older Linux kernels, but current kernels use Maple Tree for VMA indexing. Red-black trees remain important in the kernel, but the exact subsystem and kernel version matter.

### Process Control Block Mapping

The phrase process control block maps differently on the two systems.

| Textbook idea | Linux practice | Windows practice |
|---|---|---|
| PCB as the process record | Linux does not usually teach a separately named PCB. `task_struct` is the central schedulable-task structure, and process-wide state is split into shared structures such as `mm_struct`, `files_struct`, `fs_struct`, `signal_struct`, `sighand_struct`, `cred`, and namespace pointers. | Windows has `_EPROCESS` as the executive process object. It contains an embedded `_KPROCESS` field historically visible as the process control block or `Pcb`, but `_KPROCESS` is not the whole process. |
| TCB as the thread record | Linux threads are tasks. A thread is a `task_struct` sharing selected resources with other tasks in the same thread group. Architecture-specific thread state is split into kernel stack, `thread_struct`, and saved register/trap-frame state. | Windows has `_ETHREAD` as the executive thread object and `_KTHREAD` as the kernel dispatcher/scheduler thread block. User-mode thread state is also reflected in the TEB. |
| Process table | Linux has multiple views: PID namespaces and `struct pid`, task lists, `/proc`, cgroups, scheduler queues, and RCU-protected lookup paths. | Windows has multiple views: active process list, handle/object references, process/thread ID lookup, jobs, sessions, ETW events, debugger extensions, and memory-manager state. |
| Address-space pointer | `task_struct->mm` for user tasks, with `active_mm` rules for kernel threads. | Address-space state belongs to the process object; kernel symbols expose process memory-manager fields, VAD root, page-directory/base fields, and working-set related state by build. |
| Open-object authority | `files_struct` and `fdtable` point to `struct file`; each `struct file` has mode, operations, path, refcount, and private data. | `_EPROCESS` points to a handle table; each handle entry records granted access and references an Object Manager object. |

The important distinction is that Linux makes the schedulable task the central structure and builds a Unix process as a group of tasks sharing resources. Windows makes process and thread distinct executive objects: process for address space, handles, token, sections, job/session membership, and process-wide state; thread for execution, waits, APCs, stack, and scheduling.

### Memory-Management Structure Layers

A useful cross-platform rule: do not collapse range policy, hardware translation, physical-page metadata, and file backing into one mental object.

| Layer | Linux | Windows | What can go wrong if confused |
|---|---|---|---|
| Range policy | `vm_area_struct` in the `mm_struct` VMA index. | VADs such as `_MMVAD*` nodes in the process VAD tree. | Seeing a legal range does not mean every page is resident or writable now. |
| Hardware translation | Page-table levels and PTEs. | Page-table levels and PTEs, including prototype/software PTE states. | Seeing a PTE does not explain the higher-level mapping policy by itself. |
| Physical page metadata | `struct page` / folio, LRU/reclaim, refcount/mapcount, page-cache or anonymous state. | PFN database entries, working-set state, page lists, share counts, modified/standby state. | A physical page can be shared, COW, pinned, reclaimable, or file-backed. |
| File or image backing | `address_space`, page cache, inode/file, VMA file pointer, `vm_ops`. | Section object, control area, subsection, segment, file object, image section state. | Disk, loader metadata, and mapped memory can disagree after COW, deletion, replacement, or manual mapping. |
| User-mode loader view | ELF interpreter and runtime linker metadata such as `link_map`. | PEB loader lists and `LDR_DATA_TABLE_ENTRY` state. | Loader lists are useful but not authoritative; memory manager state can reveal hidden or manually mapped code. |

For Linux memory debugging, the path is usually:

`task_struct -> mm_struct -> VMA index -> vm_area_struct -> page tables/PTE -> struct page or folio -> page cache/file or anonymous state`

For Windows memory debugging, the path is usually:

`_EPROCESS -> VAD tree -> VAD -> section/control-area/subsection or private commit -> PTE/PFN state -> file/image/pagefile/private backing`

These paths explain why `/proc/<pid>/maps` and VMAs are the first Linux memory view, while VMMap, `!address`, `!vad`, section objects, and private/mapped/image classification are the first Windows memory view.

### Process And Thread Enumeration Is A Cross-View Problem

Process enumeration is where list/tree theory becomes practical. There is rarely one authoritative list that proves the whole system state.

| Investigation question | Linux views to compare | Windows views to compare |
|---|---|---|
| Is the task/process alive? | PID namespace lookup, `/proc`, task list, scheduler state, cgroups, audit/ftrace/eBPF, open fds, memory mappings. | Active process list, process handles, PID/CID lookup as exposed by tools, ETW process events, jobs/sessions, thread list, VADs, object references. |
| Is a thread running or waiting? | `task_struct` state, run queue, wait queue, kernel stack, futex/wait-channel traces. | `_KTHREAD` state, wait blocks, dispatcher objects, APC state, stack, ETW thread events. |
| Is memory legitimate? | VMA flags, backing file, deleted mappings, page-cache state, PTEs, `smaps`, dynamic linker state. | VAD type, protection, commit, section backing, PEB loader list, image-load ETW, thread start address, page protections. |
| Is authority legitimate? | `cred`, capabilities, namespace context, LSM state, fd inheritance, setuid/file capability path. | token, privileges, integrity, AppContainer/PPL, handle granted access, impersonation, object security descriptor. |
| Could one view be lying? | Compare `/proc` with scheduler/cgroup/audit/kernel-memory views. | Compare Toolhelp/PSAPI/PEB with VADs, handles, ETW, object manager, and debugger views. |

This is why `ActiveProcessLinks` is important but not enough. It is one embedded doubly linked list field inside `_EPROCESS`. A process object may still have handles, threads, an address space, scheduler traces, ETW history, section objects, job/session membership, and VADs even if one enumeration list is corrupted or manipulated. The Linux equivalent lesson is that hiding from `/proc` or one `task_struct` list does not erase scheduler state, PID references, cgroup membership, open files, memory mappings, audit trails, or RCU-protected references.

### Structure-Level Transition Checklist

When moving from OS theory to a real Linux or Windows kernel, answer these in order:

1. Which object owns the policy: process, thread, memory range, file, socket, token, credential, driver, or section?
2. Which embedded node links it into the current list or tree?
3. Which lookup index finds it by PID, handle, fd, virtual address, timer deadline, key, or object name?
4. Which lock, RCU rule, rundown protection, or dispatcher rule protects the traversal?
5. Which reference count or handle keeps the object alive after it is removed from a visible list?
6. Which lower-level structure actually enforces the outcome: PTE, TLB, token/cred, handle entry, page-cache page, IRP, or scheduler queue?
7. Which independent view should agree if the system is healthy?

## Parent-Child Processes and Lifetime

This is one of the biggest differences.

### Linux

- A process has a parent PID (`PPID`) tracked by the kernel.
- Parent-child relationship is structurally important.
- Children normally outlive or die independently of the parent unless explicit signal/session/job-control behavior is used.
- When a parent exits, living children are reparented, usually to PID 1 or a subreaper such as `systemd`.
- When a child exits, it becomes a zombie until the parent collects its exit status with `wait`, `waitpid`, or related APIs.
- The process tree is meaningful for lifecycle, shells, job control, terminal sessions, and supervision.

### Windows

- A process can record an inherited-from process ID, but Windows does not enforce Unix-style parent ownership.
- There is no zombie process equivalent that waits for the parent to reap it.
- Process exit status is stored in the process object and can be read by any process with a suitable handle.
- A parent can exit while the child continues normally.
- A process object remains alive after termination as long as handles to it remain open.
- Lifetime control is commonly done with job objects, service control, handles, tokens, sessions, and explicit policy rather than the parent-child tree.

### Analogy and Breakpoint

Linux `PPID` is a core lifecycle relationship. Windows `InheritedFromUniqueProcessId` is mostly lineage metadata and a telemetry/debugging clue.

If you want a Windows mechanism closer to "kill this whole subtree" or "own this group", think **Job Object**, not parent process.

Why this exists: Unix process parentage is part of the programming model because `fork`, `exec`, signals, shells, terminals, and `wait` all revolve around the parent. Windows process parentage is not the main ownership mechanism because NT uses object references and handles for lifetime. A process can be created by one process, debugged by another, assigned to a job, run under a service account, and waited on by any process that holds a suitable handle. This makes lineage useful for telemetry, but too weak to be the authority model.

## Process Creation

| Concept | Linux | Windows |
|---|---|---|
| Main model | `fork` then `execve` | `CreateProcess` / `NtCreateUserProcess` |
| Address space at birth | `fork` clones current process using copy-on-write | New process object and address space are created around an image section |
| Replace current image | `execve` replaces image in same PID | No exact direct equivalent in normal Win32 process creation |
| Parent role | Parent calls `fork`; child starts as near-copy | Caller asks kernel/user-mode loader path to create a separate process |
| Common security impact | Inherited file descriptors and environment | Inherited handles, token, integrity level, mitigation policy, attributes |

Linux teaches "process creation is cloning plus replacement." Windows teaches "process creation is object creation plus image mapping plus thread start."

For the detailed "nearby calls, different contract" map, read [Related System Calls and API Semantics](<05-related-system-calls-and-api-semantics.md>). That file separates `fork`, `vfork`, `clone`, `execve`, `execveat`, `posix_spawn`, `system`, `CreateProcessW`, `NtCreateUserProcess`, `ShellExecuteEx`, CRT `_spawn`, and termination APIs.

Why this exists: `fork` is elegant when the parent context is the natural template for the child, especially for shells and server prefork models. Windows had to support GUI processes, multiple subsystems, explicit handles, security tokens, process parameters, application compatibility, and heavily threaded programs where duplicating a live process image would be surprising and expensive. Creating a fresh process around an image section gives the kernel and loader a controlled place to apply security policy, mitigation policy, handle inheritance, environment, current directory, and initial thread state.

## Process Object vs Address Space vs Image

### Linux

- `task_struct` represents a schedulable task.
- A process is often a thread group sharing memory.
- `mm_struct` describes the address space.
- Executable image and mappings are represented through VMAs.

The important split is that schedulability, address-space ownership, file table sharing, credentials, and image mappings are related but distinct kernel objects or references. Evidence comes from walking task relationships, thread-group sharing, `mm_struct`, `files_struct`, `cred`, and VMA state instead of assuming one "process struct" explains everything.

### Windows

- `EPROCESS` represents the kernel process object.
- `ETHREAD` represents a thread.
- Address space is tied to the process object and described internally by VADs.
- Executable images and DLLs are mapped through section objects.
- User-mode process metadata is exposed through the PEB.

The important split is that `_EPROCESS` is not "the whole process" in one flat struct; threads, handle tables, VADs, section objects, tokens, jobs, sessions, and the PEB each carry different authority or evidence.

### Practical Mapping

- Linux `task_struct` roughly maps to Windows `EPROCESS` plus `ETHREAD`, depending on whether you mean process or thread.
- Linux VMA roughly maps to Windows VAD.
- Linux `/proc/<pid>/maps` roughly maps to Windows VMMap, `!address`, or memory manager data.

Treat these as semantic translations, not field translations. The useful question is which structure owns scheduling, memory policy, authority, lifetime, and observability in the OS being discussed. A strong answer names the evidence view too: `/proc`, kernel symbols/source, WinDbg extensions, ETW, handle tables, VADs, VMAs, and memory dumps each expose different slices.

## Threads

| Concept | Linux | Windows |
|---|---|---|
| Kernel schedulable entity | Task | Thread |
| User-visible process | Thread group | Process object with threads |
| Thread local structure | TLS via runtime/thread pointer | TEB plus TLS slots |
| Main thread | Convention from process start | Initial thread created with process |
| Thread ID | TID, often separate from TGID | Thread ID under process |

Linux internally treats threads as tasks that share resources. Windows has a clearer process object vs thread object split in the public mental model.

## Waiting and Exit Status

### Linux

- Parent waits on child.
- Exit status must be reaped.
- Unreaped dead child becomes zombie.
- `SIGCHLD` notifies parent.

The reason zombies exist is that exit status is still owed to the parent even after most task resources are gone. That small retained record is the synchronization artifact that lets `waitpid` report termination reliably.

### Windows

- Any process with a process handle can wait on that process object.
- Wait APIs work on many waitable kernel objects, not only child processes.
- Exit status is queried from the process object.
- No zombie reaping model.

The reason is that waiting is a property of handles to waitable objects, while lifetime is controlled by object references rather than a mandatory parent reap operation.

Windows waiting is object-handle based. Linux waiting is parent-child and signal oriented.

## Handles vs File Descriptors

### Linux File Descriptors

- Small integers indexing a per-process file descriptor table.
- Point to open file descriptions.
- Used for files, sockets, pipes, devices, epoll, eventfd, signalfd, pidfd, and more.
- Permissions are mostly decided when opened; operations then use the FD.

The authority is the opened file description and the process fd table entry, not the pathname string that originally produced it. That is why unlinking or renaming the path after open does not necessarily remove access through an existing fd.

### Windows Handles

- Opaque values indexing a per-process handle table.
- Reference kernel objects managed by the Object Manager.
- Object types include process, thread, file, section, event, mutex, token, job, registry key, desktop, window station, ALPC port, and more.
- Each handle has granted access rights.
- Handles can be inherited, duplicated, protected, audited, and queried.

The authority is the granted access mask on the handle table entry, which is why duplicating or inheriting a handle can move power without reopening the object's name.

### Core Difference

Linux generalizes through "everything is a file" more often. Windows generalizes through "everything important is an object behind a handle."

Why this exists: Unix file descriptors are intentionally small and general; they make pipes, files, sockets, terminals, and devices compose with the same I/O calls. Windows handles generalize a different set of properties: object type, object namespace, reference-counted lifetime, granted access, inheritance, duplication into another process, auditing, waiting, and security descriptors. That is why a Windows handle can naturally represent a process, token, event, section, registry key, desktop, file, or ALPC port even when `read` and `write` are not meaningful operations.

## Object Namespaces

### Linux

- Filesystem namespace is central.
- Many kernel interfaces appear under `/proc`, `/sys`, `/dev`, cgroups, and namespaces.
- Namespaces isolate views of mounts, PIDs, network, UTS, IPC, cgroups, and users.

The reason this matters is that a path or PID is resolved inside a namespace context; two processes can see different "same" names because their views are intentionally different. Evidence must therefore include the mount, PID, user, network, and cgroup namespace context of the process doing the lookup.

### Windows

- Object Manager namespace is central for kernel objects.
- Examples: `\Device`, `\Driver`, `\BaseNamedObjects`, `\Sessions`, `\KnownDlls`, symbolic links, named sections, mutexes, events.
- Win32 paths like `C:\...` are translated into NT object paths such as `\Device\HarddiskVolume...`.

The reason this matters is that user-facing Win32 paths are not the only names in play; devices, sections, events, sessions, and symbolic links can all be named, opened, secured, and confused at the NT object layer. Evidence includes the NT path, object type, security descriptor, symbolic-link resolution, and handle granted access.

### Analogy

Linux `/proc`, `/sys`, and `/dev` are not the same as the Windows Object Manager namespace, but both are ways to expose kernel state and named kernel resources.

Why this exists: Linux exposes much of the kernel through filesystem-shaped interfaces because shell tools and VFS conventions are central to the ecosystem. Windows centralizes many kernel names in the Object Manager because the same naming, reference, symbolic-link, and security machinery can be applied to files, devices, sections, events, mutexes, desktops, sessions, and driver-created objects. The user-visible `C:\...` path is therefore only one projection over a deeper NT object namespace.

## Security Model

| Area | Linux | Windows |
|---|---|---|
| Identity | UID, GID, supplementary groups, capabilities, LSM labels | Access tokens with SIDs, groups, privileges, integrity level, AppContainer capabilities |
| Object authorization | Unix mode bits, POSIX ACLs, capabilities, LSM policy | Security descriptors with DACL/SACL/owner, access masks, privileges, MIC |
| Privileged user | `root`, capabilities can split root power | Administrators, SYSTEM, TrustedInstaller, privileges, integrity levels, PPL |
| Impersonation | Credentials, namespaces, capabilities, setuid/setgid | First-class impersonation tokens and thread impersonation |
| Audit | auditd, LSM/audit framework | Security auditing, ETW, event logs |

The closest analogy to Linux credentials is a Windows access token, but Windows tokens carry richer authorization data and privileges. A Windows access check is typically token plus desired access plus object security descriptor plus mandatory integrity rules.

Why this exists: Unix authorization started from local users, groups, mode bits, and a superuser, then added capabilities and LSM policy as systems became more complex. Windows NT was built for networked enterprise identity and object-level discretionary access control from the start. A server process may need to impersonate a client over SMB/RPC/COM, check many group SIDs, use only specific privileges, obey integrity boundaries, and access objects with per-object ACLs. Tokens and security descriptors are the data structures that make that model work.

## Syscalls and User-Kernel Boundary

### Linux

- Applications usually call libc wrappers.
- libc invokes syscalls through architecture-specific ABI.
- Syscall numbers are part of the Linux user-kernel ABI for a given architecture.
- Many tools trace this boundary with `strace`, eBPF, perf, ftrace, and audit.

The key authority boundary is the syscall entry point: user registers and pointers become untrusted kernel inputs, then VFS, MM, LSM, credentials, and subsystem policy decide what happens.

### Windows

- Applications usually call Win32 APIs.
- Win32 APIs often go through `kernel32.dll` / `kernelbase.dll`, then `ntdll.dll`.
- `ntdll` contains user-mode stubs for Native API calls.
- System service numbers are implementation details and can vary by build.
- Many APIs do substantial user-mode work before the syscall boundary.

The authority boundary often starts before the kernel transition because Win32, COM, RPC, brokers, and policy wrappers may validate or transform the request before any Native API call occurs.

Do not map Linux "syscall equals OS API" directly to Windows. On Windows, the documented Win32 API, Native API, and syscall layer are separate layers with different stability contracts.

Why this exists: Linux exposes syscalls as the stable user-kernel ABI, with libc mostly providing convenience, standards compatibility, and runtime behavior. Windows preserves application compatibility at the Win32/API layer, not at the syscall-number layer. Keeping Win32 and Native API above the kernel service table lets Microsoft change kernel implementation details, syscall numbers, object layouts, and internal behavior while old applications continue to run through the documented API contract.

For a broader table of confusing syscall/API neighbors, including file/path, process, wait/termination, memory, dynamic loading, and shell-mediated execution, use [Related System Calls and API Semantics](<05-related-system-calls-and-api-semantics.md>).

### API Layer Mapping

| Task | Linux / ELF user mode | Windows / PE user mode | Reversing significance |
|---|---|---|---|
| Public application API | libc, libpthread, libdl, libm, toolkit libraries | Win32 API, COM, .NET, CRT, framework DLLs | The public call may be far above the kernel boundary. |
| Lower OS API | Raw syscalls, vDSO helpers, netlink, ioctl-heavy subsystem APIs | Native API in `ntdll`, lower-level calls such as `NtCreateFile`, `NtAllocateVirtualMemory`, `NtMapViewOfSection` | Malware may bypass higher-level wrappers to reduce telemetry or use features not exposed by friendly APIs. |
| Syscall dispatch | Architecture syscall ABI and stable syscall numbers for that architecture | `ntdll` syscall stubs and build-specific service numbers | Linux syscall IDs are normal ABI knowledge; Windows direct-syscall assumptions are version-sensitive. |
| Dynamic library load | `dlopen`, loader path search, `ld.so.cache`, rpath/runpath | `LoadLibrary`, `LoadLibraryEx`, `LdrLoadDll`, DLL search order, side-by-side manifests, KnownDLLs, API sets | Load events, search paths, and loader policy are common abuse and detection points. |
| Dynamic symbol lookup | `dlsym`, ELF symbol tables, versioned symbols | `GetProcAddress`, `LdrGetProcedureAddress`, PE export directory, ordinal/name lookup | Runtime resolution hides static imports and is common in packers, plugins, and malware. |
| Module enumeration | `dl_iterate_phdr`, `/proc/<pid>/maps`, linker `link_map` | PEB loader lists, Toolhelp/PSAPI, `LdrEnumerateLoadedModules` | Unlinked or manually mapped modules may disappear from friendly enumerators but remain visible in memory maps. |
| Function interposition | `LD_PRELOAD`, `LD_AUDIT`, PLT/GOT changes, symbol wrapping | IAT/EAT patching, inline hooks, Detours-style trampolines, AppInit/hooks in legacy contexts | Hooking is normal in profilers and security tools, but also common in spyware and rootkits. |
| Device/kernel extension | `ioctl`, netlink, eBPF, kernel modules | IOCTLs to device objects, ETW/WFP/filter drivers, kernel drivers | User-mode payloads often rely on privileged helpers for visibility, tampering, or persistence. |

### Dynamic Loading API Equivalents

| Concept | Linux | Windows | Caveat |
|---|---|---|---|
| Load a library into current process | `dlopen("libx.so", flags)` | `LoadLibrary("x.dll")`, `LoadLibraryEx`, lower-level `LdrLoadDll` | Both run loader logic, but their search rules, initialization callbacks, and locking rules differ. |
| Resolve an exported function | `dlsym(handle, "name")` | `GetProcAddress(module, "Name")`, `LdrGetProcedureAddress` | Windows can resolve by ordinal; ELF symbols can be versioned and affected by visibility/binding. |
| Release a library reference | `dlclose` | `FreeLibrary` | Unload does not guarantee immediate absence if references, TLS, threads, or loader state keep it alive. |
| Main program pseudo-handle | `dlopen(NULL, ...)` | `GetModuleHandle(NULL)` | Similar use case, different loader state and symbol-scope rules. |
| Current process module walk | `dl_iterate_phdr`, `r_debug`, `/proc/self/maps` | PEB loader lists, `EnumProcessModules`, Toolhelp snapshot | Manual mapping and unlinking can confuse high-level enumeration on both platforms. |
| Loader-debug breakpoint | `_r_debug.r_brk` used by debuggers | Loader notifications and debugger events around `LdrLoadDll`/`LdrUnloadDll` | Useful for unpacking and module-load tracing. |
| Environment-driven preload | `LD_PRELOAD`, `/etc/ld.so.preload` | No exact equivalent; related mechanisms include DLL search-order abuse, AppInit DLLs, IFEO, shell extensions, service DLL configuration | These are analogous as load redirection/persistence ideas, not API equivalents. |

### Runtime API Resolution Patterns

Benign software uses runtime resolution for plugins, optional features, compatibility, and delayed loading. Malware and packers use the same primitives to reduce static imports, evade simplistic signatures, or select APIs only after environment checks.

- On Linux, suspicious patterns include small import tables followed by `dlopen`/`dlsym`, direct syscall wrappers, walking ELF program headers, parsing `/proc/self/maps`, resolving symbols from `libc` or `ld-linux`, or relying on `LD_PRELOAD`/`LD_AUDIT`.
- On Windows, suspicious patterns include resolving `LoadLibraryA/W`, `GetProcAddress`, and `VirtualAlloc` early; walking the PEB to find loaded modules; parsing PE export tables manually; hashing API names; resolving Native API calls from `ntdll`; or dynamically selecting `Nt*` APIs.
- Static analysis should connect strings, hash constants, export-table parsing, and indirect calls. Dynamic analysis should watch library load events, memory protection changes, thread creation, section mapping, and cross-process handle access.

## Loader and Binary Format

| Concept | Linux | Windows |
|---|---|---|
| Main executable format | ELF | PE/COFF |
| Dynamic libraries | `.so` | `.dll` |
| Loader | kernel maps interpreter, then dynamic linker such as `ld-linux` | Windows loader in user mode, heavily involving `ntdll` |
| Import resolution | PLT/GOT, dynamic linker | Import Address Table, loader, API sets |
| Pre-entry behavior | constructors, dynamic linker work | TLS callbacks, loader work, `DllMain` |
| Library search risk | `LD_LIBRARY_PATH`, rpath/runpath, preload | DLL search order, side-loading, known DLLs, manifests, API sets |

Linux loader intuition helps, but PE has Windows-specific concepts: sections as image mappings, import tables, export tables, relocations, TLS callbacks, API set resolution, and `DllMain`.

### Process Startup, Thread Startup, and Destruction

`main` is a runtime callback on both platforms, not the first code the kernel runs.

| Lifecycle area | Linux / ELF | Windows / PE | Security implication |
|---|---|---|---|
| Kernel handoff | `execve` maps ELF segments, prepares argv/envp/auxv, maps vDSO/vvar, and starts the ELF interpreter for dynamic binaries. | Process creation opens the image, creates an image section, creates process/initial-thread objects, prepares PEB/TEB/process parameters, and enters user-mode loader startup. | Kernel-created state defines the initial trust and observation surface. |
| Loader work | `ld-linux` maps dependencies, relocates, resolves symbols, initializes TLS, and runs loader callbacks. | `ntdll` loader code maps DLLs, resolves imports/API sets, relocates, initializes TLS, calls TLS callbacks, and calls DLL `DllMain`. | Loader policy is where search-order abuse, preload/side-loading, and pre-entry execution appear. |
| Runtime startup | `_start` from CRT startup objects calls libc startup; glibc commonly reaches `__libc_start_main`, which eventually invokes `main`. | The PE entry point is often `mainCRTStartup`, `wmainCRTStartup`, or `WinMainCRTStartup`; the CRT initializes runtime state and then calls `main`, `wmain`, or `WinMain`. | Auditing only application `main` misses runtime and initializer code. |
| Thread startup | `pthread_create` reaches the user routine through libc/thread runtime setup; the kernel task is not the whole story. | User thread routines are reached through wrappers commonly visible as `RtlUserThreadStart` and `BaseThreadInitThunk`. | Thread start addresses, TLS state, and wrapper frames matter in debugging and malware triage. |
| Normal teardown | Returning from `main` flows through `exit`, `atexit`, C++ destructors, TLS cleanup, `.fini_array`, and then `_exit`/`exit_group`. | CRT exit, `atexit`, C++ destructors, TLS/FLS cleanup, DLL detach, and `ExitProcess` participate in orderly termination. | Destructors and finalizers are code-execution surfaces. |
| Abnormal teardown | `_exit`, fatal signals, `execve`, or forced kill skip much user-mode cleanup. | `TerminateProcess` is forceful and can bypass orderly user-mode cleanup. | Do not assume cleanup callbacks ran after crashes or forced termination. |

### Thread-Local Storage: Linux TCB Versus Windows TEB

Linux has thread-local storage. It is just not organized around a Windows-style TEB.

| Area | Linux | Windows |
|---|---|---|
| Per-thread base | Architecture/runtime thread pointer. On x86-64 Linux this is commonly FS base; on AArch64 it is TPIDR_EL0. Exact layout is libc/ABI-specific. | TEB pointer, reached through architecture-specific segment/register conventions such as GS on x64 Windows and FS on 32-bit x86 Windows. |
| Main structure | Thread Control Block plus dynamic thread vector and TLS blocks for the executable/shared objects. | TEB plus TLS slot arrays, FLS state, stack bounds, last-error state, SEH-related state on x86, and pointer to the PEB. |
| Language/API surface | ELF TLS such as `__thread` and C/C++ `thread_local`; pthread keys/destructors; libc per-thread state such as `errno`. | `__declspec(thread)`, PE TLS directory, Win32 `TlsAlloc`/`TlsGetValue`, FLS APIs, CRT per-thread state, last-error storage. |
| Loader role | ELF `PT_TLS`/TLS program header data tells the dynamic linker how to allocate and initialize TLS for modules; dynamic TLS can be added for loaded shared objects. | PE TLS directory describes TLS data and callbacks; the loader initializes TLS and invokes TLS callbacks during process/thread attach paths. |
| Pre-entry behavior | TLS storage is initialized before normal code needs it, but ELF does not have PE-style TLS callback tables. Pre-main code usually comes from dynamic linker work, IFUNC resolvers, `.preinit_array`, `.init_array`, constructors, and runtime startup. | TLS callbacks are explicit pre-entry execution points and can run before the PE entry point; `DllMain` runs during loader attach/detach events. |
| Thread exit | pthread/TLS destructors and language runtime destructors can run at thread exit, unless the thread/process dies abnormally. | FLS/TLS cleanup, DLL thread detach, CRT cleanup, and process detach can run on orderly teardown; forceful termination can skip them. |

Security implications:

- Thread-local does not mean secret. It is private to a thread by convention and address calculation, but it lives in process memory. Same-process code can usually read it, and cross-process memory authority or a dump can expose it.
- TLS often contains sensitive runtime state: `errno`, locale/CRT state, allocator or runtime caches, per-thread credentials in some applications, stack/pointer guard values on some libc/architecture combinations, and language runtime bookkeeping. Exact offsets are implementation details, not portable contracts.
- TLS/TEB/TCB corruption can redirect per-thread control or confuse runtime checks. Examples include stale pthread keys, wrong destructors, wrong per-thread object lifetime, fake TEB/PEB assumptions in Windows malware analysis, or tampered loader/runtime metadata.
- Pre-entry and teardown code are analysis surfaces. On Windows, TLS callbacks are explicit malware/packer hiding points. On Linux, constructors, IFUNC resolvers, dynamic linker work, and C++ `thread_local` dynamic initialization/destructors are the closer surfaces.
- In reversing, segment-register or thread-pointer-relative loads are often TLS. Do not mistake `fs:`/`gs:` access for ordinary global memory without identifying the OS, architecture, and ABI.

### Code Mutation, Mitigations, and Cache Coherency

Real mitigations are permission, provenance, and control-flow mechanisms: NX/DEP, W^X, ASLR/KASLR, stack canaries, RELRO, CFI, CET shadow stack/IBT, arm64 BTI/PAC, Windows CFG/KCFG, ACG/CIG, WDAC/code integrity, VBS/HVCI, and related policy. They do not normally work by comparing I-cache contents with D-cache contents before execution.

The related Arm behavior is real but different: on split I-cache/D-cache systems, freshly written code bytes may live on the data side while instruction fetch still observes stale instruction-side state. Without the required data-cache clean, instruction-cache invalidate, and barriers, a shellcode loader, JIT, hook, or unpacker can fail to execute the bytes it just wrote.

The useful analysis model is:

- compare mapped code bytes with clean file-backed images when provenance matters
- inspect private dirty executable pages and anonymous/JIT mappings
- track writable-to-executable transitions such as `mprotect` or `VirtualProtect`
- correlate loader metadata with `/proc/<pid>/maps`, VADs, ETW image-load events, thread starts, and memory protections
- understand whether indirect calls, indirect jumps, and returns are constrained by CFG, CFI, CET, BTI, PAC, or shadow-stack policy

Instruction-cache coherency is therefore a real low-level issue for JITs, hotpatching, hooks, unpackers, and self-modifying code, and it can accidentally mitigate naive shellcode on some Arm targets. x86/x64 mostly hides I-cache/D-cache maintenance from normal application code; Arm-style systems make explicit cache maintenance more visible. Windows exposes the contract with `FlushInstructionCache`; portable Linux/user-mode code often uses compiler/runtime helpers such as `__builtin___clear_cache`.

Raspberry Pi 3 versus Raspberry Pi 4 is usually a Cortex-A53 versus Cortex-A72 and runtime/kernel-interface question, not a clean ARMv7 versus ARMv8 split. Both Pi 3 and Pi 4 use ARMv8-A cores, even though 32-bit Linux can expose an ARMv7-style user ABI. Treat cache-flush discussions as coherency/correctness and architecture-specific stale-code questions, not as a generic shellcode-detection mechanism or universal mitigation bypass.

### ELF vs PE/COFF Details

| Area | ELF / Linux | PE/COFF / Windows | Malware-analysis angle |
|---|---|---|---|
| File identity | ELF header, program headers, section headers | DOS stub, NT headers, optional header, data directories, section table | Packers often disturb optional metadata while keeping loader-required fields valid. |
| Loader view | Program headers drive memory mapping | PE sections plus image section object drive mapping | Section names are advisory; memory permissions and mapped ranges matter more than names. |
| Import model | Dynamic section, relocation records, PLT/GOT, symbol lookup rules | Import directory, IAT, delay-load imports, API-set forwarding | Missing or tiny imports can indicate packing, shellcode-style loading, or runtime resolution. |
| Export model | Dynamic symbol table, visibility, symbol versions | Export directory, names, ordinals, forwarded exports | Export forwarding and ordinals matter in Windows reverse engineering. |
| Relocation | REL/RELA entries, PIE/shared object relocations | Base relocation table, preferred image base, ASLR | Relocation stripping or unusual relocation behavior can complicate loaders and unpacking. |
| Initialization | `.init_array`, constructors, dynamic linker callbacks | TLS callbacks, `DllMain`, CRT initializers | Pre-entry execution is important for breakpoints and behavior attribution. |
| Thread-local storage | ELF TLS models | PE TLS directory and callbacks | TLS can run before a familiar main-entry breakpoint. |
| Hardening metadata | RELRO, canaries via compiler/runtime, NX, PIE, CET notes depending on toolchain | DEP/NX, ASLR, CFG, SafeSEH on x86, CET, load-config directory, signatures/catalogs | Mitigation metadata guides exploitability and unpacking expectations. |
| Signing/trust | Usually distribution/package/signature policy outside ELF itself | Authenticode/catalog signing, WDAC policy, SmartScreen reputation | Windows places more operational weight on file signing and trust policy. |
| Debug symbols | DWARF, build IDs, split debug files | PDBs, CodeView records, public/private symbols | Symbol discovery workflow differs sharply. |

### DLL vs Shared Object

DLLs and shared objects are both dynamically loaded code modules, but the surrounding conventions differ.

- A Linux `.so` is normally position-independent ELF with symbol visibility and dependency resolution controlled by the dynamic linker. Symbol interposition is a normal ELF feature and can be used intentionally by profilers, wrappers, and test harnesses.
- A Windows `.dll` is a PE image loaded through the Windows loader. The export table is explicit, imports are patched through the IAT, initialization goes through loader-managed entry points, and `DllMain` has strict loader-lock constraints.
- A `.so` often participates in process-wide symbol resolution by name. A DLL usually exposes a more explicit export surface, and callers commonly bind through import libraries, delay-load thunks, COM registration, or `GetProcAddress`.
- Search-order abuse exists in both worlds, but Windows DLL side-loading is shaped by application directories, KnownDLLs, manifests, SafeDllSearchMode, API sets, and packaged-app rules. Linux library hijacking is shaped by rpath/runpath, `LD_LIBRARY_PATH`, loader cache, writable library paths, and preload mechanisms.

Why this exists: ELF dynamic linking grew around Unix symbol resolution, shared objects, and interposition, where replacing or wrapping symbols is often an intended feature. PE/DLL loading grew around explicit imports, exported APIs, binary compatibility, and application installation rules. Windows therefore puts more weight on import tables, export forwarding, API-set redirection, side-by-side policy, KnownDLLs, and loader-managed initialization. This is why Windows malware often hides static imports with `GetProcAddress`, while Linux malware often leans on dynamic linker behavior, preload paths, or direct ELF parsing.

## Memory Management

### Similarities

- Both use virtual memory, page tables, page faults, copy-on-write, memory-mapped files, demand paging, ASLR, DEP/NX, and per-process address spaces.
- Both separate user and kernel address ranges.
- Both have shared libraries mapped into multiple processes.

The shared enforcement point is the MMU/TLB consuming PTEs, even though Linux and Windows use different higher-level policy objects to decide what those PTEs should be. That is why both OSes ultimately reduce many memory questions to mapping policy, backing object, protection bits, residency, and invalidation.

### Linux Emphasis

- VMAs in `mm_struct`.
- `/proc/<pid>/maps`, `/proc/<pid>/smaps`.
- `mmap`, `mprotect`, `brk`, `munmap`.
- Overcommit policy is a major concept.

Linux memory questions usually start by asking what VMA covers the address, what backs it, and what the fault path is allowed to instantiate.

The evidence path is `/proc/<pid>/maps`, `smaps`, page-fault behavior, file backing, page-cache state, and kernel source for the active fault handler.

### Windows Emphasis

- VADs for virtual address descriptors.
- Reserved vs committed memory is explicit.
- Section objects and views are central.
- `VirtualAlloc`, `VirtualProtect`, `MapViewOfFile`, `NtCreateSection`, `NtMapViewOfSection`.
- Image-backed, mapped, and private memory categories matter heavily in debugging and EDR analysis.

Why this exists: Linux makes `mmap` the main abstraction for anonymous memory, file mappings, shared memory, and executable mappings. Windows splits the model into address reservation, committed memory, page protection, section objects, and mapped views because the kernel tracks commit charge explicitly and uses section objects as the common backing abstraction for images, mapped files, and shared memory. This is why Windows analysis constantly asks whether a region is private, mapped, or image-backed, while Linux analysis often starts from the VMA list and backing file.

For the detailed flag/API translation, read [Cross-Platform Process Memory Access and Memory API Flags](<04-process-memory-access-and-memory-api-flags.md>) here. That file is the place to study `ReadProcessMemory`/`PROCESS_VM_READ` versus `process_vm_readv`/ptrace, `VirtualAllocEx` versus remote `mmap` patterns, `mprotect` versus `VirtualProtect`, and security-relevant `mmap`/`madvise` flags.

### Memory Map Region Taxonomy

Do not explain a Linux `/proc/<pid>/maps` view or a Windows VMMap view as "ELF versus PE" only. ELF and PE explain image-loader regions, but a real process map is the combined result of loader policy, user allocators, stacks, shared-memory objects, file mappings, JIT/runtime code, device mappings, guard pages, COW, commit policy, and current residency.

| Region family | Linux map view | Windows VMMap/VAD view | What creates it |
|---|---|---|---|
| Main executable image | ELF `PT_LOAD` mappings for the executable; dynamic ELF state appears through backing paths and loader metadata. | EXE image section, usually shown as image-backed memory tied to a PE image. | `execve`/ELF loader path versus `CreateProcess`/image section creation. |
| Shared libraries / DLLs | `.so` mappings, dynamic linker, relocations, GOT/PLT, TLS, and COW data pages. | DLL image sections, KnownDLL/API-set resolution, loader lists, relocations/imports/TLS, and COW pages. | ELF dynamic linker versus Windows loader. This is where ELF/PE matters most. |
| Heap and allocator arenas | `brk` heap plus anonymous `mmap` arenas; allocator state is user-space metadata over VMAs. | Process heaps, segment heap/LFH/page heap style behavior; heap segments are built over private committed/reserved ranges. | `malloc`/allocator policy, not the binary format. |
| Thread stacks | Stack VMAs with guard/growth behavior and per-thread layout. | Reserved/committed stack regions with guard pages and TEB-linked metadata. | Thread creation and stack policy. |
| Anonymous private memory | Anonymous `mmap`, JIT arenas, unpacked regions, scratch mappings, COW-private pages. | `VirtualAlloc`/`NtAllocateVirtualMemory` private VADs, JIT/unpacked/private RX/RWX regions. | Runtime allocation, JITs, packers, application memory management. |
| File-backed data mappings | File-backed `mmap`, page-cache-backed regions, deleted-but-mapped files, `MAP_PRIVATE`/`MAP_SHARED`. | Data-file section views through `CreateFileMapping`/`MapViewOfFile`, Cache Manager and section-object state. | Memory-mapped files and cache/mapping policy. |
| Explicit shared memory | POSIX shm, SysV shm, `memfd`, tmpfs-backed mappings, inherited or fd-passed mappings. | Pagefile-backed or file-backed sections, named file mappings, inherited/duplicated section handles. | IPC design and authority over fd/handle/name. |
| Runtime/kernel-provided user mappings | vDSO/vvar/vsyscall-like regions where present. | PEB/TEB, KUSER_SHARED_DATA, ntdll/runtime support mappings. | OS/runtime fast paths and process/thread metadata. |
| Device/DMA mappings | Driver `mmap` of device buffers, DMA-BUF, graphics/media buffers. | Mapped device/driver views, MDL-described or driver-mediated mappings where exposed. | Driver and device frameworks, not ELF/PE. |
| Free/reserved/noaccess/guard | Gaps, unmapped holes, `PROT_NONE`, guard-like ranges depending on runtime. | Free address space, reserved-but-uncommitted ranges, `PAGE_NOACCESS`, `PAGE_GUARD`. | Address-space layout, reservation, guard, mitigation, and allocator policy. |

Similarities:

- Both systems reduce runtime access to PTE permissions, page faults, TLB state, backing objects, COW, and residency.
- Both have image mappings, file mappings, private anonymous memory, stacks, heaps, shared memory, and runtime-created executable regions.
- Both can show a range as valid while the physical page is not resident yet.

Differences:

- Linux exposes a VMA-centered view through `/proc/<pid>/maps`/`smaps`; Windows tooling usually pivots through VADs plus private/mapped/image categories, commit, working set, and section objects.
- Linux uses `mmap` as the broad mapping primitive for files, anonymous memory, shared memory, and many device mappings. Windows splits similar decisions across `VirtualAlloc`, section objects, mapped views, heap APIs, and protection APIs.
- Windows reserve/commit accounting is explicit and central. Linux relies more on lazy faulting, overcommit policy, memcg limits, and mapping flags.
- PE/ELF format details matter for image regions, import/export/relocation/TLS behavior, and loader metadata; they do not explain heap arenas, stacks, JITs, memfd/shm, mapped data files, device mappings, or kernel allocator behavior.

### User And Kernel Allocation Differences

Focused companion: [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>) covers `malloc`/`new`, UCRT, `LocalAlloc`/`GlobalAlloc`, `HeapAlloc`, `HeapCreate`, LFH, segment heap, `VirtualAlloc`/`VirtualFree`, compiler/runtime fingerprints, and Visual Studio heap debugging.

User-mode allocation:

| Area | Linux | Windows |
|---|---|---|
| Raw process address-space API | `mmap`, `munmap`, `mprotect`, `brk`, `madvise`. | `VirtualAlloc`, `VirtualFree`, `VirtualProtect`, `MapViewOfFile`, `UnmapViewOfFile`, `VirtualQuery`. |
| General heap API | `malloc` implementation may use `brk` for smaller arenas and anonymous `mmap` for larger allocations; behavior depends on libc/allocator. | `HeapAlloc`/process heaps, segment heap/LFH/page heap/runtime heaps; large regions are ultimately backed by VM manager reservations/commit. |
| Accounting | Overcommit, memcg, `MAP_NORESERVE`, fault-time allocation, RSS/smaps. | Explicit reserve/commit, private bytes/commit charge, working set, pagefile-backed private memory. |
| Security clues | Anonymous RX/RWX, `mprotect` transitions, executable `memfd`, deleted mappings, private dirty library pages. | Private RX/RWX, `VirtualProtect` transitions, executable mapped sections, modified image pages, VAD/PEB mismatch. |

Kernel allocation:

| Area | Linux | Windows |
|---|---|---|
| Page allocator | Buddy allocator, per-CPU pagesets, zones, reclaim, compaction, memcg pressure. | PFN database, page lists, working sets, commit/pagefile accounting, memory manager page-state machinery. |
| Small kernel objects | SLUB/slab caches, `kmalloc`, per-CPU allocations, GFP flags and sleep/reclaim constraints. | Paged/nonpaged pool, NX pool, pool tags, lookaside-style caches, `ExAllocatePool2`-era APIs, Driver Verifier/Special Pool. |
| Virtually contiguous kernel memory | `vmalloc`, `vmap`, module mappings, ioremap/device mappings. | System address-space regions, system PTEs, driver/image mappings, MDL mappings, section/cache manager views. |
| Context constraints | GFP flags, atomic context, interrupt/softirq/workqueue context, page-fault permissibility. | IRQL, paged versus nonpaged memory, DPC/APC/work-item context, pageable-code rules. |
| Security clues | Slab cache type, freelist hardening, KASAN/KFENCE/KCSAN, hardened usercopy, pins/GUP, module memory. | Pool tag/type, paged/nonpaged misuse, Special Pool, Driver Verifier, MDLs, use-after-free, IRQL violations, executable pool. |

The practical rule is: user maps are usually about process VMA/VAD policy and loader/runtime allocation; kernel memory is about allocator class, lifetime, context constraints, and whether the code is allowed to fault, sleep, or touch pageable memory.

### Process Memory API Analogy

| Question | Linux answer | Windows answer |
|---|---|---|
| What gives authority to read another process? | A ptrace-style permission check using credentials, dumpable state, namespaces, capabilities, and LSM/Yama policy; concrete APIs include `process_vm_readv`, `ptrace`, and `/proc/<pid>/mem`. | A process handle with granted access such as `PROCESS_VM_READ`; `ReadProcessMemory` checks that handle and the readability of the requested range. |
| What gives authority to write another process? | `process_vm_writev`, ptrace writes, or `/proc/<pid>/mem` writes after ptrace-like authorization and mapping checks. | A process handle with `PROCESS_VM_WRITE` and usually `PROCESS_VM_OPERATION`; `WriteProcessMemory` also requires the target range to be writable/accessible for the operation. |
| What changes a target address space? | `mmap`/`mprotect` normally affect the calling process; changing another process usually requires target cooperation or debugger-like control. | `VirtualAllocEx` and `VirtualProtectEx` directly operate on a target process when the handle has `PROCESS_VM_OPERATION`. |
| What is the handle/fd analogy? | An fd can refer to a file, procfs object, memfd, or shared-memory object; it does not normally carry a reusable process-memory access mask. | A handle table entry references a kernel object and carries granted access. For process handles, the access mask shapes later operations. |
| What is the strongest shared pattern? | Pass an authority check, locate or create a VMA, set protections, and copy/map/fault memory. | Pass an access-mask/token policy check, locate or create a VAD/section view, set protections, and copy/map/fault memory. |

Study focus: do not memorize "Linux API X equals Windows API Y." Instead, ask which object carries authority, which range descriptor carries policy, which backing object supplies data, and which PTE bits eventually enforce the access.

## IPC and Synchronization

| Concept | Linux | Windows |
|---|---|---|
| Pipes | `pipe`, FIFOs | Anonymous/named pipes |
| Local sockets | Unix domain sockets | ALPC, named pipes, RPC, COM |
| Shared memory | `mmap`, `shm_open`, SysV SHM | Section objects, file mappings |
| Events | eventfd, futex, signals | Event objects, waitable timers, APCs, IOCP |
| Mutex/semaphore | pthread/futex/semaphore | Mutex, semaphore, critical section, SRW lock, keyed events |
| Main async notification | signals, epoll, io_uring, poll/select | APCs, IOCP, alertable waits, threadpool callbacks |

Signals do not map cleanly to Windows. Windows has console control events, exceptions, APCs, waits, job notifications, and messages, but none is exactly "Unix signals."

Why this exists: Unix signals came from process control, terminal behavior, and asynchronous notification in a process-tree world. Linux later added many FD-centric mechanisms such as `epoll`, `eventfd`, `signalfd`, and `io_uring`. Windows instead built a general waitable-object model and asynchronous I/O around dispatcher objects, events, APCs, IOCP, threadpools, ALPC/RPC, and GUI message queues. The result is more object-type diversity, but also a consistent pattern: wait on handles, complete I/O through completion mechanisms, and let subsystems expose richer IPC protocols.

### IPC Performance And Security Tradeoffs

Do not choose IPC only by API familiarity. For security work, identify the object that carries authority, the name or namespace used to find it, the lifetime owner, the copy or mapping cost, and the synchronization contract. The same mechanism can be safe in a small parent-child tool and dangerous as a privileged broker boundary.

Linux IPC tradeoffs:

| Mechanism | Performance shape | Security shape |
|---|---|---|
| Pipe / FIFO | Simple byte stream with kernel buffering and backpressure. Good for parent-child streaming and shell-style composition; not good for random access or very large shared state. | Anonymous pipes depend on fd inheritance and close discipline. FIFOs add pathname, mode-bit, directory, mount-namespace, and race considerations. Leaked fds become leaked authority. |
| Unix domain socket | General local IPC with stream, datagram, and seqpacket options. More overhead than shared memory, but flexible and easy to integrate with `poll`/`epoll`. Can pass fds and credentials. | Filesystem or abstract-socket names define discoverability. Peer credentials and `SCM_RIGHTS` are powerful; fd passing intentionally transfers authority and can also leak it. Namespace and container boundaries matter. |
| Shared memory: `mmap`, `shm_open`, `memfd`, SysV SHM | Best fit for high-volume bulk data after setup because data is mapped rather than repeatedly copied through read/write paths. Needs a separate notification and ownership protocol. Cache-line bouncing, NUMA placement, false sharing, and TLB pressure can dominate. | Permissions, fds, names, seals, and cleanup rules decide who can map it. The hard bugs are races, stale mappings, TOCTOU, uninitialized data exposure, and inconsistent state after peer death. Pair it with futexes, eventfd, semaphores, robust ownership, or protocol-level recovery. |
| `eventfd`, `timerfd`, `signalfd` | Efficient fd-composable notification, timer, and signal integration. Useful with `epoll`; not a bulk-data transport. `eventfd` is counter-like, so multiple events may coalesce. | Authority is the fd. Inheritance and passing matter. `signalfd` can reduce async-signal-handler bugs, but it also changes signal-delivery assumptions and must be understood with masks and threads. |
| Futex / pthread synchronization | Userspace fast path; kernel is entered mainly on contention or wake. Very fast when the memory protocol is correct. | A futex is a wait protocol around a memory address, not a named securable object. Lost wakes, wrong memory ordering, owner death, and protected-data corruption are the risks. Robust futexes help detect owner death but do not repair damaged invariants. |
| `poll`, `epoll`, `io_uring` | `poll` scans a list. `epoll` scales readiness waiting across many fds. `io_uring` is a submission/completion model that can reduce syscall overhead and support registered resources, but its performance wins depend on workload and setup cost. | Readiness is not ownership of completed work; readiness can be stale. `epoll` has watched-object lifetime and edge-triggering footguns. `io_uring` raises buffer, file registration, cancellation, pinning, credential, and lifetime questions. |
| Netlink / audit | Structured kernel-userspace event and control channel. Good for subsystem protocols and security/audit streams; not a generic byte-stream replacement. | Security depends on the netlink family, capabilities, namespace, multicast group, and message validation. A listener must handle drops, spoofing constraints, policy, and versioned message formats. |
| D-Bus and brokered IPC | Higher overhead than raw sockets or shared memory because a broker handles routing, discovery, policy, and object naming. Useful when policy and service discovery matter more than hot-path throughput. | The broker policy is part of the security boundary. Risks include overbroad method permissions, confused deputies, activation surprises, denial of service, and trusting names instead of authenticated peers. |

Windows IPC tradeoffs:

| Mechanism | Performance shape | Security shape |
|---|---|---|
| Anonymous pipe | Simple local byte stream, common for child-process stdio redirection. Kernel buffering and copying; easy to use but limited as a service protocol. | Authority is the inherited or duplicated handle. This avoids a named discovery surface, but handle inheritance mistakes can leak access into children or helpers. |
| Named pipe | Service-friendly local or remote-capable IPC with byte or message mode, overlapped I/O, and IOCP integration. Usually a strong practical default for Windows service IPC, but heavier than shared memory or ALPC for tight local hot paths. | DACLs, impersonation level, client identity checks, remote-client rejection, first-connector behavior, and pipe-name predictability matter. Common failures are pipe squatting, confused-deputy impersonation, and trusting message shape. |
| ALPC | Optimized local IPC used by core OS subsystems and service boundaries. Supports messages, handles, sections, and high-performance local broker designs. | High-value privilege-boundary surface. Port security, connection policy, impersonation, message validation, section/handle transfer, and callback lifetime decide safety. Bugs often become local privilege escalation or sandbox escape paths. |
| RPC | IDL/marshalling model over local or remote transports. Productive for service APIs and versioned interfaces, but marshalling, authentication, and transport layers add overhead. | Endpoint ACLs, authentication level, authorization checks, impersonation/delegation, parser bugs, and remote exposure matter. A local RPC interface can become remote attack surface if binding and firewall assumptions are wrong. |
| COM / DCOM | Component activation and object interface model, not just a transport. Good for integration, automation, and object lifetime; poor as a raw high-throughput pipe. Apartment transitions and marshalling can be expensive. | CLSID/AppID registration, launch/access permissions, elevation monikers, service identity, apartment reentrancy, and activation paths are the security model. COM hijack and persistence bugs come from registration and load-path authority, not only message parsing. |
| Section / file mapping plus events | Fastest Windows bulk-data pattern after setup: map a section, then synchronize with events, semaphores, mutexes, IOCP, or protocol state. Performance depends on cache behavior and avoiding false sharing. | Section DACLs, handle duplication, inherited mappings, stale views, executable mappings, and race-prone shared state are the risks. Synchronization failure can turn a "fast path" into data exposure or corruption. |
| Event / semaphore / mutex / waitable timer | Control-plane synchronization, not data transport. Kernel waits and context switches cost more than userspace-only synchronization but compose well with the dispatcher model. | Named dispatcher objects live in Object Manager namespaces and have DACLs. Predictable names, weak DACLs, session/global namespace confusion, and abandoned mutex state are security and reliability issues. |
| IOCP / threadpool I/O | Scalable completion dispatch for files, sockets, named pipes, and other overlapped I/O. Avoids one thread per operation and is the normal high-scale Windows server model. | The risk is async lifetime: buffers, handles, callbacks, request contexts, and cancellation must outlive completions. Stale completion keys or context pointers can become UAFs. |
| Window messages / mailslots | GUI messages are session/desktop oriented and useful for UI integration, not service IPC. Mailslots are legacy and limited. | Window-station, desktop, session, integrity, and UIPI rules matter for messages. Treat mailslots as legacy unless you have a strong compatibility reason; naming and weak protocol semantics make them unattractive for new privileged designs. |

How to choose:

- Use pipe/named pipe/Unix socket for small streams or request-response IPC.
- Use ALPC/RPC/COM or D-Bus-style brokers when identity, activation, policy, and service boundaries matter more than raw throughput.
- Use shared memory or sections for bulk data, but only with an explicit synchronization, recovery, and ownership protocol.
- Use `epoll`/`io_uring` on Linux and IOCP/threadpool I/O on Windows for high-concurrency designs; compare readiness versus completion semantics before translating designs.
- For security review, always name the authority carrier: fd, handle, token, credential, namespace path, DACL, broker policy, impersonation state, or shared memory mapping.

### Linux Event, Wait, And Monitoring Analogs

Do not map Windows `CreateEvent` to one Linux primitive. Windows exposes a broad waitable-handle model through dispatcher objects. Linux splits the same problem across several mechanisms, each with a narrower contract:

| Need | Linux mechanism | Closest Windows neighborhood | Caveat |
|---|---|---|---|
| Wait for a userspace lock/condition word | `futex`, pthread mutexes/condvars | Critical sections, condition variables, keyed events, waits | Futexes wait on a userspace address; there is no Object Manager name, handle, or DACL for the futex word itself. |
| Notify through a file descriptor | `eventfd`, `timerfd`, `signalfd` | Events, waitable timers, console/signaling-adjacent APIs | These compose with `poll`/`epoll` because they are fds; semantics are counter/timer/signal-specific, not generic dispatcher-object semantics. |
| Wait for readiness across many sources | `poll`, `select`, `epoll` | `WaitForMultipleObjects`, IOCP, threadpool waits | Linux waits mostly for fd readiness or subsystem-specific readiness; Windows waits on typed handles or completion packets. |
| Sleep inside kernel code until a condition changes | wait queues, completions, wakeups | dispatcher wait blocks, events, kernel wait APIs | Linux kernel wait queues/completions are internal synchronization building blocks, not normally securable user-visible named objects. |
| Watch filesystem namespace changes | `inotify`, `fanotify`, `fsnotify` | ReadDirectoryChangesW, minifilters, ETW/Sysmon file events | `inotify` is path/watch oriented and can miss semantic policy context; `fanotify` is broader and can support permission events depending on privilege/config. |
| Receive structured kernel/user events | netlink families, audit, connector-style interfaces where used | ETW providers, Event Log, WMI, callbacks | Linux has multiple event channels rather than one ETW-like fabric. Audit is policy/security oriented; netlink is subsystem protocol. |
| Trace execution paths | ftrace, tracepoints, kprobes, uprobes, perf events, eBPF/bpftrace | ETW/WPA/xperf, WPP, debugger breakpoints | Tracepoints are stable-ish named hooks; kprobes/uprobes are dynamic and more fragile; eBPF adds programmable filtering under verifier and privilege constraints. |
| Observe or enforce security hooks | LSM hooks, BPF LSM, seccomp-BPF, cgroup BPF | SRM/callbacks/minifilters/WFP/ETW-adjacent policy points | BPF can be observability, filtering, or policy depending on attach type. The verifier and attach permissions are part of the security model. |

The strong analogy is not "Linux eventfd equals Windows event." It is: both kernels need ways to block, wake, notify, and observe state transitions, but Windows normalizes many waits through handles and dispatcher objects, while Linux normalizes many user-visible notifications through file descriptors, futex addresses, subsystem event streams, and tracing hooks.

Modern `select()` stance:

- `select()` is still useful to recognize, and it can be acceptable for tiny, portable, low-fd-count tools.
- It is usually the wrong default for scalable services because it has a fixed `fd_set` bitmap model, an `FD_SETSIZE` ceiling in common libc usage, destructive input/output sets that must be rebuilt, and O(n) scanning up to `nfds` on each call.
- `pselect()` fixes the classic signal-mask race around "unblock signal and start waiting", but it does not make `select()` a high-scale readiness API.
- `poll()` avoids the fixed bitmap interface but still scans a list. `epoll` is the normal Linux readiness primitive for many fds. `io_uring` is a newer submission/completion model when the design benefits from queued operations rather than readiness-only waiting.

Security consequences:

- An event-like Linux design should name whether the authority is an fd, a memory address plus process mapping, a watched inode/path, a BPF program/map, a netlink socket, or a kernel-internal wait queue.
- `epoll` readiness is not completion ownership. Readiness can be stale by the time userspace acts, and subsystem teardown can create lifetime bugs when watched objects outlive or out-die their owners.
- `inotify`/`fanotify` visibility depends on watched objects, mount namespaces, privilege, queue overflow, and whether the event stream represents notification or permission mediation.
- eBPF/perf/ftrace visibility depends on attach point, kernel config, capabilities, BPF token/LSM policy where used, verifier acceptance, and whether the event is a stable tracepoint or a fragile probe.

## Services, Daemons, Sessions

### Linux

- Long-running services are usually daemons supervised by `systemd`.
- Service lifecycle is connected to cgroups, units, logs, and PID tracking.
- Login/session concepts are handled by PAM, systemd-logind, terminals, cgroups, and process trees.

The authority model is a combination of unit configuration, credentials, capabilities, cgroups, namespaces, and inherited file descriptors. A service's real reach is therefore not just the executable path; it is the full launch context created by the supervisor.

### Windows

- Services are managed by the Service Control Manager.
- A service is normally a process or shared service host controlled through SCM APIs.
- Sessions, window stations, and desktops are central for interactive isolation.
- Session 0 isolation matters: services do not run in the interactive user desktop.

Windows service behavior is not just "daemon with a different manager"; SCM, service accounts, tokens, sessions, and desktops change the security model.

Why this exists: Unix daemons grew naturally from background processes supervised by init systems and later `systemd`, with lifecycle tied to PIDs, cgroups, signals, logs, and unit files. Windows services are managed through SCM because services need a control protocol, named service records, recovery behavior, account selection, service SIDs, dependency management, and session 0 isolation. The design separates non-interactive service authority from interactive desktop users, which matters for both defense and malware persistence.

## Devices and Drivers

### Linux

- Device files under `/dev`.
- Drivers expose file operations, sysfs, procfs, netlink, ioctls, char/block devices.
- Kernel modules can be loaded depending on policy.
- eBPF can extend kernel behavior under verifier constraints.

The common mechanism is that user mode reaches driver state through kernel-mediated objects and subsystem callbacks, so permissions, lifetime, and input validation depend on the exposed interface. The evidence is the device node or subsystem API, open permissions, operation table, private data, and the lifetime rules around close, teardown, and async work.

### Windows

- Driver objects and device objects exist in the Object Manager namespace.
- User mode reaches drivers through device symbolic links and handles.
- I/O is represented by IRPs.
- IOCTLs are a major user-kernel interface.
- Driver signing, HVCI, PatchGuard, and vulnerable driver blocklists are major modern constraints.

Both OSes have drivers and IOCTL risk. Windows driver research requires strong understanding of IRPs, device objects, access checks, buffering modes, and kernel mitigations.

Why this exists: Linux drivers often integrate through subsystem-specific callbacks and expose state through device files, sysfs, procfs, netlink, or ioctls. Windows routes device I/O through the Object Manager and I/O manager so requests can flow as IRPs through layered driver stacks, filters, filesystem drivers, and device drivers. That model supports asynchronous I/O, cancellation, filter drivers, plug and play, power management, and consistent driver dispatch, but it also means IOCTL security and buffering bugs are a major Windows attack surface.

## Malware, Spyware, and Rootkit Technique Mapping

This section is meant for comparison, reverse engineering, and defensive reasoning. The same primitives are used by debuggers, profilers, EDRs, accessibility tools, game anti-cheat, malware, spyware, and rootkits; intent is inferred from context, trust, persistence, stealth, and policy violations.

### Cross-Process Access and Injection

| Technique family | Linux concepts | Windows concepts | What to inspect |
|---|---|---|---|
| Open/attach to target | `ptrace`, `/proc/<pid>/mem`, `process_vm_readv`/`process_vm_writev`, pidfds, namespace/capability gates | `OpenProcess`, handle access masks, `SeDebugPrivilege`, PPL restrictions, object callbacks | Cross-process handles, ptrace relationships, privilege transitions, target protection level. |
| Allocate or map target memory | Remote `mmap` via debugger-like control, shared mappings, memfd-backed mappings | `VirtualAllocEx`, `NtAllocateVirtualMemory`, `NtCreateSection`, `NtMapViewOfSection`, `MapViewOfFile` | New executable/private memory, shared sections between unrelated processes, suspicious RW-to-RX transitions. |
| Write payload/code/data | `/proc/<pid>/mem`, `process_vm_writev`, debugger writes | `WriteProcessMemory`, section-backed writes, mapped-view writes | Writes into executable regions, modified code pages, private copies of image pages. |
| Start or redirect execution | `ptrace` register control, signal/context manipulation, injected thread-like behavior through runtime calls | `CreateRemoteThread`, `NtCreateThreadEx`, `QueueUserAPC`, thread-context hijack, `SetThreadContext`, `RtlCreateUserThread` | New threads with starts outside known modules, APC queues, changed instruction pointers, suspended/resumed threads. |
| Load a library in target | Remote call to dynamic linker functions, preload at exec time, loader state manipulation | Remote `LoadLibrary`/`LdrLoadDll`, DLL injection, `SetWindowsHookEx` for GUI contexts | Module load event source, path trust, unsigned modules, modules not backed by normal files. |
| Replace process image | `execve` after staging, interpreter/script replacement, `memfd` execution patterns | Process hollowing, process doppelganging/herpaderping-style image confusion, section/image replacement patterns | Mismatch between process path, mapped image, command line, file object, and memory content. |
| Manual/in-memory loader | Custom ELF loader, memfd or anonymous executable mappings | Reflective DLL loading, manual PE mapping, shellcode loader | Executable memory without normal loader metadata, absent PEB/linker entries, custom reloc/import resolution. |

The strongest cross-platform analogy is not "CreateRemoteThread equals ptrace." The better abstraction is: gain authority over another process, place or map code/data into its address space, then arrange control flow to execute it.

### User-Mode Hooking and API Interposition

| Goal | Linux mechanisms | Windows mechanisms | Detection hints |
|---|---|---|---|
| Intercept library calls | `LD_PRELOAD`, `LD_AUDIT`, PLT/GOT patching, symbol wrapping | IAT patching, EAT patching, Detours-style inline hooks, delay-load hook changes | Unexpected module load order, writable import tables, branch stubs at function prologues. |
| Intercept syscalls/API boundary | libc wrapper replacement, seccomp user notification, ptrace syscall tracing, eBPF uprobes | Hooked Win32/Native APIs, patched `ntdll` stubs, ETW/AMSI provider tampering attempts | Modified code pages in shared libraries/DLLs, syscall stubs not matching clean image. |
| Observe credentials/input | PAM modules, shell/profile hooks, terminal/session hooks, browser extension/native messaging abuse | Credential providers, SSPs, keyboard hooks, accessibility APIs, browser extensions, COM add-ins | New authentication plugins, unusual signed/unsigned modules in sensitive processes, high-integrity input capture. |
| Hide activity from tools | Interpose `readdir`, `stat`, `procfs` reads, libc wrappers | Hook `NtQuerySystemInformation`, `NtQueryDirectoryFile`, registry/query APIs | User-mode tools disagree with kernel/raw telemetry, hidden entries appear from offline or lower-level views. |

Hooking is not automatically malicious. The red flags are stealth, persistence, privilege mismatch, tampering with security tools, and hooks inside high-value processes without a legitimate owner.

### Persistence and Auto-Start Surfaces

| Persistence class | Linux examples | Windows examples | Defensive question |
|---|---|---|---|
| Service manager | `systemd` units/timers, init scripts | SCM services, service DLLs, drivers | Who created it, when, under what account, and is the binary path trusted? |
| User logon/startup | Shell profiles, desktop autostart entries, cron/anacron, user systemd units | Run/RunOnce keys, Startup folder, scheduled tasks, logon scripts, WMI event consumers | Does it execute in user context and survive reboot/logon? |
| Loader/path hijack | `LD_PRELOAD`, `/etc/ld.so.preload`, rpath/runpath, writable library directories | DLL search-order hijack, side-loading, AppInit DLLs, IFEO debugger, COM hijacking, Winlogon/userinit/shell settings | Is a trusted process loading code from an unexpected writable location? |
| Authentication/plugin path | PAM modules, NSS modules, SSH authorized keys/config, shell replacements | Credential providers, SSP/AP packages, LSA plugins, authentication packages | Is code inserted into login, credential, or token issuance paths? |
| Scheduled/remote management | cron, systemd timers, SSH forced commands, package-manager hooks | Scheduled Tasks, WMI permanent event subscriptions, PowerShell profiles, GPO scripts | Is the trigger hidden in normal admin automation? |
| Kernel/driver | Kernel modules, initramfs changes, eBPF programs pinned in bpffs | Kernel drivers, boot-start drivers, filter drivers | Does it load before defenders, or gain kernel visibility/control? |

### Privilege Escalation Themes

| Theme | Linux | Windows |
|---|---|---|
| Misconfigured authority | SUID/SGID binaries, writable scripts in privileged paths, sudoers mistakes, capabilities on files | Weak service ACLs, writable service paths, unquoted service paths, weak registry/file ACLs, token privileges |
| Kernel attack surface | syscalls, ioctls, filesystems, eBPF/verifier bugs, netfilter, drivers | Native syscalls, IOCTLs, kernel drivers, filter drivers, win32k, CLFS/ALPC/RPC surfaces |
| Credential/token abuse | SSH keys, Kerberos tickets, cached creds, setuid transitions | Access tokens, impersonation/delegation, service accounts, LSASS secrets, Kerberos/NTLM material |
| Namespace/session boundary issues | Containers, user namespaces, mount namespace escapes | AppContainer, lowbox tokens, sessions, jobs/silos, desktop/window station boundaries |

The conceptual mapping is "turn limited code execution into broader authority." The artifacts differ: Linux often exposes permission mistakes through filesystem metadata and capabilities, while Windows often exposes them through ACLs, services, tokens, privileges, and COM/RPC boundaries.

### Kernel Rootkits and Stealth

| Rootkit objective | Linux internals | Windows internals | Modern constraints |
|---|---|---|---|
| Hide process/file/network state | Hook syscalls or file/proc operations, alter kernel lists, VFS/procfs manipulation, netfilter hooks | SSDT/inline hooks historically, object callbacks, filter drivers, DKOM attempts, minifilters, WFP callouts | Kernel lockdown, module signing, eBPF verifier, PatchGuard, HVCI, VBS, driver signing, EDR kernel telemetry. |
| Persist in kernel | Loadable kernel module, initramfs/boot chain, DKMS/package hooks, eBPF persistence where available | Boot-start/system-start drivers, vulnerable-driver abuse, boot configuration, firmware-adjacent persistence | Secure Boot, measured boot, TPM attestation, vulnerable driver blocklists, WDAC. |
| Intercept I/O | LSM hooks, VFS hooks, netfilter, eBPF tracing/filtering, block-layer hooks | File-system minifilters, registry callbacks, process/thread/image callbacks, WFP, NDIS filters | Legitimate security products use many of the same extension points. Trust and signing are central. |
| Tamper with telemetry | Disable audit/eBPF probes, alter procfs/sysfs views, hide module state | Patch ETW/AMSI/user-mode collectors, tamper with callbacks/providers, hide drivers or callbacks | Cross-view detection, kernel memory integrity, and protected processes make simple hiding harder. |

Do not overfit to old textbook rootkits. Modern systems push serious attackers toward signed/vulnerable drivers, boot-chain attacks, living-off-the-land persistence, user-mode telemetry tampering, or abuse of legitimate extension points rather than obvious syscall-table patching.

### Fileless and Memory-Resident Execution

| Idea | Linux | Windows |
|---|---|---|
| Anonymous executable content | `memfd_create`, anonymous mappings, deleted-but-mapped files, interpreter-fed payloads | Private executable pages, section-backed mappings, script engines, in-memory .NET/PowerShell content |
| Backing-file mismatch | Deleted executable still mapped, replaced file after exec, container overlay confusion | Hollowed image, transacted/deleted backing file tricks, mapped section not matching on-disk file |
| Script/runtime abuse | shell, Python, Perl, Lua, JVM, browser runtimes | PowerShell, WSH, MSHTA, Office/VBA, .NET, JavaScript engines |
| Detection emphasis | Memory maps, open deleted files, audit/eBPF, process lineage, command line, interpreter telemetry | ETW, AMSI, Script Block Logging, Sysmon, memory scanners, image-load and section telemetry |

### Network and C2 Surface

| Area | Linux | Windows |
|---|---|---|
| Local firewall/filtering | netfilter/nftables, eBPF/XDP, iptables compatibility | Windows Filtering Platform, Defender Firewall, NDIS filters |
| Socket telemetry | `ss`, `/proc/net`, audit/eBPF, conntrack | ETW network providers, WFP events, Sysmon network events, netstat/GetExtendedTcpTable |
| Proxy/credential integration | environment proxy variables, systemd service env, browser profiles, Kerberos/GSSAPI | WinHTTP/WinINet proxy settings, credential manager, SSPI, browser/enterprise policy |
| Stealth theme | Hide sockets from `/proc`, inject into trusted network daemons, abuse SSH | Inject into trusted signed processes, abuse WinHTTP/COM, live inside service hosts or browsers |

### Spyware Collection Surfaces

| Collection target | Linux | Windows | What changes the risk |
|---|---|---|---|
| Keyboard and UI input | X11 global visibility, Wayland portal/compositor policy, terminal hooks, accessibility frameworks | Low-level keyboard hooks, Raw Input, UI Automation, accessibility APIs, injected GUI hooks | Desktop/session isolation, accessibility permissions, integrity level, trusted input paths. |
| Screen and window content | X11 capture, Wayland restrictions/portals, compositor APIs, browser/desktop extensions | GDI/Desktop Duplication/DXGI capture, window messages, browser/Office add-ins | User consent prompts, session isolation, protected content paths, enterprise policy. |
| Browser/session data | Browser profile files, cookies, extension storage, keyrings, native messaging hosts | Browser profiles, DPAPI-protected secrets, extensions, native messaging hosts, credential manager | Secret storage backend, process integrity, extension policy, disk encryption, profile sync. |
| Credentials and tokens | SSH keys/agents, Kerberos caches, keyrings, PAM/NSS hooks, shell history | DPAPI, LSASS-adjacent secrets, SSPI, credential manager, browser vaults, tokens | Whether secrets are protected by hardware, user presence, process protection, or service isolation. |
| Clipboard and local IPC | X11/Wayland clipboard APIs, D-Bus, Unix sockets | Clipboard APIs, COM/RPC, named pipes, window messages | Session boundaries and brokered access decide how broad observation can be. |
| Audio/camera/location | PipeWire/PulseAudio/ALSA, V4L2, desktop portals | Media Foundation, DirectShow, device capability prompts, privacy settings | Modern permission brokers matter more than raw device APIs on managed desktops. |

### Anti-Analysis and Telemetry Evasion

| Evasion family | Linux examples | Windows examples | Defensive response |
|---|---|---|---|
| Debugger/sandbox checks | `ptrace` state, `/proc` inspection, timing checks, container/VM artifacts | PEB/debug flags, `NtQueryInformationProcess`, timing checks, VM artifacts, parent/process-name checks | Normalize environment assumptions and correlate with behavior, not just checks. |
| Import/API hiding | Runtime `dlopen`/`dlsym`, direct syscalls, string encryption, custom ELF parsing | Runtime `LoadLibrary`/`GetProcAddress`, API hashing, manual PE export parsing, direct Native API/syscall use | Recover resolved APIs dynamically and label indirect calls. |
| Telemetry tampering | Stop audit agents, alter preload paths, hide from `/proc`, disable or evade eBPF probes | Patch user-mode collectors, interfere with ETW/AMSI, disable services, attack security product processes | Cross-check with kernel, network, memory, and remote logs. |
| Living off the land | shell, SSH, systemd, package managers, interpreters | PowerShell, WMI, rundll32/regsvr32/mshta, scheduled tasks, signed admin tools | Treat trusted binaries as execution containers; inspect command, parentage, and data flow. |
| Packing/obfuscation | UPX/custom ELF packing, encrypted sections, interpreter stubs | PE packers, encrypted resources/sections, staged loaders, .NET obfuscators | Look for unpacking memory transitions, entropy outliers, and post-unpack imports/modules. |

### Cross-View Detection Mindset

- Compare high-level enumerators with lower-level views: `/proc` versus eBPF/kernel memory on Linux; Toolhelp/PSAPI versus VADs, handles, ETW, and kernel callbacks on Windows.
- Compare loader metadata with memory reality: `link_map`/`dl_iterate_phdr` versus `/proc/<pid>/maps`; PEB loader lists versus VADs, `!address`, and image-load telemetry.
- Compare disk with memory: mapped image hashes, deleted backing files, private executable pages, modified shared-library/DLL code pages.
- Compare declared identity with authority: command line, parent/creator, token or UID, integrity/capabilities, namespace/session, code signature/package origin.
- Treat API names as clues, not proof. A benign debugger and malware may both use cross-process memory APIs; the difference is authorization, target choice, persistence, stealth, and operator intent.

## Observability and Debugging

| Task | Linux | Windows |
|---|---|---|
| Process tree | `ps`, `/proc`, `pstree` | Process Explorer, WMI, ETW, process snapshot APIs |
| Syscall/API trace | `strace`, eBPF, audit | Procmon, ETW, API Monitor, debugger breakpoints |
| Memory map | `/proc/<pid>/maps`, `pmap` | VMMap, WinDbg `!address` |
| Loaded modules | `/proc/<pid>/maps`, `ldd` | Process Explorer, WinDbg `lm`, PEB loader lists |
| Kernel debug | `kgdb`, crash, drgn, ftrace | WinDbg kernel debugging, crash dumps |
| Event telemetry | auditd, journald, eBPF, LSM logs | ETW, Windows Event Log, Sysmon, Defender telemetry |
| Dynamic loader trace | `LD_DEBUG`, `ldd`, audit modules, debugger breakpoints on loader | Loader snaps, ETW image-load events, Procmon, debugger breakpoints on `LdrLoadDll` | Follow module loads and dependency resolution. |
| Injection triage | `/proc/<pid>/maps`, `pmap`, ptrace/audit/eBPF events, deleted mapped files | VADs, handles, thread starts, image-load ETW, Sysmon Event IDs, `!vad`, `!handle` | Look for cross-process access plus executable memory plus unusual control-flow starts. |
| Rootkit triage | module list, kernel taint, BPF program lists, audit/eBPF cross-checks, offline memory | driver list, callback lists, PatchGuard/HVCI state, memory forensics, boot measurements | Cross-view and offline analysis matter because rootkits can lie to normal APIs. |

Linux often exposes live state through pseudo-files. Windows often exposes it through APIs, ETW, handles, object namespaces, and debugger extensions.

Why this exists: Linux observability benefits from the same filesystem-shaped interface as the rest of the system: `/proc`, `/sys`, tracefs, debugfs, logs, and eBPF/ftrace/perf surfaces. Windows relies heavily on provider-based eventing and tooling because many important resources are typed objects rather than files, and because enterprise diagnostics need structured, correlated events across processes, files, registry, network, image loads, services, and drivers. ETW is not just "Windows logging"; it is a core instrumentation fabric.

### Practical Tool Equivalents

| Linux habit | Windows tool/workflow | What to learn |
|---|---|---|
| `ps`, `pstree`, `top`, `/proc/<pid>/status` | Process Explorer, Task Manager Details, PowerShell `Get-Process`, WMI/CIM | Parent metadata, token/integrity, loaded modules, handles, job membership. |
| `lsof`, `/proc/<pid>/fd` | Process Explorer lower pane, Sysinternals handle.exe, WinDbg `!handle` | Handle type, granted access, object name, inheritance, duplicate handles. |
| `strace -f` | Procmon, ETW traces, API Monitor, debugger breakpoints | Procmon shows semantic file/registry/process/network operations; raw syscall tracing is rarely enough. |
| `/proc/<pid>/maps`, `pmap` | VMMap, `VirtualQueryEx`, WinDbg `!address`, `!vad` | Private vs mapped vs image memory, protection, commit, VADs, suspicious executable regions. |
| `ldd`, `/proc/<pid>/maps` modules | Process Explorer DLL view, WinDbg `lm`, ETW image-load events | Loader paths, signed/unsigned modules, API sets, manually mapped code clues. |
| `journalctl`, auditd | Event Viewer, Windows Event Log, Sysmon, ETW/WPA | Provider/event model, event IDs, correlation across process/image/file/registry/network. |
| `perf`, ftrace, eBPF | ETW/WPA/xperf, Windows Performance Recorder, debugger instrumentation | Kernel/user provider tracing and stack capture. |
| `gdb`/`lldb` | WinDbg/cdb, Visual Studio debugger | PDB symbols, extension commands, PEB/TEB, handles, VADs, loader state. |
| `systemctl`, unit files | services.msc, `sc.exe`, PowerShell service cmdlets, registry service keys, Autoruns | SCM lifecycle, service accounts, service DLLs, failure actions, dependencies. |
| `lsmod`, `/sys`, `modinfo` | driverquery, Device Manager, WinObj, WinDbg `lm`, Driver Verifier | Driver objects, device objects, symbolic links, minifilters, callbacks, signing. |
| `iptables`/`nft`, `ss` | Windows Defender Firewall, WFP-aware tools, `netstat`, ETW network providers | WFP layers, filtering callouts, per-process network telemetry. |

### Windows Triage Workflow For Linux Readers

1. Identify the process: image path, command line, parent metadata, token user, integrity level, session, job, and whether it is protected or a service.
2. Inspect loaded code: DLL list, image-load events, module paths, signatures, API-set forwarding, and whether executable memory exists outside normal modules.
3. Inspect handles: process/thread/file/section/token/event/ALPC handles, granted access, inheritance, and cross-process handles into sensitive targets.
4. Inspect memory: VAD layout, private executable pages, mapped sections, image-backed regions, protection changes, and disk-memory mismatch.
5. Inspect persistence: services, scheduled tasks, Run keys, WMI consumers, COM registrations, IFEO, shell extensions, drivers, and startup folders.
6. Inspect telemetry: Procmon for semantic operations, ETW/Sysmon/Event Log for correlation, WinDbg/VMMap for lower-level state.
7. Cross-check views: friendly APIs, ETW, handles, VADs, file signatures, and offline artifacts should agree. Disagreement is often the clue.

## Containers and Isolation

### Linux

- Containers are mostly namespaces plus cgroups plus filesystem layering plus capabilities/seccomp/LSM policy.
- PID namespaces make process parentage appear different inside the container.
- cgroups strongly shape resource accounting and service supervision.

The reason containers are not a single mechanism is that isolation is composed: namespaces change views, cgroups constrain resources, capabilities/seccomp/LSM reduce authority, and the host kernel is still shared. Any escape or hardening discussion has to identify which layer failed rather than saying "container" as if it were one boundary.

### Windows

- Windows has jobs, silos, sessions, AppContainers, lowbox tokens, integrity levels, and Hyper-V backed isolation options.
- Windows Server containers and Hyper-V containers use different isolation boundaries.
- Job objects are important for process grouping and limits but are not identical to cgroups.

Useful analogy: Linux cgroups and Windows job objects both constrain groups of processes, but Linux containers also rely heavily on namespaces, while Windows has its own silo/session/token model.

Why this exists: Linux containers are a natural extension of namespaces, cgroups, capabilities, seccomp, LSM labels, and filesystem layering. They virtualize views of existing Unix resources. Windows isolation evolved through jobs, sessions, window stations/desktops, access tokens, AppContainers, silos, and Hyper-V-backed isolation. Jobs can limit and group processes, but they do not replace namespaces; Windows isolation often combines token restrictions, object namespace isolation, session boundaries, and sometimes a lightweight VM boundary.

## End-to-End Operation Flows

These flows are the most useful way to transition from Linux internals to Windows internals. Each one starts from a familiar Linux operation and follows the equivalent Windows path through user mode, kernel objects, authority checks, and observability. The "why" behind each flow is usually the same pattern: Linux favors a compact Unix abstraction that composes with FDs, paths, process trees, and shell tools; Windows favors typed securable objects, explicit handles, compatibility layers, and subsystem-specific managers.

### Opening a File

| Step | Linux | Windows |
|---|---|---|
| User API | `open`, `openat`, `fopen`, language runtime wrappers | `CreateFileW`, CRT `_wopen`, .NET/PowerShell wrappers |
| Path interpretation | VFS resolves path through mount namespace, dentries, inodes, symlinks, bind mounts | Win32 normalizes path, then Native API uses NT paths such as `\Device\HarddiskVolume...\path`; Object Manager resolves device objects and symbolic links |
| Security check | Current credentials, mode bits, POSIX ACLs, capabilities, LSM policy, mount flags | Access token, desired access mask, file security descriptor, share mode, integrity policy, privileges, reparse point policy |
| Kernel object | FD table entry points to a `struct file`, which references inode/dentry/path and file operations | Process handle table entry references a `FILE_OBJECT` with granted access and related device/section/cache state |
| I/O execution | VFS calls filesystem/device `file_operations`; page cache and block layer may participate | I/O manager sends IRPs through filesystem/filter/device stacks; cache manager and memory manager may participate |
| Observation | `strace`, audit, eBPF, `/proc/<pid>/fd`, `lsof`, `fanotify` | Procmon, ETW file I/O providers, Sysmon, handle inspection, WinDbg `!fileobj`/`!handle` |

Transition rule: a Linux file open returns a small FD tied to VFS state. A Windows file open returns a handle to an object, with explicit granted access and sharing semantics that can block later opens even if ACLs allow them.

Why: Linux assumes pathname resolution plus credentials produce an open file description that later operations can use. Windows adds share modes and granted access because many applications coordinate through mandatory sharing rules and because the handle is the durable authority token for future operations on that file object.

### Creating a Process

| Step | Linux | Windows |
|---|---|---|
| Common API | `fork` plus `execve`, or `posix_spawn` | `CreateProcessW`, lower-level `NtCreateUserProcess` |
| Initial model | `fork` clones parent state with copy-on-write; `execve` replaces the current image; `posix_spawn` is a POSIX API that usually combines creation plus exec-like behavior behind a library/runtime contract | New process object, address space, image section, parameters, token, and initial thread are created as one operation |
| Image loading | Kernel validates executable/interpreter, maps ELF/interpreter, passes control to dynamic linker | Image file is opened, section object is created/mapped, PEB/process parameters are prepared, loader initializes DLLs in user mode |
| Inheritance | File descriptors, environment, signal dispositions, credentials subject to exec rules | Handles marked inheritable, environment block, current directory, token, mitigation policy, parent/process attributes |
| Lifetime | Parent may `wait`; unreaped dead children become zombies | Process object is waitable by any holder of a suitable handle; no zombie reaping; object survives while handles exist |
| Observation | `pstree`, `/proc`, `strace -f`, audit/eBPF, `waitpid` state | Process Explorer, ETW process/thread/image events, Procmon, Sysmon, WinDbg `!process`/`!handle` |

Transition rule: Linux process creation is often clone-and-replace, while `posix_spawn` exposes a higher-level "start this program" contract. Windows process creation is object/image/thread construction around an executable section.

Why: Linux optimizes around the parent as a template. Windows optimizes around an executable image, explicit creation attributes, and compatibility/security policy applied before the initial thread runs.

### Loading a Shared Library or DLL

| Step | Linux | Windows |
|---|---|---|
| Static dependency load | ELF interpreter and `ld-linux` load `DT_NEEDED` objects | Windows loader loads import dependencies, API set forwarders, side-by-side assemblies where applicable |
| Runtime load | `dlopen` calls dynamic linker | `LoadLibrary`/`LoadLibraryEx` call loader routines such as `LdrLoadDll` |
| Symbol lookup | `dlsym`, symbol visibility, versions, PLT/GOT, interposition rules | `GetProcAddress`, export directory, forwarded exports, ordinal/name lookup |
| Initialization | constructors, `.init_array`, TLS setup | TLS callbacks, CRT initialization, `DllMain` under loader lock |
| Search policy | rpath/runpath, `LD_LIBRARY_PATH`, `ld.so.cache`, trusted system paths, preload rules | application directory, system directories, KnownDLLs, manifests, API sets, packaged-app policy, safe search settings |
| Observation | `LD_DEBUG`, `ldd`, `/proc/<pid>/maps`, `dl_iterate_phdr`, debugger breakpoints | Loader snaps, ETW image-load events, PEB loader lists, Procmon, WinDbg `lm` and loader breakpoints |

Transition rule: `dlopen`/`dlsym` and `LoadLibrary`/`GetProcAddress` are concept peers, not behavioral twins. ELF symbol interposition is a normal design feature; PE import/export behavior is more explicit and loader-policy driven.

Why: ELF treats process-wide symbol resolution and interposition as normal linking behavior. Windows treats DLL loading more as explicit module loading under compatibility and search-policy rules, with the loader patching imports and honoring PE-specific metadata.

### Making a Syscall or Native OS Call

| Step | Linux | Windows |
|---|---|---|
| Normal call path | App calls libc; libc may wrap, cache, emulate, or enter kernel | App calls Win32/COM/CRT; code often reaches `kernelbase`/`kernel32`, then `ntdll` Native API |
| Kernel transition | libc or inline stub uses architecture syscall ABI | `ntdll` syscall stub enters kernel using build-specific service number |
| ABI stability | Syscall numbers are a public per-architecture ABI | Win32 API is stable; Native API is less documented; syscall numbers are not a stable app contract |
| Work before kernel | libc may do thread cancellation, errno handling, vDSO, buffering | Win32 may perform path normalization, parameter conversion, app-compat behavior, API set resolution, RPC/ALPC, or user-mode fallback |
| Observation | `strace`, perf, ftrace, audit, eBPF tracepoints/kprobes/uprobes | Procmon for semantic events, ETW, API Monitor, debugger breakpoints, syscall tracing in specialized tools |

Transition rule: on Linux, syscall tracing often gives the main truth. On Windows, syscall tracing alone is too low-level and misses important Win32/user-mode behavior.

Why: Linux intentionally exposes syscalls as a stable ABI. Windows intentionally hides kernel service details behind documented APIs so compatibility can survive kernel changes.

### Allocating, Mapping, and Protecting Memory

| Step | Linux | Windows |
|---|---|---|
| Reserve/commit model | `mmap` creates mappings; overcommit policy can defer physical commitment | `VirtualAlloc` explicitly reserves address space and commits pages; commitment is a first-class accounting concept |
| File mapping | `mmap` maps file pages through VMAs and page cache | `CreateFileMapping`/`MapViewOfFile` or `NtCreateSection`/`NtMapViewOfSection` map section views |
| Image mapping | ELF executable/shared object mappings are VMAs with permissions from program headers | PE images are mapped as image sections; VADs distinguish image, mapped, and private memory |
| Protection changes | `mprotect` changes VMA permissions | `VirtualProtect`/`NtProtectVirtualMemory` change page protections |
| Copy-on-write | `fork` and private mappings rely heavily on COW | Image sections and mapped views use COW for modified image/shared pages; no normal `fork` workflow |
| Observation | `/proc/<pid>/maps`, `/proc/<pid>/smaps`, `pmap`, perf/eBPF | VMMap, `VirtualQueryEx`, WinDbg `!address`/`!vad`, ETW memory/image events |

Transition rule: Linux memory analysis starts with VMAs. Windows memory analysis starts with VADs plus the distinction between private, mapped, and image-backed regions.

Flag rule: Linux often exposes the key semantics as `mmap`/`mprotect`/`madvise` flags. Windows spreads the same ideas across allocation type (`MEM_RESERVE`, `MEM_COMMIT`, `MEM_RESET`, `MEM_LARGE_PAGES`), protection (`PAGE_READWRITE`, `PAGE_EXECUTE_READ`, `PAGE_GUARD`, CFG target flags), and mapping view access (`FILE_MAP_READ`, `FILE_MAP_WRITE`, `FILE_MAP_COPY`, `FILE_MAP_EXECUTE`). Treat these as policy inputs to VMA/VADs and PTEs, not as isolated API trivia.

Why: Linux centers analysis on mappings described by VMAs. Windows centers analysis on allocation state, commit accounting, protection, section backing, and whether memory came from an image, mapped file, or private allocation.

### Reading Process State

| Step | Linux | Windows |
|---|---|---|
| Process metadata | `/proc/<pid>/status`, `/proc/<pid>/cmdline`, `/proc/<pid>/environ`, `/proc/<pid>/fd` | Process APIs, PEB/process parameters, WMI, ETW snapshots, handle queries |
| Memory map | `/proc/<pid>/maps` and `smaps` | `VirtualQueryEx`, VMMap, WinDbg `!address`, VAD tree |
| Loaded modules | `/proc/<pid>/maps`, `ldd`, `dl_iterate_phdr` | PEB loader lists, PSAPI/Toolhelp, ETW image-load events, WinDbg `lm` |
| Open resources | `/proc/<pid>/fd`, `lsof` | Handle table queries, Process Explorer/handle.exe, WinDbg `!handle` |
| Trust boundary | `ptrace_scope`, credentials, namespaces, capabilities, LSM | access masks on process handles, integrity levels, privileges, PPL, session boundaries |

Transition rule: Windows has no single `/proc` replacement. You assemble truth from APIs, handles, ETW, memory manager state, and debugger views.

Why: Linux exposes process state through a filesystem-shaped live interface. Windows exposes different slices of process state through the API layer that owns each abstraction: process manager, Object Manager, memory manager, loader, ETW providers, and debugger data.

### IPC and Synchronization Flow

| Step | Linux | Windows |
|---|---|---|
| Basic wait | `wait`, futex, `poll`, `epoll`, signals, condition variables | `WaitForSingleObject`, `WaitForMultipleObjects`, dispatcher objects, APCs, IOCP |
| Named/local IPC | Unix sockets, pipes, FIFOs, D-Bus, netlink | Named pipes, ALPC, RPC, COM, mailslots in legacy cases |
| Shared memory | `mmap`, `shm_open`, SysV shared memory, memfd | Section objects and file mappings |
| Async I/O | `epoll`, `io_uring`, signals, eventfd | Overlapped I/O, IOCP, threadpool I/O, APC completion in some paths |
| Observation | `ss`, `lsof`, `/proc`, strace/eBPF | Procmon, ETW, handle inspection, RPC/ALPC debugging, WinDbg extensions |

Transition rule: Linux pushes many async flows through FD readiness. Windows pushes many async flows through waitable objects, IOCP, APCs, threadpools, and subsystem-specific RPC/ALPC.

Why: Unix composability favors "wait until this descriptor is ready." Windows composability favors "wait on this object or receive completion for this operation," which scales across files, processes, events, timers, console objects, GUI messages, and asynchronous device I/O.

### Service or Daemon Startup

| Step | Linux | Windows |
|---|---|---|
| Manager | `systemd`, init, supervisor, cron/timers | Service Control Manager, Scheduled Tasks, WMI event consumers, Group Policy startup/logon scripts |
| Unit definition | unit file, environment, cgroup, dependencies, capabilities, namespace options | service registry keys, binary path or service DLL, account/token, service SID, dependencies, recovery actions |
| Runtime identity | UID/GID, capabilities, namespaces, cgroup | service account, token privileges, integrity level, service SID, session 0, desktop isolation |
| Control protocol | signals, `systemctl`, watchdog notifications, cgroup state | SCM control codes, service status reports, stop/pause/interrogate handlers |
| Logs and telemetry | journald, syslog, audit, cgroup accounting | Event Log, ETW, SCM events, Sysmon, WMI |

Transition rule: a Windows service is not just a daemon. SCM, service accounts, service SIDs, session 0, registry configuration, and recovery policy are part of the security and lifecycle model.

Why: Windows separates long-running machine services from interactive users and gives them a manager, account model, dependency graph, status protocol, and recovery policy. That is why service configuration is security-sensitive even before looking at the service binary.

### Driver and IOCTL Path

| Step | Linux | Windows |
|---|---|---|
| User entry | open device file under `/dev`, then read/write/ioctl/mmap | open device symbolic link with `CreateFile`, then `DeviceIoControl`, read/write, mapped sections in some designs |
| Kernel object path | VFS reaches character/block driver `file_operations` or subsystem-specific hooks | Object Manager resolves symbolic link to device object; I/O manager builds IRPs for driver stack |
| Request representation | syscall arguments, `struct file`, driver-defined ioctl data, subsystem buffers | IRP plus `IO_STACK_LOCATION`, buffering mode, MDLs, device/driver objects |
| Security boundary | file mode/ACLs, capabilities, LSM, namespaces, device cgroup | device object security descriptor, handle access mask, IOCTL access bits, caller token, driver checks |
| Extension model | kernel modules, built-in drivers, eBPF/LSM/netfilter/filesystem hooks | WDM/WDF drivers, minifilters, WFP callouts, registry/process/thread/image callbacks |
| Observation | audit/eBPF/ftrace, `/sys`, `/proc`, module list, dynamic debug | Driver Verifier, ETW, WinDbg kernel debugging, Procmon, device tree/object namespace, verifier logs |

Transition rule: Windows driver communication is usually an Object Manager plus I/O manager plus IRP story. Always ask what device object was opened, what access was granted, and what the IOCTL buffering/security contract is.

Why: Windows needs layered drivers and filters to cooperate across filesystem, storage, network, security, plug-and-play, and power-management paths. IRPs are the packet format that lets those layers forward, complete, cancel, inspect, or transform I/O.

### Registry and Configuration State

| Step | Linux | Windows |
|---|---|---|
| Configuration storage | text files under `/etc`, user dotfiles, service unit files, package databases, desktop settings stores | Registry hives plus files, service registry keys, COM registration, policy keys, application config files |
| API path | normal file I/O for many configs, subsystem-specific tools | `RegOpenKeyEx`/Native registry APIs, Group Policy, WMI, installer/COM APIs |
| Security | filesystem permissions, MAC policy, package ownership | registry key security descriptors, token privileges, integrity, registry virtualization in some compatibility contexts |
| Persistence relevance | cron/systemd/profile/package hooks, writable config paths | Run keys, services, scheduled tasks, IFEO, COM hijacks, shell extensions, WMI subscriptions |
| Observation | file integrity monitoring, auditd, package verification | Procmon registry events, Event Log, Sysmon, Autoruns, registry transaction/log analysis |

Transition rule: Windows uses the registry as a first-class configuration database and object namespace adjacent to the filesystem. For persistence and system behavior, registry state is as important as files on disk.

Why: Windows needs structured machine/user configuration, ACLs, policy distribution, COM/service registration, hardware/software inventory, and compatibility settings that can be managed by APIs and enterprise tooling. The registry solves that differently from editable text files under `/etc`.

### Cross-Process Inspection and Injection Model

| Step | Linux | Windows |
|---|---|---|
| Obtain authority | matching UID, `ptrace` permission, capabilities, namespace/LSM policy | process handle with needed access, token privileges, integrity/PPL/session restrictions |
| Inspect memory | `ptrace`, `/proc/<pid>/mem`, `process_vm_readv`, core dumps | `ReadProcessMemory`, `NtReadVirtualMemory`, minidumps, debugger APIs |
| Modify memory | debugger writes, `/proc/<pid>/mem`, `process_vm_writev` | `WriteProcessMemory`, mapped sections, debugger APIs |
| Change execution | register/context control, signals, remote dynamic-linker calls under debugger control | remote thread, APC, context hijack, debug APIs, section/image manipulation |
| Defensive view | correlate ptrace/write events, memory maps, deleted mappings, process lineage | correlate handles, VADs, thread starts, image loads, ETW/Sysmon, memory protection changes |

Transition rule: do not memorize one injection API as the equivalent. The invariant is authority over the target, memory placement, and control-flow redirection.

Access-right detail: on Windows, the handle is the durable authority artifact. `PROCESS_VM_READ` is the `ReadProcessMemory` bit; `PROCESS_VM_WRITE` and `PROCESS_VM_OPERATION` are the write/address-space-operation bits; `PROCESS_CREATE_THREAD`, `PROCESS_DUP_HANDLE`, `PROCESS_SUSPEND_RESUME`, and query rights are separate capabilities that often appear in tooling. On Linux, the comparable question is not "which handle bit?" but "would this operation pass the ptrace/procfs/capability/namespace/LSM checks, and does the target VMA allow the requested access?"

Why: injection techniques differ because the object and security models differ, but the underlying problem is universal. The attacker or tool must pass an authority check, create or modify executable state, and cause a thread to execute the desired code path.

### Debugging and Crash Analysis

| Step | Linux | Windows |
|---|---|---|
| User-mode live debug | gdb/lldb, `strace`, perf, eBPF uprobes | WinDbg/cdb, Visual Studio debugger, Procmon, Process Explorer, ETW/WPA |
| Kernel debug | kgdb, crash, drgn, ftrace, kdump | WinDbg kernel debugging, crash dumps, Driver Verifier, KDNET/VM debugging |
| Symbols | DWARF, build IDs, distro debug packages | PDBs, Microsoft public symbol server, private symbols when available |
| Crash artifacts | core dumps, kdump/vmcore, journald/audit context | user dumps, kernel dumps, WER reports, Event Log, ETW traces |
| First commands/views | backtrace, registers, mappings, FDs, threads, syscalls | `!analyze -v`, `lm`, `!peb`, `!teb`, `!handle`, `!address`, `!process`, `!thread` |

Transition rule: on Windows, symbol configuration and debugger extensions are not optional extras; they are how much of the OS becomes readable.

Why: Linux kernel source and DWARF/debug packages often make structure discovery direct. Windows internals are exposed through public/private PDBs, WDK headers, and debugger extensions, so correct symbols are the difference between useful object-level analysis and raw addresses.

## Common Bad Analogies

- "Windows parent process is like Linux PPID." Only partly true. Windows parentage is weak metadata; Linux parentage drives waiting, reparenting, and zombies.
- "Windows handles are just file descriptors." Only partly true. Handles cover many object types and carry granted access masks.
- "Windows syscall numbers are like Linux syscall numbers." Bad assumption. Windows SSNs are not a stable public ABI.
- "DLL side-loading is just `LD_LIBRARY_PATH` abuse." Similar risk class, different loader rules and mitigations.
- "`dlopen` is exactly `LoadLibrary` and `dlsym` is exactly `GetProcAddress`." They solve similar runtime-loading problems, but ELF symbol scope/versioning and PE export/IAT behavior differ.
- "CreateRemoteThread injection is the Windows version of `ptrace` injection." The broader pattern maps better than the specific API: cross-process authority, memory placement, and control-flow redirection.
- "Rootkits mainly hook syscall tables." Historically important, but modern Linux and Windows rootkits also abuse legitimate extension points, signed or vulnerable drivers, boot trust gaps, and telemetry tampering.
- "Spyware is just keylogging." Modern spyware is usually broader: credentials, browser data, screenshots, clipboard, microphone/camera, local IPC, extensions, and cloud/session tokens.
- "SYSTEM is root." Similar power level in many cases, but Windows privileges, integrity, PPL, service SIDs, and tokens make this more nuanced.
- "Windows services are daemons." Similar role, different control plane and security model.
- "Signals are APCs." Not equivalent. APCs require alertable waits and are thread-targeted execution mechanisms.

## Quick Interview Answers

### What happens if a parent dies?

Linux: child is reparented, normally to PID 1 or a subreaper. If the child exits before being waited on, it can become a zombie until reaped. The reason is that Linux exit status is part of the parent/child contract: the dead task's heavy resources are gone, but a small kernel record remains so the parent can collect status through `wait*`.

Windows: child keeps running. The parent-child link does not impose lifetime dependency. The process object persists after termination while handles remain open. Use job objects for group lifetime control. The reason is that Windows lifetime is object-handle based: a process is a waitable object with references, not an entry that must be reaped only by its parent.

### What is the closest Windows equivalent to `fork`?

There is no normal equivalent. Windows process creation is `CreateProcess` / `NtCreateUserProcess`, which creates a new process around an image rather than exposing a general user-mode contract that duplicates the current address space and continues both parent and child from the same instruction stream. This difference exists because Windows process creation is centered on object creation, image sections, explicit handles, process parameters, and a new initial thread, while Unix `fork` is centered on duplicating process state and relying on COW to make that cheap. Some internal/native mechanisms can clone process-like state, but they are not the normal application model and should not be treated like Unix `fork`.

### What is the closest Linux equivalent to a Windows handle?

A file descriptor is the closest everyday analogy, but it is incomplete. A Windows handle references a kernel object of a specific type and includes granted access rights. Linux FDs cover many things, but Windows object handles are broader and more explicitly tied to the Object Manager and security descriptors. The interview-safe rule is to ask what authority travels with the reference: an fd usually represents an opened file/socket-like object, while a Windows process/token/section handle can carry reusable rights that later APIs consume without reopening the original name.

### What is the closest Windows equivalent to `/proc/<pid>/maps`?

There is no single file. Use VMMap, Process Explorer, WinDbg `!address`, `lm`, PEB loader lists, VAD inspection, and memory-query APIs such as `VirtualQueryEx`. The reason is that Windows memory state is split across memory-manager VADs, section objects, image loader metadata, PTE state, and user-mode PEB lists. Strong evidence comes from cross-checking those views: private executable VADs, image-backed mappings, loader-list entries, thread start addresses, and modified image pages should tell a coherent story.

### What is the closest Windows equivalent to Linux credentials?

An access token. It contains user SID, group SIDs, privileges, integrity level, default DACL, session information, and possibly AppContainer/capability data. The reason this is the right analogy is that both Linux `cred` and Windows tokens are data representations of authority, but Windows access checks combine the token with object security descriptors, mandatory integrity, privileges, impersonation state, and sometimes protection level. Evidence is the actual token attached to the process or thread, not the username string.

### What are the Windows equivalents of `dlopen` and `dlsym`?

The closest everyday equivalents are `LoadLibrary`/`LoadLibraryEx` and `GetProcAddress`. The lower-level loader equivalents are `LdrLoadDll` and `LdrGetProcedureAddress` in `ntdll`. Treat them as conceptually related, not identical, because ELF and PE have different symbol, dependency, initialization, and search semantics. The "why" is that runtime loading is a loader-policy decision, not just a function lookup: search order, manifests/API sets, KnownDLLs, loader lock, TLS callbacks, `DllMain`, and export forwarding can all affect what actually runs.

### What is the core cross-platform model for process injection?

Authority over a target process, a way to place or map code/data into its address space, and a way to redirect or create execution. Linux and Windows expose different APIs for those steps, but the model is the same. The "why" is that execution is ultimately a thread consuming bytes from an executable mapping under that process's address-space and token/credential context. Useful analysis therefore separates the authority primitive, the memory primitive, and the execution primitive, then validates each with handles/fds, VMA/VAD state, thread start/context evidence, loader metadata, and telemetry.

## High-ROI Study Pairs

- Linux process tree, zombies, `waitpid` -> Windows process handles, exit status, job objects.
- Linux `fork`/`execve` -> Windows `CreateProcess`, image sections, initial thread.
- Linux FDs -> Windows handles and granted access masks.
- Linux UID/GID/capabilities -> Windows tokens/SIDs/privileges/integrity.
- Linux `/proc/<pid>/maps` and VMAs -> Windows VADs, VMMap, `!address`.
- Linux ELF/ld.so/PLT/GOT -> Windows PE loader/IAT/API sets/TLS callbacks.
- Linux `dlopen`/`dlsym` -> Windows `LoadLibrary`/`GetProcAddress` and `LdrLoadDll`/`LdrGetProcedureAddress`.
- Linux `LD_PRELOAD`/PLT-GOT interposition -> Windows DLL side-loading/IAT-inline hooking, with different loader rules.
- Linux `ptrace`/`process_vm_writev`/`/proc/<pid>/mem` -> Windows `OpenProcess`/`WriteProcessMemory`/section mapping/thread or APC execution.
- Linux LKMs/eBPF/netfilter/LSM hooks -> Windows drivers/minifilters/WFP/callbacks.
- Linux X11/Wayland/portal/keyring/browser-profile boundaries -> Windows sessions/desktops/UIAccess/DPAPI/browser-profile boundaries.
- Linux signals -> Windows waits, APCs, exceptions, console events, messages.
- Linux cgroups/namespaces -> Windows jobs/silos/sessions/AppContainers.
- Linux audit/eBPF/strace -> Windows ETW/Procmon/Sysmon/WinDbg.

## Why-First Study Prompts

Use these to test whether the comparison is understood, not just memorized.

- Why does Windows need handles with granted access instead of using one FD-like integer model for everything?
- Why does Windows process creation start from an image section instead of cloning the parent like `fork`?
- Why are Windows process parent IDs useful for telemetry but weak for lifecycle control?
- Why does Windows keep Win32 stable while allowing Native API details and syscall numbers to vary?
- Why do access tokens need SIDs, groups, privileges, impersonation, integrity, and AppContainer state instead of only UID/GID-like fields?
- Why does Windows memory analysis care so much about private versus mapped versus image-backed memory?
- Why is the registry security-sensitive in the same way `/etc`, unit files, package hooks, and desktop autostart files are security-sensitive on Linux?
- Why are IRPs and layered driver stacks central to Windows I/O, while Linux driver reasoning often starts from VFS/subsystem callbacks?
- Why does ETW/Procmon often explain Windows behavior better than raw syscall tracing?
- Why do Windows rootkit and EDR discussions focus on callbacks, minifilters, WFP, signed drivers, PatchGuard, HVCI, and PPL rather than only syscall hooks?

### Why-First Answer Key

The answers should be derivable from the main sections above. This compact key makes the expected reasoning explicit.

| Prompt | Expected answer |
|---|---|
| Why does Windows need handles with granted access instead of using one FD-like integer model for everything? | NT generalizes more than byte-stream I/O. Handles represent typed Object Manager objects such as files, processes, threads, tokens, sections, events, registry keys, desktops, and ALPC ports. A handle carries reference-counted lifetime, granted access, inheritance, duplication, auditing, waiting behavior, and object security. Linux FDs intentionally optimize for a small uniform I/O interface. |
| Why does Windows process creation start from an image section instead of cloning the parent like `fork`? | Windows optimizes process creation around an executable image, explicit process attributes, security tokens, inherited handles, mitigation policy, process parameters, GUI/session state, and compatibility policy. Starting from an image section gives the kernel and loader a controlled setup point. Linux `fork` works naturally in a Unix shell/process-tree model where the parent is the template and `execve` replaces the image. |
| Why are Windows process parent IDs useful for telemetry but weak for lifecycle control? | Windows process lifetime is reference-counted through process objects and handles, not owned by the parent. Any process with a suitable handle can wait on or query another process. Jobs, SCM, sessions, and service policy are stronger lifecycle mechanisms. Linux parentage is stronger because `wait`, zombies, `SIGCHLD`, reparenting, shells, and job control depend on it. |
| Why does Windows keep Win32 stable while allowing Native API details and syscall numbers to vary? | Win32 is the long-term application compatibility contract. Native API and syscall service numbers are implementation layers below that contract, so Windows can change kernel internals, syscall numbers, and object layouts while old applications continue to work through documented APIs. Linux exposes syscalls as a stable user-kernel ABI. |
| Why do access tokens need SIDs, groups, privileges, impersonation, integrity, and AppContainer state instead of only UID/GID-like fields? | Windows was designed for enterprise and networked object-level security. A process or thread may need to represent a user, groups, privileges, service identity, integrity level, AppContainer capabilities, or an impersonated client over RPC/SMB/COM. Access checks combine the token, requested access, security descriptor, integrity rules, and privileges. |
| Why does Windows memory analysis care so much about private versus mapped versus image-backed memory? | Windows uses section objects and VADs to distinguish image mappings, file/shared mappings, and private committed memory. That distinction explains loader state, copy-on-write image pages, injected/private executable memory, mapped sections, and disk-memory mismatch. Linux analysis often starts from VMAs and backing files in `/proc/<pid>/maps`. |
| Why is the registry security-sensitive in the same way `/etc`, unit files, package hooks, and desktop autostart files are security-sensitive on Linux? | The registry stores structured machine/user configuration, service definitions, COM registration, policy, startup locations, IFEO, shell integration, driver/service state, and application compatibility settings. It is an ACL-protected configuration database, so registry writes can change execution and persistence just as privileged config-file changes can on Linux. |
| Why are IRPs and layered driver stacks central to Windows I/O, while Linux driver reasoning often starts from VFS/subsystem callbacks? | Windows routes many I/O requests through the I/O manager as IRPs that pass through device objects, driver objects, filesystem stacks, filters, plug-and-play, power, cancellation, and completion paths. Linux drivers are often reasoned about through VFS operations or subsystem-specific callbacks such as block, network, USB, or character-device paths. |
| Why does ETW/Procmon often explain Windows behavior better than raw syscall tracing? | Many Windows operations have important meaning above the syscall layer: Win32 normalization, registry and file semantics, image loads, services, COM/RPC, object names, provider events, and compatibility behavior. ETW and Procmon show semantic events across subsystems, while raw syscall tracing can be too low-level. On Linux, syscalls more often map directly to the stable public ABI being investigated. |
| Why do Windows rootkit and EDR discussions focus on callbacks, minifilters, WFP, signed drivers, PatchGuard, HVCI, and PPL rather than only syscall hooks? | Modern Windows strongly constrains crude kernel patching with PatchGuard, driver signing, HVCI/VBS, PPL, and telemetry. Legitimate and malicious kernel visibility often flows through supported extension points: process/thread/image callbacks, registry callbacks, file-system minifilters, WFP/NDIS, ETW providers, and signed or vulnerable drivers. Old syscall-table-hook mental models are incomplete. |

## Transition Checklist

Use this as the practical path from Linux internals competence to Windows internals competence.

1. Process model: explain why Windows has no normal `fork`, why parentage is weak, how handles keep terminated process objects alive, and when job objects replace process-tree thinking.
2. Object model: open Process Explorer or WinDbg and identify handles for files, sections, processes, threads, events, tokens, registry keys, and ALPC/named-pipe objects.
3. Security model: map UID/GID/capabilities to token user SID, group SIDs, privileges, integrity level, AppContainer state, impersonation level, and security descriptors.
4. Files and registry: trace a `CreateFile` and a registry open in Procmon, then explain the Win32 path, NT object path, desired access, share mode, and result.
5. Loader model: compare one ELF program and one PE program by imports, exports, relocations, TLS/constructors, dynamic loading APIs, and module-load telemetry.
6. Memory model: compare `/proc/<pid>/maps` with VMMap for a live process, then identify image, mapped, private, reserved, committed, RW, RX, and copy-on-write regions.
7. Syscall boundary: explain why `strace` intuition does not fully transfer, then trace a Windows file or process operation through Win32, Native API, and kernel event telemetry.
8. IPC model: compare Unix sockets/pipes/eventfd/futexes with named pipes/ALPC/RPC/COM/events/APCs/IOCP.
9. Service model: compare a `systemd` unit with a Windows service registry entry, service account token, service SID, session 0 behavior, and SCM control flow.
10. Driver model: compare a Linux `/dev` ioctl path with a Windows `CreateFile` plus `DeviceIoControl` path through device objects, IRPs, IOCTL access bits, and buffering.
11. Debugging model: configure symbols, load a dump in WinDbg, and locate process, thread, module, handle, VAD, token, and call-stack information.
12. Malware-analysis model: describe injection, persistence, hooking, and rootkit behavior as authority plus object manipulation plus control flow plus telemetry gaps, not as one API name.

## Related Local Notes

- [Windows internals long-term mastery roadmap](<../04-windows/01-windows-long-term-mastery-roadmap.md>)
- [Windows case-study resource map](<../04-windows/02-windows-case-study-resource-map.md>)
- [Linux internals long-term mastery roadmap](<../03-linux/README.md>)
- [Paging, residency, page lists, and shared memory](<../05-topic-notes/paging-residency-page-lists-and-shared-memory.md>)
- [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)
- [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>)
- [Windows object handles, references, and tokens](<../05-topic-notes/windows-object-handles-references-and-tokens.md>)
- [Windows IPC named pipes, RPC, ALPC, and security](<../05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>)

Use these as companion routes when a comparison answer needs deeper source-backed detail rather than another short analogy.

The comparison file is the map; these notes are where to validate the mechanism against OS-specific internals.
