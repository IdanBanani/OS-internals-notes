# Source-Enriched Windows Mechanisms

Value Score: 92/100
Role: Windows mechanism owner
Proof Level: Source-backed conceptual

Date: 2026-05-16

Purpose: condensed mechanism notes built from the local Windows 11 Internals Pluralsight subtitles and the local Windows PDFs. Use this as the bridge between the roadmap/question banks and the raw source material. It is intentionally explanatory rather than a source inventory.

## Sources Used

Primary local sources:

- [Pluralsight - Windows 11 Internals by Pavel Yosifovich](<../../Pluralsight - Windows 11 Internals by Pavel Yosifovich>)
  - `Foundations`
  - `Processes and Jobs`
  - `Threads`
  - `Memory Management`
  - `Kernel Mechanisms`
- [Yosifovich Pavel - Windows Native API Programming - 2024.pdf](<../../Yosifovich Pavel - Windows Native API Programming - 2024.pdf>)
- [Forshaw James - Windows Security Internals - 2024.pdf](<../../Forshaw James - Windows Security Internals - 2024/Forshaw James - Windows Security Internals - 2024.pdf>)
- [Windows Internals, Part 2 by Mark Russinovich.epub](<../../Windows Internals, Part 2 by Mark Russinovich.epub>)
- [windows-kernel-programming-pavel-yosifovich.pdf](<../../windows-kernel-programming-pavel-yosifovich.pdf>)
- [Internals of Windows Memory Management for Malware Analysis.pdf](<../../Internals of Windows Memory Management for Malware Analysis.pdf>)
- [os_book.pdf](<../../os_book.pdf>)

Use `os_book.pdf` as a Hebrew warm-up only. The deeper mechanisms below should be learned from the Windows 11 Internals subtitles, Native API book, Forshaw security book, kernel-programming book, and Windows Internals-style references.

Case-study enrichment:

- [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) is the first stop when an abbreviation such as VAD, PTE, PFN, IRP, IOCTL, MDL, APC, DPC, ALPC, ETW, AMSI, PEB/TEB, PPL, VBS/HVCI, CFG/CET, DMA, or IOMMU needs expansion plus a practical evidence path.
- [Flare-On Windows Internals Case Notes](<04-flareon-windows-internals-notes.md>) distills selected official Flare-On solutions plus community writeups into mechanism-level lessons. Use `help` for driver/WFP memory forensics, `crackinstaller` for BYOVD and registry callbacks, `evil` for exception dispatch, `golf` and `HVM` for hypervisor boundaries, and the bootkit/firmware cases for boot trust.
- [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) maps the local Windows Concept, Windows Security, Windows Security Workbook, and Windows Forensic Journey PDFs. Use those as review and drill companions after reading the mechanism sections below.
- [Windows roadmap know-cold explanations](<08-windows-roadmap-know-cold-explanations.md>) expands the roadmap checklist items into direct explanations, including reserved/committed/resident memory, tokens, I/O, mitigations, and EDR visibility.
- [Paging, residency, page lists, and shared memory](<../05-topic-notes/paging-residency-page-lists-and-shared-memory.md>) is the focused companion for section backing, pagefile-backed shared memory, image-backed DLL pages, standby/free/zero page lists, demand-zero faults, and PFN/PTE relationships.
- [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>) is the focused companion for `malloc`/`new`, UCRT, `LocalAlloc`/`GlobalAlloc`, `HeapAlloc`, `HeapCreate`, LFH, segment heap, `VirtualAlloc`/`VirtualFree`, Visual Studio debugging, and compiler/runtime heap fingerprints.
- [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>) is the focused companion for special kernel APCs, file-system cache, paged/nonpaged pool, section objects, `Nt`/`Zw`, `SeLockMemoryPrivilege`, `kernel32` address reuse, PEB/TEB API discovery, DLL sharing, and KASLR.
- [Windows object handles, references, and tokens](<../05-topic-notes/windows-object-handles-references-and-tokens.md>) is the focused companion for handle table entries, object pointer references, handle count versus pointer count, same-object identity by kernel address, handle flags/access masks, token duplication/logon APIs, and object residency caveats.
- [Windows IPC named pipes, RPC, ALPC, and security](<../05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>) is the focused companion for named-pipe endpoint security, pipe impersonation/SQOS, RPC binding and endpoint-mapper behavior, ALPC message attributes, and service-boundary confused-deputy bugs.
- [Attacker-relevant structures and components](<../05-topic-notes/attacker-relevant-structures-and-components.md>) answers how attackers misuse these mechanisms defensively: loader metadata, at-rest PE mutation, VAD/image/private-memory mismatch, process injection variants, reflective/manual mapping, cross-process memory overwrite, shellcode/generated code, process identity mismatch, hooks/detours/pointer tables, kernel dispatch/callback redirection, tokens, persistence configuration, malware/spyware collection, anti-debug state, telemetry gaps, and network artifacts.
- [C++ and modern C++ internals for security researchers](<../02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>) covers the compiled C++ layer that often appears inside Windows user-mode products and `.sys` drivers: vtables, destructors, smart pointers, COM-style refs, Windows RAII wrappers, templates, STL containers, atomics, intrinsics, ABI, and optimizer artifacts.

## Offensive Priority Index

This file is physically ordered like a Windows internals explanation. For offensive low-level research, prioritize the sections like this:

| Score | Sections | Why they matter first |
|---:|---|---|
| 100 | Object Manager, handles, security descriptors, tokens, access checks | Authority is represented as objects, handles, granted access, tokens, privileges, integrity, and ACLs. |
| 100 | Process creation, process identity, PEB/TEB, loader state, DLL loading, KnownDLLs, API sets | Process identity and loader state decide startup, module discovery, side-loading, API resolution, and evidence mismatches. |
| 99 | Memory Manager, VADs, sections, commit, working sets, PTE bits, mapped files, PE images | Memory metadata and backing decide injection, sharing, executable bytes, page residency, and cross-view detection. |
| 98 | IPC endpoints, named pipes, RPC, ALPC | Broker/service boundaries, endpoint ACLs, impersonation, handle/view transfer, and confused-deputy bugs. |
| 97 | Threads, waits, thread pools, WorkerFactory, IRQL, DPCs, APCs, async lifetime | Execution timing, callbacks, queueing, waits, race windows, and kernel/user deferred execution. |
| 96 | I/O Manager, drivers, IRPs, IOCTLs | Driver attack surface, kernel extension points, and device-mediated authority. |
| 95 | Telemetry/tool views, malware/EDR mapping, signature/trust checkpoints, mitigations | Evidence, trust checks, policy gates, and modern constraints such as PPL, CFG/CET, VBS/HVCI, and code integrity. |

## The Core Shape

Windows is easiest to reason about as layered object and policy machinery:

1. User code usually calls Win32 or framework APIs.
2. Many calls pass through `kernelbase`, `kernel32`, `advapi32`, `user32`, COM/RPC, or runtime code.
3. Lower-level OS calls often reach `ntdll` Native API routines and syscall stubs.
4. Kernel execution lands in executive subsystems such as the Object Manager, Memory Manager, I/O Manager, Process Manager, Configuration Manager, and Security Reference Monitor.
5. Real enforcement is still backed by lower-level mechanisms: CPU privilege, page tables, handle tables, object references, driver dispatch, code integrity, and sometimes the hypervisor.

The interview mistake to avoid: treating "the syscall" as the whole Windows API. On Windows, stable compatibility lives at the documented API layer; Native API details and syscall service numbers are lower-level implementation details.

## Executive Versus Kernel Layer

The Foundations system-architecture subtitles make a distinction that the earlier notes underplayed: `ntoskrnl.exe` contains both the Windows Executive and the lower kernel layer. People often say "the Windows kernel" for both, but interview answers should separate them.

| Layer | Main responsibility | Examples |
|---|---|---|
| Executive | Higher-level OS managers that implement most resource policy and system services. | Object Manager, Memory Manager, I/O Manager, Cache Manager, Configuration Manager, Process Manager, Security Reference Monitor, Power Manager, PnP Manager. |
| Kernel | Lower-level scheduling, dispatching, interrupt/trap, synchronization, and architecture-specific machinery. | Thread scheduling, dispatcher objects and waits, interrupt/exception dispatch, DPC/APC mechanics, low-level locks, per-processor state, platform-specific assembly paths. |
| HAL and drivers | Hardware abstraction and extensibility around devices and buses. | Interrupt controllers, timers, DMA adapters, file-system drivers, device drivers, filters. |

The syscall path makes this concrete. A user-mode API such as `CreateFileW` eventually reaches an `ntdll` Native API stub such as `NtCreateFile`. The stub enters the system-service dispatcher. The kernel dispatcher uses the service number to reach the kernel-mode implementation of the service, and the executive component that owns the operation does the real work. For `NtCreateFile`, the I/O Manager and Object Manager participate, security policy is checked through token/security-descriptor machinery, an IRP may be built, and drivers such as a filesystem driver ultimately handle the request.

The distinction matters because "kernel mode" is not one policy blob. A good explanation names the executive manager that owns the object or policy, then names the lower enforcer. Example: object access is an Object Manager plus Security Reference Monitor story, backed by handle tables, references, and page protections. Virtual memory is a Memory Manager story, backed by page tables and the MMU. Device I/O is an I/O Manager and driver-stack story, backed by IRPs, device objects, MDLs, and CPU privilege.

Useful symbol-prefix orientation, with build caveats:

| Prefix | Usual area |
|---|---|
| `Ob` | Object Manager |
| `Ps` | Process/thread manager |
| `Mm` | Memory Manager |
| `Mi` | Memory Manager internals |
| `Io` | I/O Manager |
| `Cc` | Cache Manager |
| `Cm` | Configuration Manager / registry |
| `Se` | Security Reference Monitor |
| `Ke` / `Ki` | Kernel dispatcher, scheduler, interrupt/trap internals |
| `Ex` | Executive support routines, pools, rundown, resources, push locks, worker infrastructure |

Security phrasing: "which executive component owns the decision, which lower mechanism enforces it, and what evidence proves it?" Do not answer "the kernel checks it" when the real answer is token/SRM/handle access, VAD/PTE permissions, IRP/device-object dispatch, or Code Integrity policy.

## Object Manager, Objects, And Handles

