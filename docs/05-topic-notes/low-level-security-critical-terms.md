# Low-Level Security Critical Terms

Value Score: 82/100
Role: Critical terms glossary
Proof Level: Recall, owner-linked

Date: 2026-05-19

Scope: compact but causal explanations for terms that appear across the maps and question banks. This file is a quick clarification layer, not a replacement for the deeper companion notes.

Primary companions:

- [Practical concept anchors](<practical-concept-anchors.md>)
- [Low-level security component map](<../01-comparisons-and-maps/02-low-level-security-component-map.md>)
- [x86 privilege rings, descriptors, and syscall entry](<x86-privilege-rings-descriptors-and-syscall-entry.md>)
- [Paging, residency, page lists, and shared memory](<paging-residency-page-lists-and-shared-memory.md>)
- [Windows object handles, references, and tokens](<windows-object-handles-references-and-tokens.md>)
- [Windows IPC named pipes, RPC, ALPC, and security](<windows-ipc-named-pipes-rpc-alpc-security.md>)
- [Hardware and OS security Q&A](<../02-question-banks/05-hardware-security-relationship-qa.md>)
- [ARM architecture differences](<../01-comparisons-and-maps/03-arm-architecture-differences.md>)

## Placement Rule

This file owns short, causal definitions. A term belongs here when a reader needs to stop confusing layers: handle versus pointer, PPL versus token privilege, KPTI versus VBS, `CR3` versus a page table, or kernel thread versus user process.

Do not make this file the deepest treatment of every mechanism. Put bit-level x86 behavior in the x86 privilege note, memory-residency lifecycles in the paging note, Windows subsystem details in the Windows mechanism notes, and cross-layer ownership arguments in the component map. If a term needs more than a few paragraphs to explain correctly, keep the quick answer here and link to the owning deep dive.

If the problem is not "what does this abbreviation mean?" but "how do I use or prove this concept in practice?", go to [Practical concept anchors](<practical-concept-anchors.md>). That file links terms such as IOMMU, page cache, VMA/VAD, PTE/PFN, IRP/MDL, LSM, RCU, eBPF, io_uring, ETW, AMSI, PPL, VBS/HVCI, CFG, and CET to experiments and owner docs.

## Windows Authority And Object Terms

### PPL State

PPL means Protected Process Light. It is Windows process-protection state, not a token privilege and not the same as being elevated administrator. The kernel uses it to restrict what other processes can do to a protected process, especially which handle rights can be granted for operations such as memory access, handle duplication, thread creation, or termination.

What matters:

- **Where the state lives:** process protection metadata in the kernel's process object, commonly exposed in debugger/tooling as protection type and signer level.
- **What decides it:** image signing, Windows protection policy, service configuration, and feature-specific policy such as LSA protection.
- **What it blocks:** even an administrator with `SeDebugPrivilege` may not receive powerful access to a higher-protection process.
- **Why attackers care:** LSASS as PPL changes credential-dumping from "open process and read memory" into a protection-boundary problem involving signer level, vulnerable drivers, Credential Guard, or different credential/session paths.
- **Evidence:** Process Explorer protection column, WinDbg process protection fields, handle access failures, Code Integrity events, LSA protection settings, and Credential Guard/VBS state.

### Handles, Object Pointers, And Raw Pointers

The sentence is correct:

> Handles are rights-bearing references in a per-process table. Kernel object pointers are addresses plus lifetime rules. A raw pointer without a reference is not authority and does not keep an object alive.

The deeper model:

| Thing | What it proves | What it does not prove |
|---|---|---|
| Handle | A process has a handle-table entry to a typed kernel object with a granted access mask and attributes. | It is not a direct pointer and is not valid in other processes unless inherited/duplicated. |
| Referenced kernel object pointer | Kernel code holds a lifetime reference, such as from an object-reference API or subsystem lookup. | It does not carry a new per-handle granted access mask by itself. |
| Raw copied pointer | Only that some code saw an address at some time. | No access authority and no lifetime guarantee; the object may be freed or reused. |

The security invariant is that authority and lifetime are separate. A handle answers "may this caller perform this operation?" A reference answers "will this object remain alive while I use this pointer?"

