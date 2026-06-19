# Windows Internals Deep Understanding Questions, Scored

Value Score: 92/100
Role: Windows active-recall owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-15

Purpose: a prioritized self-test for Windows internals, especially for someone transitioning from Linux internals. The comparison document explains mappings and design rationale; this file turns the Windows side into a standalone scored question bank and includes full best-answer explanations for each question.

Dense-term companion: [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) expands and routes Windows terms such as VAD, PTE/PFN, section object, IRP, IOCTL, MDL, APC, DPC, ALPC, RPC, ETW, AMSI, PEB/TEB, PPL, VBS/HVCI, CFG, CET, DMA, and IOMMU to practical evidence paths and owner docs.

Source companion: [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>) turns the local Pluralsight Windows 11 Internals subtitles and PDFs/books into mechanism notes for the Executive/kernel split, Object Manager, access checks, process creation, PEB/TEB, loader behavior, memory management, scheduling, `CreateEvent`/dispatcher events, thread pools/WorkerFactory, IRQL/DPC/APC, jobs/silos, drivers, and telemetry. Read it before answering this bank if any term below feels memorized rather than understood.

Focused kernel-memory companion: [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>) answers the common follow-ups around special kernel APCs, file-system cache, paged/nonpaged pool, section objects and mapped views, `Nt`/`Zw`, `SeLockMemoryPrivilege`, `kernel32` address reuse, PEB/TEB API discovery, DLL sharing, and KASLR.

Focused object companion: [Windows object handles, references, and tokens](<../05-topic-notes/windows-object-handles-references-and-tokens.md>) answers handle-entry layout, object pointer references, handle count versus pointer/reference count, same-object identity by kernel address, handle flags and granted access, `DuplicateTokenEx`/`LogonUser`/`OpenProcessToken`, and kernel object residency caveats.

Focused IPC companion: [Windows IPC named pipes, RPC, ALPC, and security](<../05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>) answers named-pipe endpoint security, `SECURITY_SQOS_PRESENT`, pipe instance races, RPC protocol sequences, endpoint mapper limits, RPC binding auth/QoS, ALPC message attributes, handle/view transfer, and impersonation failure bugs.

Case-study companion: [Flare-On Windows Internals Case Notes](<../04-windows/04-flareon-windows-internals-notes.md>) uses official Flare-On solutions plus selected community writeups to turn CTF solver paths into concrete Windows-internals prompts for memory forensics, driver/WFP analysis, BYOVD, registry callbacks, exception dispatch, API hashing, ring -1 hypervisor behavior, Windows Hypervisor Platform tracing, bootkits, and UEFI firmware analysis.

Hebrew case-study companion: [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>) references the newly added PDFs for Kerberos, LSASS, ETW, Event Logs, Windows Authorization, NTLM, WinAPI hashing, injection, DLL side-loading, direct/tampered syscalls, minifilters, BYOVD/DSE, Windows Kernel, AFDUMP, and firmware trust topics. Use them for deeper examples after validating current Windows behavior.

Journey companion: [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) points to companion Windows Concept, Windows Security, Windows Security Workbook, and Windows Forensic review tracks. Use them as concept bridges, active-recall drills, and evidence-oriented review beside this bank.

Technique companion: [Attacker-relevant structures and components](<../05-topic-notes/attacker-relevant-structures-and-components.md>) provides answered defensive explanations for attacker misuse of PE/loader metadata, at-rest PE mutation, image-memory patching, cross-process memory overwrite, injection variants, reflective/manual mapping, hollowing/ghosting-style identity mismatches, shellcode/generated code, hooks/detours/pointer tables, kernel callbacks/dispatch paths, token impersonation, UAC/elevation-policy confusion, persistence configuration, malware/spyware collection methods, anti-debugging, telemetry gaps, and network/DNS/proxy artifacts.

Remote-attacker companion: [Remote-attacker low-level mechanisms](<../05-topic-notes/remote-attacker-low-level-mechanisms.md>) turns the Windows answers into the 0/1-click RCE+PE-to-agent scenario: client execution context, token/integrity/session state, handle/object authority, VAD/PTE/section memory, loader/path/IPC behavior, async lifetime, driver extensions, credentials, communication, telemetry, mitigations, Windows persistence surfaces, containers/virtualization, DMA, and boot trust. Vulnerability/exploitability reasoning is secondary to the security internals that determine what an authorized agent can do.

Vulnerability-research companion: [Vulnerability research and exploitation primitives](<../05-topic-notes/vulnerability-research-and-exploitation-primitives.md>) keeps the secondary exploitability track separate: Windows structures of interest, bug classes, primitives, mitigations, constraints, and safe authorized validation.

Score meaning:

| Score range | Meaning |
|---|---|
| 95-100 | Core mental model. Missing this breaks many other explanations. |
| 90-94 | Very high value for senior interviews, debugging, reversing, and defense. |
| 85-89 | Important depth that distinguishes real understanding from memorization. |
| 80-84 | Practical depth for malware analysis, driver work, or endpoint security. |
| 70-79 | Specialized or role-dependent. |

## Cross-Cutting Responsibility Map

Use [the low-level security component map](<../01-comparisons-and-maps/02-low-level-security-component-map.md>) alongside this question bank for the low-level checker/enforcer split. Windows answers should explicitly separate:

| Boundary | Windows checker/policy component | Lower-level enforcer |
|---|---|---|
| Object and process access | Object Manager, Security Reference Monitor, tokens, security descriptors, integrity, PPL | Kernel object paths and MMU-backed memory access |
| User-to-kernel transition | `ntdll` syscall stubs, kernel syscall/trap dispatch, driver dispatch paths | CPU privilege level, syscall entry state, SMEP/SMAP, page permissions |
| Process memory access | handle creation, granted access, `SeDebugPrivilege`, integrity, PPL, memory manager | kernel copy/map routines plus MMU permissions |
| Physical memory and DMA | memory manager, driver APIs, MDLs, DMA remapping policy | MMU, IOMMU, DMA engine, hypervisor where enabled |
| Boot and kernel integrity | Secure Boot policy, Windows Boot Manager, Code Integrity, WDAC, ELAM, HVCI | UEFI firmware, TPM measured boot, hypervisor-enforced isolation |
| Kernel tamper resistance | PatchGuard, HVCI, driver signing, CFG/CET where available | kernel integrity checks, hypervisor controls, CPU control-flow features |

## Tackle-Resistant Answer Pattern

For every Windows internals answer, force the explanation through these checks:

1. Name the object: process, thread, token, section, file object, device object, driver object, registry key, event, ALPC port, or another typed object.
2. Name the authority: token state, handle granted access, privilege, integrity level, AppContainer/capability, PPL/protection level, job/session boundary, or driver/kernel authority.
3. Name the transition: Win32 to Native API, user mode to kernel mode, object open to later handle use, path string to file object, VAD policy to PTE translation, IRP creation to driver dispatch, or image section to loader metadata.
4. Name the enforcer: Object Manager/SRM, memory manager/MMU, I/O manager/driver, dispatcher, Code Integrity, hypervisor, IOMMU, or firmware/TPM-backed boot policy.
5. Name the evidence: handle table, token, security descriptor, VADs, PTEs, PEB/TEB, ETW, Procmon/Sysmon, WinDbg symbols, IRPs, loaded modules, file IDs, signatures, or memory dump views.
6. State the caveat: Windows build, symbol view, policy state, undocumented field stability, protection level, or whether the data source is user-mode and tamperable.

This pattern prevents most shallow answers. If the explanation cannot say who had authority, which object was acted on, which boundary was crossed, and what independent evidence would prove it, it is not interview-ready yet.

## Top Priority Questions

