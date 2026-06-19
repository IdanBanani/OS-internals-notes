# Windows Internals Long-Term Mastery Roadmap

Value Score: 86/100
Role: Long-term Windows mastery roadmap
Proof Level: Roadmap

Date: 2026-05-12

Scope: long-term Windows internals mastery from an offensive security research perspective. Use the modules in order, but do not treat them as a countdown. Stay with a module until you can explain the mechanism, map it to evidence, and reason about failure modes without relying on memorized phrases. This roadmap stays at research/interview level and avoids operational malware or bypass playbooks.

Focused companion: [Windows case-study resource map](<02-windows-case-study-resource-map.md>) maps PE structure, PEB/TEB/TLS/SSN, DLL loading/debugging, keylogging/injection/hooking/side-loading API analysis, and recent ClickFix/CrashFix/FileFix writeups into defensive study topics.

Mechanism companion: [Source-enriched Windows mechanisms](<06-source-enriched-windows-mechanisms.md>) distills the local Pluralsight subtitle content and PDFs/books into concrete explanations of the Executive/kernel split, Object Manager, handles, PEB/TEB, loader, memory, scheduling, dispatcher objects, `CreateEvent`/event waits, thread pools/WorkerFactory, IRQL/DPC/APC, jobs/silos, drivers, and telemetry.

Checklist companion: [Windows roadmap know-cold explanations](<08-windows-roadmap-know-cold-explanations.md>) expands every mechanism checkpoint below. Use it when a checklist term needs an actual explanation, especially memory terms such as reserved, committed, and resident.

Technique companion: [Attacker-relevant structures and components](<../05-topic-notes/attacker-relevant-structures-and-components.md>) gives answered defensive explanations for how attackers misuse handles, tokens, VADs, section objects, PEB/TEB metadata, PE files at rest, image-backed/private memory, injection variants, reflective/manual mapping, hollowing/ghosting-style mismatch, hooks/detours/pointer tables, kernel callbacks/dispatch paths, persistence configuration, malware/spyware collection methods, telemetry gaps, anti-debug state, and network APIs.

Use [the local Hebrew and Digital Whisper paper reading map](<05-local-hebrew-paper-reading-map.md>) to place the older Hebrew/local PDFs into this roadmap. It says which papers belong beside each module, what to focus on, and which exploit/rootkit materials are mainly historical.

Use [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>) for the newer Hebrew issue PDFs you added. It covers Windows identity, loader/syscalls, kernel/driver telemetry, Linux/eBPF/SLUB, firmware, and reversing case studies with current-build caveats.

Use [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) for the Journey PDFs. The Windows Concept, Windows Security, Windows Security Workbook, and Windows Forensic Journey files are useful as concept bridges, security recall drills, and evidence-oriented review beside this roadmap.

Use [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) whenever a compact term appears before it is fully taught. It expands and routes Windows-heavy concepts such as VAD, PTE/PFN, section object, IRP, IOCTL, MDL, APC, DPC, ALPC, ETW, AMSI, PEB/TEB, PPL, VBS/HVCI, CFG, CET, DMA, and IOMMU to practical evidence paths and deeper owner docs.

## Verdict

This roadmap is a mastery path first and an interview-prep aid second. If an interview appears, compress by reviewing the modules and artifacts you have already proven; do not use the calendar as the main teacher. For broader theoretical OS internals coverage, keep scheduling, synchronization, virtual memory policy, filesystems, interrupts, and I/O in the active loop. Those topics are included below as theory checkpoints.

Use `os_book.pdf` only as a Hebrew warm-up. It is useful for Sysinternals, WinAPI, memory layout, PE/DLL basics, and introductory OS concepts, but it is too shallow to be the main source for modern Windows internals, mitigations, credentials, drivers, or EDR-relevant behavior.

## What Is Relevant Now