### SRM

SRM is the Windows Security Reference Monitor. It is the kernel security component behind access validation and auditing decisions such as `SeAccessCheck`-style checks.

SRM combines:

- caller token: user SID, groups, privileges, integrity level, AppContainer/capability state, impersonation state;
- target policy: security descriptor, DACL/SACL, owner, mandatory integrity policy;
- requested access: desired access mask and object-type-specific rights;
- extra policy: privileges, PPL/protection level, object manager rules, and subsystem-specific checks.

Do not reduce SRM to "ACL checker." It is the place where Windows subject identity and object security policy become a kernel access decision.

## Windows I/O And Driver Terms

### Driver Dispatch

A Windows driver dispatch routine is a function pointer in a driver's `DRIVER_OBJECT->MajorFunction[]` table. The I/O Manager calls the appropriate dispatch routine when it sends an IRP with a major function such as create, close, read, write, cleanup, PnP, power, or device control.

Why this matters:

- `DeviceIoControl` usually reaches `IRP_MJ_DEVICE_CONTROL`.
- The device object's security descriptor and the handle's granted access gate who can send requests.
- The IOCTL code and buffering method decide how user buffers are represented.
- The driver still has to validate sizes, pointer provenance, caller mode, state, and authorization.

Dispatch tables are high-value because they are legitimate control-flow tables in kernel memory. Redirection or weak validation can turn a normal request path into privileged behavior.

### Ring0 Driver Operation Versus CPL Elevation

Do not blur these two questions:

| Question | Correct layer |
|---|---|
| How does user execution enter kernel privilege? | CPU entry mechanisms, descriptor/gate checks, syscalls, interrupts, exceptions, or a vulnerable kernel/driver path. |
| What can already privileged driver code do? | IRP/IOCTL handling, dispatch tables, callbacks, process attachment, memory copying/patching, token/process/object manipulation, device/MMIO/DMA programming. |

The Ring0 rootkit material belongs mostly to the second question. It teaches which Windows kernel structures and extension points become powerful after a driver is loaded. That is not superficial vocabulary: the "why" is that those structures are later consumed by trusted kernel paths, so changing them changes what trusted code will execute, filter, observe, or authorize.

### IRP

An IRP is an I/O Request Packet. It is the Windows kernel object used to describe an I/O operation as it moves through a driver stack.

Important fields/concepts:

- major/minor function code;
- one `IO_STACK_LOCATION` per driver layer;
- file object, device object, status, completion state;
- user/system buffers or MDLs depending on buffering mode;
- cancellation, completion routines, and ownership/lifetime rules.

"An IRP may be built" means the I/O Manager or a driver creates this request object and sends it down a device stack. The security question is who authorized the original handle/request, who owns each buffer, and which driver layer is allowed to complete or mutate it.

### MDL

MDL means Memory Descriptor List. It describes a virtual buffer in terms of the physical pages backing it after those pages have been probed and locked.

Used for:

- direct I/O without copying every byte through an intermediate buffer;
- DMA, where a device needs stable physical page information or IOMMU mappings;
- mapping user pages into kernel virtual address space under controlled rules.

The invariant is lifetime: pages described by an MDL must remain resident and stable for the duration of the operation. MDL misuse can become stale DMA, data corruption, information disclosure, or use-after-free across an I/O completion path.

### `PROC_THREAD_ATTRIBUTE_HANDLE_LIST`

This Windows process-creation attribute is a handle inheritance filter. It says which existing handles should be inherited by the child process when extended startup attributes are used.

It is not a naming channel and it does not label handles for the child. The parent and child still need a protocol to agree that a numeric handle value means "control pipe," "job object," or another role. Its security value is reducing accidental handle leaks from broad `bInheritHandles=TRUE` launches.

## Firmware And Platform Tables

### ACPI Tables

ACPI tables are firmware-provided data structures that describe platform hardware and policy to the OS: devices, power states, interrupt routing, timers, NUMA, sleep states, and firmware methods.

Common tables:

| Table | Role |
|---|---|
| DSDT | Main Differentiated System Description Table; contains AML describing devices and methods. |
| SSDT | Secondary System Description Tables; add or override AML/device descriptions. Do not confuse with Windows' System Service Descriptor Table. |
| FADT | Fixed ACPI Description Table; points to key ACPI structures and fixed hardware features. |
| MADT | Multiple APIC Description Table; describes interrupt controllers and CPU interrupt topology. |

ACPI is security-relevant because firmware-originated tables influence what the OS believes hardware looks like. A bad ACPI table can change device enumeration, interrupt routing, power behavior, or firmware-method execution.

## x86 Privilege And Memory Terms

### MSR

MSR means Model-Specific Register. On x86/x64, MSRs hold CPU configuration and feature state that does not fit in ordinary architectural registers.

High-value examples:

- `IA32_EFER`: long mode, syscall enablement, NX enablement;
- `IA32_LSTAR`: 64-bit syscall entry target;
- `IA32_STAR`/`IA32_FMASK`: syscall/sysret segment and flags behavior;
- `IA32_GS_BASE` and `IA32_KERNEL_GS_BASE`: GS base state used around `swapgs`;
- `IA32_APIC_BASE`: local APIC base and enable state on relevant systems.

`wrmsr` is privileged. User mode cannot directly write MSRs. A vulnerable driver that writes an attacker-selected MSR/value is a kernel confused-deputy bug.

### Gates

Gates are descriptor-table entries that define controlled control transfers, often across privilege or exception boundaries.

| Gate | Where | Normal modern role |
|---|---|---|
| Call gate | GDT/LDT | Rare in modern x64 OS ABIs; historically a controlled far-call privilege transition. |
| Interrupt gate | IDT | Exception and interrupt entry; clears interrupt flag on entry. |
| Trap gate | IDT | Exception/debug-style entry; differs from interrupt gate in flag behavior. |
| Task gate | GDT/IDT | Hardware task switch mechanism; mostly obsolete for modern x86-64 OS design. |

Gates matter because the CPU checks descriptor type, presence, DPL, selector state, and stack-switch rules. A gate is not just a function pointer.

### U/S, SMEP, SMAP, STAC/CLAC, And ret2usr

`U/S` is the user/supervisor permission bit in an x86 page-table entry:

- `U/S = 1`: user-mode accesses may be allowed if other permissions also allow it.
- `U/S = 0`: supervisor-only page; CPL3 access faults.

SMEP prevents supervisor-mode instruction fetch from user pages. It directly degrades the old `ret2usr` pattern, where kernel control flow is redirected to code bytes in a user mapping.

SMAP prevents supervisor-mode data reads/writes to user pages except through controlled access windows. Kernel copy routines bracket deliberate user-buffer access with architecture support such as `stac` and `clac` on x86. Robust syscall entry also prevents user-controlled flags from turning SMAP into a bypass.

The key point: entering CPL0 does not make user pages into kernel pages. Page attributes still matter.

### Long Mode

Long mode is x86-64 execution mode. It requires paging and `IA32_EFER` long-mode enablement. In long mode, ordinary segmentation base/limit checks are mostly flattened for `CS`, `DS`, `ES`, and `SS`, but descriptors still matter for code-segment mode, privilege, gates, TSS, IDT delivery, and FS/GS base handling.

### Privileged Control State

Privileged control state is CPU state that changes what code can execute, which address space is active, how exceptions enter the kernel, and which protections exist.

| x86/x64 state | Role | How an attacker can change it |
|---|---|---|
| `CR0` | Protected mode, paging, write-protect, and other core controls. | Only after kernel/hypervisor/firmware authority: kernel code execution, kernel ROP/JOP, vulnerable driver, DMA/firmware/hypervisor bug. |
| `CR3` | Active page-table root. | Same; or indirectly by corrupting trusted kernel address-space metadata that later gets loaded. |
| `CR4` | SMEP, SMAP, PCID, VMX, PAE, UMIP, and other feature controls. | Same; direct user writes fault. |
| MSRs / `EFER` | Syscall, NX, GS base, APIC, speculation, and many CPU controls. | Same; exposed `wrmsr` in a driver is dangerous because kernel code performs the write. |
| `GDTR`/`IDTR`/`TR` | Descriptor-table and TSS roots. | Same; persistent tampering may be blocked or detected by PatchGuard/HVCI/VBS-like policy on Windows. |

