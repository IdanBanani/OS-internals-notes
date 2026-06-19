# Windows Kernel Memory, Sections, Privileges, And ASLR

Value Score: 90/100
Role: Windows kernel-memory owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-18

Scope: special kernel APCs and IRQL, file-system cache behavior, paged versus nonpaged pool, section objects and mapped views, `Nt` versus `Zw`, `SeLockMemoryPrivilege`, `kernel32.dll` mapping behavior, `main` versus `wmain`, PEB/TEB based module discovery, Windows versus Linux ASLR, DLL/shared-object page sharing, and KASLR.

Primary source anchors:

- Microsoft Learn: [types of APCs](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/types-of-apcs), [managing hardware priorities](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/managing-hardware-priorities), [`ExAllocatePool2`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-exallocatepool2), [file mapping](https://learn.microsoft.com/en-us/windows/win32/memory/file-mapping), [`CreateFileMapping`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createfilemappinga), [`OpenFileMapping`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-openfilemappinga), [`MapViewOfFile`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-mapviewoffile), [Cache and Memory Manager tuning](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/subsystem/cache-memory-management/), [`Nt` and `Zw` routines](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/using-nt-and-zw-versions-of-the-native-system-services-routines), [`PreviousMode`](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/previousmode), [privilege constants](https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants), [`AdjustTokenPrivileges`](https://learn.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-adjusttokenprivileges), [large-page support](https://learn.microsoft.com/en-us/windows/win32/memory/large-page-support), [`/DYNAMICBASE`](https://learn.microsoft.com/en-us/cpp/build/reference/dynamicbase-use-address-space-layout-randomization), [`main` and command-line arguments](https://learn.microsoft.com/en-us/cpp/cpp/main-function-command-line-args), [`wmain`](https://learn.microsoft.com/en-us/cpp/c-language/using-wmain), [`TEB`](https://learn.microsoft.com/en-us/windows/win32/api/winternl/ns-winternl-teb), and WinDbg [`!peb`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-peb).
- Local companions: [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>), [ELF, PE, loaders, and linkers Q&A](<../02-question-banks/04-binary-loaders-linkers-qa.md>), [Cross-platform process memory API flags](<../01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md>), [Paging, residency, page lists, and shared memory](<paging-residency-page-lists-and-shared-memory.md>), and [Windows object handles, references, and tokens](<windows-object-handles-references-and-tokens.md>).

## Offensive Priority Index

| Score | Section | Why it matters |
|---:|---|---|
| 100 | Section objects and mapped views; file-system cache | Sections are the key bridge between files, pagefile-backed memory, sharing, image mappings, and many injection/reversing observations. |
| 100 | PEB/TEB, FS/GS, API discovery; `kernel32.dll` address behavior; DLL sharing/relocations | Loader and module-discovery behavior is central to ASLR bypasses, export walking, API hashing, and shared image-page reasoning. |
| 99 | Paged versus nonpaged pool; special kernel APCs and IRQL | Kernel exploitation and driver analysis need pool residency, NX pool, pageable-code constraints, and IRQL/APC rules. |
| 98 | `Nt` versus `Zw`; `SeLockMemoryPrivilege` | Native API caller mode and privilege/token state decide whether sensitive memory operations are authorized. |
| 97 | Windows ASLR versus Linux ASLR; KASLR | Mitigation reasoning and info-leak value, especially when comparing Windows and Linux. |
| 94 | `main` versus `wmain` | Useful for process startup and argument parsing, but lower priority than authority, mapping, and mitigation state. |

## Special Kernel APCs And IRQL

Windows APCs execute in the context of a particular thread. The trap is that "APC" is not one thing.

| APC type | Mode and level | Delivery rule | Common meaning |
|---|---|---|---|
| Regular user APC | User mode | Runs when the target thread enters an alertable wait. | `QueueUserAPC`, some overlapped I/O completion paths. |
| Special user APC | User mode | Runs in user mode without the normal alertable-wait requirement. | Newer user APC variant; still user-mode code, not kernel execution. |
| Normal kernel APC | Kernel mode at `PASSIVE_LEVEL` | Preempts user-mode code and is often used by file systems and filters. | Kernel work that must run in a target thread context but can use passive-level rules. |
| Special kernel APC | Kernel mode at `APC_LEVEL` | Preempts user-mode code and kernel-mode code currently running at `PASSIVE_LEVEL`. | I/O completion and other internal kernel mechanics. |

So the direct answer is: yes, a special kernel APC runs in kernel mode at `APC_LEVEL`. On common Windows IRQL diagrams `APC_LEVEL` is the level between `PASSIVE_LEVEL` and `DISPATCH_LEVEL`; do not build reasoning on a raw number when the named level and allowed DDIs are what matter.

Security and driver implications:

- APCs run in a target thread context, unlike DPCs, which are per-processor deferred work.
- Code above `APC_LEVEL` must not touch pageable memory safely; `DISPATCH_LEVEL` and interrupt paths require nonpaged data and no blocking.
- A special kernel APC is not a user APC injection trick. It is kernel-mode machinery with IRQL constraints.
- Disabling APC delivery, entering critical/guarded regions, holding locks, or waiting alertably changes whether queued APC work can run.

## File-System Cache

The Windows file-system cache is mainly Cache Manager plus Memory Manager cooperation. It is not "a copy of every file in a separate heap."

| Path | What usually happens |
|---|---|
| Cached `ReadFile` | Data can be copied from the system file cache if present; otherwise faults/I/O bring file data into cache-backed pages. |
| Cached `WriteFile` | Data can be written to cache first; lazy writer and filesystem policy later push dirty data to storage. |
| Memory-mapped file | A section/view lets the process access file bytes through virtual memory; page faults bring file-backed pages into RAM. |
| `FILE_FLAG_NO_BUFFERING` | Asks for uncached-style I/O with strict alignment and device/filesystem constraints; it does not make all lower caches disappear. |
| `FILE_FLAG_RANDOM_ACCESS` / sequential hints | Influence Cache Manager read-ahead/trimming decisions; they are performance hints, not authority. |

Cached file pages are physical RAM pages while resident. Clean cached pages can move to the standby list and be reused because the file can reconstruct them. Dirty mapped or cached file pages belong to file/cache writeback, not to private pagefile-backed process memory. This is why RAMMap can show "Mapped File", "Metafile", "Standby", and "Modified" categories that are not the same as process private heap.

File-system drivers and minifilters participate through I/O Manager, Cache Manager, and Memory Manager contracts. A cached read, a mapped view fault, and a lazy-writer flush can be different call paths touching the same file object and section state. For security analysis, correlate the `FILE_OBJECT`, section/control area, VAD, cache state, minifilter activity, and final storage writeback rather than assuming one API call equals one disk operation.

## Paged Versus Nonpaged Pool

Kernel pool is system memory used by the kernel and drivers, not a user-mode heap. Modern drivers should prefer APIs such as `ExAllocatePool2` or `ExAllocatePool3` with explicit flags and a pool tag.

| Pool choice | Use when | Cost/security meaning |
|---|---|---|
| Paged pool | The allocation is only touched from contexts where paging and the needed waits are legal. | Cheaper in the sense that it can be reclaimed/paged and does not permanently consume scarce resident memory. Illegal at high IRQL paths. |
| Nonpaged pool | The allocation may be touched at `DISPATCH_LEVEL`, in DPC/interrupt-adjacent paths, while holding spin locks, by DMA/MDL paths, or anywhere page faults are illegal. | Scarcer because it must stay resident. Overuse creates system pressure; corruption is often high impact. |
| Nonpaged executable pool | Only for rare code-generation or trampoline-style cases with a strong reason. | Executable kernel data is a major attack surface and should be exceptional. |

`ExAllocatePool2` allows callers at IRQL `<= DISPATCH_LEVEL`. A caller at `DISPATCH_LEVEL` must request nonpaged memory. A caller at `<= APC_LEVEL` can request paged memory, but that does not mean every later access path is safe. The allocation's pool type must match the highest-IRQL or most constrained path that will ever touch it, not only the IRQL at allocation time.

Rules of thumb:

- If a DPC, ISR-adjacent path, spin-lock-protected path, completion routine at elevated IRQL, or device/DMA path can touch it, use nonpaged memory.
- If the object is large, rarely touched, and only used at passive-level file/control paths, paged pool is preferable.
- Nonpaged pool should normally be NX. Resident kernel data does not need execute permission; executable nonpaged pool is an exceptional code-generation or trampoline case.
- Always use meaningful pool tags; pool tags are ownership evidence in dumps, leaks, and exploitation triage.
- Pool type is not a confidentiality boundary. It changes residency, faultability, reuse, pressure, and exploit reliability.
- Not every kernel object or object-related allocation is nonpaged. The object type, allocation path, and later access context decide residency. Handle tables, object names, security descriptors, VAD/file/section/cache metadata, and type-specific side allocations can have different pool or backing choices from the object body itself.

## Section Objects And Mapped Views

A Windows file mapping object is a section object exposed through Win32 APIs. It is a kernel memory object with handles, access rights, optional names, security descriptors, maximum protection, and backing state.

| Layer | Win32 API | Native API | Meaning |
|---|---|---|---|
| Create/open backing file | `CreateFile` | `NtCreateFile`/`NtOpenFile` | Open a file object with access/share state. |
| Create section/file mapping | `CreateFileMapping` | `NtCreateSection`/`ZwCreateSection` | Create a section object backed by a file, image, or pagefile. |
| Open named mapping | `OpenFileMapping` | `NtOpenSection`/`ZwOpenSection` | Obtain a handle to an existing named section if the DACL and namespace allow it. |
| Map view | `MapViewOfFile`/`MapViewOfFileEx` | `NtMapViewOfSection`/`ZwMapViewOfSection` | Insert a view into one process address space as a VAD range. |
| Unmap/close | `UnmapViewOfFile`, `CloseHandle` | `NtUnmapViewOfSection`, `NtClose` | Drop the view or object handle reference. |

Important details:

- `CreateFileMapping` creates the section object; it does not map the view. `MapViewOfFile` maps a view.
- Passing `INVALID_HANDLE_VALUE` to `CreateFileMapping` creates a pagefile-backed section. The initial contents are zero, and no ordinary file path reconstructs the bytes.
- A named file mapping is a named kernel object. `OpenFileMapping` is an object open and access-check operation, not "find a pointer to memory by name."
- Section maximum protection and per-view access both matter. A view cannot exceed what the section allows.
- Views can exist at different virtual addresses in different processes.
- Physical page sharing does not require identical virtual addresses. The same PFN can be mapped by different PTEs at different VAs.
- A section can outlive the original file handle while section handles or mapped views still reference it.

Security meaning:

- A shared writable section is an IPC channel. Treat its DACL, handle inheritance, duplication, naming, and protocol validation as a boundary.
- An executable pagefile-backed section or executable mapped view is high-signal in injection triage, but not automatically malicious.
- Image sections (`SEC_IMAGE` and loader-created image mappings) have PE-specific layout/protection semantics and should not be modeled as ordinary data-file mappings.

## `Nt` Versus `Zw`

For user-mode callers, the `Nt*` and `Zw*` names for the same Native API service generally behave identically because both enter the kernel through the system-service path.

For kernel-mode callers, the distinction is about the thread's `PreviousMode` and parameter trust:

| Kernel caller choice | Meaning |
|---|---|
| Call `ZwXxx` | The wrapper tells the service that parameters come from a trusted kernel-mode source. The service treats pointers/handles according to kernel-mode expectations. |
| Call `NtXxx` | The service consults the current thread's `PreviousMode`. If the current operation originated from user mode, parameters may be probed/treated as user supplied. |

This is not a clean "bypass security checks" API for driver developers. The dangerous pattern is a confused-deputy driver: user mode asks a driver to open/map/read something, and the driver calls `ZwCreateSection`, `ZwMapViewOfSection`, or another `Zw*` service using kernel authority without impersonating the caller or enforcing the caller's intended policy. That can bypass the user's DACL restrictions because the driver, not the user, became the subject of the operation.

Driver rules:

- If acting on behalf of a user request, capture/probe user buffers correctly and make an explicit authorization decision.
- Use impersonation or the right access-check model when the user's identity should matter.
- Do not pass raw user pointers to `Zw*` as if the kernel will protect you.
- Use `OBJ_KERNEL_HANDLE` for handles that must not be visible in the user handle table when not running in the system process context.
- Treat Native APIs as lower-level implementation contracts, not as stable Win32 substitutes for normal applications.

## `SeLockMemoryPrivilege`

`SeLockMemoryPrivilege` is the privilege behind the "Lock pages in memory" user right. It is represented in an access token as a privilege LUID plus attributes such as enabled, disabled, or removed.

Where it lives:

- The long-term assignment lives in LSA/local or domain security policy: Local Security Policy -> Local Policies -> User Rights Assignment -> Lock pages in memory, or equivalent Group Policy/LSA APIs.
- A logon session receives a token containing the privileges assigned to that account/group at token creation time.
- Existing tokens do not automatically gain a newly assigned privilege; the user/service generally needs a new logon/token.

What `EnablePrivilege(SE_LOCK_MEMORY_NAME)` style code does:

- It opens the effective process or thread token.
- It calls `LookupPrivilegeValue` and `AdjustTokenPrivileges`.
- It can enable the privilege only if that token already contains it.
- `AdjustTokenPrivileges` cannot add a privilege that is absent. A successful API return must still be checked with `GetLastError`; `ERROR_NOT_ALL_ASSIGNED` means the token did not have the requested privilege.

Attacker model:

- A process cannot conjure `SeLockMemoryPrivilege` into its token with a normal API call.
- Code that already runs with a token containing the privilege can enable it if it has token-adjust rights.
- Code that steals, duplicates, or impersonates a token that already contains the privilege can act with that effective token, subject to token handle rights, impersonation level, integrity/PPL policy, and other constraints.
- Kernel compromise or a vulnerable driver can modify token state directly, but that is no longer ordinary privilege enabling.

Practical uses include large pages (`MEM_LARGE_PAGES`) and APIs that lock physical pages. Do not confuse this with ordinary `VirtualLock`, which has different limits and does not make a process immune to all memory pressure.

## Why `kernel32.dll` Often Has The Same Addresses

In many ordinary Win32 processes on the same boot, `kernel32.dll`, `KernelBase.dll`, and `ntdll.dll` appear at the same virtual base addresses. The reason is a combination of loader policy, ASLR image-section reuse, KnownDLL/API-set behavior, and address-space layout choices.

But the precise rule is narrower:

- A function address is usually `module base + export/function RVA`.
- With ASLR disabled or unsupported, a DLL may load at its preferred base if free.
- With ASLR enabled, Windows can choose a randomized base for an image and reuse section-backed image mappings efficiently across processes.
- Common system DLLs are loaded early and consistently, so collisions are uncommon in normal processes.
- The same DLL can still map elsewhere because of bitness, collisions, mitigation policy, image updates, manual mapping, app container/package behavior, or process-specific layout.
- Many `kernel32` exports are forwarders or thunks to `KernelBase` or lower `ntdll` routines, so the address imported from `kernel32` may not be where the real implementation body lives.
- A C/C++ macro has no runtime virtual address unless it expands to a function call or data reference; `LoadLibrary` is an API export, not a macro mapping.

So: "same address in every process" is an observed regularity for many system DLLs, not a security contract. Reversers should verify mapped bases with `lm`, VMMap, `VirtualQueryEx`, PEB loader lists, or ETW image-load data.

## `main` Versus `wmain`

Windows does not start a process at C `main`.

The usual chain is:

```text
kernel process/thread creation
  -> ntdll loader initialization
  -> dependency loading, imports, relocations, TLS callbacks, DllMain
  -> PE entry point, often CRT startup
  -> main / wmain / WinMain / wWinMain
```

`main` receives narrow `char **argv` after CRT command-line parsing. `wmain` is the Microsoft wide-character variant that receives `wchar_t **argv`, which fits Windows' native UTF-16 command-line model better. GUI subsystem programs commonly use `WinMain`/`wWinMain`. `_tmain` is a source-level compatibility macro that selects narrow or wide based on build macros; it is not a kernel entry point.

Security/reversing implication: code can run before `main` through TLS callbacks, CRT initialization, static constructors, delay-load helpers, DLL attach routines, and loader work. A breakpoint on `main` is late.

## FS/GS, TEB, PEB, And API Discovery

Windows exposes per-thread and per-process user-mode metadata through the TEB and PEB.

| Architecture/mode | Common user-mode convention |
|---|---|
| 32-bit x86 Windows | `FS`-relative addressing reaches the TEB. |
| x64 Windows | `GS`-relative addressing reaches the TEB in user mode; kernel mode has its own GS/KPCR mechanics. |
| WOW64 | There are 32-bit and 64-bit views, so tooling must know which mode it is interpreting. |

The TEB contains a pointer to the PEB. The PEB contains process-wide user-mode metadata, including loader data that links loaded modules. Malware, shellcode-like code, packers, and legitimate low-level tools can walk:

```text
TEB -> PEB -> loader metadata -> module base -> PE export directory -> function RVA
```

This supports API discovery without imports: find `ntdll`, `kernel32`, or `KernelBase`; parse exports; resolve names or hashes; compute addresses. It is not a magic kernel bypass. It is same-process user-mode introspection. If the attacker already has code execution or a memory disclosure in the process, ASLR for that process is largely reduced to "find one trustworthy module base, then add known offsets."

Defensive caveats:

- PEB/TEB are user-mode structures and can be tampered with.
- Export walking and API hashing are analysis clues, not proof of malice by themselves.
- Cross-check PEB loader lists with VADs, ETW image-load events, `lm`, memory scans, and backing files.
- Do not hard-code TEB/PEB offsets in supported production software; Microsoft documents these structures as subject to change.

## Windows ASLR Versus Linux ASLR

The statement "Windows ASLR is much weaker than Linux ASLR" is too broad. The correct answer is conditional.

Windows weaknesses or historical issues:

- Common system DLLs often have the same base across many processes during a boot, so a local cross-process module-base leak can be valuable.
- Old or misbuilt images without `/DYNAMICBASE` or relocation metadata reduce ASLR.
- Some legacy 32-bit address spaces have lower entropy.
- API discovery through PEB walking is straightforward after same-process code execution.

Windows strengths:

- Modern 64-bit Windows supports high-entropy VA, bottom-up randomization, image randomization, CFG/CET-adjacent mitigations, ACG/CIG policies in some contexts, and strong process mitigations.
- PPL, CIG/ACG, CFG, CET, and VBS/HVCI can matter more than raw module entropy for many attack chains.

Linux weaknesses or caveats:

- A non-PIE main executable can have fixed text addresses even when libraries move.
- `fork` preserves the parent's layout in children, so a leak from one worker can apply to siblings in fork-server models.
- `/proc`, core dumps, logs, or info leaks can expose maps if permissions/policy are weak.
- Shared libraries usually move, but a single leak still turns offsets into addresses.

Linux strengths:

- PIE plus per-exec `mmap` layout randomization commonly gives strong per-process diversity for the main executable and shared objects.
- W^X, RELRO, stack canaries, CET/IBT where enabled, seccomp, namespaces, and LSM policy combine with ASLR.

The mature security statement is:

> Windows has some cross-process address reuse patterns, especially for common system DLLs, that can make local leaks more reusable than a naive "per process ASLR" model suggests. Linux often has stronger per-exec diversity for PIE/shared-object layouts, but fork inheritance, non-PIE binaries, and information leaks can erase that advantage. In both systems, ASLR is defense-in-depth and usually falls once the attacker can read a reliable code or module pointer.

## Relocations, DLL Sharing, And Linux Shared Objects

Physical sharing does not require the same virtual address. Two processes can map the same physical page at different virtual addresses.

What breaks sharing is private modification. Relocations are one source of private modification:

- If an image page needs a relocation write for a process-specific base, that page can become private/COW and stop sharing with other processes.
- If code is position-independent or uses RIP-relative addressing without patching the text page, clean code pages can be shared even when mapped at different VAs.
- Writable data pages for DLLs/shared objects are normally private per process because each process needs its own globals, GOT/IAT-like state, TLS-related state, and relocation-touched data.
- A same-process hook or patch to DLL code normally creates a private modified image page for that process rather than rewriting one global system DLL page.

Windows PE DLLs:

- Have preferred bases and base relocation tables.
- Are mapped as image sections.
- Can share clean image pages.
- May create private COW pages when relocations, imports, hotpatches, hooks, or writable image data diverge.

Linux ELF shared objects:

- Are normally position-independent `ET_DYN` objects.
- Use RIP-relative/PIC code, GOT/PLT, and dynamic relocations to support mapping at arbitrary VAs.
- Share clean executable segments through file-backed mappings.
- Keep writable data/GOT/TLS state private per process.
- Treat text relocations as undesirable because they hurt W^X, sharing, and hardening.

So "a DLL must be mapped at the same virtual address in every process to share code" is false. Same VA can make relocation avoidance and old PE assumptions easier, but the actual sharing condition is clean file/image-backed pages whose contents are identical and can be mapped by multiple PTEs.

## What KASLR Affects

KASLR randomizes kernel virtual addresses. It does not usually randomize private structure layouts or field offsets; those are build/symbol/compiler details.

Windows KASLR can affect:

- `ntoskrnl.exe` base and kernel-mode image bases such as HAL and drivers;
- kernel module/driver load addresses;
- kernel stacks, pool regions, system PTE/vmalloc-like regions, and other kernel VA allocation choices depending on version/configuration;
- user/kernel split assumptions together with KVA shadow/KPTI-style mitigations.

Linux KASLR can affect:

- the kernel image physical/virtual base where supported;
- loadable kernel module addresses;
- `vmalloc`/`ioremap` and other kernel virtual allocation regions depending on architecture/configuration;
- direct-map/vmemmap layout on some architectures/configurations.

Separate hardening mechanisms may randomize or protect allocator freelists, slab caches, pool metadata, syscall tables indirectly through read-only mappings, control-flow targets, or function order. Do not call all of that KASLR. In exploit reasoning, KASLR mainly raises the need for a kernel pointer disclosure before a write/control primitive can reliably target kernel code, gadgets, dispatch tables, pool objects, or credential/token/process structures.

KASLR is fragile against leaks:

- formatted kernel pointer leaks;
- uninitialized kernel memory disclosures;
- side channels that reveal direct-map/module layout;
- exposed debug/profiling interfaces;
- kernel object addresses leaked to user mode;
- vulnerable drivers that disclose pointers.

The stable question is not "is KASLR enabled?" but "which address family is randomized, how much entropy is present, and can the attacker disclose enough layout to use the primitive?"

## Active Recall

1. Why does a special kernel APC run at `APC_LEVEL`, while a normal kernel APC runs at `PASSIVE_LEVEL`?
2. Why is paged pool cheaper but unsafe for DPC/interrupt-adjacent access paths?
3. Why can a mapped view exist without the file handle remaining open?
4. Why is `OpenFileMapping` an object open with a DACL check?
5. Why is `ZwCreateSection` not a legitimate user-security bypass for drivers?
6. Why can `AdjustTokenPrivileges` fail with `ERROR_NOT_ALL_ASSIGNED` even though the API call returned success?
7. Why can `kernel32.dll` appear at the same base in many processes without making ASLR "off"?
8. Why is a breakpoint on `main` late in both PE and ELF programs?
9. Why does PEB walking reduce ASLR only after code execution or a memory disclosure?
10. Why does physical code sharing not require the same virtual address?
11. Why do relocations and writable globals reduce page sharing?
12. Why does KASLR affect addresses but not private structure field layouts?