- Windows architecture: user mode, kernel mode, executive, object manager, memory manager, I/O manager, security reference monitor.
- Native API: `ntdll`, syscalls, `Nt*`/`Zw*`, object namespaces, handles, sections, PEB/TEB.
- Security model: tokens, SIDs, privileges, integrity levels, impersonation, AppContainer, security descriptors, access checks, auditing.
- Credential protection: LSASS, PPL, Credential Guard, LSA protection, SAM, NTLM, Kerberos, logon sessions.
- Modern mitigations: VBS, HVCI/Memory Integrity, Kernel CFG, CET/shadow stacks, CFG, ACG, CIG, ASLR, DEP, WDAC/App Control, vulnerable driver blocklists.
- Kernel and drivers: device objects, driver objects, IRPs, IOCTLs, callbacks, minifilters, WFP, ETW, PatchGuard constraints.
- Telemetry and defensive surfaces: ETW, AMSI, Defender/EDR architecture, Sysmon-style events, process/thread/image/registry callbacks.
- Exploit reasoning: bug class -> primitive -> boundary crossed -> mitigation encountered -> telemetry produced.
- Theory: scheduling, context switches, concurrency, locks, deadlocks, paging, working sets, page faults, cache/buffer managers, filesystem metadata, interrupts/DPC/APC.

## Core Source Files

- `Forshaw James - Windows Security Internals - 2024.pdf`
- `Yosifovich Pavel - Windows Native API Programming - 2024.pdf`
- `windows-kernel-programming-pavel-yosifovich.pdf`
- `Windows Internals, Part 2 by Mark Russinovich.epub`
- `Yosifovich Pavel - Windows 10 System Programming, Part 1 and 2 - 2020, 2021`
- `Pluralsight - Windows 11 Internals by Pavel Yosifovich`
- `Pluralsight - Windows Internals*`
- `Reversing Malware Analysis Training`
- `os_book.pdf` as optional Hebrew warm-up only.
- `TheWindowsConceptJourney_v6_March2025.pdf` as a broad Windows concept bridge before deeper Native API, Pluralsight, and debugger work.
- `TheWindowsSecurityJourney_v6_Jan2025.pdf` and `TheWindowsSecurityJourneyWorkbook_v1_June2025.pdf` as security-model review and active recall after Forshaw.
- `TheWindowsForensicJourney_v2_April2025.pdf` as evidence-oriented support for ETW/Event Log, process, file, registry, network, and memory triage.
- [Local Hebrew and Digital Whisper paper reading map](<05-local-hebrew-paper-reading-map.md>) for the older PE, loader, anti-debug, process-injection, rootkit, Win32k, hypervisor, SMM, SRUM, and firmware papers.
- [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>) for newer Hebrew issue PDFs covering Windows identity/auth, ETW/Event Logs, LSASS, WinAPI hashing, injection, DLL side-loading, direct/tampered syscalls, minifilters, BYOVD/DSE, Windows kernel, Linux/eBPF/SLUB, and firmware.

## How The Windows 11 Pluralsight Course Fits

Promote `Pluralsight - Windows 11 Internals by Pavel Yosifovich` to the primary video track for OS-theory and Windows-internals fundamentals. It is newer, cleaner, and better aligned with Windows 11 than the older 2013-2014 Pluralsight courses.

Use it this way:

- `Foundations`: use in the architecture module. Replaces most of the old Pluralsight Basic Concepts/System Architecture modules.
- `Processes and Jobs`: use in the process/object module. Adds process creation, loader behavior, special process types, jobs, and silos.
- `Threads`: use in the process/object and mitigation/concurrency modules. Strong coverage for scheduling, priorities, affinity, processor groups, stacks, and thread data structures.
- `Memory Management`: use in the process/object and mitigation/concurrency modules. Strong coverage for address spaces, committed/reserved memory, page translation, page faults, working sets, page files, memory APIs, memory-mapped files, large pages, DLL injection, and ASLR.
- `Kernel Mechanisms`: use in the kernel/I/O and theory modules. Strong coverage for object management, handles, object namespaces, interrupts, IRQLs, DPCs, exceptions, crash dumps, synchronization primitives, APCs, fast mutexes, executive resources, and high-IRQL synchronization.