The safe interview sentence:

> User mode cannot directly modify privileged control state. It must exploit or abuse a component that already runs at a privilege level allowed to modify that state.

### DPL And Segment State

DPL is Descriptor Privilege Level. It is policy in a descriptor, not the currently executing privilege. CPL is current code privilege. RPL is a selector-supplied requested privilege tag. Segment state includes selectors, descriptor caches, descriptor tables, and FS/GS bases. Long mode reduces base/limit segmentation, but it does not remove privilege checks around code segments, gates, TSS, IDT, or FS/GS.

## ARM64 Control State

On arm64, exception levels and system registers replace x86 ring/control-register vocabulary.

| State | Meaning |
|---|---|
| `TTBR0_EL1` / `TTBR1_EL1` | Translation table base registers, commonly split between user and kernel translation roots. |
| `SCTLR_EL1` | System Control Register: MMU, caches, alignment, endianness, and related controls. |
| `VBAR_EL1` | Vector Base Address Register for EL1 exception vectors. |
| `PSTATE` | Current process state: condition flags, interrupt masks, current exception level, selected stack pointer, and execution state. |
| `ESR_ELx` / `FAR_ELx` / `ELR_ELx` / `SPSR_ELx` | Exception syndrome, fault address, exception return address, and saved state. |

The analogy is conceptual, not bit-for-bit: `TTBR` is CR3-like, `VBAR` is IDT-like, and EL0/EL1/EL2/EL3 are ring-like. The entry/return instructions and page-table bits are different.

## Authority Tables And Translation State

"Authority tables" are tables that the CPU, hypervisor, IOMMU, or kernel uses as truth for execution, translation, or dispatch.

| Table/state | Owner | What it decides |
|---|---|---|
| Page tables | Kernel or hypervisor depending on layer. | Virtual-to-physical mapping and page permissions. |
| IDT/GDT/TSS | Kernel, with hypervisor constraints where active. | Exception/interrupt entry, segment/gate policy, stack selection. |
| Syscall targets | Kernel-configured CPU state such as MSRs or vector table. | Where user/kernel transition lands. |
| EPT/NPT/stage-2 tables | Hypervisor. | Guest-physical to host-physical mapping and guest memory permissions. |
| IOMMU tables | Kernel/hypervisor/device manager. | Which memory a device can DMA to/from. |
| VMCS/VMCB | Hypervisor and virtualization hardware. | Guest/host state, intercept controls, exit reasons, and VM-entry/exit behavior. |

An attacker values these tables because changing them changes what the machine believes, often below normal API-level telemetry.

## Syscall And Entry Terms

### Syscall Mechanisms

| Architecture | Mechanism | Target state |
|---|---|---|
| x86-64 | `syscall` / `sysret` | MSRs such as `LSTAR`, `STAR`, `FMASK`, plus entry code stack/GS/page-table setup. |
| 32-bit x86 legacy | `sysenter` / `sysexit`, `int 0x2e` or `int 0x80` depending on OS/history. | SYSENTER MSRs or IDT gate. |
| arm64 | `svc` and exception return. | `VBAR_EL1` vector table, `ESR_EL1`, `ELR_EL1`, `SPSR_EL1`, syscall ABI registers. |

### ABI Dispatch

ABI dispatch is the step after architectural entry where kernel code interprets the user-mode ABI:

- locate syscall number;
- collect arguments from registers and, when needed, user memory;
- validate syscall number and mode;
- dispatch through a kernel service table or equivalent path;
- copy/probe user buffers safely;
- return status and output through the ABI.

This is why syscall entry is not the whole system call. Entry gets you into trusted code; ABI dispatch decides which service runs and how untrusted arguments are interpreted.

### KPTI And KVA Shadow

KPTI is Linux Kernel Page Table Isolation. KVA shadow is the Windows analogue. Both split the user-mode page-table view from the full kernel view on affected systems.