The Object Manager is the generic executive component that gives many Windows resources common identity, naming, lifetime, type, and security behavior. Processes, threads, files, sections, events, mutexes, semaphores, jobs, tokens, registry keys, devices, drivers, symbolic links, desktops, window stations, and ALPC ports are not all files. They are typed objects with different semantics.

Key vocabulary:

| Term | Meaning |
|---|---|
| Object type | The class of object, such as Process, Thread, File, Section, Event, Mutant/Mutex, Token, Key, Driver, Device, or Directory. Type controls valid operations and generic access mapping. |
| Object name | Optional name in the NT object namespace. Many objects are unnamed and reachable only by references or handles. |
| Object directory | In-memory Object Manager directory, not a filesystem directory. Examples include `\Device`, `\Driver`, `\KnownDlls`, and per-session `BaseNamedObjects`. |
| Symbolic link | Object namespace link that redirects one NT object path to another, commonly used for DOS device names and device exposure. |
| Handle | Per-process table entry that points to an object and carries granted access. The handle value is not a pointer and is not globally meaningful. |
| Reference count | Keeps an object alive while kernel references exist. A handle contributes a reference, but internal references can also keep an object alive after all visible handles close. |
| Handle count | Count of open handles to an object. This can be zero while a kernel reference still keeps the object alive. |

Mechanism:

- Opening or creating an object performs path lookup if the object is named.
- The caller requests desired access.
- The Object Manager and Security Reference Monitor evaluate the caller's token against the target security descriptor.
- If allowed, the process receives a handle table entry with a granted access mask.
- Later operations check the handle's granted access, not just the original name.
- Closing the handle removes that handle reference. The object disappears only when all references are gone and the object type-specific cleanup has completed.

Do not reduce this to one refcount formula. A handle is a rights-bearing reference; kernel code can also hold pointer references through `ObReferenceObject*` paths; a raw copied pointer does not count unless the code owns a counted reference or another lifetime guarantee. The object pointer/reference count is therefore usually at least the handle count, but it is not simply "user handles + kernel handles + every pointer variable." Temporary lookup references and type-specific lifetime rules also appear.

In a live debugger, two real handles that decode to the same object body address refer to the same Object Manager object. Different object body addresses mean different Object Manager object bodies, though they can still represent the same underlying file, section backing, or similar token contents. Compare object body pointers with object body pointers, not encoded handle table bits or object-header addresses, and beware stale addresses after free/reuse.

Handle table entries hold more than the object pointer: granted access, inheritance/protect-from-close/audit-related attributes, and internal entry usage/ref metadata. On modern x64 builds, private `_HANDLE_TABLE_ENTRY` layouts are often 16 bytes because Windows can pack aligned/canonical pointer bits plus access and attributes into two 64-bit words, but this is a private build-specific layout. The access mask is kernel table state; `SetHandleInformation` can change documented flags such as inheritance/protect-from-close, not grant new object rights.

Inherited handles keep the same handle value and access in the child, but the child still needs a protocol that says what the value means. The usual channels are argv, environment, `STARTUPINFO` standard handles, an IPC control message, or a named object opened by the child. `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` restricts which handles are inherited; it is not a semantic label list visible to the child.

Interview phrasing: a Windows handle is authority to a typed object, not merely an integer file descriptor.

### Object Namespace Edge Cases

The object-management "odds and ends" subtitles call out several mechanisms that should not be lost behind the main handle model:

| Mechanism | Why it matters |
|---|---|
| Private object namespace | A named-object namespace guarded by a boundary descriptor and security descriptor. It lets cooperating processes create names that do not collide with ordinary global/session names and can reduce name-squatting mistakes. |
| Per-session object namespace | Named objects can resolve differently across sessions, especially under `BaseNamedObjects`. Service/session 0 behavior and interactive-session behavior can therefore differ even when the visible name looks similar. |
| `Global\` and `Local\` prefixes | Win32 prefixes for named kernel objects. `Global\` commonly resolves through an Object Manager symbolic link to the machine-wide root `\BaseNamedObjects` namespace. Service applications use that global namespace by default; `Local\` stays in the caller's session namespace. The security boundary is still the target object's DACL, not the prefix or link. |
| User and GDI objects | Window manager and GDI state use GUI/session-oriented handle tables and are not simply ordinary NT Object Manager handles. For GUI reversing, input isolation, leaks, and old win32k exploit history, inspect USER/GDI handle views separately from normal kernel handles. |
| Terminated process/thread object | A Windows process or thread can be dead but still have a waitable object, exit status, handles, and references. This is not Linux parent-reaped zombie semantics; lifetime is object/reference based. |

Security phrasing: for named objects, ask which namespace was used, who could open it, whether the name was predictable, whether unexpected pre-existence was handled safely, whether shared-memory contents were trusted, and whether the evidence comes from Object Manager handles or GUI-specific handle views.

## Security Descriptors, Tokens, And Access Checks

Forshaw's security material is the anchor for this area. The practical access-check model is:

| Component | Role |
|---|---|
| Access token | Carries user SID, group SIDs, privileges, integrity level, AppContainer/capabilities, session data, and default DACL. A process has a primary token; a thread can impersonate. |
| Security descriptor | Attached to securable objects. Contains owner, group, DACL, and optional SACL. |
| DACL | Grants or denies access through ACEs. Absence of a DACL is not the same as an empty DACL. |
| SACL | Drives auditing. It does not grant normal access. |
| Privilege | Special authority such as debug, backup, restore, or impersonation-related rights. Privileges are not generic "admin wins" flags; they must apply to the operation. |
| Integrity level | Mandatory Integrity Control can block write-up even if a DACL seems permissive. |
| AppContainer/capability | Lowbox-style app identity and fine-grained capability SIDs that restrict access further. |
| PPL/protection | Protection levels can block invasive access even from otherwise powerful callers. |

Mechanism:

1. Caller asks for a specific access mask.
2. Generic bits are mapped to object-type-specific rights.
3. Deny and allow ACEs are evaluated against token SIDs.
4. Privileges may supplement or bypass specific checks.
5. Integrity policy and protection policy may still deny access.
6. If access is granted, the resulting handle records the granted mask.

Interview phrasing: do not say "it runs as admin" as the final answer. Name the token, requested access, security descriptor, privilege, integrity, AppContainer/PPL state, and resulting handle rights.

## Process Creation And Process Identity

Windows process creation is not `fork`. The Windows path creates a new process object around an image, address space, token, attributes, handles, and an initial thread.

Conceptual sequence:

1. The image file is opened.
2. An image section is created for the executable.
3. A process object and address space are created.
4. The image section is mapped into the new address space.
5. Process parameters and environment are prepared.
6. The PEB is created for user-mode process metadata.
7. The initial thread and its TEB are created.
8. `ntdll` and loader initialization run before normal application entry.
9. Imports, DLL dependencies, API-set redirection, TLS callbacks, CRT startup, and `DllMain` callbacks happen before the main program body.

User-mode startup detail:

- The first useful user-mode frames are loader/runtime frames, not application `main`.
- `ntdll` loader code initializes the process view of modules, applies relocations, resolves imports, handles API sets, initializes TLS, and calls loader-managed callbacks.
- TLS callbacks can run before the PE address-of-entry-point.
- DLL `DllMain` routines receive process attach notifications under loader-lock constraints.
- The executable entry point is commonly a CRT stub such as `mainCRTStartup`, `wmainCRTStartup`, or `WinMainCRTStartup`.
- The CRT startup initializes runtime state, security-cookie support, argument/environment handling, static initializers, and only then calls `main`, `wmain`, or `WinMain`.
- New thread procedures are likewise reached through wrapper frames; debuggers commonly show `ntdll!RtlUserThreadStart` and `kernel32!BaseThreadInitThunk` around the user thread routine, with exact details varying by build and symbol view.

Terms:

| Term | Meaning |
|---|---|
| Process object | Executive object representing process-wide identity/lifetime/security state. |
| Address space | Virtual memory container described by VADs, page tables, sections, and mapped views. |
| Image section | Section object created from a PE image and mapped into the process. |
| Initial thread | First executable thread used to enter loader/application initialization. |
| Parent process ID | Telemetry and creation metadata. It is not the main Windows ownership primitive. |
| Job object | Grouping/limit/accounting/lifecycle primitive. More important than parentage when you need "manage this process set." |

Interview phrasing: process equals object plus address space plus token plus handle table plus threads plus loader state, not just an EXE running.

### Process And Thread Teardown

Normal teardown is not the same thing as forcible termination.

| Path | What usually happens |
|---|---|
| `main`/`WinMain` returns | CRT exit path runs, then process termination proceeds. |
| `exit` / CRT termination | Runs `atexit` handlers, C++ destructors, CRT cleanup, and then calls OS termination APIs. |
| `ExitProcess` | Terminates process execution and notifies loaded DLLs with process-detach callbacks where possible. |
| `TerminateProcess` | Forceful termination. It can bypass orderly user-mode cleanup and should not be modeled as "destructors ran." |
| `ExitThread` / thread return | Thread-local cleanup and DLL thread-detach notifications may run, subject to loader state and process teardown context. |

Security implication: `DllMain`, TLS callbacks, FLS/TLS destructors, CRT destructors, exception handlers, vectored handlers, and `atexit` callbacks are code-execution surfaces around the obvious program body. Malware and protectors can hide behavior before the nominal entry point or during cleanup, and benign programs can crash or deadlock by doing too much work under loader constraints.

## PEB, TEB, And Loader State

The Pluralsight process/thread modules emphasize that the PEB and TEB are user-mode data structures created as part of process/thread initialization. They are heavily used by debuggers, the loader, runtimes, and malware, but most fields are not a stable public contract.

| Structure | Scope | Important contents |
|---|---|---|
| PEB | One per process | Loader data, process parameters, environment, API-set map, heap/process flags, module lists, image base, command line path data. |
| TEB | One per thread | Stack limits, thread-local storage, last-error value, thread ID/client ID data, SEH-related state on x86, pointer back to the PEB. |

Why it matters:

- Debuggers use PEB/TEB data to inspect modules, parameters, stacks, and thread state.
- Malware may walk PEB loader lists instead of using imports.
- PEB loader lists can disagree with actual memory mappings when code is manually mapped, unlinked, injected, or corrupted.
- TLS callbacks can run before the nominal program entry point, so "break at main" can miss behavior.

Analysis rule: compare PEB loader lists with `lm`, ETW image-load events, VADs, and mapped image sections. Do not trust one view.

## DLL Loading, KnownDLLs, API Sets, And Side-Loading

Windows DLL loading is PE image loading plus policy.

Key terms:

| Term | Meaning |
|---|---|
| Implicit linking | Imports are resolved by the loader as part of process/DLL initialization. |
| Explicit linking | Code calls `LoadLibrary*`/`LdrLoadDll` and `GetProcAddress` at runtime. |
| KnownDLLs | DLLs listed by Windows and mapped early as section objects, exposed through `\KnownDlls`. They short-circuit normal path search for those names. |
| API sets | Contract DLL names redirected by the loader to implementation DLLs. The mapping is visible through process loader/API-set state. |
| Loader lock | Internal serialization around loader state. `DllMain` must avoid complex work that can deadlock under it. |
| Side-by-side policy | Manifest/version policy affecting DLL binding. |
| Side-loading/search-order hijacking | A trusted or expected binary loads an unexpected DLL because path/search policy allows it. |

Mechanism:

- PE headers describe imports, exports, relocations, TLS, resources, and sections.
- Image sections map executable images with image-specific behavior.
- The loader resolves dependencies, patches the IAT, handles relocations, calls TLS callbacks, and calls `DllMain`.
- KnownDLLs and API sets mean that "the DLL name in imports" is not always the final filesystem path.

Base-address rule: a PE preferred image base is only a preference when relocation metadata and policy allow moving the image. Images linked for ASLR, such as `/DYNAMICBASE` images with usable relocation data, can be mapped at randomized bases; images without base relocations are effectively fixed and may fail to load if the preferred range is unavailable. Attackers historically used fixed or predictably based DLLs as ROP and API-target anchors. Modern Windows raises the bar, but a leaked base of a common section-backed DLL may still be useful because the same image often maps at the same chosen base across many processes in the same boot/session. Always verify the target process's mapped base through the PEB loader list, VADs, ETW, debugger module list, or a memory map.

`kernel32.dll` example: in a normal Win32 process, `kernel32.dll` is loaded early and is familiar to shellcode because it leads to functions such as `LoadLibrary*` and `GetProcAddress`. That familiarity does not make it a fixed-address object. Modern `kernel32.dll` is relocatable and ASLR-enabled, and many exports forward to `KernelBase` or API-set-resolved implementation DLLs. Reliable analysis or exploitation therefore starts by finding the actual mapped base in the target process, then resolving the export or forwarder path. A hard-coded `kernel32` VA is historical or environment-specific material, not a modern rule.

Analysis rule: for suspicious DLL behavior, inspect the loaded module path, image backing, signature, import source, API-set redirection, KnownDLL status, and whether the module is present in normal loader metadata.

## Memory Manager: VADs, Sections, Commit, And Working Sets

The memory subtitles are useful because they separate user-visible counters from actual policy.

| Term | Meaning |
|---|---|
| Reserve | Allocate a virtual address range without committing storage. |
| Commit | Promise backing store for private pages, usually RAM or page file-backed storage when needed. |
| VAD | Kernel memory-manager structure describing a process virtual address range and its high-level policy. |
| PTE | Hardware/software page-table entry describing actual translation state. |
| Working set | Pages currently resident for a process. Accessing them should not fault for residency. |
| Private bytes / commit size | Private committed memory, not the same as current RAM use. |
| Section object | Kernel object for file mappings, shared memory, and image mappings. User mode sees this through mapped files or `MapViewOfFile`; Native API exposes `NtCreateSection`/`NtMapViewOfSection`. |
| Prototype PTE | Memory-manager structure used for section-backed pages so multiple views can share common page state. |
| Copy-on-write | Shared image/mapped pages become private when written. |

Mechanism:

- VADs describe what ranges are valid and what policy applies.
- PTEs describe current translation, validity, protection, and software states.
- Page faults are not always bad. They may demand-zero a page, bring a page from disk, resolve a mapped file/image page, or perform copy-on-write.
- The working set is resident memory. Commit is promised private backing. A process can have high commit and a smaller resident working set.
- Memory-mapped files and PE images are section-backed views. This is why file-backed image pages, shared mapped pages, private executable pages, and modified image pages tell different stories.

Analysis rule: classify memory as private, mapped, or image; then ask whether it is committed, resident, executable, writable, file-backed, present in loader metadata, and consistent with expected image-load telemetry.

### Resident Kernel State And Process Roots

Windows can page some kernel virtual memory, but not every kernel structure is eligible to disappear to disk whenever pressure exists. Residency is controlled by the page state, allocation type, lock/pin state, and the context in which the memory may be touched.

| Resident/nonpageable category | Why it must stay available |
|---|---|
| Live page-table pages | The MMU needs the PML4/PML5, PDPT, page directories, and final page tables that are reachable from a live address-space root. The data page described by a non-present PTE can be paged out; the paging-structure page needed to read that PTE cannot be demand-paged in by the same translation path. |
| PFN database and core Memory Manager state | Page faults, working-set changes, page-list transitions, COW, and section/prototype-PTE resolution need physical-page metadata. Losing that state would prevent the kernel from resolving memory itself. |
| Nonpaged pool and nonpageable code/data | Drivers and kernel paths at elevated IRQL, under spin locks, in DPC/interrupt paths, or on fault-critical paths cannot take arbitrary page faults. |
| MDL-locked and DMA/I/O buffers | Locked pages must remain resident while a device, DMA engine, storage path, or kernel copy path depends on their physical frames. |
| Ready/running kernel stacks and per-processor state | A runnable thread's kernel stack and CPU-local scheduler/interrupt state must exist when the processor enters kernel mode. Waiting thread stacks can be swapped out and later brought back through the transition state. |
| Large-page allocations | Explicit Windows large pages are resident/nonpageable, which is part of both their performance value and their security/forensics signal. |

For `_EPROCESS` and `_KPROCESS`, reason in two layers. The core executive process object and embedded kernel process block are nonpageable control state for scheduling, waits, address-space switching, object lifetime, and process accounting. `_KPROCESS.DirectoryTableBase` is one of those address-space anchors. But the process graph fans out into many separately managed objects and mappings: handle tables, tokens, jobs, sections, file objects, VAD-related memory, the user-mode PEB, process parameters, and subsystem/session state. Do not mark all of those "non-swappable" just because an `_EPROCESS` field can lead to them; inspect the allocation/backing path and current PTE/PFN state.

On 4-level x64, a top-level PML4 is per address-space root, not per thread and not one global table for the whole OS. The normal process case is one top-level root for a process whose address space still exists. That includes running, ready, waiting, and suspended processes; it excludes a dead process object whose address-space teardown has already released its page tables. The machine can therefore have many PML4 pages: process roots, special boot/system roots, and on KVA-shadow builds often a restricted user root plus a fuller kernel root variant for the same process. At any given instant, each logical processor translates through the root currently loaded in `CR3`. Threads in the same process normally reuse the same process root, and a context switch to another thread in the same process may avoid an address-space root change.

Classic user/kernel translation uses one active hierarchy. User VAs index the lower/user portion of the active PML4; kernel VAs index the higher/kernel portion. The user entries are process-specific, while the kernel entries are normally kept consistent across process roots and point to shared kernel mappings. The CPU does not ask whether the address is "kernel" and then switch to PID 4; it walks from current `CR3` and checks the present, user/supervisor, RW, NX, large-page, and related bits. With KVA shadow/KPTI, entry to the kernel can switch from a restricted user root to a full kernel root, and return to user mode switches back.

For translating addresses in dumps, the System process (`PID 4`) directory table base is a common kernel-VA translation root, not a magic one. Normal Windows kernel virtual addresses are mapped consistently in the kernel half of process address spaces, so an ordinary `_EPROCESS`, `_ETHREAD`, pool, driver, or kernel image VA should translate through any valid kernel-mode process root. You use the target process root for target user addresses. You use a kernel root for kernel addresses. PID 4 is popular because it is stable and always present; KVA shadow/KPTI complicates this by separating restricted user roots from fuller kernel roots, so choose the kernel root field/view when translating kernel VAs.

### x64 PTE/PDE Bits For Security Reasoning

Do not flatten PTEs into "address plus permissions." A valid x64 Windows PTE or large-page PDE is simultaneously hardware translation state and Windows Memory Manager state. Intel defines the architectural bits that the MMU consumes; Windows overlays software meaning on available bits and uses completely different encodings when `Valid` is clear.

Common valid-entry fields:

| Field | Internals meaning | Attacker-modification effect |
|---|---|---|
| `Valid` / present | Hardware may consume the entry during a page walk. If clear, the raw entry is a Windows software PTE, not this hardware layout. | Turning invalid software state into a present mapping can expose or corrupt memory; clearing valid forces faults and may desynchronize views until TLBs are flushed. |
| Hardware write/RW | Allows stores without a protection fault. | Makes protected data or code writable, bypasses read-only and COW enforcement if combined with the right state. |
| Owner/user | User/supervisor accessibility. Windows PTE output often names this `Owner`. | User-accessible supervisor mappings are severe if reachable; clearing it breaks user access. SMEP/SMAP, KPTI, and VBS change the practical outcome. |
| Write-through / cache-disable | Memory-type/cache behavior for the translation. | Wrong settings can create coherency bugs, MMIO/device corruption, or crashes. |
| Accessed / dirty | Hardware-maintained usage and write indicators used by memory-management policy. | Can poison working-set aging, modified-page accounting, writeback, and forensic signals. |
| Large page / PAT context | In a PDE/PDPTE, selects a large-page leaf; in a 4 KB PTE, the same low-bit area can mean PAT/cache attributes. | Large-page abuse can remap much more memory at once, but alignment and reserved-bit checks make invalid changes crash-prone. |
| Global | TLB lifetime hint across address-space switches. | Can keep translations alive unexpectedly; TLB shootdown and `INVLPG`/global-page handling matter. |
| COW / prototype / software write bits | Windows-owned bits in the software-available range that guide COW, section/prototype, and intended-write behavior. | Hardware does not enforce COW from this bit alone. Corrupting these bits can confuse fault handling and sharing semantics; setting hardware RW is what removes the write fault. |
| PFN / page frame number | Physical frame for a leaf entry or next-level paging-structure page for a non-leaf entry. Older examples often show a 36-bit PFN; modern width depends on the CPU and OS. | Redirects a VA to different physical memory. This can target code, data, page tables, tokens, or arbitrary PFNs, but mismatches with PFN database, VADs, caching, and TLBs often crash or expose the tampering. |
| Reserved / high feature bits | Must match CPU feature rules. "Bits 48-62 reserved" is a useful old diagram only for specific physical-address widths and feature sets. | Reserved-bit violations fault. Incorrect high-bit assumptions are a common source of bad exploit/debugger reasoning. |
| NX/XD | Execute-disable when supported and enabled. | Clearing it can bypass DEP for that mapping if other policies permit control flow there; setting it blocks instruction fetch. CFG/CET/ACG/CIG/code integrity still matter above NX. |

The strongest primitive is usually not "flip NX" in isolation. It is the ability to make the Memory Manager, PFN database, VAD/prototype-PTE state, TLBs, and hardware PTEs disagree in a controlled way. Defensive analysis should compare `!vad`, `!pte`, PFN state, working-set data, image backing, memory protections, and TLB-sensitive timing when available.

### Large Pages And Translation Shortcuts

Large pages are best understood as a page-walk shortcut and a TLB-reach multiplier. A normal 4 KB x64 translation reaches a final PTE. A 2 MB translation stops one level earlier: a PDE with the page-size bit set becomes the leaf, uses a 2 MB-aligned PFN base, and treats the low 21 virtual-address bits as the offset. A 1 GB translation stops at the PDPT/PDPTE level and treats the low 30 bits as the offset. The permission, NX, cache, global, accessed, dirty, and PFN fields in that higher-level leaf apply to the entire range.

After the walk, the TLB caches the resulting translation at that page size. One 2 MB TLB entry can cover the same virtual range as 512 separate 4 KB TLB entries. On a TLB hit, lower page tables are not read. On a TLB miss, the hardware walk finds the large-page leaf and does not read lower-level table pages that do not participate in that mapping. If the Memory Manager later splits or removes the large page, stale large-page TLB entries must be invalidated before smaller-page permissions are trusted.

Windows large-page APIs are explicit and intentionally restrictive:

| API path | Practical meaning |
|---|---|
| `VirtualAlloc(..., MEM_RESERVE | MEM_COMMIT | MEM_LARGE_PAGES, ...)` | Private large-page allocation. Size and base must align to `GetLargePageMinimum`; caller needs `SeLockMemoryPrivilege`; memory is resident/nonpageable. |
| `CreateFileMapping(..., SEC_LARGE_PAGES, ...)` plus `MapViewOfFile(..., FILE_MAP_LARGE_PAGES, ...)` | Pagefile-backed section/view using large pages. On Windows 10 1703 and newer, the map call must request large pages explicitly. |
| Normal `VirtualAlloc` / normal mapped views | Small-page mappings unless the Memory Manager uses internal large mappings for its own purposes. Do not assume every large aligned region is large-page-backed. |

Pros: higher TLB coverage, fewer TLB misses, fewer page walks, fewer paging-structure pages, predictable residency, and better performance for large hot memory regions. Cons: privileged setup, physical-contiguity pressure, all-at-once reserve+commit behavior, less flexible protection, no ordinary paging, and noisier memory accounting. Security effects follow from that coarseness: making a large-page PDE writable or executable changes a whole 2 MB range; changing its PFN aliases a large physical region; setting large-page state incorrectly tends to fault or bugcheck because reserved bits, alignment, and PFN database expectations must all match.

For triage, unexpected large pages are not automatically malicious, but they demand an owner and reason. Look for database/VM/JIT/runtime explanations, the `SeLockMemoryPrivilege` holder, large-page API usage, executable large pages, unusual resident private bytes, and mismatches between VAD policy and the large-page leaf shown by debugger PTE views.

### Memory-Mapped Files, Section Views, And PE Images

The short phrase "memory-mapped files and PE images are section-backed views" means this object chain:

| Layer | What it means | Evidence |
|---|---|---|
| File object | An opened file/device instance with granted access and share state, normally from `CreateFileW`/`NtCreateFile`. | Handle table, Procmon open, file ID/path, share/access masks. |
| Section object / file mapping object | Kernel memory object created from a file handle, pagefile backing, or image file. Win32 exposes this through `CreateFileMapping`; Native API exposes `NtCreateSection`. | Section handle, section name if any, maximum protection, file/image backing. |
| View | A per-process virtual address range mapped from the section through `MapViewOfFile` or `NtMapViewOfSection`. | VAD, `VirtualQuery`, VMMap, `!address`, `!vad`. |
| Prototype PTE / control-area-style state | Shared memory-manager state that lets many views refer to the same section-backed pages and resolve faults consistently. | WinDbg memory-manager views, VAD/prototype-PTE clues, shared/private page state. |
| Resident page | The physical page currently used after a fault. It may be clean shared, dirty shared, private COW, standby, modified, or not resident yet. | Working set, PFN/PTE views, VMMap shared/private/RSS-like categories. |

Win32 names and native names line up like this: `CreateFileMapping` creates the section/file-mapping object, `OpenFileMapping` opens an existing named mapping if the Object Manager namespace and DACL allow it, and `MapViewOfFile` maps a per-process view. Native paths such as `NtCreateSection`/`ZwCreateSection` and `NtMapViewOfSection`/`ZwMapViewOfSection` are lower-level equivalents. Passing `INVALID_HANDLE_VALUE` to `CreateFileMapping` creates a pagefile-backed section; it is shared memory without an ordinary file path, not a heap allocation.

Typical data-file mapping flow:

1. Open a file with suitable access and sharing.
2. Create a file mapping/section with a maximum protection such as read-only, read-write, execute-read, or copy-on-write.
3. Map a view into one or more processes. Each view has its own address, VAD, access, and protection constraints.
4. The view can exist before all pages are resident. First access faults pages in from the file/cache or resolves COW.
5. Shared writable data-file views dirty section/cache state; `FlushViewOfFile` pushes modified mapped data toward storage, and durable file/metadata guarantees may also require file-handle flushing and filesystem policy.
6. Unmapping a view and closing handles drops references. A section/view can keep backing state alive after the original file handle is closed.

PE image mapping is related but not the same as ordinary data-file mapping:

| Data-file section | PE image section |
|---|---|
| Maps file bytes as data according to mapping/view protections. | Created with image semantics, commonly through `SEC_IMAGE`/loader paths. |
| Offsets and protections are caller/API driven within section limits. | PE headers and section table shape image layout, alignment, and initial protections. |
| `FILE_MAP_WRITE`/shared writable views can modify file-backed cached data and later persist depending on flush/writeback. | Image code/data pages are normally mapped for execution/load semantics; writes to shared image pages usually become private COW pages and do not patch the file for other processes. |
| `FILE_MAP_COPY` creates private COW changes. | Relocations, hotpatches, hooks, and modified image bytes commonly show up as private image/COW pages. |
| Loader metadata is not automatically involved. | The user-mode loader adds PEB loader-list state, import resolution, API-set redirection, TLS callbacks, and `DllMain`. An image section alone is not the whole "module loaded normally" story. |

If a process writes to a system DLL page, the answer depends on what kind of mapping and authority path is involved. A same-process patch to a writable image data page or a code page made writable normally produces a private COW page in that process; other processes continue to see the clean shared image page. `WriteProcessMemory` into another process changes that target process's mapping, not a global system copy. A deliberately shared writable PE section, named section, pagefile-backed section, or data-file mapping is different: all processes mapping that same writable object can observe changes according to the section's permissions and synchronization. A kernel primitive that tampers with PTEs, section/control-area state, or the backing file can have broader effects, but that is no longer ordinary user-mode DLL sharing and runs into integrity policy, signing, cache lifetime, and system-stability constraints.

Physical sharing does not require the same virtual address. Two processes can map the same clean file/image page at different VAs through different PTEs. What reduces sharing is private modification: relocations, writable globals, import fixups, hooks, hotpatches, or other writes make the affected pages private/COW. Modern PE and ELF code try to keep executable text clean and position-friendly; writable data, GOT/IAT-like state, TLS, and process-specific relocation state are per process.

This is why Windows memory analysis asks whether a VAD is private, mapped, or image-backed. The same address range size and protection can mean very different things:

- mapped data file: a view of file data and cache-manager state;
- pagefile-backed section: shared memory with no ordinary disk file;
- image section: PE-aware executable image mapping;
- private VAD: `VirtualAlloc`/heap/JIT/unpacked memory with private commit;
- private image page: a former shared image page that diverged through COW.

Security and reversing rules:

- `CreateFileMapping`/`MapViewOfFile` is not just "faster file I/O"; it creates memory objects whose lifetime, DACL, maximum protection, handle inheritance, and mapped views matter.
- A section can be an IPC object. If two processes map the same writable section, one process can alter what the other reads unless the protocol validates and synchronizes shared state.
- Executable shared sections and executable pagefile-backed sections are high-signal triage artifacts. Legitimate JITs, browsers, and runtimes may use executable mappings, but the backing object and control-flow evidence must make sense.
- A signed PE file on disk and an image VAD in memory can diverge. Modified image pages, private executable COW pages, and missing/altered PEB loader metadata are exactly why defenders compare disk bytes, section backing, VAD type, ETW image-load events, and thread starts.
- KnownDLLs are section-object mechanics plus loader policy: trusted DLL image sections are made available under `\KnownDlls`, which changes path-search behavior and evidence.

### Reserved, Committed, And Resident Memory

These terms are easy to collapse into "allocated memory," but they describe different layers.

| Term | What it means | What it does not mean |
|---|---|---|
| Reserved | A virtual address range is set aside in the process address space. | The OS has not necessarily promised private backing, and the pages are not necessarily usable yet. |
| Committed | The OS has promised backing store for private pages if they are touched, charged against the system commit limit. | The pages are not necessarily in RAM right now. |
| Resident | A physical page is currently in RAM and can be accessed without a hard page-in. | The range is not necessarily private, and residency can change under memory pressure. |

Example: a process can reserve a 1 GB range, commit 16 MB inside it, and have only 200 KB resident because only a few pages were touched recently. VMMap, `!address`, `!vad`, working-set views, and performance counters are answering different questions, so mismatched numbers are normal.

The Linux translation is deliberately not exact. Linux usually creates VMAs through `mmap`, grows the heap through `brk`, and relies on overcommit policy for anonymous private backing. A successful `malloc` or anonymous `mmap` often creates usable virtual address space before every page is physically resident; physical pages appear on first touch. That is close to the Windows reserve/commit/residency layering as a reasoning model, but Linux does not expose the same explicit `MEM_RESERVE`/`MEM_COMMIT` contract for ordinary allocations.

### User-Mode Heaps And Virtual Allocation

Windows user-mode memory has another layer above VADs: heap and runtime allocators. `malloc`, `new`, `LocalAlloc`, `GlobalAlloc`, `HeapAlloc`, `HeapCreate`, and `VirtualAlloc` are not interchangeable names for the same operation.

| API family | Mechanism | Main implication |
|---|---|---|
| UCRT `malloc`/`free`, C++ `new`/`delete` | Runtime allocation family, usually backed by Windows heap manager calls. | Pair with the same runtime family; debug CRT and overridden operators can change layout. |
| `LocalAlloc`/`GlobalAlloc` | Compatibility APIs; on modern 32-bit and 64-bit Windows they are implemented over the default process heap. | Still free with `LocalFree`/`GlobalFree`; wrapper implementation does not erase ownership rules. |
| `HeapAlloc`/`HeapFree` | Allocates from an explicit heap handle such as `GetProcessHeap()` or a `HeapCreate` heap. | The heap handle determines the allocation domain, synchronization policy, LFH/segment/NT-heap behavior, and free path. |
| `VirtualAlloc`/`VirtualFree` | Page-granular reserve/commit/release/decommit API. | Direct regions usually appear as private VAD/MEM_PRIVATE data rather than ordinary heap blocks; protection and size are page-based. |

Heaps are used for small allocations because virtual memory is page-granular. A 64-byte C++ object should not require a separate page, VAD, and kernel transition. The heap manager reserves and commits larger regions, then suballocates blocks with metadata, size classes, caching, and synchronization. This is related to reserve/commit because heaps can reserve address space and commit pages as needed, but the more general reason is sub-page allocation efficiency.

Default process heap, private heaps created with `HeapCreate`, LFH policy, segment heap, page heap, and custom runtime heaps all change layout and security evidence. LFH is not a separate heap; it is a policy/front-end used for suitable small allocations. Segment heap is a newer heap implementation and is the recommended/default-backed choice for packaged apps unless legacy behavior is requested. In WinDbg, use `!heap` to distinguish NT heap versus segment heap and to inspect heap ownership; in Visual Studio, disabling `Enable Just My Code` and using the Immediate window expression form such as `? GetProcessHeap()` can make runtime heap calls easier to inspect during a native debugging session.

For the detailed cross-platform heap/API answer, use [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>).

## IPC Endpoints, Named Pipes, RPC, And ALPC

Windows IPC endpoints are object and identity boundaries, not only message paths. A useful answer names the endpoint, transport, DACL or registration policy, server identity, client token, impersonation level, parser/marshalling layer, transferred resources, and evidence source.

Named pipes are `FILE_OBJECT`s managed by NPFS. They use familiar file APIs, which is why a path-consuming service can accidentally be directed at `\\.\pipe\name` or `\\host\pipe\name` instead of an ordinary file. The endpoint's security descriptor is the main access-control knob. Remote-style pipe paths ride SMB, and `\\127.0.0.1\pipe\name` should be treated as remote-style pipe semantics to the same host. Client code that should not be impersonated must set `SECURITY_SQOS_PRESENT` with an anonymous or identification-level result. Server code that must own a privileged pipe name should set an explicit DACL and use `FILE_FLAG_FIRST_PIPE_INSTANCE` when first-instance ownership matters.

RPC adds IDL, NDR marshalling, binding handles, protocol sequences, endpoint mapping, authentication, and QoS. `ncalrpc` is the local path and is implemented over ALPC on modern Windows. `ncacn_np` uses named pipes over SMB. `ncacn_ip_tcp` exposes a TCP endpoint and commonly involves the RPC endpoint mapper for dynamic endpoints. `RpcServerRegisterAuthInfo` is not the same as "only authenticated clients can call me"; interface registration flags, callbacks, binding authentication, and method-level authorization still decide what actually runs.

ALPC is the local low-level facility below many Windows services and local RPC paths. It can carry messages, handles, security context, and section-backed data views. That means ALPC review is not only about bytes. It is also about whether a peer can transfer handles or mapped views, whether the receiver accepts unexpected attributes, and whether every receiver-side resource is closed or unmapped on every path.

The recurring confused-deputy bug is failed impersonation. A service may call `ImpersonateNamedPipeClient` or `RpcImpersonateClient` to perform a request as the client. If the call fails and the service continues, the operation can run as the service account instead. Correct code treats impersonation failure as request failure, reverts reliably after success, and never assumes thread identity changed unless the API succeeded.

For Windows 11, keep these as current mechanism lessons, not frozen exploit recipes. Endpoint names, default security descriptors, private layouts, and service hardening effects must be checked on the target build.

For the detailed IPC answer, use [Windows IPC named pipes, RPC, ALPC, and security](<../05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>).

## Threads, Scheduling, Waits, And Stacks

Windows threads are executive objects and scheduler units. A process is not what runs; threads run.

Address-space roots belong to the process side of the graph. In debugger symbols, the classic page-table root field is `_KPROCESS.DirectoryTableBase` inside the process-control-block state embedded in `_EPROCESS`. `_KTHREAD` contributes scheduling and execution state; it does not own the process page-table root.

| Term | Meaning |
|---|---|
| `_ETHREAD` / `_KTHREAD` | Executive and kernel scheduler/thread structures. `_KTHREAD` carries dispatcher, wait, APC, priority, stack, and scheduling state. |
| Dispatcher object | Waitable kernel object with signal state. Threads, processes, events, semaphores, mutexes, timers, and queues have wait semantics. |
| Ready/running/waiting | Core scheduling states: ready to run, currently executing, or blocked on a wait. |
| Transition | Temporary state used when a thread must become ready but its kernel stack must first be swapped back into RAM. |
| Quantum | Time slice given to a running thread before preemption rules apply. |
| Dynamic priority/boost | Windows can boost priority for responsiveness or starvation relief, then decay back. |
| Affinity | Set of processors a thread is allowed or preferred to run on. |
| Processor group | Windows grouping for systems with many logical processors. A thread belongs to one group at a time. |
| Kernel stack | Per-thread kernel-mode stack. It must be resident when the thread is ready/running because high-IRQL paths cannot fault pageable stack memory. |
| User stack | Per-thread user-mode stack, sized from PE header defaults or explicit creation parameters. |

Mechanism:

- Waiting is object-centric: `WaitForSingleObject` works because many objects expose signal state.
- A terminated thread or process becomes signaled, which lets other threads wait for completion.
- Scheduler decisions are affected by priority, quantum, affinity, processor topology, waits, boosts, and interrupts.
- Thread enumeration crosses process/thread lists, handles, debugger views, ETW, and scheduler state.

Interview phrasing: Windows synchronization and scheduling meet at dispatcher objects, waits, signal state, and thread state.

## User-Mode Thread Pool And Worker Factory

The Threads subtitles cover a mechanism missing from the first notes: the Windows thread pool. A thread pool is a per-process async execution facility that lets code submit work and let Windows choose which worker thread runs the callback. It avoids the cost and memory pressure of creating one thread per small task, while still letting work run off the caller's current thread.

Key pieces:

| Term | Meaning |
|---|---|
| Default process thread pool | Each process has a thread pool that normal APIs and libraries can use. |
| Private thread pool | A caller-created pool with its own properties, useful when one work class should not starve another or needs custom min/max thread settings. |
| Worker thread | A real thread in the process that waits for threadpool work and runs callbacks. |
| `WorkerFactory` / `TpWorkerFactory` | Kernel object behind the user-mode threadpool machinery. Debuggers and object tools may expose worker-factory state even though most code uses Win32 threadpool APIs. |
| `ntdll` threadpool code | Much of the runtime machinery and worker entry path lives in user-mode `ntdll` routines with `Tpp*`-style names. |
| Work item | Callback plus context queued for execution. |
| Wait/timer/I/O callbacks | Threadpool can dispatch not only generic work but also timer, wait, and I/O-style callbacks through related APIs. |
| Callback environment | Configuration that can bind callbacks to a private pool, cleanup group, priority, and related behavior. |
| Cleanup group | Lifetime grouping for threadpool callbacks so shutdown can wait for or cancel outstanding work. |

Mechanism:

1. Code submits work through APIs such as `QueueUserWorkItem`, `CreateThreadpool`, `CreateThreadpoolWork`, `SubmitThreadpoolWork`, or `TrySubmitThreadpoolCallback`.
2. User-mode threadpool code records the callback and context, then coordinates with the process's pool and worker-factory state.
3. Worker threads wait for work, wake, run callbacks, and return to the pool.
4. The pool grows and shrinks based on load and policy. It deliberately does not create thousands of threads immediately just because thousands of work items were queued.
5. The submitter usually does not own or wait on individual thread handles. Completion must be represented through another synchronization mechanism: event, counter, cleanup group, future/promise, I/O completion, or explicit callback state.

This is why threadpool code is an async-lifetime surface. The callback may run after the submitting function returns, on a different thread, under a different stack, and concurrently with other callbacks. Captured pointers, `this`, stack addresses, handles, COM interface pointers, and buffers must outlive the callback or be protected by refcounts/cancellation/cleanup groups. Shared counters need interlocked operations or locks; a simple `+=` is a data race when several worker callbacks update it.

Debugging and reversing evidence:

| Evidence | What it tells you |
|---|---|
| Thread start or stack in `ntdll!Tpp*` routines | The thread is probably a threadpool worker or waiting in threadpool runtime code. |
| Object type/name showing WorkerFactory | The process has kernel-backed worker-factory state for pool management. |
| Many queued callbacks but fewer worker threads | Normal pool throttling, not necessarily a stuck process. |
| Event or counter used by caller | The program is probably waiting for callback completion rather than waiting on worker thread handles. |
| ETW/thread events plus stacks | Show when worker threads were created, woke, executed callback code, and went idle. |

Security relevance:

- User-mode injection or malware may execute inside a threadpool worker, so "thread start address" alone can point to `ntdll` while the interesting frame is deeper in the stack.
- Server, RPC, COM, timer, wait, and I/O-heavy programs often use thread pools, so unexplained callback lifetime is a common source of UAF, race, and shutdown bugs.
- A threadpool can hide concurrency. A single API call may enqueue many callbacks that run later and in parallel.
- Private pools, callback environments, and cleanup groups are control-plane objects. If attacker-influenced code can alter which pool is used or when cleanup happens, it can create starvation, cancellation races, or stale-context use.

Interview phrasing: thread pool equals "callbacks plus dynamic worker threads plus worker-factory/runtime state plus async lifetime." Do not model it as "the program created N known threads and waits on their handles."

### User-Mode Thread Pools Versus Kernel Worker Queues

The phrase "Windows thread pool" is easy to overload. Keep these layers separate:

| Mechanism | Where it lives | What runs | Security/reversing rule |
|---|---|---|---|
| Win32 thread pool | Per process, mostly user-mode `ntdll` threadpool runtime plus kernel support such as worker-factory and wait/completion objects. | User-mode callbacks on ordinary threads in the process. | Treat it as same-process async execution. The callback runs with the process token/thread context unless impersonation or COM/RPC context changes it. |
| Default/private pool | User-mode pool configuration inside a process. | Work, timer, wait, and I/O callbacks selected by callback environment and pool policy. | Private pools and cleanup groups are lifetime/control-plane objects; they do not create a separate kernel scheduler class. |
| WorkerFactory / `TpWorkerFactory` | Kernel object supporting user-mode pool worker creation/wakeup/accounting. | It does not run the user's callback itself; ordinary process threads eventually run the callback in user mode. | Seeing a WorkerFactory means kernel-backed pool management exists for the process, not that callback code is executing in kernel mode. |
| IOCP consumers | Kernel completion port plus threads that remove completion packets. Threads can be application-created or pool-managed. | User-mode code processes completions after the kernel posts packets. | IOCP is a completion queue, not a magic thread type. Ask which thread drains it and who owns the completion key/context. |
| Runtime/framework pools | .NET, CRT/PPL, RPC, COM, browser runtimes, and service frameworks may use Win32 threadpool APIs or maintain additional worker sets. | User-mode runtime callbacks or request handlers. | Do not assume every `Tpp*`-looking worker belongs to the same logical queue, and do not assume every RPC/COM worker is the Win32 default pool. |
| Kernel work items and worker queues | Kernel/executive and driver framework mechanisms such as `ExQueueWorkItem`, `IoQueueWorkItem`, WDF work items, and system worker threads. | Kernel-mode callbacks, commonly at `PASSIVE_LEVEL`, often in system worker thread context. | This is not the Win32 thread pool. Driver code uses it to defer work that cannot run in an ISR/DPC path or needs a sleepable context. |
| DPCs, ISRs, and timers | Kernel interrupt/deferred-execution machinery. | Kernel code at interrupt/DPC constraints; timers can queue DPCs or wake/wait paths. | DPCs are not worker threads and cannot be treated like blocking pool callbacks. Move to a work item when pageable or blocking work is needed. |
| Driver-created system threads | Kernel threads created explicitly by drivers or the OS. | Kernel-mode thread routine. | Not per-process user-mode pool work. It has a thread object and kernel stack, but no normal user callback/user stack execution model. |

So the corrected mental model is:

1. A user-mode threadpool worker is a normal process thread. It has `_ETHREAD`/`_KTHREAD` scheduler state, a TEB, a user-mode stack for user execution, and a kernel stack used during system calls, waits, APC/kernel paths, and other kernel-mode execution.
2. The callback body for Win32 threadpool work runs in user mode. It may enter kernel mode when it performs I/O, waits, synchronization, memory management, syscalls, or RPC/COM/driver-mediated operations.
3. The pool is per process at the user-mode API/runtime level, but it is not purely user-mode: WorkerFactory, waitable objects, completion ports, handles, and the scheduler are kernel-backed pieces.
4. Kernel-mode work queues are separate. They run kernel callbacks on system worker threads and are used by drivers and executive code, not by arbitrary user-mode callbacks.
5. Exact stack sizes are build, architecture, image, and creation-policy details. For reasoning, the important split is user stack for user-mode execution versus kernel stack for kernel-mode execution; do not rely on historical byte counts.
6. In traces, separate "thread start is `ntdll!TppWorkerThread`" from "interesting code is the callback deeper on the stack." For kernel work items, look instead for system worker threads, driver routines, IRQL, and work-item ownership.

## IRQL, Interrupts, DPCs, APCs, And Pageable Code

The Kernel Mechanisms and Memory Management subtitles repeatedly tie IRQL to memory safety and scheduling constraints.

| Term | Meaning |
|---|---|
| IRQL | Per-processor interrupt request level. Higher IRQL masks lower-priority work and restricts what kernel code can do. |
| PASSIVE_LEVEL | Normal kernel execution level. Blocking and pageable access are generally allowed. |
| APC_LEVEL | Level associated with APC delivery and certain kernel synchronization rules. |
| DISPATCH_LEVEL | Level used by DPCs and many spin-lock-protected paths. Blocking and pageable memory access are not allowed. |
| ISR | Interrupt service routine. Runs at device interrupt IRQL and should do minimal urgent work. |
| DPC | Deferred Procedure Call. Moves follow-up interrupt work to DISPATCH_LEVEL so ISRs stay short. |
| APC | Asynchronous Procedure Call. Runs in the context of a particular thread under specific conditions. User APCs need alertable waits; kernel APCs are part of kernel scheduling/I/O mechanics. |

Mechanism:

- Code running above `APC_LEVEL` cannot safely touch pageable code/data because resolving a page fault may require operations that cannot run at that IRQL.
- ISRs should acknowledge hardware and queue deferred work.
- DPCs run later at `DISPATCH_LEVEL`, still too high to block or touch pageable memory.
- Work that can block or perform complex I/O should be moved to worker threads or PASSIVE_LEVEL paths.
- Spin locks are appropriate for short high-IRQL critical sections; mutex-style blocking primitives are not.

APC type is part of the IRQL answer. Normal kernel APCs run in kernel mode at `PASSIVE_LEVEL`; special kernel APCs run in kernel mode at `APC_LEVEL` and can preempt passive-level user or kernel execution. User APCs run in user mode and regular user APCs require alertable waits. A special kernel APC is therefore not the same thing as a DPC and not the same thing as user-mode APC injection.

Kernel pool choice follows the same rule. Paged pool is preferable for passive/APC-level-only state because it can be reclaimed and does not permanently consume scarce resident memory. Nonpaged pool is required for state touched at `DISPATCH_LEVEL`, by DPC/interrupt-adjacent paths, while holding spin locks, or by device/DMA/MDL paths where a page fault would be illegal. With modern APIs such as `ExAllocatePool2`, a caller at `DISPATCH_LEVEL` must request nonpaged memory; the allocation type must match every later access path, not only the allocation call site.

Debugging rule: when a driver crashes, always ask "what IRQL was this code running at, and did it touch pageable memory, wait, or call an API illegal at that IRQL?"

## Synchronization Primitives

Windows has user-mode, executive, and kernel-only synchronization tools. Choose based on scope, waitability, IRQL, contention pattern, and whether other processes must participate.

| Primitive | Scope | Typical use |
|---|---|---|
| Critical section | User mode, same process | Fast intra-process mutual exclusion. |
| SRW lock | User mode, same process | Shared/exclusive reader-writer lock. |
| Event | Kernel object | Signal one-time or level-like conditions; waitable by handle. |
| Semaphore | Kernel object | Counted resource availability. |
| Mutex/mutant | Kernel object | Cross-process or waitable mutual exclusion. |
| Waitable timer | Kernel object | Time-based wakeups. |
| Fast mutex | Kernel mode | Kernel-only mutual exclusion, raises IRQL rules depending on variant. |
| Executive resource | Kernel mode | Shared/exclusive kernel lock for reader-heavy resources. |
| Push lock | Kernel mode | Lightweight shared/exclusive synchronization used internally. |
| Spin lock | Kernel mode/high IRQL | Very short critical sections; spins instead of blocking. |

Mechanism:

- Dispatcher objects integrate with waits and signal state.
- User-mode locks avoid kernel transitions in uncontended cases.
- Kernel locks must honor IRQL and pageable-memory rules.
- Deadlocks often come from wrong lock order, blocking at high IRQL, calling into unknown code while holding a lock, or doing loader/driver callbacks under constrained locks.

Interview phrasing: name the execution level and contention model before naming the lock.

### Subtitle Additions: Locks, APCs, And IRQL

The Kernel Mechanisms synchronization subtitles are useful because they connect primitive choice to actual bug classes:

| Topic | Interview-grade lesson |
|---|---|
| Data race | Unsynchronized concurrent access is a correctness bug when at least one participant writes. Interlocked operations fix single-variable atomicity; they do not automatically protect a multi-field invariant. |
| Critical section | Process-local, user-mode, and efficient when uncontended. It is not a named cross-process object and cannot replace a securable dispatcher object. |
| Semaphore | The count is the resource token model: waits decrement, releases increment up to the maximum. Bad release counts can over-admit; bad acquire/release balance can deadlock. |
| Mutex abandonment | A waiter can acquire an abandoned mutex, but the data protected by the previous owner may be inconsistent. Treat abandoned status as recovery/corruption evidence. |
| Fast mutex | Kernel-only mutual exclusion, not a dispatcher object. Acquisition constrains APC/IRQL behavior, so blocking or waiting while holding it can deadlock paths that require special kernel APC delivery. |
| Executive resource | Kernel reader-writer lock for shared/exclusive access, similar in intent to SRW locks but used inside the kernel. It is useful for read-heavy state and visible in debugger ownership/resource views, but it is not a high-IRQL primitive. |
| High-IRQL synchronization | At dispatch/interrupt-adjacent levels, use spin-style primitives and keep the critical section tiny. Do not fault pageable memory, perform blocking waits, or call unknown code. |

Security angle: race, UAF, and deadlock analysis often starts by asking which primitive was supposed to serialize the object state, what execution level held it, and whether callbacks, APC delivery, cancellation, or I/O completion could reenter the same state machine.

### CreateEvent, KEVENT, And Dispatcher Waits

`CreateEvent` is the Win32 API for creating or opening an event synchronization object. Mechanically, it gives the caller a handle to a typed executive object whose synchronization behavior is backed by a kernel dispatcher object, commonly discussed as `KEVENT` at the kernel layer. The useful mental model is: Object Manager handle plus access rights plus optional name/security plus dispatcher signal state.

`CreateEvent` inputs matter because they describe both object identity and wait behavior:

| Input/concept | Mechanism meaning |
|---|---|
| Security attributes | Optional security descriptor and inheritance choice. If omitted, defaults come from the creating token. |
| Manual-reset flag | If true, the event is a notification/manual-reset event: once signaled, it can release all current and future waiters until someone calls `ResetEvent`. |
| Auto-reset flag | If manual-reset is false, the event is a synchronization/auto-reset event: one waiter is released and the event resets as part of wait satisfaction. If no waiter exists when it is set, the event generally remains signaled until one waiter consumes it. |
| Initial state | Starts the dispatcher state as signaled or nonsignaled. This decides whether the first wait can pass immediately. |
| Name | Optional Object Manager name. Win32 named events normally live under the process/session/global `BaseNamedObjects` namespace chosen by the subsystem layer. |

The common call chain is `CreateEvent*` in Win32/KernelBase to Native APIs such as `NtCreateEvent`; waits flow through APIs such as `WaitForSingleObject`/`WaitForMultipleObjects` to `NtWaitForSingleObject`/related services; signaling flows through `SetEvent`, `ResetEvent`, and Native equivalents such as `NtSetEvent`. The Object Manager handles lookup, naming, security, handle creation, and access rights. The dispatcher handles signal state, wait lists, wait blocks, and waking threads.

What the event is for:

- Flow synchronization: "work is ready", "shutdown requested", "this producer is done", "this async operation completed".
- Cross-thread or cross-process notification when handles are inherited, duplicated, opened by name, or passed through another IPC path.
- Completion handoff in APIs such as overlapped I/O, ALPC/RPC-style async notification, service coordination, and application shutdown logic.

What it is not:

- Not a data lock by itself. It can announce that a condition changed, but the protected data still needs a lock, interlocked state, or a condition-variable/SRW/critical-section pattern.
- Not a queue. If many work items arrive, a single event bit can coalesce notifications; pair it with a real queue/counter when item count matters.
- Not a reliable "pulse" primitive. `PulseEvent`-style logic is race-prone because a thread can miss the brief signaled interval if it is not actually waiting at the right instant. Prefer condition variables, semaphores, IOCP/threadpool waits, or explicit counters.

Deep wait model:

1. A waiting thread supplies one or more handles.
2. The Object Manager resolves each handle to an object and locates the underlying dispatcher object or embedded dispatcher object.
3. The kernel links wait blocks between the waiting thread and the dispatcher object wait lists.
4. If the event becomes signaled, wait satisfaction logic decides which waiters can run. `WaitAny` can complete when one object is signaled; `WaitAll` requires all objects to be signaled together.
5. The awakened thread becomes ready, subject to normal scheduling rules, priority, affinity, APC/alertable-wait behavior, timeout state, and IRQL constraints.

Security and reversing implications:

- Named events are securable named objects. A weak DACL or predictable name can create spoofing, denial-of-service, cross-session confusion, or unintended cross-process signaling.
- `CreateEventEx` lets callers specify an access mask at creation/open time. This matters when a process wants minimal rights rather than a broad handle.
- A successful `OpenEvent`/`CreateEvent` path gives a handle with a granted access mask; later `SetEvent`, `ResetEvent`, or wait operations depend on that handle's rights.
- In a debugger or trace, do not stop at the Win32 API name. Correlate the handle, object name/namespace, type, granted access, signaled state, waiting threads, and call stack.

Interview phrasing: `CreateEvent` creates or opens a handle to a securable event object whose useful behavior is dispatcher signal state. Manual-reset events broadcast a condition until reset; auto-reset events hand one waiter a wakeup token. Correct usage still needs a separate data invariant.

### Exception And Abandoned-State Caveats

The Kernel Mechanisms exception and synchronization subtitles add several debugger-facing caveats:

| Caveat | Mechanism | Security/debugging relevance |
|---|---|---|
| First-chance exception | The debugger gets an early notification before normal user-mode exception dispatch decides whether application handlers can handle it. | A first-chance fault is not automatically a crash; malware and protectors may intentionally use exceptions for control flow. |
| Second-chance exception | If normal handlers do not handle the exception, the debugger gets a final notification before process termination. | In WinDbg, distinguish "interesting handled fault" from "unhandled crash" before drawing conclusions. |
| SEH/VEH dispatch | Vectored and structured handlers can redirect execution; x64 unwind metadata changes how stack unwinding and handler discovery work. | Static CFG can lie when exception dispatch is part of the control-flow design. |
| Abandoned mutex | If a thread exits while owning a mutex, a waiter can acquire it with an abandoned status. | The lock may now be owned, but the protected data may be inconsistent. Treat it as a corruption/recovery signal, not normal success. |

Interview phrasing: exception dispatch and synchronization status codes are part of the execution model. Do not collapse every exception into "crash" or every successful wait into "protected data is valid."

## Jobs, Silos, Sessions, And Containers

The Processes and Jobs subtitles are especially useful here.

| Term | Meaning |
|---|---|
| Job object | Kernel object that groups processes and can apply limits, accounting, termination, CPU, memory, UI, and security-related policy. |
| Nested job | Windows 8+ model allowing a process to be in a job hierarchy so multiple layers of policy can apply. |
| Silo | Isolation extension of the job model. Server silos are used for Windows containers. |
| Object namespace isolation | Silos can isolate named kernel objects so identical names in different containers do not collide. |
| Registry/filesystem isolation | Container/silo policy can redirect or isolate registry and file views. |
| Session | Isolation boundary for interactive logon/UI state. Session 0 is service-focused; user sessions are interactive. |
| Window station/desktop | GUI object namespace and input/desktop isolation layer inside a session. |
| AppContainer | Security sandbox/capability model for UWP/lowbox-style processes. It is not the same thing as a server silo. |

Mechanism:

- Parent process ID is weak lifecycle metadata.
- Jobs provide explicit process-group ownership and limits.
- Nested jobs let multiple managers constrain a process tree or process set.
- Server silos extend jobs with namespace and system-view isolation for containers.
- Object Manager namespace isolation is why named objects can exist independently inside different silos.

Interview phrasing: if the question is "who owns this process group?", answer with jobs/services/sessions/tokens, not just parent PID.

## I/O Manager, Drivers, IRPs, And IOCTLs

Use `windows-kernel-programming-pavel-yosifovich.pdf` and Windows Internals-style I/O references for depth. The roadmap should treat this as a first-class area because endpoint products, kernel bugs, vulnerable drivers, and rootkits often live here.

| Term | Meaning |
|---|---|
| Driver object | Kernel object representing a loaded driver and its dispatch routines. |
| Device object | Kernel object representing a device endpoint exposed by a driver. |
| Symbolic link | Object namespace link that makes a device reachable from user mode, often via Win32 `\\.\Name`. |
| `FILE_OBJECT` | Per-open state for a file/device handle. |
| IRP | I/O request packet. The I/O Manager sends it through a driver stack. |
| I/O stack location | Per-driver request parameters inside an IRP. |
| IOCTL | Device-specific control request sent through `DeviceIoControl`/IRP major function dispatch. |
| MDL | Memory Descriptor List, used to describe locked user/kernel pages for direct I/O. |
| Minifilter | File-system filter driver loaded at a defined altitude. |
| WFP callout | Windows Filtering Platform extension point for network filtering/classification. |

Mechanism:

1. User mode opens a device/file path and receives a handle with granted access.
2. User mode sends reads/writes/IOCTLs through the handle.
3. The I/O Manager builds IRPs and routes them through the device stack.
4. Drivers validate object state, caller mode, buffer lengths, access rights, and IOCTL method.
5. Completion may be synchronous or asynchronous.
6. Bugs often come from missing access checks, unsafe `METHOD_NEITHER`, bad lifetime/cancel handling, MDL misuse, or trusting user pointers.

Interview phrasing: an IOCTL is not just a function call into the kernel. It is a handle-authorized request through the I/O Manager into a driver dispatch path.

## Crash Dumps, Bugchecks, And Driver Verifier

The System Crash subtitles are worth keeping in the path because offensive low-level work depends on turning a bugcheck into evidence:

| Mechanism | What to retain |
|---|---|
| Bugcheck | A deliberate stop when the kernel decides continuing is unsafe. The interesting part is the violated invariant, not only the stop code name. |
| Small dump | Compact triage artifact with bugcheck data, stack, and key state. Good for first pass, often insufficient for pool/object/lifetime reconstruction. |
| Kernel or automatic dump | Captures kernel address space, drivers, kernel stacks, and enough system state for most driver crashes. It usually omits arbitrary user-mode private memory. |
| Complete dump | Captures physical memory and is the most complete but has size, privacy, and storage/pagefile implications. |
| Dump staging | Crash dump configuration and pagefile/backing storage matter because Windows needs a reliable path to preserve memory before normal filesystem services are available again. |
| WinDbg workflow | Start with symbols and `!analyze -v`, then verify the stack, bugcheck parameters, current thread/process, IRQL, loaded modules, driver objects, IRPs, pool, locks, and suspicious callbacks. |
| Driver Verifier | Makes driver bugs fail earlier and more deterministically. Special Pool, pool tracking, IRQL checking, I/O verification, and deadlock detection are especially useful for UAF/OOB, illegal pageable access, bad completion, and lock-order bugs. |
| Manual kernel dump | Useful for hangs and deadlocks where the system is not crashing by itself. The dump can show waiting threads, held locks/resources, and the blocked owner path. |

Security angle: Verifier and crash dumps are not just debugging conveniences. They help prove primitive shape: lifetime misuse, illegal IRQL access, bad lock order, unsafe I/O completion, pool corruption, or access-control boundary failure. For interview answers, explain the invariant and the evidence path rather than stopping at "it crashed in a driver."

## Flare-On Case-Study Bridge

Use the Flare-On notes as concrete drills for the mechanisms above, not as the authority for current Windows behavior.

| Challenge | Mechanism drill | Internals conclusion |
|---|---|---|
| `help` | Start with a crash dump and PCAP, then walk stack evidence to `DRIVER_OBJECT`, device names, IOCTL dispatch, secondary drivers, and WFP callouts. | Rootkit triage is cross-view work. Loaded-module lists, PCAP bytes, object namespace, driver memory, and dispatch tables each reveal a different part of the system. |
| `crackinstaller` | Follow a pre-`main` initializer into a dropped signed driver, Capcom IOCTL, SMEP toggle, reflective unsigned driver, `IoCreateDriver`, `CmRegisterCallbackEx`, and COM registry state. | BYOVD work is not just "load a bad driver." The important model is signed kernel code plus a weak dispatch boundary plus callback/registry/COM effects above it. |
| `evil` | Follow VEH/SEH-driven faults, API hashing, and runtime code patching instead of trusting the initial static CFG. | Exceptions are part of the Windows execution model. Malware can use exception dispatch as an intentional control-flow engine. |
| `golf` | Treat `vmcall` and driver-loaded VT-x code as a ring -1 boundary, then reason about VMX capability, VM exits, and lab virtualization state. | Hypervisor-rootkit thinking adds a layer beneath the kernel. The observed OS control flow may be incomplete without the VMM's exit handling. |
| `HVM` | Trace a user-mode process that imports `WinHvPlatform.dll`, maps guest memory, runs a virtual CPU, and handles port-I/O VM exits. | Hypervisor APIs introduce another boundary protocol: host process, guest physical memory, virtual CPU registers, and VM exits must be reasoned about separately. |
| `doogie.bin`, `Suspicious Floppy Disk`, `Mbransom` | Rebase 16-bit boot code, trace BIOS `INT 13h` disk access, track MBR/VBR/Track 0 layout, and identify interrupt hooks or hidden stages. | Bootkits sit below the OS filesystem view. The disk layout and real-mode execution path can explain behavior that extracted files do not show. |
| `CATBERT Ransomware` | Extract UEFI PE modules from an OVMF image, inspect modified EFI shell commands, and model EFI services plus challenge bytecode. | Firmware analysis is PE and platform analysis before Windows starts. Secure Boot, measured boot, TPM, and ELAM exist because this layer can matter. |

Freshness caveat: `help` is Windows 7-era, `evil` is x86, `crackinstaller` uses an old vulnerable-driver primitive, `golf` is a custom 2018 hypervisor, the BIOS bootkit cases are legacy-shaped, and `HVM`/`CATBERT` are challenge runtimes. They are excellent mental-model exercises, but modern conclusions still need current Microsoft docs, current CPU manuals, and current Windows build behavior.

## Telemetry And Tool Views

Windows internals are learned by correlating views:

| View | What it reveals |
|---|---|
| Process Explorer | Processes, handles, DLLs, tokens, jobs, protection, threads, memory counters. |
| Process Monitor | File/registry/process/thread/network-ish operation timeline at a high semantic level. |
| VMMap | Private/image/mapped memory, commit, working set, protections. |
| WinObj/Object Explorer | Object Manager namespace, directories, symbolic links, named objects. |
| WinDbg | Symbol-backed structures and debugger extensions such as `!process`, `!thread`, `!handle`, `!object`, `!vad`, `!address`, `!pte`, `!irp`, `dt`. |
| ETW/WPA/WPR/Sysmon | Time-based system behavior: process/thread/image/file/registry/network/provider events, sometimes with stacks. |

Analysis rule: never rely on one list. Cross-check handles, object namespace, loader lists, VADs, ETW, memory mappings, symbols, and tool output.

## Malware And EDR-Relevant Mapping

Use these mechanism translations during reversing and defensive interviews:

| Suspicious behavior | Mechanism view |
|---|---|
| Sparse imports | Runtime loader/API resolution, PEB walking, export parsing, API hashing, or delayed loading. |
| At-rest PE mutation | File-backed bytes, PE directories, imports/exports, TLS, resources, overlay data, signature/catalog trust, and file timeline must explain the image that later maps. |
| Signature/check-use race | Authenticode, catalog, SmartScreen, App Control, and driver signing each check a specific object and policy context; compare the checked file identity to the executed image section and later memory state. |
| DLL side-loading | Loader search policy, KnownDLLs/API sets, path trust, signed host plus untrusted dependency. |
| Process injection | Handle access, token/integrity/PPL checks, remote memory allocation or section mapping, memory protections, thread/APC/context start path. |
| Cross-process memory patching | Target process handle rights, remote write/protect operations, image/private page state, thread context, and clean-image byte mismatch. |
| Hollowing/tampering | Image section mismatch, VAD/image/private memory mismatch, loader list inconsistency, thread start address, ETW image/process events. |
| User-mode hooks | Modified DLL code pages, IAT/EAT/inline patches, private executable stubs, mismatch with clean image. |
| Kernel tampering | Driver load/signing, callback/minifilter/WFP ownership, dispatch-pointer ownership, DKOM/data-only mutation, PTE/page-state anomalies, PatchGuard/HVCI constraints, ETW gaps, crash dumps. |
| Credential targeting | Token/logon session/LSASS/PPL/Credential Guard boundaries, not only "read process memory." |
| Container escape thinking | Silo/job/object namespace/registry/filesystem isolation boundary, not just process ancestry. |

Good interview answers name the object, the authority, the subsystem, the low-level enforcer, and the observable trace.

## Signature And Trust Checkpoints

Signature checks are stage-specific:

| Stage | Mechanism view |
|---|---|
| File signing | Authenticode or catalog signing covers SIP-defined content, not necessarily every byte in a flat-file sense. For PE files, certificate-table-related bytes are special. |
| Download/open | SmartScreen and Smart App Control-style paths can add reputation and app-intelligence decisions based on file hash, publisher/certificate, and download context. |
| Explicit verification | `WinVerifyTrust`, Explorer properties, `signtool`, security tools, installers, and application code check the object they are given at that moment. A later open by path can be a different file. |
| User-mode image load | Ordinary EXE/DLL loading is not universal Authenticode enforcement. Enforcement appears when App Control/WDAC UMCI, Smart App Control, protected-process policy, CIG/ACG contexts, or `/INTEGRITYCHECK` require it. |
| Kernel driver load | Kernel Code Integrity validates driver signing during the driver load path; HVCI/Memory Integrity strengthens executable-kernel-page policy. |
| Runtime memory | A valid disk signature does not continuously attest to copy-on-write image pages, private executable memory, IAT/EAT/vtable changes, detours, or kernel writes after load. |

TOCTOU analysis asks whether the checked object and the used object are identical. Be suspicious of path-based verification followed by a separate open, writable allow-rule directories, installer checks that do not recheck extracted payloads, reputation checks followed by replacement, and signed image sections whose memory later diverges from clean file bytes. The defensive habit is to bind decisions to stable identity: file handle, file ID, volume, hash, signer, directory ACL, section backing, ETW image-load event, VAD type, and memory-vs-clean-image comparison.

## Mitigations, Code Mutation, And Cache Coherency

Modern Windows exploitability is shaped by several overlapping mitigation families:

| Mitigation | What it constrains |
|---|---|
| DEP/NX | Prevents execution from pages not marked executable. |
| ASLR/KASLR | Makes useful code/data addresses less predictable. |
| CFG / Kernel CFG | Restricts indirect calls to valid call targets recorded or allowed by control-flow metadata. |
| CET shadow stack / hardware stack protection | Checks return-address integrity against a protected shadow stack on supported hardware/configurations. |
| CET IBT where available | Constrains indirect branch landing sites on supported hardware/software stacks. |
| ACG | Restricts dynamic code generation in constrained processes. |
| CIG / code integrity policy / WDAC | Restricts what signed or policy-approved code can be loaded or executed in protected contexts. |
| HVCI/VBS | Uses virtualization-backed policy to harden kernel-mode code integrity and related enforcement. |

These mitigations do not work by comparing instruction-cache bytes with data-cache bytes before every instruction executes. The practical security model is page permissions, image/section provenance, code-integrity policy, control-flow metadata, and runtime telemetry. Defenders look for executable private memory, writable-to-executable transitions, modified image pages, thread starts outside known modules, suspicious dynamic function-table registration, IAT/EAT/inline patches, and mismatches between VADs, loader lists, ETW image-load events, and clean file bytes.

Cache coherency is still important for generated or modified code. Windows documents `FlushInstructionCache` as the contract after code bytes are written or page protections are changed for execution. JITs, unpackers, hotpatchers, hooks, and shellcode-like stagers all depend on the CPU eventually fetching the new instruction stream. On x86/x64 this is usually less visible to application code because the architecture provides strong coherency properties; on ARM64-style systems explicit cache maintenance is more central. A stale I-cache can make freshly written code fail to execute until the right cache maintenance runs, which is security-relevant for naive shellcode, but it is not the same as CFG/CET/code-integrity policy. Treat "cache flush bypass" narrowly as an architecture/coherency or stale-code question, not as a generic bypass of DEP, CFG, CET, ACG, CIG, or code signing.

## High-Value Recall Prompts

Answer these from memory after reading the source material:

1. Why can an object have zero handles but still exist?
2. Why is a handle an authority transfer mechanism?
3. What gets created before user `main` or `WinMain` executes?
4. Why do KnownDLLs involve section objects?
5. What is the difference between a VAD and a PTE?
6. Why can a page fault be normal behavior?
7. Why is working set not the same as committed memory?
8. Why does a ready thread need a resident kernel stack?
9. Why can high-IRQL code not touch pageable memory?
10. Why does an ISR usually queue a DPC instead of doing all work inline?
11. Why are jobs a better lifecycle model than parent PID?
12. How does a server silo isolate named kernel objects?
13. Why is `METHOD_NEITHER` dangerous in IOCTL handling?
14. Why is direct syscall use not enough to understand behavior?
15. Which tool views would you correlate for suspected manually mapped code?