What it does not replace:

- Forshaw 2024 remains the primary source for Windows security, authentication, authorization, auditing, tokens, and credentials.
- `Windows Native API Programming` remains the primary source for Native API depth.
- `windows-kernel-programming-pavel-yosifovich.pdf` and the older Pluralsight Windows Internals 3 material remain useful for I/O manager, device drivers, IRPs, IOCTLs, WDF/WDM, and writing/debugging drivers, because the Windows 11 course folder does not appear to include a dedicated I/O/device-driver track.

## Source-Enriched Mechanism Review

Before claiming readiness, review [Source-enriched Windows mechanisms](<06-source-enriched-windows-mechanisms.md>) and make sure you can explain:

- Why the Object Manager gives typed objects common naming, reference counting, handle, security, and namespace behavior.
- Why a handle carries granted access and can keep an object alive independently of its name.
- How a process is created around an image section, address space, token, PEB, TEB, initial thread, and loader initialization.
- Why KnownDLLs and mapped files are section-object mechanisms, not just path strings.
- How VADs, PTEs, commit, working set, page faults, mapped views, and image/private memory fit together.
- How dispatcher objects, waits, priorities, quantum, affinity, processor groups, and kernel stacks shape thread behavior.
- What `CreateEvent` creates, how manual-reset and auto-reset events differ, and why an event is a waitable condition signal rather than a data lock or queue.
- Why Windows thread pools are callback/runtime/WorkerFactory machinery with dynamic workers, not a fixed set of caller-owned thread handles.
- Why IRQL constrains pageable memory access and why interrupt work is split into ISR, DPC, APC, and worker-thread paths.
- Why jobs and silos explain lifecycle/isolation better than parent PID alone.
- How IOCTL analysis crosses handles, file/device objects, IRPs, buffer methods, MDLs, and driver dispatch routines.
- Which tool views to correlate: Process Explorer, Procmon, VMMap, WinObj, WinDbg, ETW, and Sysmon-style events.

## Useful External References

- Microsoft Learn: Credential Guard, LSA protection, VBS/HVCI, vulnerable driver blocklist, App Control/WDAC, Authenticode/PE signing, SmartScreen/Smart App Control, Kernel-mode hardware stack protection, CFG, ETW, AMSI, ASR rules.
- No Starch: `Windows Security Internals` by James Forshaw.
- Digital Whisper current/local issues through 185 via [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>), especially issue 181 for kernel-network and ROP-hiding discussion, issue 182 for UEFI/physical-trust boundaries, issue 184 for syscall tampering and pointer authentication, and issue 185 for SLUB/CVE-analysis context.

## Long-Term Mastery Modules

Cadence rule: modules are ordered by dependency, not by days. A module is complete when you can draw the path, name the authority and lifetime state, run or design a confirming experiment, and explain what the evidence does not prove.

### Module 1 - Architecture, Tools, and Native API Path

Goal: draw the full path from user code to kernel behavior.

Read/watch:

- Journey support: `TheWindowsConceptJourney_v6_March2025.pdf` for a broad concept pass.
- Yosifovich, `Windows Native API Programming`, chapters 1-4.
- Pluralsight Windows 11 Internals: `Foundations`.
- Optional Hebrew warm-up: `os_book.pdf`, chapter 1 on Sysinternals.

Be able to explain:

- User mode vs kernel mode.
- Win32 API vs Native API vs syscall.
- `kernel32`/`kernelbase`/`ntdll` roles.
- System service dispatch at a conceptual level.
- Object manager and named object namespace.

Theory checkpoint:

- What is an OS responsible for?
- What happens during a context switch?
- What does "kernel mode" actually allow that user mode does not?

Mastery artifact:

- Be able to diagram: process -> Win32 API -> `ntdll` -> syscall -> kernel service -> object manager/security checks.

### Module 2 - Processes, Threads, Objects, Handles, and Memory