The security reason is Meltdown-class exposure: "mapped but supervisor-only" was not always enough for confidentiality. The mitigation keeps most kernel mappings out of the user view and uses a small trampoline/entry region to switch to the full kernel view on entry.

PCID on x86 and ASID on other architectures reduce TLB flush costs by tagging translations with an address-space identity.

### Separate User/Kernel Roots And VBS

KVA shadow/KPTI commonly means two roots for a process: a user root with minimal kernel entry mappings and a kernel root with the full kernel view. VBS is different: it uses Hyper-V/VTL isolation and second-stage translation to protect selected secure-kernel state from the normal kernel. Do not collapse KVA shadow and VBS into the same table split.

## Interrupt And Deferred-Work Terms

### APIC And GIC

APIC is the x86 Advanced Programmable Interrupt Controller family: local APICs per CPU, I/O APICs or MSI/MSI-X for device routing. GIC is ARM's Generic Interrupt Controller. Both maintain state such as enable bits, target CPU, priority/mask, pending/active state, and delivery mode.

This state matters because it decides which CPU receives an interrupt, at what priority, and how the kernel observes device/timer events.

### ISR, DPC, APC, softirq, tasklet, workqueue

| Term | System | Meaning |
|---|---|---|
| ISR | Windows/general | Interrupt Service Routine: first handler for a hardware interrupt. |
| DPC | Windows | Deferred Procedure Call: runs later at lower urgency than ISR but still in constrained kernel context. |
| Work item | Windows | Work queued to system worker threads; can run in safer process context. |
| APC | Windows | Asynchronous Procedure Call delivered to a specific thread; kernel and user APCs have different semantics. |
| softirq | Linux | Deferred interrupt work class, often used for networking and timers. |
| tasklet | Linux | Older/dynamic softirq-based deferred work mechanism; less favored in modern code. |
| workqueue | Linux | Deferred work executed by kernel worker threads in process context. |

The invariant is context: ISR/hardirq paths must be fast and cannot do everything. Deferred work changes lifetime, locking, sleepability, and evidence.

## Page Tables, PTEs, And Residency

### CR3 Or TTBR

`CR3` on x86/x64 and `TTBR0/TTBR1` on arm64 point to active translation-table roots. Changing them changes the virtual-memory view. User mode cannot directly write them; the scheduler, exception entry path, or hypervisor-controlled code does.

### Invalid PTE States

When hardware says a PTE is not present/valid, the OS may still encode software meaning in the PTE-shaped storage.

Common meanings:

- demand-zero: legal range, allocate or map zero-filled memory on access;
- pagefile/swap-backed: private dirty contents live in backing storage;
- transition/standby: page is still resident but not currently valid in the working set;
- prototype/shared: consult a shared section/control-area/prototype PTE or file-backed object;
- copy-on-write: write fault should create a private copy;
- protection failure: not exactly an "invalid PTE kind"; it is a fault result when access violates range/PTE policy.

Do not say every file-backed or COW page is simply an "invalid PTE bit." These are OS software encodings and backing-object relationships layered over hardware-valid/invalid state.

### Hardware PTE Bits

Common x86-64 PTE bits:

| Bit/concept | Meaning |
|---|---|
| Present | Hardware may translate the entry. |
| R/W | Write permission. |
| U/S | User/supervisor reachability. |
| PWT/PCD/PAT | Cache/memory type controls. |
| Accessed | Hardware observed access. |
| Dirty | Hardware observed write. |
| Global | TLB lifetime across address-space switches where enabled. |
| NX/XD | Execute disable, effective when NXE is enabled in `EFER`. |
| Protection keys | Extra user/supervisor protection-key controls where supported. |
| PFN | Physical frame number or next paging-structure address. |

OS-owned bits and invalid encodings vary by OS and build. Always separate hardware-enforced bits from software interpretation.

### Live Page-Table Pages Are Resident

Hardware-walkable translation pages must be resident while reachable from an active or schedulable address-space root. The CPU page walker reads paging structures by physical address; it cannot page in the page table page from a pagefile by itself.

