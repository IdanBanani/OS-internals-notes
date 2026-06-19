# 03. Syscall Entry, Interrupts, Exceptions, Kernel Stacks, and ELF Loading

Value Score: 85/100
Role: Linux entry/ELF owner
Proof Level: Conceptual, lab-routed

## 1. The correct split: interrupts, exceptions, syscalls

This is basic, but senior interviewers ask it because sloppy answers here predict sloppy reasoning later.

### Interrupts

- asynchronous
- not caused by the current instruction stream
- examples: device IRQ, timer interrupt, IPI for TLB shootdown

The important "why" is that interrupt handlers run because external hardware or another CPU needs service now, not because the current userspace instruction requested the kernel. That changes what state can be trusted, what locks can be taken, and whether work must be deferred to a safer context.

### Exceptions

- synchronous
- caused by the currently executing instruction or context
- examples: page fault, divide-by-zero, invalid opcode, general protection fault

Exceptions are tied to the current execution context, so the saved registers and fault metadata are evidence about the instruction that triggered the transition. A page fault, for example, may be normal demand paging or a protection failure; the distinction comes from the fault code, address, VMA, and access type.

### System calls

- explicit user-to-kernel privilege transitions
- architecturally defined entry ABI and calling convention

System calls are the normal controlled door from user mode into kernel services. The kernel must treat register arguments and user pointers as untrusted, copy or probe memory safely, enforce policy, and return through an exit path that restores user execution without leaking privileged state.

## 2. Why entry paths matter for vulnerability research

Entry/exit code determines:

- where registers are saved
- which stack is used
- how privilege level changes happen
- how return to userspace is validated
- which mitigations are in the path

It is not just "glue code." It is part of the security boundary.

The reason is that entry code is where hardware privilege state becomes kernel software state: registers are saved, stacks are selected, speculation mitigations may run, and user-controlled arguments become kernel-visible data. Bugs here can affect every syscall, fault, interrupt, signal return, and context switch path.

## 3. x86-64 specifics

Strong candidates usually know these points:

- x86-64 has multiple entry mechanisms with different conventions
- some IDT exceptions push error codes and others do not
- `syscall` entry behavior differs from interrupt/trap-gate behavior
- stack switching and GS-base handling are delicate
- special events use IST-backed alternate stacks

Useful mental anchor:

> x86 entry is tricky because the kernel must reconcile different hardware entry conventions with stack switching, `swapgs`, speculation mitigations, and re-entrancy.

For the detailed x86 privilege model behind this paragraph, use [x86 privilege rings, descriptors, and syscall entry](<../05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md>). The important split is that CPL comes from the current code-segment state, DPL/RPL checks live in descriptor and selector mechanics, IDT gates and `SYSCALL` have different entry rules, and privileged state such as `CR3`, `CR4`, `IA32_LSTAR`, GS-base MSRs, GDT/IDT/TSS roots, SMEP, and SMAP is not writable by user mode. Entry bugs matter because they are where those hardware facts become saved registers, kernel stacks, per-CPU state, and return frames.

## 4. Kernel stacks on x86-64

Do not treat "the kernel stack" as one thing.

There are multiple important stack concepts:

- per-thread kernel stack
- interrupt stack
- IST-based special stacks for NMI, debug, machine check, double fault, and similar paths

Why alternate stacks exist:

- the normal stack may be in transition or already compromised
- some events must still be handled safely

---

> **▸ Case Study — SWAPGS Spectre gadget (CVE-2019-1125)**
>
> **What broke:** On x86-64, the `swapgs` instruction swaps the contents of the `GS` segment base register with an MSR holding the kernel's per-CPU base address. The kernel must execute `swapgs` on entry from userspace (to switch to the kernel GS base) and again on return (to restore the user GS base). In certain non-maskable interrupt paths, the kernel's decision about whether `swapgs` had already occurred could be speculated over incorrectly, leaving a window where speculative kernel code ran with a user-controlled GS base rather than the kernel's.
>
> **Primitive gained:** A Spectre-v1-style transient information disclosure. Kernel memory read via a cache side channel. No write primitive — but as with Meltdown, KASLR and secret disclosure are meaningful even from a read-only gadget.
>
> **Why it worked:** The kernel's NMI entry path included an explicit check: had `swapgs` already been executed before the NMI interrupted execution? That check was a conditional branch. Speculative execution could evaluate the wrong branch outcome and execute the gadget's memory access with the wrong GS base installed. Because GS is used to index into per-CPU data structures, a wrong GS base pointed speculative loads at attacker-influenced memory rather than kernel memory — but the cache timing side channel exposed the content of nearby kernel memory regardless.
>
> **In the wild:** Discovered by multiple researchers including Andy Lutomirski and the Microsoft MSRC team. Disclosed July 2019. Required no special privileges. Particularly relevant because it demonstrated that even the entry/exit glue code — the most carefully audited part of the kernel — could harbor Spectre-class disclosure gadgets.
>
> **What changed:** An `LFENCE` serializing instruction was inserted in the speculative-execution window in the NMI path to prevent the speculative evaluation of the conditional branch. The fix is architecture-specific because it depends on the precise `swapgs` ordering semantics that only exist on x86.

