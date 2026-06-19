# x86 Privilege Rings, Descriptors, And Syscall Entry

Value Score: 90/100
Role: x86 privilege owner
Proof Level: Source-backed conceptual

Date: 2026-05-19

Scope: x86/x86-64 privilege enforcement for security-internals reasoning: CPL, DPL, RPL, segment selectors, GDT/LDT/IDT descriptors, TSS stack state, `SYSCALL`/`SYSRET`, `INT`/exceptions/interrupt gates, privileged control registers, MSRs, SMEP/SMAP, and why vulnerable drivers that expose privileged instructions are dangerous. This is defensive/reversing oriented and intentionally avoids operational exploit recipes.

Source anchors:

- Intel: [Intel 64 and IA-32 Architectures Software Developer's Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html), especially Volume 3 for protection, interrupts/exceptions, task management, VMX, and Volume 4 for MSRs.
- AMD: [AMD64 Architecture Programmer's Manual Volumes 1-5](https://docs.amd.com/v/u/en-US/40332_4.09_APM_PUB), especially protected-mode, long-mode, syscall, and system-programming details.
- Ilia Dafchev: [Exploiting WRMSR in vulnerable drivers](https://idafchev.github.io/blog/wrmsr/), useful for understanding why `LSTAR`, `CR3`, `swapgs`, SMEP/SMAP, KPTI/KVAS, and driver IOCTL validation belong in the same mental model.
- Ido Veltzman: [Lord Of The Ring0 Part 1](https://idov31.github.io/posts/lord-of-the-ring0-p1), [Part 3](https://idov31.github.io/posts/lord-of-the-ring0-p3), [Part 4](https://idov31.github.io/posts/lord-of-the-ring0-p4), [Part 5](https://idov31.github.io/posts/lord-of-the-ring0-p5), and [Part 6](https://idov31.github.io/posts/lord-of-the-ring0-p6), useful for separating "how ring0 is reached" from "what an already loaded Windows kernel driver can do with dispatch, callbacks, process attachment, and memory patching."

## Core Model

On x86, ring enforcement is not one check. It is a chain of checks over selector state, descriptor tables, entry mechanisms, page-table permissions, and privileged registers.

The short version:

```text
current CS selector -> CPL
selector RPL + descriptor DPL -> privilege check
entry gate or syscall MSR -> allowed transition target
TSS/IST/kernel entry code -> safe privileged stack and per-CPU state
page U/S, NX, SMEP, SMAP -> memory execution/access checks
CRx/MSRs/GDTR/IDTR/TR -> privileged state only kernel/hypervisor may write
```

The operating system chooses the tables, descriptors, entry targets, stacks, and page tables. The CPU enforces them when code tries to execute, load a selector, take an interrupt, enter a syscall, touch memory, or write privileged state.

That is why "the kernel decides policy" and "the CPU enforces privilege" are both true.

## What Ring0 Rootkit Material Teaches

The local `lord_of_the_ring0` note is useful, but it should not be read as a list of magic CPL3-to-CPL0 transitions. Its main lesson is post-entry: once a Windows driver is already running in kernel mode, it can interact with high-authority OS state that user mode cannot directly mutate.

The important categories are:

- **Driver request surface:** user mode reaches a driver through device handles, IOCTLs, IRPs, buffering methods, MDLs, and dispatch routines. This is where weak validation can convert ordinary input into privileged behavior.
- **Dispatch and callback state:** `DRIVER_OBJECT->MajorFunction[]`, SSDT-style service dispatch, object/process/registry callbacks, minifilters, WFP callouts, and telemetry providers are legitimate kernel extension points. Tampering with them redirects already trusted execution.
- **Kernel-to-user memory control:** APIs such as process lookup, process attachment, virtual-memory protection changes, and kernel copy routines let privileged code inspect or patch a user process, but the operation still depends on process context, address-space roots, PTE permissions, and object lifetime.
- **Integrity constraints:** PatchGuard, HVCI/VBS, code integrity, SMEP/SMAP, KPTI/KVAS, and driver-signing policy constrain different pieces of the story. They do not replace IOCTL validation or object-lifetime discipline.

So use the Ring0 material as the Windows driver/rootkit companion to the CPU model: it explains what ring0 authority can target after the boundary is crossed, while CPL/DPL/RPL, gates, MSRs, CR registers, page permissions, and hypervisor state explain the boundary itself.

## CPL, DPL, And RPL

The numbers are inverted from normal intuition: `0` is most privileged, `3` is least privileged.

| Term | Where it lives | What it means |
|---|---|---|
| CPL | Current `CS` selector privilege bits, interpreted through the current code segment. | The privilege level of the currently executing code. Normal user mode is CPL3; normal kernel mode is CPL0. |
| DPL | Descriptor Privilege Level inside a GDT/LDT/IDT descriptor or gate descriptor. | The privilege policy attached to a segment or gate. It answers "which privilege levels may use this descriptor?" |
| RPL | Requested Privilege Level in the low bits of a selector value. | A software-supplied selector privilege tag. It can intentionally make a selector less privileged than the caller. |

For data segments, the CPU checks the effective privilege against the descriptor. A useful simplified rule is:

```text
effective privilege = max(CPL, RPL)   ; numerically larger is less privileged
access allowed if descriptor DPL >= effective privilege
```

This is why a CPL3 program cannot load a CPL0 data segment just by putting a kernel selector value into a segment register. The descriptor's DPL check fails and the CPU raises a general-protection fault.

For code execution and gates, the exact rules differ by descriptor type:

- A normal nonconforming code segment is not a free cross-ring jump target.
- A call gate is an explicit descriptor that can allow a controlled transition to a more privileged code segment if the gate DPL, selector RPL, current CPL, target descriptor, and presence/type checks all pass.
- An interrupt or trap gate in the IDT controls exception/interrupt entry. Its DPL matters for software `INT n`; hardware interrupts and CPU exceptions are not "authorized" by user mode in the same way.
- `SYSCALL`/`SYSRET` bypass most old segmentation gate mechanics and use MSRs configured by the OS.

So the real answer to "what enforces rings?" is not just "CPL." It is CPL plus descriptor/gate checks plus privileged entry mechanisms plus page permissions.

## Selectors And Descriptor Tables

A segment selector is not a pointer. It is an index-like value that names a descriptor in the GDT or LDT and carries an RPL.

| Structure | Role |
|---|---|
| GDT | Global Descriptor Table. Holds system-wide descriptors such as kernel/user code/data descriptors, TSS descriptors, and sometimes gate descriptors. |
| LDT | Local Descriptor Table. Per-task/process segmentation table in older designs or special compatibility cases. Mostly unimportant for normal modern x64 application execution. |
| IDT | Interrupt Descriptor Table. Holds interrupt/trap gate descriptors for exceptions, software interrupts, and hardware interrupt vectors. |
| TSS | Task State Segment. Modern x86-64 OSes mostly use it for ring0 stack pointers and IST stacks, not full hardware task switching. |
| GDTR/LDTR/IDTR/TR | CPU registers that point to the descriptor tables or current TSS. Loading them is privileged. |

Long mode made most base/limit segmentation irrelevant for ordinary `CS`, `DS`, `ES`, and `SS` addressing. That does not mean segmentation disappeared. The CPU still uses descriptors for privilege level, code segment mode bits, gate semantics, TSS state, and exception delivery. FS/GS are also special because their bases are still meaningful and are commonly backed by MSRs.

## Why User Code Cannot Just Jump To Ring0

A near `jmp` or `call` stays in the current code segment. If user code is executing with a user `CS`, its CPL remains 3. Jumping to a kernel virtual address still fails because normal kernel pages are supervisor pages, KPTI/KVAS may hide them from the user page-table view, and there is no valid CPL0 code segment transition.

A far transfer that tries to load a different `CS` is checked against descriptor rules. A user-chosen selector naming a kernel DPL0 code segment is not accepted as a normal direct transfer from CPL3. If a gate exists, the CPU uses the gate's descriptor rules and a controlled stack transition. Modern commodity OSes do not expose call gates as their normal user/kernel ABI.

The normal fast path is a syscall instruction. The OS configures the hardware entry state first, then user code executes the instruction, and the CPU transfers to the OS-selected entry target.

## Syscall Entry On x86-64

`SYSCALL`/`SYSRET` is the main x86-64 user/kernel transition path on modern Linux and Windows. It is not an ordinary function call and it is not an IDT interrupt gate.

Key state:

| State | Why it matters |
|---|---|
| `IA32_EFER.SCE` | Enables the syscall extension. |
| `IA32_LSTAR` | Holds the 64-bit syscall entry RIP. |
| `IA32_STAR` | Holds syscall/sysret segment-selector state. |
| `IA32_FMASK` | Masks selected `RFLAGS` bits during entry. |
| `RCX` and `R11` | Used by hardware to save return RIP and flags for `SYSRET`. |
| `IA32_KERNEL_GS_BASE` and GS base state | Used with `swapgs` to move between user thread-local state and kernel per-CPU state. |

Important subtlety: on x86-64, `SYSCALL` does not perform the full old-style interrupt-gate stack switch for the OS. Early kernel entry code must arrange a safe kernel stack, per-CPU base, and full kernel address-space visibility. On Windows with KVA shadow or Linux with KPTI, the initial entry may run in a minimal mapped region and then switch to the full kernel page-table view.

This is why entry code is delicate:

- The CPU enters CPL0 and sets RIP from `LSTAR`.
- The initial stack and GS/per-CPU state still need careful OS handling.
- KPTI/KVAS may require a `CR3` switch very early.
- `swapgs` must be correct on every syscall, interrupt, NMI, and return path.
- Return through `SYSRET` must restore the user view and validate return state.

If an MSR such as `LSTAR` is corrupted, the next syscall can be redirected before normal syscall dispatch. But user mode cannot execute `wrmsr`; the dangerous case is a kernel bug or driver IOCTL that writes attacker-influenced MSR state.

## Other Transition Mechanisms And Why They Matter Less Day To Day

`SYSCALL` is the ordinary x86-64 ABI path, but it is not the only architectural way control can cross privilege or execution layers. The useful security question is always: who is allowed to create the entry state, which stack is used, which page-table view is active, and what validates the return path?

| Mechanism | What it really is | Why it is rarely the normal modern path |
|---|---|---|
| `SYSENTER`/`SYSEXIT` | Older fast syscall mechanism with target state in SYSENTER MSRs. | Important for 32-bit and compatibility history; not the usual x86-64 syscall path on modern Windows/Linux. |
| Software `INT n` | IDT-gate entry through an interrupt/trap gate. | Legacy syscall ABIs used it, but x86-64 fast syscall paths mostly replaced it; gate DPL still matters for whether CPL3 may invoke a vector. |
| Call gate | GDT/LDT descriptor that can permit a controlled far call to a more privileged code segment. | Modern commodity x64 OSes generally do not expose call gates as their user/kernel ABI. Creating a useful gate requires control over descriptor-table state and still lands under SMEP/SMAP/NX/page-table constraints. |
| Task gate / hardware task switch | Descriptor-driven switch through TSS machinery. | Modern x86-64 kernels use the TSS mainly for stacks/IST, not full hardware task switching. Tampering with TSS/TR is privileged and integrity-sensitive. |
| `IRETQ` / return frame | Return from interrupt/exception style entry by restoring saved state. | It is a return mechanism, not a user-selected privilege upgrade. Bugs arise when kernels mishandle saved selectors, canonicality, stack state, or `swapgs` state during return/fault paths. |
| SMI/SMM | Firmware/system-management mode below the OS. | It is not normal OS ring0. The OS often has limited visibility; security belongs to firmware, chipset configuration, and platform updates. |
| VM exit / hypercall | Transition from guest execution to a hypervisor. | Guest CPL0 is still below the hypervisor. Bugs here are hypervisor/interface bugs, not ordinary user-to-kernel syscall bugs. |
| Vulnerable driver path | Kernel code executes privileged operations on untrusted request data. | This is the common real-world bridge: user mode does not execute privileged instructions directly; a weak driver does so as a confused deputy. |

This is why a list of "ways to reach ring0" can be misleading. Some entries are legitimate ABI doors, some are obsolete or rare descriptor mechanisms, some are return-path bug classes, and some are lower-than-kernel layers. For exploitability and defense, the important distinction is whether the attacker controls architectural entry state, kernel request data, descriptor/table memory, return-frame state, or a lower-layer interface.

## Interrupts, Exceptions, IDT Gates, And IRET

Interrupts and exceptions use IDT gate descriptors. This path differs from `SYSCALL`.

When an interrupt or exception is delivered, the CPU:

1. Uses the vector number to select an IDT descriptor.
2. Checks descriptor type, presence, and privilege rules where applicable.
3. Loads the target code selector and RIP from the gate.
4. Switches stacks if the event crosses privilege levels or uses an IST entry.
5. Pushes a saved machine frame such as old `SS:RSP`, `RFLAGS`, `CS:RIP`, and sometimes an error code.
6. Enters the handler at CPL0 for normal kernel exceptions/interrupts.

The DPL on an IDT gate is especially important for software interrupts. If user code executes `INT n`, the gate DPL decides whether CPL3 is allowed to invoke that vector directly. Hardware interrupts and CPU-generated exceptions are different; a page fault or timer interrupt is not a user request.

`IRETQ` reverses an interrupt/exception style transition by restoring saved state. That makes return validation critical. Bad saved selectors, noncanonical return addresses, incorrect `swapgs` state, or stack confusion can turn an entry/exit bug into a privilege or disclosure issue.

## TSS, RSP0, IST, And Kernel Stacks

The TSS is not mainly a hardware-task-switching feature in modern 64-bit Linux/Windows. Its high-value role is stack selection.

| TSS field class | Why it matters |
|---|---|
| `RSP0` | Stack pointer used when entering ring0 from a less privileged ring through gate-style transitions. |
| IST entries | Alternate stacks for dangerous events such as NMI, double fault, machine check, or debug paths. |
| I/O bitmap | Legacy mechanism controlling port I/O permission at task granularity. |

Security invariant:

> Privileged entry must land on a kernel-owned stack or a known alternate stack, not on attacker-controlled user memory.

`SYSCALL` entry needs explicit OS stack handling, while interrupt/trap gates have more hardware stack-switch machinery. Either way, the kernel must quickly move from user-controlled state to trusted per-thread/per-CPU state.

## Privileged Registers And Instructions

The most security-relevant privileged state:

| State | Role | Why attackers care |
|---|---|---|
| `CR0` | Enables protected mode/paging and includes write-protect behavior. | Clearing write-protect from kernel context can allow writes to read-only kernel mappings. |
| `CR3` | Active page-table root. | Changes the entire virtual-to-physical view. |
| `CR4` | Enables features such as SMEP, SMAP, PCID, PAE, UMIP, VMX, and others depending on CPU/OS. | Disabling SMEP/SMAP or changing paging-related behavior can alter exploit constraints. |
| `IA32_EFER` | Long-mode, syscall, and NX-related control. | NXE and SCE affect execute policy and syscall availability. |
| `IA32_LSTAR`/`STAR`/`FMASK` | Syscall entry and return policy. | Corrupting entry state can redirect the most important user/kernel door. |
| `IA32_GS_BASE`/`IA32_KERNEL_GS_BASE` | User/kernel GS base state. | Wrong GS state breaks per-thread/per-CPU addressing and can produce serious entry bugs. |
| `GDTR`/`IDTR`/`LDTR`/`TR` | Descriptor-table and TSS roots. | Changing them changes the CPU's privilege and interrupt dispatch truth. |

Instructions such as `wrmsr`, `rdmsr`, `mov` to/from control registers, `lgdt`, `lidt`, `lldt`, `ltr`, and many interrupt-control operations are privileged. From CPL3 they fault instead of changing the machine.

That last sentence is the security boundary. A vulnerable driver that accepts an untrusted MSR index/value and executes `wrmsr` is not "letting user mode execute `wrmsr`." It is kernel code executing a privileged instruction on behalf of untrusted input. The bug is the confused-deputy bridge from user request to privileged CPU state.

## SMEP, SMAP, NX, And Page Permissions

Privilege level alone is not enough. The page tables also have privilege and execution permissions.

| Mechanism | Enforcement point | Security meaning |
|---|---|---|
| U/S page bit | Page walk and TLB permission check. | User code cannot access supervisor pages; supervisor code can normally access both unless SMAP-like controls apply. |
| NX/XD | Instruction fetch permission. | Data pages can be mapped readable/writable but non-executable. |
| SMEP | Supervisor instruction fetch from user pages. | Kernel CPL0 code cannot execute bytes from user mappings when enabled. |
| SMAP | Supervisor data access to user pages. | Kernel CPL0 code cannot casually read/write user pages except through controlled sequences. |
| `STAC`/`CLAC` | AC flag handling while SMAP is enabled. | Kernel code uses these instructions to bracket deliberate user-memory access; user mode cannot use them as a bypass. |
| KPTI/KVAS | Address-space layout and `CR3` switching. | User-mode page-table view may not contain the full kernel mapping set. |

This is why "I redirected RIP to my buffer" is not a complete ring0 story. At CPL0, a user page is still a user page. SMEP can block instruction fetch from it. SMAP can block data access to a user stack or buffer. KPTI/KVAS may mean the target kernel address is not mapped in the current view until entry code switches roots.

`ret2usr` is the classic exploit shape where corrupted kernel control flow returns or jumps into bytes mapped as a user page. Without SMEP, the U/S bit alone does not stop supervisor-mode instruction fetch from a user page. With SMEP enabled, that fetch faults, so a real CPL0 exploit must use kernel-resident code, change trusted control state, or find another permitted execution path.

`STAC` sets the AC flag so supervisor code can intentionally access user pages while SMAP is enabled; `CLAC` clears it again. Correct kernels keep those windows small, route user-buffer access through copy/probe helpers, and do not trust user-supplied saved flags across entry. The important security distinction is that `STAC`/`CLAC` are kernel-controlled bracketing instructions, not authority attached to the user pointer itself.

## Windows And Linux Anchors

| Topic | Linux view | Windows view |
|---|---|---|
| Syscall instruction | Architecture-specific entry code, syscall table dispatch, KPTI trampoline where enabled. | `ntdll` syscall stubs enter kernel; `KiSystemCall64`/shadow-style paths are the kernel side conceptually. |
| Descriptor tables | GDT/IDT/TSS setup in architecture code; LDT mostly compatibility/special use. | GDT/IDT/TSS exist below the Windows Executive; PatchGuard/HVCI can make tampering risky or blocked. |
| GS/FS | User TLS often through FS; kernel per-CPU state uses GS on x86-64 with `swapgs` entry discipline. | x64 user mode and kernel mode use GS-base switching for TEB/KPCR-style state. |
| KPTI/KVAS | KPTI separates user and kernel page-table views on affected systems. | KVA shadow is the Windows analogue on affected configurations. |
| Driver bug bridge | `ioctl` or device file bug can expose privileged kernel operations. | `DeviceIoControl` to a weakly secured or vulnerable driver can expose privileged operations such as MSR/control-state mutation. |

## Hypervisor Caveat

A hypervisor adds a lower layer. Guest CPL0 is not the final authority when VMX/SVM is active. The hypervisor can intercept instructions such as `CPUID`, `WRMSR`, control-register writes, and page faults depending on configuration, and EPT/NPT can overrule guest page tables.

Keep the layers separate:

```text
guest CPL3 -> guest CPL0 -> hypervisor/root mode -> firmware/SMM/secure world
```

The same instruction can have different meaning depending on which layer controls the intercept and translation state. For example, a guest kernel may think it owns `CR3`, while the hypervisor still owns second-stage translation.

## Common Mistakes

| Mistake | Better model |
|---|---|
| "CPL is stored in a normal register." | CPL is derived from the current code segment selector/state, not from a general-purpose register. |
| "DPL and CPL are the same thing." | CPL is current execution privilege; DPL is policy in a descriptor or gate. |
| "RPL can make user code more privileged." | RPL can only make a selector request less privileged for checks; it cannot bypass CPL. |
| "Long mode removed segmentation, so GDT/IDT/TSS do not matter." | Long mode flattens most base/limit behavior, but descriptors still matter for privilege, gates, TSS, IDT, and FS/GS special cases. |
| "SYSCALL automatically gives a complete kernel context." | It enters CPL0 at the OS-selected target, but the OS still has to establish stack, GS/per-CPU state, page-table view, and safe dispatch. |
| "Call gates, IRET, SMM, and VM exits are all just ring0 tricks." | They live at different layers. Call gates are descriptor-mediated entries, IRET is a constrained return path, SMM is firmware/system-management mode, and VM exits enter a hypervisor. |
| "Ring0 rootkit techniques explain how user mode gets ring0." | Many explain what already privileged driver code can do after it is loaded: dispatch tampering, callbacks, process attachment, memory patching, or telemetry interference. |
| "WRMSR is a user-mode attack by itself." | `wrmsr` is privileged. The vulnerability is a kernel/driver path that executes it using untrusted input. |
| "SMEP/SMAP stop kernel compromise." | They stop specific user-page execute/access patterns. Data-only corruption, kernel ROP, signed vulnerable drivers, and legitimate kernel APIs may still matter. |
| "Ring0 is always final control." | Hypervisors, VBS/HVCI, SMM, firmware, and IOMMU state can sit below or beside the normal kernel. |

## Evidence And Debugging Views

When validating a privilege-boundary explanation, look for independent evidence:

- Current mode/CPL and trap frame state.
- `CS`, `SS`, `RFLAGS`, `RIP`, `RSP`, and saved return frame.
- `CR0`, `CR3`, `CR4`, `IA32_EFER`, `IA32_LSTAR`, `IA32_STAR`, `IA32_FMASK`, and GS-base MSRs.
- GDT, IDT, TSS, IST, and syscall entry symbols.
- Page-table U/S, NX, writable, global, and large-page bits.
- KPTI/KVAS state and the current page-table root on entry/exit.
- Driver device ACLs, IOCTL access bits, input validation, and whether a kernel routine executes privileged instructions from untrusted request data.
- Hypervisor/VBS status and whether MSR/control-register accesses are intercepted.

## Interview Summary

Use this answer shape:

> x86 user/kernel isolation is enforced by the CPU using the current code segment privilege, descriptor and gate DPL/RPL checks, controlled entry mechanisms such as `SYSCALL` or IDT gates, privileged state such as CR registers/MSRs/GDTR/IDTR/TSS, and page-table permissions such as U/S, NX, SMEP, and SMAP. The kernel owns the tables and register setup; the CPU enforces them. A privilege escalation needs a kernel, driver, hypervisor, or firmware path that changes those trusted states or executes privileged code on untrusted input.

## Active Recall

1. Why is CPL derived from `CS` rather than from `RAX` or another general register?
2. Why does DPL live in descriptors and gates instead of in user-mode code?
3. Why can RPL reduce effective privilege but not grant more privilege?
4. Why does long mode still need GDT, IDT, and TSS state?
5. Why is `SYSCALL` not the same mechanism as an interrupt gate?
6. Why does x86-64 syscall entry still need explicit stack and `swapgs` discipline?
7. Why are call gates descriptor-policy mechanisms rather than ordinary function pointers?
8. Why is `IRETQ` a return-path risk but not a normal user-selected ring upgrade?
9. Why is corrupting `LSTAR` different from corrupting the syscall table?
10. Why does SMEP matter even after the CPU enters CPL0?
11. Why does SMAP make a user stack or user buffer unsafe for kernel ROP/data access?
12. Why is a vulnerable driver that exposes `wrmsr` a confused-deputy bug?
13. What evidence would prove that KPTI/KVAS changed the active page-table root during entry?
14. How does a hypervisor change the meaning of guest CPL0?