Goal: explain process and memory internals without relying on API folklore.

Read/watch:

- `Windows Native API Programming`, process/thread/memory/object chapters.
- Pluralsight Windows 11 Internals: `Processes and Jobs`, `Threads`, `Memory Management`, and `Kernel Mechanisms` object-management modules.
- `Windows Internals, Part 2`: memory manager sections after the basic object/address-space model is solid.

Be able to explain:

- Process object vs address space vs executable image.
- Thread object, user stack, kernel stack, TEB.
- PEB, loader lists, environment, process parameters.
- Handles, access masks, object types, reference counts.
- Sections, views, image mapping, private memory, shared memory.
- VADs, page faults, working sets at a conceptual level.

Theory checkpoint:

- Demand paging, page tables, TLB, page faults.
- Resident vs committed vs reserved memory.
- Scheduler states, ready/running/waiting, priority, quantum.
- Synchronization primitives and race conditions.

Mastery artifact:

- Explain how process injection, hollowing, and image tampering are visible through process/thread/memory/object concepts without giving implementation steps.

### Module 3 - Security Model and Access Checks

Goal: make Windows authorization intuitive.

Read/watch:

- Forshaw, `Windows Security Internals`, chapters on tokens, SIDs, privileges, groups, integrity levels, security descriptors, access checks, auditing.
- Journey support: `TheWindowsSecurityJourney_v6_Jan2025.pdf`; then use `TheWindowsSecurityJourneyWorkbook_v1_June2025.pdf` for recall drills.

Be able to explain:

- Primary token vs impersonation token.
- SIDs, groups, restricted tokens, privileges.
- Mandatory Integrity Control.
- DACL/SACL/owner, ACE ordering, access masks.
- `SeAccessCheck` conceptually.
- UAC split tokens.
- AppContainer and capability SIDs.

Theory checkpoint:

- Protection domains.
- Capability-based vs ACL-based security.
- Time-of-check/time-of-use issues in privileged services.

Mastery artifact:

- Given a handle-opening scenario, explain which token, object security descriptor, desired access, privileges, and integrity level matter.

### Module 4 - Authentication, Credentials, and Identity Boundaries

Goal: understand modern credential attack surface without outdated LSASS assumptions.

Read/watch:

- Forshaw chapters on authentication, logon, SAM, NTLM, Kerberos, Negotiate, auditing.
- Microsoft docs: Credential Guard and LSA protection.
- Journey support: `TheWindowsSecurityJourney_v6_Jan2025.pdf` for identity and credential-boundary review.

Be able to explain:

- Logon sessions and token creation.
- LSASS role.
- Authentication packages and SSPs at a conceptual level.
- NTLM vs Kerberos flow at interview depth.
- PPL and why LSASS access changed.
- Credential Guard and VBS isolation.
- Auditing and event visibility.

Theory checkpoint:

- Trusted computing base.
- Isolation boundaries.
- Local vs domain authentication threat models.

Mastery artifact:

- Explain why "dump LSASS" is not a modern research answer by itself, and what protections/telemetry changed the problem.

### Module 5 - Kernel, I/O, Drivers, and Telemetry

Goal: understand how endpoint security products and kernel components interact with Windows safely and unsafely.

Read/watch:

- `windows-kernel-programming-pavel-yosifovich.pdf`: driver basics, kernel objects, callbacks, synchronization.
- Pluralsight Windows 11 Internals: `Kernel Mechanisms`, especially object management, interrupts, exceptions, crash dumps, and synchronization.
- Older Pavel Pluralsight Windows Internals 3: I/O System, Device Drivers, Writing Software Device Drivers.
- Windows Internals Part 2: I/O system and cache/filesystem sections after the basic driver/I/O path is clear.
- Journey support: `TheWindowsForensicJourney_v2_April2025.pdf` when translating driver, file, registry, process, and network mechanisms into evidence.

Be able to explain:

- Driver objects, device objects, symbolic links.
- IRPs and major function dispatch.
- IOCTLs and user/kernel buffer handling risks.
- Kernel callbacks: process/thread/image/registry/object callbacks.
- Minifilters and WFP at a conceptual level.
- ETW providers/consumers and kernel telemetry.
- PatchGuard and why old kernel-hooking assumptions are bad.

Theory checkpoint:

- Interrupts, IRQL, DPCs, APCs.
- Blocking vs nonblocking I/O.
- DMA and device trust at a high level.
- Filesystem cache, metadata, journaling, consistency.

Mastery artifact:

- Explain how a vulnerable driver can become a security boundary problem and how modern driver blocklists/HVCI affect that risk.

### Module 6 - Mitigations and Exploit Reasoning

Goal: reason from vulnerability primitive to modern mitigation boundary.

Read/watch:

- Microsoft docs: CFG, Kernel CFG, CET/shadow stacks, VBS/HVCI, WDAC/App Control, ASR rules, vulnerable driver blocklist.
- `Slides` exploit primitives and kernel mitigation slides, as general theory only.
- Selected AWE/Corelan material only for historical Windows exploit development context.

Be able to explain:

- DEP/NX, ASLR, CFG, CET, ACG, CIG.
- KASLR and kernel pointer disclosure relevance.
- Pool/heap concepts at interview level.
- Use-after-free, race, type confusion, integer overflow, out-of-bounds.
- Exploit primitive taxonomy: read, write, info leak, control-flow, data-only.
- Why old DEP/ASLR bypass material is insufficient on modern Windows.

Theory checkpoint:

- Memory safety bug classes.
- Control-flow integrity vs data-only attacks.
- Race conditions and lock granularity.
- Kernel/user boundary validation.

Mastery artifact:

- For a hypothetical kernel bug, describe the primitive, required reliability, target boundary, mitigations, and expected telemetry.

### Module 7 - Malware Analysis, EDR Framing, and Scenario Review

Goal: connect internals knowledge to realistic research discussion.

Read/watch:

- `Reversing Malware Analysis Training`, parts 2, 8, 9, 12.
- [Attacker-relevant structures and components](<../05-topic-notes/attacker-relevant-structures-and-components.md>) for answered defensive explanations of how malicious tooling repurposes at-rest PE mutation, image-memory patching, cross-process memory overwrite, process injection variants, reflective/manual mapping, shellcode/generated code, hollowing/ghosting-style identity mismatches, hooks/detours, token impersonation, kernel callback/dispatch redirection, persistence configuration, malware/spyware collection methods, anti-debug state, telemetry gaps, and network artifacts.
- Digital Whisper local archive: `Windows Architecture`, `Windows Notify Routine Internals`, `Windows Notification Facility`, `Process Herpaderping`, `Importless Malware`, `API Set Map & AVRF`, `Threadmap`, `Windows Kernel Fuzzing`, `Malware Hunting with YARA`.
- Digital Whisper issues 134-185: use the newer map for `Inside LSASS`, `ETW`, `Windows Authorization 101`, `WinAPI Hashing`, code injection, DLL side-loading, direct/tampered syscalls, minifilters, BYOVD/DSE, `Windows Kernel`, and `AFDUMP`.
- `Books` from a telemetry/detection perspective, not as a build guide.

Be able to explain:

- PE loading, imports, API sets, loader behavior.
- At-rest PE mutation versus in-memory image/private-page mutation.
- Signature/certificate checkpoints: Authenticode, catalog signing, SmartScreen reputation, `WinVerifyTrust`, WDAC/UMCI, Smart App Control, `/INTEGRITYCHECK`, and kernel Code Integrity.
- TOCTOU reasoning: whether the file/path checked for trust is the same file object, image section, and memory bytes later executed.
- DLL loading and injection concepts.
- AMSI and ETW roles.
- Common EDR visibility points.
- Anti-analysis and packing concepts.
- Difference between user-mode hooks, detours, pointer-table hooks, kernel callbacks, ETW, AMSI, and memory scanning.