| Score | Area | Deep-understanding question | Strong answer must cover | Current coverage |
|---:|---|---|---|---|
| 100 | Object Manager | Why is the Object Manager central to Windows, and how does it differ from "everything is a file"? | typed objects, object namespace, handles, object headers/types, reference counts, security descriptors, symbolic links, named objects, waitable vs non-waitable objects. | Good in [Linux vs Windows internals](<../01-comparisons-and-maps/01-linux-vs-windows-internals.md>); needs this standalone bank. |
| 99 | Handles/access | What does it mean to hold a Windows handle with granted access? | per-process handle table, granted access mask, desired access, inheritance, duplication, lifetime, auditing, object type, closing vs object destruction. | Good in comparison. |
| 98 | Tokens/security | How does a Windows access check work? | access token, user SID, group SIDs, privileges, integrity level, AppContainer/capabilities, security descriptor, DACL/SACL/owner, generic mapping, mandatory integrity, impersonation. | Good but scattered. |
| 97 | Process creation | What happens conceptually during `CreateProcess` / `NtCreateUserProcess`, and how do nearby launch APIs differ? | file open, image section, process object, address space, token, attributes, inherited handles, PEB/process parameters, initial thread, loader initialization, ETW events, `CreateProcessAsUser`/token variants, `ShellExecuteEx` shell mediation, CRT `_spawn` wrappers. | Good in comparison. |
| 96 | Process/thread structure graph | How do `_EPROCESS`, `_KPROCESS`, `_ETHREAD`, `_KTHREAD`, `ActiveProcessLinks`, handle tables, VADs, jobs, sessions, and object references compose a real Windows process? | `_EPROCESS` is an opaque process object, `_KPROCESS` is the kernel process block within it, `_ETHREAD`/`_KTHREAD` represent execution, `LIST_ENTRY` fields are embedded links not whole objects, handle/object references drive lifetime, VADs describe memory ranges, and one active list is only one view. | Added deeper comparison in [Linux vs Windows internals](<../01-comparisons-and-maps/01-linux-vs-windows-internals.md>). |
| 96 | Memory manager | How do VADs, sections, views, reserve/commit, page protections, and image mappings fit together? | VAD tree, private/mapped/image memory, section object, control area/subsection concept, commit charge, page faults, COW, `VirtualAlloc`, `MapViewOfFile`, `NtMapViewOfSection`. | Partial to good. |
| 95 | User/kernel boundary | Why is Win32 not the same as the syscall layer? | Win32/kernelbase/ntdll layering, Native API, syscall stubs, unstable service numbers, user-mode work before syscall, compatibility contract, and Windows API variant naming rules such as `Ex`, `A/W`, `AsUser`, `ByHandle`, `Nt`/`Zw`, `Rtl`, and `Ldr`. | Strong in comparison. |
| 95 | Executive/kernel split | Why is "the Windows kernel" not precise enough as a mechanism explanation? | `ntoskrnl`, Executive managers, lower kernel dispatcher/scheduler/interrupt machinery, HAL/drivers, syscall dispatch, manager-owned policy, lower enforcers, symbol-prefix/evidence orientation. | Added from Pluralsight Foundations subtitle pass. |
| 94 | I/O manager | What happens when user mode calls `CreateFile` and then `DeviceIoControl`? | Object Manager path, file/device object, handle access, I/O manager, IRP, IO stack location, buffering method, driver dispatch, completion, cancellation. | Moderate in comparison. |
| 94 | Loader/PE | How does the Windows loader map a PE and resolve DLL dependencies? | PE headers, image section, imports/IAT, exports/EAT, relocations, TLS callbacks, `DllMain`, loader lock, API sets, KnownDLLs, side-by-side policy. | Good in comparison. |
| 93 | Threads/APCs/waits | How do Windows threads, waits, dispatcher objects, APCs, and alertable waits relate? | `ETHREAD`/`KTHREAD`, waitable objects, wait blocks, kernel/user APCs, alertable wait requirement, IO completion, thread context. | Partial. |
| 93 | Events/CreateEvent | What does `CreateEvent` create, and how do event objects actually wake waiters? | event object handle, Object Manager name/security/access, `BaseNamedObjects`, manual vs auto reset, initial signal state, `SetEvent`/`ResetEvent`, wait blocks/wait lists, `WaitAny`/`WaitAll`, lost-pulse/coalescing pitfalls, security/reversing evidence. | Added from Pluralsight synchronization subtitles plus Windows Internals book pass. |
| 92 | Thread pool/async work | How do Windows thread pools, WorkerFactory objects, overlapped I/O, and cancellation change the thread and lifetime model? | default and private pools, `WorkerFactory`/`TpWorkerFactory`, `ntdll!Tpp*` runtime, work/timer/wait/I/O callbacks, callback environments, cleanup groups, dynamic worker count, completion signaling, async lifetime, cancellation races, shared-state synchronization. | Added from Pluralsight Threads subtitle pass. |
| 92 | Jobs/services/sessions | Why are jobs, SCM services, sessions, window stations, and desktops more important than parent-child process trees? | weak parentage, jobs for grouping/limits, SCM lifecycle, session 0 isolation, interactive sessions, window station/desktop isolation, service SIDs. | Good in comparison. |
| 91 | Registry/configuration | Why is the registry a first-class internals and security surface? | hives, keys/values, security descriptors, SCM/driver/COM/policy/autostart state, registry virtualization, callbacks, Procmon/Sysmon observation. | Good in comparison. |
| 91 | ETW/observability | Why is ETW foundational rather than just logging? | providers, events, kernel/user providers, stack capture, image/process/thread/file/registry/network telemetry, WPA/WPR, EDR/Sysmon use. | Moderate. |
| 90 | WinDbg/symbols | Why are PDB symbols and debugger extensions central to Windows internals? | public/private symbols, `dt`, `!process`, `!thread`, `!handle`, `!address`, `!vad`, `!object`, `!token`, `!irp`, build-specific layouts. | Partial. |
| 90 | Security boundaries | How do integrity levels, UAC, privileges, PPL, AppContainer, and impersonation change "admin/SYSTEM" thinking? | MIC, split tokens, token privileges, impersonation levels, service accounts, PPL, AppContainer/lowbox, capability SIDs, protected resources. | Good in comparison; needs depth. |
| 89 | Attacker tunables | Which Windows OS/process/thread/environment tunables matter in remote exploit chains, and what authority is required to change them? | environment block, DLL search state, PEB process parameters, token privileges, handle inheritance, mitigation policy, IFEO/WER, services/tasks/COM/WMI, Defender/AMSI/ETW policy, network/proxy/WFP, PPL/signature levels, kernel callbacks. | Expanded in [attacker-relevant structures](<../05-topic-notes/attacker-relevant-structures-and-components.md#attacker-tunable-state-os-process-thread-and-environment-parameters>). |
| 89 | File systems/cache | How does Windows file I/O interact with file-system drivers, minifilters, cache manager, and memory manager? | `FILE_OBJECT`, IRPs, file-system stack, minifilter altitude, cache manager, section objects, mapped files, oplocks/share modes. | Partial. |
| 89 | Drivers | What are driver objects, device objects, symbolic links, IRPs, MDLs, DPCs, and IOCTL buffering modes? | WDM/WDF orientation, dispatch routines, device stack, `METHOD_BUFFERED`/direct/neither, MDL, security checks, DPC/work item split. | Partial. |
| 89 | Low-level PE/process mutation | How do at-rest PE mutation, in-memory image patching, cross-process overwrites, detours, and kernel redirection differ defensively? | disk PE bytes/signature, loader directories, image-backed COW pages, private memory, process handle rights, section views, IAT/EAT/inline hooks, dispatch/callback pointers, DKOM/PTE caveats. | Expanded in [attacker-relevant structures](<../05-topic-notes/attacker-relevant-structures-and-components.md#low-level-mutation-and-patching-model>). |
| 89 | Signature checks and TOCTOU | At which stages are PE signatures, certificates, reputation, App Control, and driver signing checked, and where can check/use races appear? | Authenticode/catalog coverage, SmartScreen reputation, WinVerifyTrust, WDAC/UMCI/SAC, `/INTEGRITYCHECK`, kernel Code Integrity, driver load, file identity, path rules, section creation, post-load memory mutation. | Expanded in [attacker-relevant structures](<../05-topic-notes/attacker-relevant-structures-and-components.md#signature-certificate-and-toctou-checkpoints>). |
| 88 | Kernel mitigations | Why do PatchGuard, driver signing, HVCI, VBS, CFG, CET, and vulnerable-driver blocklists change rootkit thinking? | integrity constraints, code signing, kernel patch protection, virtualization-based isolation, control-flow mitigations, BYOVD risk. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `crackinstaller` BYOVD/SMEP/registry-callback flow; still needs current primary-source detail. |
| 88 | Process memory triage | How do you decide whether executable memory in a process is normal, packed, injected, or manually mapped? | VAD type, protection, backing file, PEB loader list, image-load ETW, private RX/RWX, modified image pages, section mapping, thread starts. | Good in comparison. |
| 87 | DLL search/loading | Why is DLL side-loading not just `LD_LIBRARY_PATH` abuse? | application directory, system directories, KnownDLLs, SafeDllSearchMode, manifests, API sets, packaged apps, service DLLs, COM. | Strong in comparison. |
| 87 | API resolution | What do `LoadLibrary`, `GetProcAddress`, `LdrLoadDll`, and manual export parsing tell you during reversing? | normal dynamic loading, lower-level loader APIs, export directory, ordinal/name lookup, API hashing, static-import evasion, telemetry. | Strong in comparison. |
| 86 | Cross-process access | What is the Windows model for process inspection/injection? | process handle access, `SeDebugPrivilege`, integrity/PPL, `VirtualAllocEx`, sections, `WriteProcessMemory`, remote threads/APCs/context, ETW/Sysmon triage. | Good in comparison. |
| 86 | Native API | When should you care about `Nt*` APIs rather than Win32 APIs? | lower-level semantics, object attributes, handles, sections, process/thread/memory operations, undocumented/stability caveats, malware/reversing patterns. | Good in comparison. |
| 85 | ALPC/RPC/COM | Why are ALPC, RPC, and COM central Windows IPC surfaces? | brokered IPC, service/client boundaries, impersonation, named endpoints, COM registration/activation, attack and observability surfaces. | Expanded with [Windows IPC named pipes, RPC, ALPC, and security](<../05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>). |
| 85 | Networking | How does Windows network filtering and telemetry differ from Linux netfilter/eBPF? | Winsock, AFD at high level, NDIS, WFP layers/callouts, Defender Firewall, ETW network providers, per-process network telemetry. | Partial. |
| 84 | Scheduler/dispatcher | What is the Windows dispatcher model? | threads as scheduling units, priorities, quantum concept, dispatcher objects, waits, ready queues conceptually, DPC/APC relation, primitive choice under IRQL/APC constraints. | Improved; still benefits from WinDbg drills. |
| 84 | Exceptions | How do SEH/VEH, user-mode exception dispatch, and unwind metadata affect reversing and malware analysis? | TEB/SEH on x86, VEH, `KiUserExceptionDispatcher`, x64 unwind info, dynamic function tables, anti-analysis use. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `evil`; comparison covers broader model. |
| 83 | WOW64 | Why is WOW64 more than "32-bit on 64-bit"? | 32-bit ntdll, wow64/wow64win/wow64cpu, transition to 64-bit, separate PEB/TEB views, syscall thunking, Heaven's Gate relevance. | Partial via Flare-On file. |
| 83 | PEB/TEB | What lives in the PEB and TEB, and why do malware and debuggers care? | loader lists, process parameters, environment, TLS, TEB stack/thread data, PEB access, anti-debug flags caveat, module enumeration. | Moderate. |
| 82 | SCM/persistence | How do Windows services become persistence and privilege boundaries? | service registry keys, binary path, service DLLs, account token, service SID, dependencies, recovery, session 0, SCM events. | Good in comparison. |
| 82 | Scheduled tasks/WMI/COM and persistence subtypes | How do scheduled tasks, WMI permanent consumers, COM hijacks, IFEO, AppInit/AppCert, Netsh helpers, Winlogon, time providers, port monitors, LSA SSPs/password filters, shims, shortcuts, screensavers, and PowerShell profiles differ as persistence surfaces? | trigger/action model, host process, registry/file artifacts, COM activation path, debugger value, WMI repository/events, LSASS/Winlogon/spooler/user32/netsh hosts, writer authority, telemetry. | Expanded in [attacker-relevant structures and components](<../05-topic-notes/attacker-relevant-structures-and-components.md>). |
| 81 | Memory forensics | How do you find hidden or unlinked code from a dump? | module list vs memory scan, VADs, pool tags, driverscan/modscan concepts, PEB mismatch, unloaded drivers, signatures, thread starts. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `help`. |
| 81 | Object callbacks | What are process/thread/image/registry callbacks, and why do security products and rootkits care? | kernel notification/callback model, legitimate EDR use, tampering/visibility, PatchGuard constraints, callback enumeration in WinDbg/tools. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `crackinstaller` registry callback behavior. |
| 80 | Minifilters/WFP | Why are minifilters and WFP common places for security products and stealthy code? | file-system minifilter stack/altitude, registry/process callbacks adjacent, WFP layers/callouts, network filtering/inspection. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for WFP callout behavior in `help`; minifilters still need more depth. |
| 80 | Code integrity | How do Authenticode, catalog signing, WDAC, SmartScreen reputation, and driver signing differ? | file signature, catalog trust, policy enforcement, user-mode reputation, kernel-mode signing, limitations. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `crackinstaller`; current WDAC/HVCI/blocklist behavior still needs Microsoft docs. |
| 79 | PowerShell/.NET/AMSI | Why are PowerShell/.NET/AMSI relevant to Windows internals? | script engines, CLR loading, AMSI scan path, ETW/script logging, in-memory assemblies, defensive telemetry. | Partial; malware-specific. |
| 78 | Hyper-V/VBS | Why does virtualization matter inside the Windows security model? | Hyper-V, VBS, HVCI, credential guard, isolated secrets/code integrity, hypervisor rootkits conceptually. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `golf` ring -1 VMX thinking and `HVM` Windows Hypervisor Platform/VM exits; VBS/HVCI still need primary-source detail. |
| 78 | GUI/input/session | Why do sessions, desktops, window stations, UIAccess, and accessibility APIs matter for spyware analysis? | interactive isolation, session 0, desktop boundaries, hooks, clipboard/screen capture, integrity levels, UIAccess. | Good in comparison; not deep. |
| 77 | Boot trust | How do Secure Boot, measured boot, TPM, BitLocker, ELAM, and boot-start drivers fit together? | boot chain, measurements, key sealing, early drivers, kernel trust, recovery/forensics implications. | Improved by [Flare-On notes](<../04-windows/04-flareon-windows-internals-notes.md>) for `doogie.bin`, `Suspicious Floppy Disk`, `Mbransom`, and `CATBERT`; modern Secure Boot/TPM policy still needs primary sources. |
| 76 | Kernel pool | What should you know about Windows kernel pool and object allocation for vulnerability analysis? | pool tags, lookaside/history at high level, object headers, special pool, pool corruption, verifier, modern pool hardening caveat. | Gap/partial. |
| 75 | Patch/triage | Given a suspected Windows vulnerability, how do you reason from bug to primitive to mitigation to patch? | object lifetime, IRQL/context, pool object, handle/security check, user/kernel copy, mitigations, verifier/test, ETW/WinDbg/crash-dump proof. | Improved; still benefits from tool-backed examples. |

## Best Answers

### 100 - Object Manager

The Object Manager is central because Windows represents many kernel resources as typed objects with common naming, lifetime, reference, handle, and security behavior. Processes, threads, files, sections, events, mutexes, tokens, registry keys, desktops, window stations, devices, drivers, symbolic links, and ALPC ports are not all "files"; they are different object types managed through common object infrastructure.

This differs from the Unix "everything is a file" intuition. A Windows object may be waitable, securable, named, inheritable, duplicable into another process, or visible in the NT object namespace without supporting byte-stream `read` and `write`. The point of the Object Manager is not uniform I/O; it is uniform object identity, lifetime, access checking, naming, and handle-based authority.

The mechanism to keep straight is: object type defines valid operations and generic-access mapping; the optional object name lives in an Object Manager directory such as `\Device`, `\Driver`, `\KnownDlls`, or a per-session `BaseNamedObjects`; the object body holds type-specific state; and object headers/reference counts keep the object alive while handles or kernel references exist. A named object can disappear from the namespace while internal references still keep the object alive, and many important objects are never named in the first place.

A pressure-resistant answer separates policy from enforcement. The Object Manager coordinates lookup, handle creation, and securable-object access with the Security Reference Monitor, but the lower-level enforcement depends on the object type and subsystem: the memory manager enforces address-space operations, the I/O manager and drivers enforce device/file operations, dispatcher objects enforce waits, and the MMU/CPU enforce user/kernel and page-permission boundaries. If an interviewer asks "so is a process just a file?", the answer is no: it is a typed, securable executive object with handles, references, token linkage, address-space state, threads, jobs, sessions, and memory-manager relationships.

### 99 - Handles And Granted Access

A handle is a per-process table entry that references a kernel object and records the access rights granted when the handle was created or duplicated. The handle value is not a pointer and is not globally meaningful. Two processes can hold different handles to the same object with different access masks.

The granted access matters because later operations are checked against the rights already on the handle, not only against the original path or object name. Handles also affect lifetime: closing a handle removes one reference, but the underlying object remains alive while any reference exists. Inheritance and `DuplicateHandle` make handles a deliberate authority transfer mechanism.

The lifecycle is: caller asks for desired access; generic rights such as read/write/all are mapped to object-specific rights; an access check decides what is granted; the resulting mask is stored in that process's handle table; later APIs test the handle entry. This is why a stale path check is weaker than a stable handle check. Once a process has a handle with `PROCESS_VM_READ`, for example, the important fact is no longer the process name string that was used during discovery; it is the granted access on that handle and whether later policy such as PPL or callbacks blocks the operation.

Do not collapse handles, references, and object lifetime into one counter. A handle contributes to handle count and object reference state, but kernel code can hold references that keep an object alive after visible handles close. A duplicated or inherited handle can move authority into a process that would not have passed the original open check. A pseudo-handle such as "current process" is also not the same as a real handle table entry until it is duplicated or converted through an API path. The interview invariant is: a handle is a scoped, rights-bearing capability to a typed object.

The object pointer/reference count should be thought of as "handle references plus counted kernel references plus temporary/type-specific references," not "every raw pointer variable in the kernel." A copied raw pointer does not keep an object alive unless the code took a real `ObReferenceObject*` reference or is protected by another documented lifetime rule. In a live debugger, the same decoded object body address means the same Object Manager object; different object body addresses mean different Object Manager objects, even if they represent the same underlying file, section backing, or similar token state. Handle-table internals such as packed object pointer bits, inverted entry usage counts, or 16-byte x64 entry layouts are build details, not stable APIs.

Inherited handles are the special case where the parent can rely on the child receiving the same handle value and granted access for the same Object Manager object. The child still needs to learn what that value means. Common channels are command-line arguments, environment variables, `STARTUPINFO` standard handles plus `GetStdHandle`, an IPC control message, shared configuration/state, or avoiding inheritance by giving the child a named object to open. `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` is the safer launch-time filter for which handles cross into the child, but it does not label those handles for the child.

### 98 - Tokens And Access Checks

A Windows access check combines the caller's access token, the requested access, the target object's security descriptor, generic access mapping, privileges, and mandatory integrity policy. The token contains a user SID, group SIDs, enabled/disabled groups, privileges, integrity level, default DACL, session information, and possibly AppContainer/capability data. A thread can also impersonate a different token.

The security descriptor contains the owner, DACL, and optionally SACL. The DACL decides allowed/denied access for SIDs; privileges can override or enable special operations; mandatory integrity can block write-up even when the DACL seems permissive. This is why "admin" or "SYSTEM" alone is not a complete authorization explanation.

The conceptual path is: choose the effective token, usually the thread impersonation token if present and otherwise the process primary token; map generic access to object-specific bits; evaluate deny and allow ACEs against token SIDs; account for applicable privileges; apply mandatory integrity and object-specific policy; then return a granted mask or denial. A SACL affects auditing, not whether ordinary access is granted. A null DACL and an empty DACL are opposite security stories: no DACL is permissive, while an empty DACL grants no ordinary access.

Privileges are not magic administrator dust. `SeDebugPrivilege` can help obtain access to many processes, but it does not mean every handle open succeeds against protected processes, integrity policy, callbacks, AppContainer restrictions, or PPL. Impersonation also changes the answer: a SYSTEM service may be checked as a low-privilege client while impersonating, and a bug may come from checking while impersonating but using the resource after reverting. The strong answer always names the token, requested right, object security descriptor, integrity/protection policy, and final handle rights.

`SeLockMemoryPrivilege` follows the same token model. The long-term "Lock pages in memory" assignment is a local/domain security policy user right; a newly created logon token then carries the privilege as a LUID with attributes. `AdjustTokenPrivileges` or helper code named `EnablePrivilege(SE_LOCK_MEMORY_NAME)` can only enable a privilege already present in the effective token. It cannot add the privilege to an arbitrary running process. Attackers can only use it normally if they already run with, duplicate, or impersonate a token containing it; kernel compromise or vulnerable-driver token patching is a different class of issue.

Token APIs differ by which token object they obtain or create. `OpenProcessToken` opens a handle to an existing process primary token with requested token rights such as `TOKEN_QUERY` or `TOKEN_DUPLICATE`. `LogonUser` authenticates credentials and returns a token for that logon type, usually a primary token but network logon can return an impersonation token. `DuplicateTokenEx` creates a new token object from an existing token handle opened with `TOKEN_DUPLICATE`, and can create either a primary token or an impersonation token. These APIs move or create token handles; they do not make the caller magically trusted outside the rights, privileges, integrity, impersonation level, and object policy involved.

### 97 - Process Creation

`CreateProcess` is a high-level API that ultimately creates a new process object and initial thread around an executable image. Conceptually, Windows opens the image file, creates an image section, creates the process object/address space, maps the image, creates process parameters and the PEB, applies attributes and mitigation policy, handles inherited handles and token context, then creates the initial thread.

User-mode loader work happens before application code runs normally. DLL dependencies are loaded, imports resolved, TLS callbacks and CRT initialization may run, and `DllMain` callbacks execute under loader constraints. ETW process, thread, and image-load events can show this path. This is fundamentally different from Linux `fork` because Windows does not normally clone the live parent as the child template.

Nearby launch APIs change the policy layer, not the core "new process around an image" model. `NtCreateUserProcess` is the lower Native API beneath common creation paths and is not the stable app-level contract in the same way Win32 is. `CreateProcessAsUser`, `CreateProcessWithToken`, and `CreateProcessWithLogon` make token/logon choice explicit. `ShellExecuteEx` is shell-mediated and can involve file associations, verbs, elevation UI, App Paths, URL handlers, and shell policy. CRT `_spawn*` functions are runtime wrappers over platform process creation. A Windows answer should therefore distinguish image creation, token choice, shell mediation, and CRT convenience wrappers.

The anti-`fork` explanation is important. Windows does not normally clone the caller's live address space and execution point. Inherited handles, environment, current directory, mitigation policy, parent-process attribute, and startup info are explicitly selected creation inputs. Parent PID is therefore telemetry and creation metadata, not a hard ownership boundary. Jobs, tokens, handles, sessions, and services carry more lifecycle and authority meaning than the parent-child tree.

Also distinguish kernel creation from user-mode initialization. The kernel can create process and thread objects and map the image, but the process is not "at main" yet. Early user-mode execution enters loader/runtime paths such as `ntdll` loader initialization, import resolution, API-set mapping, TLS callbacks, `DllMain`, and CRT startup. For reversing and EDR telemetry, this explains why image-load events, pre-entry callbacks, inherited handles, mitigation attributes, and process parameters can matter before the program's apparent entry point.

### 96 - Process And Thread Structure Graphs

Windows process theory becomes concrete through several related objects. `_EPROCESS` is the executive process object and is opaque from the supported driver-contract perspective. It contains process-wide state such as handle-table references, token linkage, memory-manager state, section/image relationships, job/session membership, and an embedded `_KPROCESS` kernel process block visible in symbols as process-control-block-like state. `_KPROCESS` is important, but it is not the whole process. For paging, the address-space root is process state, classically visible around `_KPROCESS.DirectoryTableBase` and related build-dependent fields, not a `_KTHREAD` field.

Treat the core `_EPROCESS`/`_KPROCESS` control block as nonpageable kernel process state for reasoning about scheduling, waits, address-space switching, and object lifetime. Do not extend that simplistically to every pointer reachable from `_EPROCESS`: handle-table internals, tokens, sections, VAD-related allocations, file/image metadata, user-mode PEB/process parameters, and session/subsystem state have separate allocation and residency rules. Also do not over-specialize the System process (`PID 4`) directory table base. It is a convenient stable root for translating kernel virtual addresses in dumps, but ordinary kernel VAs are normally mapped in every process's kernel address-space view. Use the target process root for target user VAs and a kernel root, not necessarily uniquely PID 4, for kernel VAs; KVA shadow means the user root may be intentionally missing most kernel mappings.

Threads are separate executive objects: `_ETHREAD` wraps `_KTHREAD`, and `_KTHREAD` carries dispatcher, wait, APC, priority, stack, and scheduling state. `ActiveProcessLinks` is an embedded `LIST_ENTRY` inside `_EPROCESS`; it links one enumeration view, not the entire identity or lifetime of the object. A real process can also be found through handles, object references, process/thread ID lookup, jobs, sessions, ETW history, thread objects, VADs, sections, and debugger extension views. Strong analysis therefore cross-checks lists against handle/object lifetime, memory mappings, threads, and telemetry instead of treating one doubly linked list as the process table.

Embedded links are a common interview trap. A `LIST_ENTRY` is not "the process"; it is two pointers embedded inside a larger structure. Debuggers and kernel code recover the containing structure by knowing the field offset for that build. This is why symbol fidelity matters and why hard-coded offsets are fragile across Windows versions. Supported drivers should rely on documented APIs and contracts, not private `_EPROCESS` field layouts.

The real graph is multi-rooted. A process object can be referenced by handles in other processes, by its own threads, by job/session structures, by debug objects, by section/image relationships, by handle-table entries, and by transient kernel references. A rootkit-style unlink from `ActiveProcessLinks` may fool one enumeration path but not VAD walks, thread ownership, handle tables, ETW history, object references, or memory-forensics scans. The mature answer is not "find the list"; it is "compare independent ownership and visibility views."

### 96 - Memory Manager

Windows virtual memory is described by VADs at the range-policy level and by page tables at the hardware translation level. `VirtualAlloc` can reserve address space without committing physical/pagefile-backed memory, then commit pages later. Protection is explicit and can be changed with `VirtualProtect` or Native API equivalents.

Section objects are the common abstraction for mapped files, shared memory, and image mappings. A process maps views of sections into its address space. Image-backed, mapped, and private memory matter because they explain loader state, COW image pages, manual mapping, injection, and file-memory mismatch. Strong analysis asks: is this region private, mapped, or image-backed; what backs it; what are its protections; and is it present in normal loader metadata?

At the API layer, `CreateFileMapping` creates a file mapping object, which is a section object; `OpenFileMapping` opens an existing named mapping if the namespace and DACL allow it; `MapViewOfFile` maps a view into one process address space. Passing `INVALID_HANDLE_VALUE` creates a pagefile-backed section rather than a file-backed one. Native APIs such as `NtCreateSection`/`ZwCreateSection` and `NtMapViewOfSection`/`ZwMapViewOfSection` are the lower-level counterparts, but they do not erase object access checks, section maximum protections, view protections, or VAD/PTE rules.

VADs, PTEs, PFN state, and working sets answer different questions. A VAD says a virtual range is reserved/committed/mapped/image-backed and what policy should apply. A PTE says what translation or software fault state currently exists. The PFN database and working-set state explain which physical pages are resident. A valid VAD can exist with no resident page; first access may demand-zero a page, read from a file, resolve a prototype PTE for a section, bring data back from paging storage, or perform copy-on-write.

Commit, residency, and backing are separate. `MEM_RESERVE` consumes address space, `MEM_COMMIT` consumes system commit charge for private backing, and residency is whether a page is currently in RAM. File-backed and image-backed pages often do not consume private commit while clean because they can be reread from the file; after modification, copy-on-write creates private pages. This is the difference between "the module path says `kernel32.dll`" and "this executable page is now private, modified code inside an image VAD."

For malware analysis and debugging, the interview-proof workflow is: inspect VAD type, protection, commit, backing file/section, image status, private versus shared pages, PEB loader-list membership, ETW image-load history, thread start addresses, and recent protection changes. Private RX memory can be a JIT, packer, unpacked payload, or injected code; image-backed memory can still be patched through COW. The conclusion comes from cross-view consistency, not one flag.

### 95 - User/Kernel Boundary

Win32 is the stable application contract, while the syscall layer is an implementation detail. A normal application call may go through a high-level DLL such as `kernel32`, `kernelbase`, `advapi32`, `user32`, `ws2_32`, or COM/RPC layers before reaching `ntdll`. `ntdll` contains Native API routines and syscall stubs, but system service numbers vary by build.

This layering exists for compatibility. Microsoft can change kernel internals, syscall numbers, and object layouts while preserving documented API behavior. For reversing, this means raw syscall traces are often too low-level; important semantics such as path normalization, registry behavior, service control, COM activation, and loader policy may happen above the syscall boundary.

The CPU boundary is still real: user mode cannot directly execute privileged kernel code or rewrite kernel state. The syscall transition moves execution into kernel mode with a defined ABI and caller mode. The kernel must still probe/capture user buffers, validate handles, check object access, obey IRQL and locking rules, and return status safely. "It made a syscall" does not mean "the kernel trusted the arguments."

Direct syscalls and Native API calls change observability and hook-bypass questions, not the underlying authorization model. A direct call to a service that allocates memory, opens a process, creates a section, or maps a view still reaches kernel Object Manager, memory-manager, security, and driver logic. Conversely, stopping at syscall names can miss user-mode policy: `ShellExecuteEx` may involve shell verbs and elevation; `CreateFileW` may involve Win32 path normalization before `NtCreateFile`; COM/RPC may perform service activation and impersonation before a low-level call appears.

Windows API suffixes and prefixes are triage clues, not proofs. `Ex` usually means an extended signature with extra flags, attributes, access, callbacks, or target context, but the change may be small (`CreateWindowEx` extended styles) or security-critical (`VirtualAllocEx` targets another process through a handle). `A`/`W` means ANSI/code-page versus UTF-16. `AsUser`, `WithToken`, and `WithLogon` make identity explicit. `ByHandle` variants avoid another path lookup and shift reasoning to the handle's granted access. `Nt`/`Zw`, `Rtl`, and `Ldr` usually point below the friendly Win32 layer, but they do not automatically bypass object security, memory-manager checks, loader rules, or build-specific caveats. A strong answer compares parameters, authority, object identity, completion semantics, cleanup rules, and telemetry rather than trusting the name.

For kernel-mode drivers, the `Nt`/`Zw` distinction is specifically about `PreviousMode` and parameter trust. A kernel caller that uses `ZwXxx` tells the service the parameters are trusted kernel-mode parameters; `NtXxx` preserves the current thread's previous-mode interpretation. That can become a vulnerability when a driver services a user request by calling `ZwCreateSection`, `ZwMapViewOfSection`, `ZwOpenFile`, or similar routines using kernel authority instead of checking or impersonating the user. It is a confused-deputy problem, not a documented "bypass security" feature.

### 95 - Executive And Lower Kernel Layer

"The kernel did it" is usually too imprecise on Windows. `ntoskrnl.exe` contains both the Windows Executive and the lower kernel layer. The Executive is the set of higher-level managers that own most resource policy: Object Manager, Memory Manager, I/O Manager, Cache Manager, Configuration Manager, Process Manager, Security Reference Monitor, PnP, and Power Manager. The lower kernel layer owns scheduling, dispatcher objects and waits, interrupt/trap dispatch, DPC/APC mechanics, low-level synchronization, per-processor state, and architecture-specific paths. HAL and drivers extend the picture around hardware and devices.

The syscall path shows the split. A user-mode API such as `CreateFileW` can flow through Win32 and `ntdll!NtCreateFile`, enter the system-service dispatcher, and then reach the kernel-mode implementation owned by executive components. The Object Manager resolves names and handles, the Security Reference Monitor participates in access checks, the I/O Manager builds or routes IRPs, and drivers or file systems perform device-specific work. The CPU mode switch is necessary, but it is not the whole policy explanation.

For security research, name the owner and the enforcer separately. Object access is an Object Manager/SRM/handle-table story backed by references and later access-mask checks. Virtual memory is a Memory Manager/VAD/section story backed by PTEs and the MMU. Device I/O is an I/O Manager/driver-stack story backed by IRPs, device objects, MDLs, and caller-mode probing. Code integrity is policy plus signing/catalog state backed by loader, memory, and sometimes hypervisor enforcement. A strong answer replaces "the kernel checks it" with "this executive component decides, this lower mechanism enforces, and these debugger/ETW/object/memory views would prove it."

Symbol prefixes are useful orientation, not a stable contract: `Ob` for Object Manager, `Ps` for process/thread manager, `Mm`/`Mi` for memory, `Io` for I/O, `Cc` for cache manager, `Cm` for registry/configuration, `Se` for security, `Ke`/`Ki` for kernel dispatcher/trap paths, and `Ex` for executive support such as pool, rundown, resources, push locks, and worker infrastructure. Build and symbol caveats still apply.

### 94 - I/O Manager

When user mode calls `CreateFile`, Windows resolves a Win32 path to an NT object path and usually opens a file or device object through the Object Manager and I/O manager. The result is a handle to a `FILE_OBJECT` or device-backed file object with granted access and sharing state. `DeviceIoControl` then sends an IOCTL request through that handle.

The I/O manager builds an IRP with an `IO_STACK_LOCATION` and passes it through the relevant driver stack. The IOCTL buffering method determines how user buffers are presented: buffered, direct I/O with MDLs, or neither, each with different safety implications. Drivers complete IRPs synchronously or asynchronously, and cancellation/completion paths are part of correctness. A strong answer always asks what object was opened, what access was granted, and what driver validated.

`CreateFile` is a misleading name because it can open ordinary files, directories, volumes, named pipes, mailslots, console objects, and device symbolic links. The path resolves to an object, but the handle records desired/granted access, share mode, create disposition, options, and the opened file/device context. A `FILE_OBJECT` is an open instance, not simply the on-disk file. Multiple handles can refer to the same file with different share/access state, and minifilters or filesystem drivers can transform the path and operation before storage sees it.

For IOCTLs, authority is split. The I/O manager can check the access bits encoded in the IOCTL definition against the handle's granted access, but the driver still owns semantic validation: input/output lengths, structure versions, pointer provenance, caller mode, object lifetime, impersonation requirements, and whether the operation should be allowed for that device state. `METHOD_BUFFERED`, direct I/O with MDLs, and `METHOD_NEITHER` create different bug classes. `METHOD_NEITHER` is especially dangerous because user pointers remain user pointers unless the driver probes, captures, and uses them only in a safe context.

Driver correctness is also temporal. IRPs can pend, complete later, be cancelled, race with device removal, or run at contexts where pageable memory and blocking operations are illegal. A strong vulnerability answer names the dispatch routine, IOCTL code, device object, buffering method, handle rights, caller mode, IRQL/context, lifetime/reference rule, and completion/cancel path.

### 94 - Loader And PE

The Windows loader maps PE images as image sections and uses PE metadata to initialize the process. The import table drives IAT patching, the export table supports `GetProcAddress`, relocations adjust addresses when the preferred base is unavailable, TLS callbacks can run before the main entry point, and `DllMain` runs under loader-lock constraints.

DLL dependency resolution is shaped by KnownDLLs, API sets, side-by-side manifests, search order, packaged-app policy, and loader state in the PEB. This is why DLL side-loading, API hashing, manual export parsing, delay-load imports, and manually mapped PE images are important in malware analysis. PE loading is not just "map file and jump."

Image-section mapping gives PE files special memory behavior. The section protections are derived from PE section metadata, pages can be shared across processes, and writes to shared image pages normally become private through COW. Loader metadata in the PEB describes the normal loader's view, but it is user-mode state and can be incomplete or tampered with. Manual mapping often lacks normal section-object, loader-list, import-resolution, TLS, and image-load telemetry patterns unless the mapper recreates them.

Common system DLL addresses are a loader/ASLR regularity, not a guarantee. `kernel32.dll`, `KernelBase.dll`, and `ntdll.dll` often appear at the same bases across ordinary processes during one boot because they are ASLR-enabled image sections loaded early and reused through normal loader/KnownDLL policy. The address of `LoadLibraryW` is still `module base + export RVA`, and many exports forward to `KernelBase` or lower layers. Verify the actual module base instead of hard-coding it; collisions, bitness, process policy, updates, and manual mapping can change the answer.

`main` is also not where Windows process execution begins. The kernel creates process/thread objects and maps the image; `ntdll` loader initialization maps DLLs, resolves imports, applies relocations, runs TLS callbacks and `DllMain`; then the PE entry point commonly enters CRT startup such as `mainCRTStartup`, `wmainCRTStartup`, or `WinMainCRTStartup`. `wmain` is the wide-character Microsoft entry convention; it receives `wchar_t` arguments after CRT parsing of Windows' Unicode command line.

The follow-up answer should include order and evidence. Before nominal entry point, the loader may process API-set redirection, KnownDLLs, dependency loading, relocations, imports, TLS callbacks, and `DllMain` calls. Evidence comes from module lists, VAD/image mappings, backing files, signatures, ETW image-load events, imports/exports, thread starts, and memory bytes compared with the file. If those views disagree, the disagreement is often the lead.

### 93 - Threads, APCs, And Waits

Windows schedules threads, not processes. Kernel thread state lives in structures such as `KTHREAD`/`ETHREAD`, while a process is the container for address space, handles, token, and process-wide state. Threads can wait on dispatcher objects such as events, mutexes, semaphores, timers, processes, and threads.

APCs are routines queued to a thread. Kernel APCs and user APCs have different rules; user APCs require the target thread to enter an alertable wait before they run. This makes APCs different from Unix signals. IO completion can use APCs in some models, but high-scale Windows I/O commonly uses IOCP or threadpool mechanisms.

The exact APC type matters. Regular user APCs run in user mode during alertable waits. Normal kernel APCs run in kernel mode at `PASSIVE_LEVEL`, commonly for file-system/filter work. Special kernel APCs run in kernel mode at `APC_LEVEL` and can preempt passive-level user or kernel execution; Windows uses them for mechanics such as I/O completion. Do not collapse a special kernel APC into either a DPC or a user-mode APC injection path.

Waits also define whether the caller can be interrupted. A normal non-alertable wait is not broken by Unix-style signals. Alertable waits can return because a user APC or I/O completion routine ran, and wait APIs have distinct outcomes for signaled object, timeout, abandoned mutex, failure, and `WAIT_IO_COMPLETION`. The reversing question is therefore not only "what object was waited on" but also "was the wait alertable, what could wake it, and did wakeup mean work completed or only that a callback ran?"

### 93 - Events And CreateEvent

`CreateEvent` creates or opens a Windows event object and returns a handle to it. That sentence hides several layers: the Object Manager owns the handle, name, type, security descriptor, namespace lookup, reference counting, and granted access; the event's synchronization behavior comes from kernel dispatcher state; and Win32 supplies convenient defaults such as placing named objects under the appropriate `BaseNamedObjects` namespace.

An event is a waitable condition flag. If it is nonsignaled, threads waiting on it block. If it becomes signaled, the dispatcher can satisfy waits and ready threads. `SetEvent` signals it; `ResetEvent` clears it; wait APIs such as `WaitForSingleObject` and `WaitForMultipleObjects` connect the waiting thread to the event through wait blocks and dispatcher-object wait lists. The signaled state is not just a Boolean in user memory; it participates in kernel wait satisfaction and scheduling.

The reset mode is the first important distinction. A manual-reset event is a notification-style event: once signaled, it can release all current waiters and allow later waiters to pass until someone resets it. An auto-reset event is a synchronization-style event: signaling releases one waiter and resets as part of wait satisfaction; if there is no waiter at that instant, the signaled state can remain available for a later waiter to consume. Use manual-reset for broadcast/state conditions and auto-reset for single-consumer handoff, but do not confuse either one with a counted queue.

Events are for flow synchronization, not data protection. They can say "work is available", "shutdown requested", or "operation completed", but the shared data behind that condition still needs a lock, interlocked state, SRW/critical-section discipline, condition variable, semaphore, IOCP, or explicit counter. A single event bit can coalesce multiple arrivals, so it can lose item counts if the program treats it like a queue. `PulseEvent`-style logic is especially fragile because a thread can miss the short signaled window if it is not already in the wait at the right moment.

The security surface is the object, not just the API call. Named events have names, namespaces, DACLs, inheritance/duplication behavior, and granted access masks. A predictable global event name or permissive DACL can let another process signal, reset, wait on, or block coordination. `CreateEventEx` is useful when a caller wants to request a narrower access mask. During reversing or debugging, inspect the handle table, object type/name, namespace, granted rights, signaled state, waiting threads, and stacks around `NtCreateEvent`, `NtSetEvent`, or `NtWaitForSingleObject`.

### 92 - Thread Pool And Async Work

The Windows thread pool is not just a convenience wrapper around a few visible `CreateThread` calls. It is a per-process async execution facility with a default pool, optional private pools, real worker threads, user-mode `ntdll` threadpool runtime code, and kernel-backed `WorkerFactory`/`TpWorkerFactory` state behind the normal Win32 APIs.

That statement is specifically about the user-mode Win32 threadpool family. Windows also has kernel worker queues and system worker threads for driver/executive work items, and those are not the same mechanism. A user-mode threadpool callback runs in user mode on an ordinary process thread; a kernel work item runs kernel-mode code, usually in a system worker-thread context, subject to IRQL and pageable-code rules. WorkerFactory support does not mean the user's callback is running in kernel mode; it means kernel objects help manage user-mode worker creation, wakeup, and completion coordination.

Code submits callbacks through APIs such as `QueueUserWorkItem`, `CreateThreadpoolWork`, `SubmitThreadpoolWork`, `TrySubmitThreadpoolCallback`, and related timer, wait, and I/O threadpool APIs. The submitter gives the runtime a callback and context; Windows decides which worker thread runs it and when. The pool grows and shrinks according to load and policy, so queuing many work items does not imply one new thread per item. In a debugger, a worker's apparent start address may be in `ntdll!Tpp*` code while the interesting application callback is deeper in the stack.

Thread identity stays ordinary. A pool worker has `ETHREAD`/`KTHREAD` scheduler state, a TEB, a user-mode stack while executing user code, and a kernel stack while executing kernel paths such as system calls, waits, I/O, APC/kernel mechanics, or faults. Kernel system worker threads are different: they execute kernel routines and do not represent arbitrary user-mode callbacks. IOCP is also different again: it is a completion queue that can be drained by application-created threads or threadpool-managed workers.

This changes the lifetime model. The caller usually does not own per-work-item thread handles and should not wait for "the thread" as if it created a dedicated thread. Completion is represented through other state: events, counters, cleanup groups, futures/promises, I/O completion, or application-owned synchronization. Callback environments can bind callbacks to private pools and cleanup groups, and cleanup groups are the tool for waiting for or cancelling a set of outstanding callbacks during shutdown.

Overlapped I/O has the same trap. A successful API call may mean the operation completed immediately, while `ERROR_IO_PENDING` means the request is outstanding and completion will arrive later through an event, IOCP, APC completion routine, threadpool I/O, or polling path. The `OVERLAPPED` structure, buffers, handles, and context are live until completion is observed. A timeout while waiting for completion is not automatically cancellation.

Cancellation is a protocol, not an eraser. `CancelIo`, `CancelIoEx`, `CancelSynchronousIo`, threadpool wait/cancel APIs, cleanup groups, and handle close patterns can request shutdown, but the request can race with normal completion. Correct code handles completed-before-cancel, cancelled-before-start, partial completion, and completion-after-cancel. It also drains or waits for completions before freeing contexts. Forceful thread/process termination may stop execution, but it can leave locks held, heap state inconsistent, and shared objects corrupted.

The security and reliability risk is temporal. A callback may run after the submitting function returned, concurrently with other callbacks, on a worker whose stack and thread identity are unrelated to the submitter. Captured stack addresses, `this` pointers, handles, COM pointers, buffers, and request objects must outlive the callback or be protected by reference counts, cancellation, and cleanup ordering. Shared counters and flags need interlocked operations or locks; a plain `+=` across worker callbacks is a data race.

For reversing and incident response, threadpool evidence includes `ntdll!Tpp*` frames, WorkerFactory object state, ETW thread events, many queued callbacks with fewer worker threads, and caller-side events or counters used to wait for completion. The strong answer is: thread pool equals callbacks plus dynamic worker threads plus worker-factory/runtime state plus async lifetime, not "the process created N known threads and joined them."

### 92 - Jobs, Services, Sessions

Windows parent process IDs are mostly lineage metadata, not ownership. Jobs are the mechanism for grouping processes, applying limits, and sometimes controlling group termination. Services are managed by SCM with explicit configuration, accounts, service SIDs, dependencies, recovery actions, and control codes.

Sessions, window stations, and desktops separate interactive logons and GUI objects. Session 0 isolation keeps services away from the interactive user's desktop. These mechanisms matter more than the parent-child tree because Windows lifetime and security are handle-, token-, job-, service-, and session-based.

### 91 - Registry And Configuration

The registry is a structured, ACL-protected configuration database used by the OS and applications. It stores machine and user settings, services and drivers, COM registration, policy, shell integration, autostart locations, IFEO debugger settings, and many compatibility knobs. Registry state can directly change what code runs and under what identity.

It is security-sensitive for the same reason `/etc`, systemd units, package hooks, and autostart files are sensitive on Linux. Registry keys have security descriptors, can be monitored by callbacks and ETW/Procmon, and are central to persistence and system behavior. A Windows investigation that ignores the registry misses a large part of the operating system.

### 91 - ETW And Observability

ETW is a provider-based eventing infrastructure used by Windows components, applications, and security tools. It can expose process, thread, image-load, file, registry, network, DNS, memory, service, and kernel events, often with stack capture. Tools such as WPR/WPA, Procmon, Sysmon, and EDRs build on this kind of eventing.

ETW is not merely a log file. It is how many Windows subsystems make behavior observable in a structured way. Because important Windows semantics live above raw syscalls, ETW and Procmon often explain intent better than tracing service numbers. Strong analysis correlates ETW with handles, VADs, module lists, signatures, and debugger state.

### 90 - WinDbg And Symbols

Windows internals are strongly tied to symbols. Public PDBs and WinDbg extensions make kernel and user structures readable: `!process`, `!thread`, `!handle`, `!address`, `!vad`, `!object`, `!token`, `!irp`, `lm`, `dt`, and related commands convert raw memory into object-level analysis. Without symbols, many fields are just build-specific offsets.

This differs from Linux source-based study. Windows source is not generally public, and undocumented structure layouts change by build. Correct symbol setup is therefore part of the skill, not tooling decoration. A serious answer distinguishes WDK-documented structures from private debugger-visible structures.

### 90 - Security Boundaries

Windows authority is layered. Integrity levels implement mandatory integrity control; UAC can give administrators filtered and elevated tokens; privileges such as `SeDebugPrivilege` are specific rights, not blanket permission; impersonation lets servers temporarily act as clients; AppContainer restricts apps with capability SIDs; PPL protects selected processes from even administrative tampering.

SYSTEM is powerful but not a complete explanation. A SYSTEM process may still be blocked by PPL, code integrity, object ACLs, session boundaries, or missing privileges. Conversely, a lower-privileged process with a powerful impersonation token or writable privileged service path can cross boundaries. Always inspect the token and object policy, not just the username.

### 89 - Attacker Tunables

Windows attacker-relevant tunables cluster around process creation, loader state, authority, telemetry, and policy. A remote bug only reaches them through the process that consumes remote input. If a service passes request data to child processes, script runtimes, DLL search paths, temp paths, or environment variables, then env/argv/current-directory state matters before privilege escalation. Once code runs as the service, it can tune child environment, DLL search directories, process mitigations selected at creation, handle inheritance, thread state, and same-user registry settings.

Privilege changes the surface. Admin or SYSTEM can alter services, scheduled tasks, WMI/COM registration, IFEO/WER, firewall/proxy/DNS policy, Defender exclusions, PowerShell logging, AppLocker/WDAC-related policy, and many machine registry settings. A kernel or vulnerable-driver primitive changes a different class of tunables: token fields, PPL/signature levels, process protection, VAD/PTE state, callback tables, driver dispatch pointers, and code-integrity-related runtime state. Defenders should ask which authority allowed the change, whether it came from remote service context or later privesc, and which independent view proves the current state: registry, SCM, ETW, token/handle tables, VADs, image-load events, driver lists, and memory.

### 89 - File Systems And Cache

Windows file I/O passes through the I/O manager and a file-system driver stack. A `FILE_OBJECT` represents the open instance, including sharing and current state. File-system minifilters can observe or modify operations at defined altitudes, which is why antivirus, EDR, encryption, backup, and some rootkit-like components live there.

The cache manager and memory manager cooperate closely. Cached reads/writes, mapped files, image sections, lazy writeback, and section objects all connect file I/O to virtual memory. Oplocks and sharing modes affect coordination between processes. This is why a file can be locked by sharing rules even when the ACL allows access, and why mapped images can remain in memory after file operations.

The file-system cache is RAM-backed while resident, not a private process heap and not "in the pagefile." Clean cached file pages can be moved to the standby list and later discarded because the file can reconstruct them. Dirty cached or mapped file pages belong to file/cache writeback. A mapped file view, a cached `ReadFile`, and lazy writer activity can therefore touch the same underlying file/section/cache state through different paths.

### 89 - Drivers

A Windows driver is represented by a driver object and creates device objects that receive I/O. User mode often opens a symbolic link that resolves to a device object and sends read/write/ioctl operations through a file handle. The I/O manager packages requests as IRPs and sends them down a stack of drivers.

MDLs describe locked physical pages for direct I/O, DPCs handle deferred work after interrupts, and work items move work to safer process context. IOCTL buffering modes are crucial: buffered I/O copies through a system buffer; direct I/O uses MDLs; neither exposes user pointers and requires extreme validation. Driver bugs often come from trusting IOCTL buffers, racing cancellation/removal, or doing blocking work at the wrong IRQL.

### 89 - Low-Level PE And Process Mutation

Separate the mutation layer before naming the technique. At-rest PE mutation changes file bytes or loader metadata before execution: headers, sections, imports, exports, TLS, resources, overlays, or signature-relevant state. In-memory image patching changes mapped module bytes or pointer tables after load, often creating copy-on-write private pages inside an image range. Cross-process overwrite adds a handle-authority question: who obtained write/operation rights to the target, what memory changed, and what thread, APC, callback, or context later entered it?

Hooks and detours are control-flow redirection forms, not one technique. IAT/EAT hooks change table pointers; inline hooks change code bytes; vtable/callback/VEH-style changes redirect through data structures; syscall-stub tampering changes the user-mode transition path. Kernel redirection raises a different bar: dispatch tables, callbacks, minifilters, WFP callouts, DKOM/data-only changes, and PTE-level changes must be evaluated against driver signing, PatchGuard, HVCI/VBS, WDAC, and vulnerable-driver exposure. Defensive proof comes from cross-view comparison: file/signature state, clean-image bytes, VADs, PTEs, PEB loader lists, handle tables, ETW events, thread starts, callback ownership, and dumps.

### 89 - Signature Checks And TOCTOU

PE signatures and certificates are checked at specific trust boundaries, not continuously. Authenticode or catalog validation proves that the signed, SIP-defined content matched a trusted signing chain at validation time. PE Authenticode does not hash every byte in a flat-file sense; certificate-table and related signing structures require special handling. SmartScreen adds download and publisher/hash reputation. `WinVerifyTrust` is an explicit caller-driven check. App Control/WDAC with UMCI, Smart App Control, protected-process rules, CIG/ACG contexts, and `/INTEGRITYCHECK` can turn signature or policy state into a user-mode load/execute decision. Kernel Code Integrity checks driver signatures during driver load, and HVCI strengthens the kernel executable-memory boundary.

The TOCTOU question is whether the checked object is the same object that later executes or loads. Weak patterns include verifying a path and later opening the path again, trusting a file in a user-writable allow-rule directory, checking an installer but not the final extracted payload, using reputation or signature state before a later replacement, or assuming a signed mapped image stayed unmodified after load. Attackers do not need perfect scheduler control; ordinary concurrency, rename/replace behavior, reparse points, hardlinks, oplocks, service restart timing, or asynchronous file operations can create check/use gaps in software that was written around paths instead of stable file objects. Defenders compare file ID, volume, hash, signer, directory ACLs, section backing, image-load events, VADs, private image pages, and clean-image bytes before trusting the conclusion.

### 88 - Kernel Mitigations

PatchGuard makes many forms of kernel patching unstable by checking critical kernel structures and code integrity. Driver signing and vulnerable-driver blocklists restrict arbitrary kernel code loading, while HVCI/VBS use virtualization support to strengthen code integrity and isolate sensitive state. CFG/CET and related mitigations reduce control-flow abuse in user and sometimes kernel contexts depending on configuration.

Modern rootkit thinking must therefore include supported extension points and policy bypasses, not only SSDT hooks. Attackers may seek signed vulnerable drivers, abuse callbacks, minifilters, WFP callouts, or tamper with user-mode telemetry. Defenders inspect code integrity state, loaded drivers, callbacks, filter stacks, ETW, and memory rather than only checking a syscall table.

### 88 - Process Memory Triage

Start with the VAD view: private, mapped, or image-backed; protections; commit; backing file; and whether the region is executable. Normal modules should usually appear in loader metadata and image-load telemetry. Suspicious regions include private RX/RWX memory, executable mapped sections shared between unrelated processes, modified image pages, missing backing files, or code not present in PEB loader lists.

Then correlate thread start addresses, call stacks, handle access, memory protection changes, and image-load events. Packed programs may unpack into private executable memory; JITs can also legitimately create executable pages. The conclusion comes from context: signer, process type, target, timing, thread starts, and whether loader metadata matches memory reality.

### 87 - DLL Search And Loading

DLL side-loading is not simply `LD_LIBRARY_PATH` abuse because Windows has its own search policy and compatibility mechanisms. Search may involve the application directory, system directories, KnownDLLs, SafeDllSearchMode, manifests, side-by-side assemblies, API sets, packaged-app rules, current directory behavior, and explicit `LoadLibraryEx` flags.

The abuse pattern is getting a trusted executable to load attacker-controlled code from a location the loader accepts. The details differ from ELF because Windows has explicit PE import/export tables, KnownDLLs, manifests, and API-set forwarding. Defenders inspect module path, signer, load order, process reputation, and whether a trusted process loads code from writable or unexpected directories.

### 87 - API Resolution

`LoadLibrary`/`LoadLibraryEx` and `GetProcAddress` are normal APIs for runtime loading and optional functionality. `LdrLoadDll` and `LdrGetProcedureAddress` are lower-level loader routines in `ntdll`. Manual export parsing bypasses even those routines by walking PE headers and export tables directly.

In reversing, dynamic API resolution often explains why static imports look sparse. Malware and packers may hash API names, parse the PEB loader list to find modules, or resolve Native API functions dynamically. The behavior is not automatically malicious, but it is a signal to recover the resolved API set dynamically and correlate it with memory and thread behavior.

### 86 - Cross-Process Access

Windows cross-process inspection starts with a handle to the target process with sufficient granted rights. Access is affected by the caller token, requested access, integrity level, `SeDebugPrivilege`, session boundaries, kernel callbacks, and PPL. `ReadProcessMemory` requires `PROCESS_VM_READ`; `WriteProcessMemory` requires `PROCESS_VM_WRITE` and `PROCESS_VM_OPERATION`; `VirtualAllocEx` and `VirtualProtectEx` require `PROCESS_VM_OPERATION`; remote-thread paths involve rights such as `PROCESS_CREATE_THREAD` plus query and VM rights depending on the API path.

The Linux analogy is not a process handle with `PROCESS_VM_READ`. Linux uses `process_vm_readv`/`process_vm_writev`, `ptrace`, and `/proc/<pid>/mem`, but authorization is checked through credentials, dumpable state, namespaces, capabilities such as `CAP_SYS_PTRACE`, Yama/LSM policy, and procfs visibility. A pidfd can stabilize process identity, but it does not by itself grant Windows-style memory rights.

Injection is not one API. The invariant is authority over the target, memory placement, and control-flow redirection. Memory may be allocated with `VirtualAllocEx` or mapped through a section; execution may use a remote thread, APC, context hijack, or loader call. Defensive triage correlates handle opens, memory writes/maps, protection changes, image loads, thread starts, and VAD anomalies.

### 86 - Native API

Native API matters when Win32 abstracts away details that are important to reversing, debugging, or security analysis. `NtCreateFile`, `NtCreateSection`, `NtMapViewOfSection`, `NtAllocateVirtualMemory`, `NtQueryInformationProcess`, and related calls expose object attributes, NT paths, handles, sections, process/thread/memory operations, and lower-level status codes.

The caveat is stability. Native API is less documented than Win32, and syscall numbers are not a stable application ABI. Malware may use Native API or direct syscalls to avoid user-mode hooks or static imports, but defenders should still reason semantically: object opened, access requested, memory mapped, thread created, section backed, and telemetry produced.

### 85 - ALPC, RPC, And COM

ALPC is the low-level optimized local IPC mechanism used by Windows subsystems and services. It can carry messages, handles, and section-backed data, so it is performance-relevant and security-sensitive. A strong review names the port, connection policy, message format, impersonation behavior, handle or section transfer, and callback lifetime.

RPC adds IDL, marshalling, binding, authentication, local/remote transports, and service API structure. It is easier to design a stable service contract with RPC than with ad hoc messages, but the tradeoff is parser, marshalling, authentication-level, endpoint ACL, and remote-exposure risk. COM adds object activation, interface identity, apartments, registry/AppID state, and lifetime rules; it is not a raw fast path, and its security failures often involve launch/access permissions, elevation, reentrancy, stale interface pointers, or COM hijacking.

Named pipes are the practical Windows service IPC baseline: message or byte mode, overlapped I/O, and IOCP support make them useful, while DACLs and impersonation make them security boundaries. The common mistakes are weak pipe security descriptors, accepting remote clients unintentionally, first-connector or name-squatting races, shared per-client state, and treating a privileged server request as trusted just because it arrived over a local pipe.

The IPC follow-up from the Csandker series is that endpoint naming and impersonation defaults are often the real bug. Named pipes are `FILE_OBJECT`s under NPFS, so file-opening code that accepts attacker-controlled paths may be redirected to `\\.\pipe\...` or remote-style `\\host\pipe\...` paths. A pipe client that does not want the server to impersonate it should set `SECURITY_SQOS_PRESENT` with an anonymous or identification-level choice. A privileged pipe server should set a deliberate DACL and use `FILE_FLAG_FIRST_PIPE_INSTANCE` when name ownership matters.

RPC should be reasoned about as interface UUID/version/opnum plus protocol sequence plus binding security, not only "a service API." `ncalrpc` is local and rides ALPC on modern Windows; `ncacn_np` rides named pipes/SMB; `ncacn_ip_tcp` is network-facing and may use the endpoint mapper. `RpcServerRegisterAuthInfo` alone does not prove all clients must authenticate. The server also needs the right registration flags, callback policy, or method-level checks. On the client side, RPC QoS controls whether the server can impersonate the client.

The highest-value bug pattern is failed impersonation. If a SYSTEM or service RPC/pipe server calls `RpcImpersonateClient` or `ImpersonateNamedPipeClient`, then continues after failure, it may perform the request as the server rather than the client. Correct code fails closed, reverts reliably after success, and treats impersonation status as part of authorization. For ALPC, add message attributes to the review: handles and section-backed views can be transferred with messages, so receiving code needs explicit ownership and cleanup rules for every accepted attribute.

These lessons remain useful for Windows 11 as mechanism-level invariants, but concrete service endpoint names, default ACLs, private ALPC layouts, and exploitability need revalidation on the exact build being analyzed.

### 85 - Networking

Windows networking starts at user-mode APIs such as Winsock but flows through kernel networking components, AFD at a high level, TCP/IP drivers, NDIS, and network drivers. Filtering and inspection are commonly performed through Windows Filtering Platform layers and callouts, Defender Firewall, and NDIS filters.

This differs from Linux netfilter/eBPF terminology but solves similar problems: packet classification, connection policy, filtering, inspection, and telemetry. ETW network providers, Sysmon, firewall logs, DNS telemetry, and per-process network APIs help correlate sockets to processes. For security analysis, WFP callouts and injected trusted processes are important places to look.

### 84 - Scheduler And Dispatcher

Windows schedules threads and uses dispatcher objects for waits and synchronization. Threads have priorities and scheduling state; the dispatcher manages ready and waiting threads and wakes them when objects are signaled or timeouts/APCs/completions occur. Processes are containers, not scheduling units.

The dispatcher model ties synchronization and scheduling together: events, mutexes, semaphores, timers, processes, and threads can all be waited on through common wait APIs. DPCs and APCs are different deferred-execution mechanisms: DPCs run in kernel at elevated IRQL for deferred interrupt work, while APCs are delivered to specific threads under defined conditions.

For interview depth, separate waitable dispatcher objects from process-local and kernel-only locks. A critical section is fast user-mode same-process serialization, not a named cross-process object. A semaphore models counted resource tokens. An abandoned mutex gives ownership to a waiter but signals that protected state may be inconsistent. Kernel fast mutexes and executive resources have APC/IRQL constraints and are not interchangeable with user-mode mutexes or events. At high IRQL, the answer should shift toward spin-style synchronization, tiny critical sections, no pageable memory, and no blocking waits.

### 84 - Exceptions

Windows exception handling is both a normal runtime mechanism and a common reversing challenge. On 32-bit Windows, SEH chains are historically linked through thread state; VEH provides process-wide vectored handlers; on x64, structured unwinding relies heavily on function tables and unwind metadata rather than the old stack-linked SEH model.

The user-mode exception path involves dispatcher logic such as `KiUserExceptionDispatcher`. Malware and protectors may deliberately trigger exceptions, use invalid opcodes, register dynamic function tables for generated code, or hide control flow in handlers. A defender or reverser should inspect exception frequency, handler registration, dynamic code regions, and unwind metadata.

The `evil` Flare-On case is a useful drill: the binary turns deliberate faults into API dispatch, resolves APIs by hash, and patches code after exception-generating byte sequences. The takeaway is that the exception path can be the real CFG, so reversing should include handler registration, fault addresses, patched bytes, and whether the sample is x86 SEH-style or x64 unwind-metadata-driven.

### 83 - WOW64

WOW64 is the subsystem that runs 32-bit Windows processes on 64-bit Windows. A WOW64 process has 32-bit user-mode DLLs and thunking layers that transition into 64-bit execution for kernel calls. Components such as wow64, wow64win, and wow64cpu participate in translating calls and switching modes.

It is more than "32-bit binary on 64-bit OS" because there are separate 32-bit and 64-bit views of structures, registry/filesystem redirection, thunked syscalls, and special transition code. Malware and anti-analysis tricks may abuse Heaven's Gate-style transitions or inspect/patch WOW64 transition paths. Reversers need to know which architecture's code and ntdll they are looking at.

### 83 - PEB And TEB

The PEB contains user-mode process metadata such as loader data, process parameters, environment, heap pointers, and flags often inspected by debuggers and malware. The TEB contains per-thread user-mode state such as stack limits, TLS, last error, exception-related state, and thread-local runtime fields.

Because the PEB loader lists describe loaded modules, many tools and malware use them for module enumeration. But PEB data is user-mode memory and can be tampered with, so it should be cross-checked against VADs and image-load telemetry. Anti-debug checks that read PEB fields are common but not definitive.

### 82 - SCM And Persistence

Windows services are configured through SCM and registry-backed service records. A service has a binary path or service DLL configuration, startup type, dependencies, account, privileges, service SID behavior, recovery actions, and control-handler protocol. Services commonly run in session 0 and often have more authority than normal user processes.

This makes services both a management mechanism and a persistence/privilege boundary. Weak service ACLs, writable service binaries, bad service DLL paths, or misconfigured accounts can become security issues. Defensive triage checks service configuration, signer, account, recent changes, SCM events, and whether the service behavior matches its declared purpose.

<a id="82---scheduled-tasks-wmi-com-ifeo"></a>

### 82 - Scheduled Tasks, WMI, COM, IFEO, And Persistence Subtypes

Scheduled Tasks persist through triggers and actions: time, logon, event, idle, or custom triggers launch commands under chosen accounts. WMI permanent event consumers can subscribe to system events and run actions through the WMI repository. COM hijacks abuse registration or activation paths so trusted COM clients load unexpected code. IFEO debugger values redirect process launch through a configured debugger.

The broader technique taxonomy adds AppInit/AppCert DLLs, Netsh helper DLLs, Winlogon shell/userinit, time providers, port monitors, LSA SSPs/password filters, application shims, shortcut modifications, screensavers, PowerShell profiles, startup folders, and logon scripts. The reason these are not interchangeable is that each has a different consumer: user32, process creation, Netsh, Winlogon, W32Time, spooler, LSASS, shim engine, Explorer/shell, PowerShell, or logon policy.

These are different persistence surfaces with different artifacts. Tasks live in task definitions and registry state; WMI in repository/event-consumer bindings; COM in CLSID/AppID/InprocServer registration; IFEO in image-name registry keys; LSASS/Winlogon/spooler/time-provider surfaces are sensitive because highly trusted hosts load or execute configured code. A strong answer names the writer, trigger, host process, account/integrity, target path, ACL, signer, and telemetry source.

### 81 - Memory Forensics

Hidden or unlinked code is found by comparing views. Normal module lists may miss manually mapped DLLs or unlinked kernel drivers, so memory scanners look for PE headers, executable VADs, pool tags, driver objects, thread start addresses, and code regions not backed by expected files. In kernel dumps, driverscan/modscan-style approaches can find objects no longer present in ordinary lists.

The key is cross-view analysis: PEB loader lists versus VADs, loaded module list versus memory scan, service registry versus driver objects, image-load events versus executable pages, and file signatures versus mapped content. Memory forensics is especially valuable when malware tampers with friendly APIs.

The `help` Flare-On case is the concrete workflow: start from crash context, recover the suspicious `DRIVER_OBJECT`, use driver start/size/init/dispatch fields to dump code, rebuild enough PE structure for analysis, then correlate IOCTL behavior and WFP state with the PCAP. The important habit is to let independent views explain each other.

### 81 - Object Callbacks

Windows exposes kernel callback mechanisms for process, thread, image-load, registry, and object-handle events. Security products use these to observe or restrict sensitive operations such as process handle creation, image loads, and registry changes. Rootkits and malicious drivers may try to hide, tamper with, or abuse similar visibility points.

PatchGuard and signing constraints make unsupported patching risky, so callbacks are important legitimate extension points. Analysis should enumerate registered callbacks where possible, inspect owning drivers, verify signatures, and correlate callback behavior with observed blocking or telemetry gaps.

The `crackinstaller` case is a useful registry-callback drill: the unsigned driver registers a callback, observes pre-create registry operations for COM-related state, and hides useful data in a place normal registry inspection may miss. The lesson is to treat callbacks as live policy code owned by a driver, not just passive telemetry.

### 80 - Minifilters And WFP

File-system minifilters sit in the file I/O path at defined altitudes and are used by antivirus, encryption, backup, DLP, and monitoring products. They can observe or affect creates, reads, writes, renames, and cleanup operations. Because they see high-value file activity, they are also relevant to stealth and tampering analysis.

WFP provides network filtering layers and callouts for classifying and acting on traffic. Security tools use WFP to implement firewalls, EDR network inspection, and policy. A strong answer explains that minifilters and WFP are supported extension points, so their presence is not malicious by itself; ownership, signing, behavior, and policy determine trust.

For WFP triage, ask which provider, sublayer, filter, callout, layer, and classify function own the behavior. The `help` case shows why runtime callout configuration matters: traffic transforms may be keyed by driver-owned state rather than visible in the PCAP alone.

### 80 - Code Integrity

Authenticode signs individual PE files; catalog signing can sign files by hash through a catalog; driver signing enforces trust requirements for kernel-mode code; WDAC applies policy about what code may run; SmartScreen adds reputation and download-origin style risk decisions. These mechanisms overlap but are not identical.

Trust is contextual. A valid signature does not mean behavior is benign, and unsigned does not always mean blocked depending on policy. Ordinary user-mode PE loading is not the same as mandatory Authenticode enforcement unless a policy, protected context, or PE flag requires it. For kernel code, signing and blocklists matter heavily because drivers run with high privilege. BYOVD attacks abuse legitimately signed but vulnerable drivers, so code integrity must be paired with vulnerability and blocklist awareness.

The `crackinstaller` case is the practical warning: a signed Capcom-style driver becomes a kernel execution primitive through a weak IOCTL and SMEP bypass. A strong code-integrity answer therefore distinguishes "the file was signed" from "the code is acceptable under current policy, not blocklisted, not vulnerable, and not being abused as a bridge into unsigned kernel logic."

### 79 - PowerShell, .NET, And AMSI

PowerShell and .NET matter because they are rich execution environments deeply integrated into Windows administration. They can load code in memory, access COM/WMI/.NET APIs, and perform actions without dropping traditional native executables. This makes them important for both legitimate automation and attacker tradecraft.

AMSI provides a scanning interface for script and dynamic content before or during execution, while ETW and script block logging can provide telemetry. Malware may try to avoid or tamper with these, but defenders correlate process lineage, command content, loaded CLR modules, AMSI/ETW events, and network/file/registry behavior.

### 78 - Hyper-V And VBS

Virtualization matters because Windows uses Hyper-V infrastructure not only for running VMs but also for security features. VBS can isolate sensitive code or secrets from the normal kernel using virtualization boundaries. HVCI strengthens code integrity by making it harder for kernel-mode code to become executable unless it satisfies policy.

This changes attacker and defender assumptions. Kernel compromise may not automatically grant access to VBS-protected secrets, and unsigned or dynamically generated kernel code may be blocked. At the same time, hypervisor-level attacks or vulnerable drivers become high-value because they may undermine these isolation layers.

Separate Windows Hypervisor Platform from VBS/HVCI. WHP lets a user-mode virtualization stack create partitions, map guest physical memory, run virtual processors, and handle VM exits. The `HVM` Flare-On case is useful for WHP mechanics and VM-exit reasoning, but it is not itself evidence for a VBS or HVCI bypass.

Also separate WHP from custom ring -1 code. The `golf` case is useful because a Windows driver sets up a thin VT-x hypervisor and `vmcall` becomes the boundary into VM-exit handling. That teaches hypervisor-rootkit mental models, while VBS/HVCI questions still require current Microsoft documentation and current CPU behavior.

### 78 - GUI, Input, And Sessions

Windows GUI and input security depends on sessions, window stations, desktops, integrity levels, UIAccess, and accessibility/input APIs. Services run in session 0, while users interact in separate sessions. A process generally cannot freely send input or inspect UI across all boundaries without appropriate integrity and desktop/session access.

Spyware analysis must therefore ask where input, clipboard, screen capture, hooks, accessibility, and browser extensions run. Keylogging is only one collection path. Screenshots, clipboard, UI Automation, browser profile access, credential stores, and injected GUI hooks all depend on session and integrity context.

### 77 - Boot Trust

Secure Boot verifies early boot components according to firmware trust policy. Measured boot records measurements into the TPM so later components or remote verifiers can assess boot state. BitLocker can seal keys to TPM measurements so disk decryption depends on expected boot integrity. ELAM lets approved anti-malware start early in the boot driver sequence.

Boot-start drivers load before many defenses, so driver trust and boot configuration matter. A complete answer connects firmware, boot manager, kernel, early drivers, code integrity, TPM measurements, and recovery/forensics. Boot trust does not prove the system is clean, but it raises the cost of persistent pre-OS tampering.

The boot-focused Flare-On cases make this concrete. `doogie.bin` and `Suspicious Floppy Disk` show BIOS-era sector loading and `INT 13h` hooks below the filesystem. `Mbransom` shows Track 0 staging and MBR tampering. `CATBERT` moves the same concern into UEFI firmware and EFI shell modules. Use those as drills, then update conclusions with Secure Boot, measured boot, TPM sealing, ELAM, and modern UEFI behavior.

### 76 - Kernel Pool

Windows kernel pool is dynamically allocated kernel memory used for many objects and buffers. Pool tags help identify allocation owners during debugging. Object headers, pool metadata, special pool, Driver Verifier, and pool diagnostics help find corruption, leaks, UAF, and overrun bugs. Exact allocator details vary across Windows versions.

For vulnerability analysis, pool knowledge helps classify primitives: can the attacker influence allocation size, reuse, lifetime, tag, adjacency, or contents? Modern pool hardening and verifier features reduce predictability, so a mature answer avoids old fixed-layout assumptions and focuses on object lifetime, type confusion, and reachable operations.

### 75 - Patch And Triage

Given a suspected Windows vulnerability, first identify the object, entry point, caller authority, IRQL/context, allocation source, lifetime owner, and security check that should have enforced the invariant. Then classify the primitive: info leak, UAF, OOB read/write, type confusion, uninitialized use, missing access check, race, or logic bug.

Next evaluate mitigations and observability: pool hardening, CFG/CET, SMEP/SMAP-equivalent behavior, PPL, HVCI, PatchGuard, Driver Verifier, ETW, and crash dump evidence. A good patch enforces the invariant at the boundary, validates user/kernel buffers and object state, fixes lifetime/refcounting, handles cancellation/error paths, and adds a regression test or verifier scenario.

For crash triage, `!analyze -v` is the first pass, not the conclusion. A stronger answer checks bugcheck parameters, current thread/process, IRQL, stack plausibility, loaded modules, driver objects, IRPs, pool state, and locks. Driver Verifier is useful when you need illegal IRQL use, Special Pool corruption, I/O misuse, pool tracking, or deadlock detection to fail close to the real bug instead of later as secondary damage.

## Remaining High-Value Depth Targets

Status: the top Object Manager/SRM, handle, access-check, process-creation, process-graph, memory-manager, user/kernel, I/O, and loader answers above have been expanded for follow-up pressure. The next pass should add tool-backed drills and build-specific examples rather than repeat the same concepts.

| Priority | Depth target | Why it matters |
|---:|---|---|
| 1 | WinDbg/Sysinternals drill for Object Manager plus SRM | Turn the strengthened object/handle/token model into repeatable evidence collection. |
| 2 | Memory-manager drill: VADs, sections, image mappings, commit, COW | Essential for debugging, malware analysis, injection triage, and exploit reasoning. |
| 3 | I/O manager and driver drill: IRPs, device stacks, IOCTL security, minifilters | Essential for driver research, EDR/rootkit analysis, and Windows kernel vulnerability work. |
| 4 | ETW/WinDbg/Sysinternals workflow | Windows internals are learned through tools and symbols; raw theory is not enough. |
| 5 | Windows security model: token, privilege, integrity, AppContainer, PPL, VBS/HVCI | Prevents bad Linux analogies like "SYSTEM is just root." |
| 6 | Loader/PE/API-set/manual-mapping deep dive | Essential for malware analysis and Linux-to-Windows binary-format transition. |
| 7 | ALPC/RPC/COM and service boundaries | Major enterprise and local privilege-boundary surfaces. |
| 8 | Boot trust and code integrity | Explains modern rootkit constraints and where signed/vulnerable drivers fit. |

## Minimal Windows Mastery Checklist

Before claiming Windows internals readiness, be able to explain these without notes:

1. A handle is not a file descriptor; it is a per-process reference to a typed, securable object with granted access.
2. A token is not just UID/GID; it carries SIDs, groups, privileges, integrity, impersonation state, and capability/AppContainer data.
3. `CreateProcess` is not `fork`; it creates process/thread objects around an image section and initializes loader state.
4. A DLL is not just a `.so`; PE loading involves IAT/EAT, API sets, TLS callbacks, `DllMain`, loader lock, manifests, and KnownDLLs.
5. `VirtualAlloc`/sections/VADs are the Windows memory-analysis starting point, not `/proc/<pid>/maps`.
6. Raw syscall numbers are not the Windows app contract; Win32 and Native API layers matter.
7. Windows I/O is IRP/device-stack driven; IOCTL security is a first-order issue.
8. ETW/Procmon/WinDbg/Sysinternals are not optional; they are how Windows behavior becomes observable.
9. Parent process IDs are telemetry, not ownership; jobs, services, sessions, handles, and tokens carry real lifecycle/security meaning.
10. Modern rootkit thinking must include callbacks, minifilters, WFP, signed drivers, PatchGuard, HVCI, VBS, PPL, and memory forensics.
11. For low-level barriers, name both the Windows checker and the real enforcer: SRM/Object Manager versus kernel object access, VAD/sections versus MMU permissions, MDLs/DMA remapping versus IOMMU, Code Integrity versus UEFI/TPM/hypervisor-backed enforcement.