An OS may free or rebuild lower-level page tables only after removing the parent entry, invalidating stale TLB state, and ensuring no CPU can walk through them. If an intermediate paging entry is not present, the fault is for the target virtual address and the OS fault handler decides whether to create the missing mapping/table.

### How Many Page Tables Per Process?

It depends on paging mode and sparsity. For common x86-64 4-level paging with 4 KiB paging-structure pages:

- each table page contains 512 entries;
- one PML4 page can describe the 48-bit canonical address layout;
- each PML4 entry covers 512 GiB through a PDPT;
- each PDPT entry covers 1 GiB through a page directory;
- each page-directory entry covers 2 MiB through a page table, or can be a 2 MiB large page;
- each page-table entry maps 4 KiB.

Real processes are sparse. They do not allocate the fully populated tree. Kernel-half entries may be shared across processes, and KPTI/KVA shadow can add separate roots or duplicated minimal kernel-entry structures. With 5-level paging, another 512-entry level sits above the PML4-like level.

### PTE Backpointer / Reverse Mapping

"PTE backpointer" is a useful intuition, but implementation differs.

- Windows PFN database entries can record a PTE address or prototype PTE relationship for resident pages, but this is not a universal list of every virtual mapping.
- Linux uses reverse mapping through `anon_vma`, file `address_space`, rmap walks, folios/pages, and mapcounts rather than one simple backpointer field.

The problem being solved is: from a physical page, find mappings that reference it so the OS can unmap, revoke, write back, migrate, reclaim, or account for it. Treat exact fields as build/kernel-version details.

### DMA Pinning

DMA pinning means pages are made resident and stable while a device or I/O path may access them. Windows commonly represents locked buffers with MDLs. Linux uses get-user-pages/pin-user-pages style APIs and the DMA mapping API, with special care for long-term pins.

The security invariant:

> A device should only access pages intentionally pinned and mapped for that device, for the intended direction and lifetime.

Stale DMA mappings, forgotten unpins, dirty-page accounting bugs, and IOMMU domain mistakes can become memory corruption or information disclosure.

## Kernel Processes And Kernel Threads

### Linux

Linux schedules tasks. A kernel thread is a task that runs kernel code and normally has no user address space of its own (`mm == NULL`). It may borrow an `active_mm` for kernel address-space mechanics, but it does not execute a user image. Examples include `kthreadd`, `kworker`, `kswapd`, and `ksoftirqd`, often shown in brackets by `ps`.

Calling these "kernel processes" is understandable but imprecise. The better term is kernel threads/tasks.

### Windows

Windows has a special System process, commonly PID 4, that hosts many system/kernel threads. It is not a normal user-mode executable named `System.exe`. The Idle process/idle threads are separate scheduler concepts. On VBS systems, Secure System / secure-kernel activity may appear as a related but separate protected environment.

Important correction: not all kernel code "runs in the System process." A driver dispatch routine for a user request may run in the requesting thread's process context; interrupt/DPC paths run in interrupt/deferred contexts; system worker threads often run under the System process. The current process context and the privilege mode are related but not identical.

## Quick Accuracy Checks

| Claim | Verdict |
|---|---|
| PPL is process protection state, not a token privilege. | Correct. |
| Handles are rights-bearing per-process table references. | Correct. |
| Raw pointers do not grant authority or lifetime. | Correct. |
| SRM means Security Reference Monitor. | Correct. |
| MDLs describe locked physical pages backing a buffer. | Correct, but they also carry mapping/lifetime semantics. |
| ACPI `SSDT` is not Windows `SSDT`. | Correct and important. |
| `U/S = 1` means user-accessible; `U/S = 0` means supervisor-only. | Correct. |
| `wrmsr` is directly executable by user mode. | False. It is privileged; bugs expose it through kernel code. |
| KPTI and KVA shadow are equivalent to VBS. | False. KPTI/KVA shadow splits page-table views; VBS adds hypervisor/VTL isolation. |
| All Windows kernel code runs in PID 4. | False. Many system threads do, but syscall/driver work can run in caller or interrupt/deferred context. |
| Live page-table pages can be swapped out while still reachable by CR3. | False in the hardware-walkable sense. They must be resident while reachable. |