Theory checkpoint:

- What OS invariants security products rely on.
- What breaks when malware tampers with loader state, memory permissions, handles, or thread creation.
- How to discuss bypass research responsibly: mechanism, assumption, detection, mitigation.

Mastery artifact:

- Run a 60-minute scenario review or mock interview:
  - 10 minutes: architecture and syscalls.
  - 10 minutes: process/memory/object model.
  - 10 minutes: tokens/access checks/authentication.
  - 10 minutes: drivers/I/O/kernel telemetry.
  - 10 minutes: mitigations and exploit primitives.
  - 10 minutes: EDR/malware-analysis scenario.

## Digital Whisper Priority List

Use the full newer-issue map here: [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>).

Read first:

- Issue 149: `Inside LSASS` and `ETW`.
- Issue 150: `WinAPI Hashing`.
- Issue 152: Windows code-injection techniques and `Mimikatz Internals`.
- Issue 156/157/158: access tokens, authorization, lateral movement, NTLM.
- Issue 162/163/164/165/168: Windows kernel, BYOVD/DSE, driver reversing, unsigned-driver loading.
- Issue 170/172/177/184: DLL side-loading, direct syscalls, proxy DLLs, tampered syscalls.
- Issue 181: `AFDUMP - Sniffing Network From The Kernel`.
- Issue 181: race-condition article.
- Issue 181: `Hiding under ROP for fun and profit`.
- Issue 182: BitLocker/UEFI physical-trust article.
- Local archive: `Windows Architecture`.
- Local archive: `Windows Notify Routine Internals`.
- Local archive: `Windows Notification Facility`.
- Local archive: `API Set Map & AVRF`.
- Local archive: `Process Herpaderping`.
- Local archive: `Importless Malware`.
- Local archive: `Malware Hunting with YARA`.
- Local archive: `Threadmap - Detecting Process Injection`.
- Local archive: `Windows Kernel Fuzzing`.

Treat as historical/background:

- Old DEP/ASLR bypass articles.
- Old PatchGuard/DSE bypass articles.
- Old rootkit material.
- Old Win32 stack exploitation bootcamps.

## Deprioritize Until The Mechanism Model Is Solid

- Full Corelan/AWE completion unless the target work is explicitly exploit-dev focused.
- SANS-style Windows privilege escalation labs except as a quick review of common misconfigurations.
- Generic web/cloud/mobile material.
- Deep malware construction tutorials.
- Most old rootkit and AV-bypass articles unless used to explain why modern Windows changed.

## Minimum Theoretical OS Checklist

Before claiming readiness, be able to explain these without notes:

- Process vs thread vs job vs handle.
- Scheduler states, priority, quantum, context switch.
- User mode vs kernel mode, syscall transition.
- Virtual memory, page tables, TLB, page faults, working set.
- Commit/reserve/private/shared/image memory.
- Synchronization: mutex, semaphore, event, spinlock, reader-writer lock.
- Deadlock conditions and avoidance.
- Interrupts, IRQL, DPC, APC.
- I/O stack, driver dispatch, IRP, IOCTL.
- Filesystem basics: metadata, caching, journaling, deleted-file recovery at concept level.
- Security model: subjects, objects, access checks, capabilities/ACLs.
- Isolation: process, session, desktop, AppContainer, VBS/secure kernel.

## Final Priority Order

1. Forshaw 2024 for Windows security model and authentication.
2. Yosifovich Native API 2024 for real Windows user/kernel API understanding.
3. Pavel Windows 11 Internals Pluralsight course for process, memory, objects, threads, interrupts, exceptions, and synchronization.
4. Older Pavel Windows Internals 3 videos/books for I/O and driver coverage.
5. Microsoft Learn for current mitigations and platform defaults.
6. Selected Digital Whisper articles for Hebrew research context.
7. Reversing Malware Analysis Training for analysis vocabulary.
8. `os_book.pdf` only as a quick Hebrew foundation refresher.