---

## 5. arm64 specifics

On arm64, think in terms of:

- EL0 userspace
- EL1 kernel
- EL2 hypervisor when relevant
- synchronous exceptions
- IRQ / FIQ / SError
- vector-table entry and `eret` return

Useful sentence:

> On arm64, privilege transitions are structured around exception levels and vector entry, not around x86-specific mechanisms like `swapgs` or IST.

That matters because mitigations and exploit assumptions do not transfer one-to-one from x86. PAN/PXN, BTI, PAC, MTE, exception levels, TTBR selection, and cache-maintenance rules shape what a kernel bug or generated-code path can actually do on arm64.

## 6. Deferred work matters

Many bugs live in transitions between:

- hardirq context
- softirq context
- process context
- worker-thread context

So if you are discussing lifetime bugs, mention deferred work:

- workqueues
- task_work
- softirq
- RCU-delayed destruction or observation patterns

Senior point:

> A lot of "memory bugs" are really context-transition bugs where one context thinks teardown already happened and another still holds a live path to the object.

The invariant is that ownership must survive across delayed execution. If a timer, workqueue, softirq, task_work item, or RCU callback can run after the logical owner has freed state, the bug is a lifetime bug even if the crashing instruction is just a normal dereference.

## 7. ELF: segments matter more than sections at runtime

This is a classic discriminator.

Sections are mostly a link-time and tooling view:

- `.text`
- `.data`
- `.bss`
- `.rodata`
- `.got`
- `.plt`

Segments and program headers are what the loader actually uses:

- `PT_LOAD`
- `PT_INTERP`
- `PT_DYNAMIC`
- `PT_GNU_STACK`
- `PT_GNU_RELRO`

If you say "the kernel maps sections," that is a red flag.

The reason is that sections are a linker/debugger organization, while program headers describe the runtime load contract: what byte ranges are mapped, where they appear in memory, which permissions they receive, and what interpreter or dynamic metadata exists. Confusing the two leads to wrong answers about `.bss`, RELRO, permissions, and file-to-memory mismatch.

## 8. What the loader actually maps

Program loading depends on:

- file offset
- virtual address
- memory size
- file size
- alignment
- segment flags

Critical subtlety:

- `memsz` can exceed `filesz`
- that is how zero-filled runtime memory like `.bss` exists without occupying bytes in the file

The loader's job is to create a memory image, not just copy the file byte-for-byte. Alignment, permissions, zero-fill, interpreter selection, and auxiliary vector setup all determine what the process can execute or access before `main`.

## 9. ELF process startup and shutdown

For a dynamically linked userspace process, the useful high-level chain is:

1. `execve()` replaces the old image.
2. The kernel validates the ELF, maps `PT_LOAD` segments, prepares the initial stack, maps vDSO/vvar, and reads `PT_INTERP`.
3. The ELF interpreter, usually `ld-linux`, runs first for a dynamic binary.
4. The dynamic linker maps dependencies, applies relocations, resolves early symbols, initializes TLS, and runs loader initialization.
5. The executable's `_start` code, normally from CRT startup objects, calls libc startup.
6. In glibc, `__libc_start_main` initializes libc/runtime state, runs pre-main constructors, and invokes `main(argc, argv, envp)`.

So `main` is a late runtime callback, not the first user instruction. Important pre-main surfaces include:

- dynamic linker relocation and symbol-resolution work
- IFUNC resolvers
- TLS setup and TLS initializers
- `.preinit_array`, legacy `.init`, and `.init_array`
- C++ global constructors and language-runtime initialization
- `LD_PRELOAD`, `LD_AUDIT`, rpath/runpath, and loader search policy where allowed

Normal shutdown is also runtime-mediated:

- returning from `main` normally flows into `exit`
- `exit` runs `atexit` handlers, C++ static destructors, stdio/libc cleanup, and finalizer paths such as `.fini_array`
- thread exit runs thread-local cleanup and TLS destructors
- `_exit`, fatal signals, `execve`, and forced termination bypass most user-mode cleanup

Security relevance: pre-main and post-main code are part of the execution surface. A breakpoint at `main`, a source-level audit of `main`, or a simple "program starts here" explanation misses constructors, IFUNCs, preload/audit libraries, TLS behavior, finalizers, and abnormal-exit differences.

## 10. PIE, ASLR, GOT/PLT, and RELRO

### PIE and ASLR

PIE lets the main executable be relocated like a shared library, which is essential for full userspace ASLR.

The reason is that non-PIE main executables have fixed text/data addresses even when libraries and stacks move. PIE removes that fixed anchor, so a leak or info-disclosure primitive is usually needed before address-dependent control-flow or data targeting becomes reliable.

Attackers take advantage of fixed or predictable code bases because known offsets become absolute addresses. The old return-to-libc and ROP pattern is: know the libc or executable base, add the gadget/function offset, and redirect control flow there. On modern Linux, shared libraries are normally position-independent `ET_DYN` mappings and ASLR gives each process its own library layout, so a leak is usually needed. The weaker case is a non-PIE `ET_EXEC` main binary: its executable code and globals sit at stable addresses even if libc, heap, stack, and vDSO move.

Do not collapse "shared object" into "fixed address." A `.so` is shared in the sense that clean file-backed pages can be reused, but its virtual base can still vary per process. Android's Zygote model is a special exception worth recognizing: preloaded runtime mappings inherited across fork can keep layout relationships, so one pointer leak into a shared pre-fork region can reveal a broader runtime layout.

### GOT and PLT

At a high level:

- PLT entries are indirection stubs
- the GOT holds resolved or relocatable addresses
- the dynamic loader fills in or uses them based on relocation policy

The security relevance is that the GOT/PLT is a runtime dispatch mechanism, not just a file-format curiosity. Lazy binding intentionally writes resolved addresses into process memory, so RELRO and binding policy decide whether a write primitive can still redirect later library calls through relocation state.

### RELRO

RELRO matters because it changes how much relocation-sensitive state remains writable after load:

- partial RELRO leaves more useful mutation surface
- full RELRO shuts down classic GOT-overwrite ideas

---

> **▸ Case Study — GOT overwrite class and the adoption of full RELRO**
>
> **What broke:** Under partial RELRO (the historical default for many years), the Global Offset Table entries for lazily-resolved library functions remained writable for the lifetime of the process. Any write primitive — buffer overflow, format string, UAF — that could reach the GOT could redirect an arbitrary library function call to attacker-controlled code.
>
> **Primitive gained:** Arbitrary code execution from an arbitrary write primitive. GOT overwrites converted even a single controlled four- or eight-byte write into a reliable call redirect: overwrite `printf@GOT`, wait for the next `printf()` call, redirect execution to a shellcode or ROP entry point.
>
> **Why it worked:** The dynamic linker intentionally mapped the GOT writable to support lazy binding — resolving function addresses on first call rather than at load time. Lazy binding traded security for startup speed. The PLT stub for an unresolved function wrote the resolved address back into the GOT after the first call. This architectural decision meant that the GOT was writable throughout the process's lifetime when partial or no RELRO was used.
>
> **In the wild:** GOT overwrites were a standard technique in format-string and heap-overflow exploitation from the late 1990s onward. They appeared in glibc-based CTF solutions, real-world exploits, and were a staple of publicly available exploitation frameworks. The technique worked on virtually every Linux shared-library executable that did not explicitly use full RELRO.
>
> **What changed:** Full RELRO resolves all dynamic symbols at load time and then calls `mprotect()` to mark the GOT read-only before any user code runs. This entirely removes writable GOT entries from the exploitation surface. Full RELRO is now the default on hardened distributions (Ubuntu, Debian, Fedora all enable it by default for most packages) and is mandatory in many Android system binaries. The cost is slightly longer startup time; the security gain is the complete removal of a major write-primitive amplifier. Partial RELRO still protects `.fini_array` and certain metadata sections but leaves the lazy-binding GOT writable.

---

## 11. `PT_GNU_STACK`, NX, W^X, and control-flow hardening

`PT_GNU_STACK` communicates stack executability policy.

Modern hardened systems aim for:

- non-executable stack
- W^X separation
- stack canaries and fortified runtime checks where enabled
- control-flow hardening such as CFI, x86 CET shadow stack/IBT, or arm64 BTI/PAC depending on hardware, kernel, compiler, and distribution choices

That forces attackers away from naive stack-shellcode thinking and toward:

- code reuse
- JIT/code-cache edges
- permission-flip logic
- data-only impact

Do not treat normal Linux shellcode detection as a policy engine that compares D-cache bytes with I-cache bytes before every instruction. The real Arm effect is subtler and still security-relevant: on split I-cache/D-cache systems, bytes written as data may not become the bytes fetched as instructions until software performs the required data-cache clean, instruction-cache invalidate, and barrier sequence. A naive shellcode loader, JIT, hook, or unpacker that skips this can fail by executing stale instructions.

Linux also relies on page permissions, mapping policy, loader hardening, and control-flow rules; defenders compare mapped memory against backing files, inspect executable anonymous/private mappings, and correlate loader metadata with `/proc/<pid>/maps` or memory-forensics views. Instruction-cache coherency sits underneath that model. On x86/x64, the architecture hides most I-cache/D-cache maintenance from normal user-mode code. On Arm and other architectures, generated or modified code often needs an explicit data-cache clean plus instruction-cache invalidation sequence before execution; portable code uses helpers such as `__builtin___clear_cache` or platform runtime APIs.

Raspberry Pi 3 versus Raspberry Pi 4 is a good concrete warning. Pi 3 is Cortex-A53 and Pi 4 is Cortex-A72; both are ARMv8-A cores, though a 32-bit OS can expose an ARMv7-style user ABI. If shellcode works on one and fails on the other, first suspect execution state, cache-maintenance behavior, and microarchitectural differences rather than simply "v7 versus v8." This is a correctness/coherency contract for JITs, hotpatching, unpackers, and self-modifying code, and can accidentally mitigate naive shellcode. It is not a universal bypass or substitute for NX/W^X, RELRO, CET, BTI, PAC, or CFI.

## 12. vDSO and vvar

These are worth remembering because they show up in real process layouts:

- **vDSO**: kernel-provided userspace helper code mapping
- **vvar**: associated read-only data mapping

Why they matter in interviews:

- they prove you understand that not every mapped page came from the main binary or a shared object
- they show up in leaks, mappings, and layout reasoning

---

> **▸ Case Study — vDSO as an ASLR-defeat stepping stone**
>
> **What broke:** Nothing in vDSO itself is broken — but the vDSO appears at a kernel-randomized address in every process's layout. Because it is a real ELF shared object mapped into userspace, it contains usable code gadgets and known-offset structures. For exploits that already have a read primitive but need a kernel-text or libc-text address to construct a ROP chain, leaking the vDSO address is often the cleanest first step: it is always present, always readable, and its layout is entirely predictable.
>
> **Primitive gained:** A partial ASLR defeat. One leaked vDSO address gives the full vDSO load base, which reveals: (a) a dense ROP gadget set from known kernel-supplied code; (b) on older kernels, proximity relationships that helped estimate other mapping bases through known layout regularity.
>
> **Why it worked:** The vDSO is designed to be readable — its entire point is to provide fast-path userspace syscall helpers. An attacker with any memory-read primitive (format string, OOB read, UAF read) can target the vDSO mapping because its virtual address is visible in `/proc/self/maps` and its presence is architecturally guaranteed. The ELF structure is constant across all processes on the same kernel.
>
> **In the wild:** vDSO address leaks appeared in heap exploitation papers and CTF write-ups extensively from approximately 2012 onward, and remained a reliable technique even as other layout-inference methods were closed off. They were especially valuable in sandboxed environments where `/proc/self/maps` was inaccessible but a memory read primitive existed.
>
> **What changed:** Modern kernels randomize the vDSO placement more aggressively and KASLR widens the entropy of all kernel-originated mappings. Nonetheless, when an exploit already has a single read primitive, the vDSO remains a well-known convenient first target because it is always mapped and always useful.

---

## 13. Strong short summary

If you need one concise answer:

> Kernel entry paths define the integrity of privilege transitions, and ELF program headers define the shape of the userspace image those transitions serve. A strong researcher understands both because control over memory only becomes impact once you understand how code, data, stacks, and return paths are actually laid out and restored.

The evidence path is concrete: inspect saved registers and fault codes for entry bugs, and inspect program headers, mappings, relocations, loader state, and memory protections for ELF/runtime bugs.
