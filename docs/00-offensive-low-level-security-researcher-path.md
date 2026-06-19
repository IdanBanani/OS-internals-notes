# Offensive Low-Level Security Researcher Path

Value Score: 97/100
Role: Offensive low-level study path
Proof Level: Lab-routed

Date: 2026-05-18

Purpose: make the large notes tree navigable for offensive low-level security research. The priority is not "learn every OS subsystem." The priority is: after code execution, what state gives authority, memory access, execution redirection, persistence, telemetry control, or a route across a security boundary?

This file is an entrypoint. It does not replace the detailed notes; it tells you which ones deserve attention first.

## Priority Rule

Read in this order:

1. Chain and objective: where the attacker or authorized agent is in the lifecycle.
2. Authority state: token, credential, privilege, handle/fd, capability, integrity, sandbox, session, namespace.
3. Memory and translation state: VAD/VMA, PTE, section/mapping, page cache, image/private mismatch, executable memory.
4. Execution and dispatch state: loader, imports/exports, callbacks, APCs, thread pools, driver dispatch, hooks, JIT/code caches.
5. IPC and broker state: named pipes, RPC, ALPC, COM, Unix sockets, inherited handles/fds, impersonation, endpoint ACLs.
6. Runtime allocation and object lifetime: heap behavior, reference counts, stale pointers, use-after-free, RAII/destructors, C++ object layout.
7. Evidence and experiments: code, debugger views, traces, logs, memory maps, handles/fds, tokens/creds, and source paths that prove the mechanism.
8. Persistence and telemetry: services, tasks, WMI/COM, registry, systemd/cron, ETW/AMSI/audit/logging, forensic evidence.
9. Vulnerability mechanics: bug classes, primitives, mitigations, reliability, exploitability constraints.
10. Hardware/firmware: DMA/IOMMU, virtualization, secure/measured boot, code integrity, hypervisor boundaries.

If a document does not help answer one of those questions, treat it as support material, not first-pass reading.

## Read First

These are the highest-signal files for the offensive low-level mindset:

1. [Security internals research: 0/1-click RCE+PE to agent](<05-topic-notes/remote-attacker-low-level-mechanisms.md>)

   Start here. It frames every mechanism by scenario stage: initial exposure, RCE, sandbox escape or PE, agent runtime, persistence, kernel/driver primitive, and evidence.

2. [Low-level security component map](<01-comparisons-and-maps/02-low-level-security-component-map.md>)

   Use this to separate policy checkers from real enforcers. This prevents shallow answers such as "the API blocks it" when the actual enforcer is a token, PTE, IOMMU, code-integrity policy, object ACL, or kernel-mode dispatch path.

3. [Low-level security critical terms](<05-topic-notes/low-level-security-critical-terms.md>)

   Keep this beside the component map when dense terms show up: PPL, SRM, handles versus object pointers, driver dispatch, IRPs, MDLs, ACPI tables, MSRs, gates, PTE states, DMA pinning, and kernel-thread/process terminology.

4. [Practical concept anchors](<05-topic-notes/practical-concept-anchors.md>)

   Use this when an abbreviation appears before you can teach it: IOMMU, page cache, VMA/VAD, PTE/PFN, IRP/MDL, LSM, RCU, eBPF, io_uring, ETW, AMSI, PPL, VBS/HVCI, CFG, and CET. It gives the expansion, owner layer, practical use, evidence path, and deeper doc/lab.

5. [Attacker-relevant structures and components](<05-topic-notes/attacker-relevant-structures-and-components.md>)

   Use this as the ranked map of high-power targets: authority state, translation state, dispatch state, integrity state, telemetry state, and device/DMA state.

6. [Hands-on internals labs](<06-hands-on-labs/README.md>)

   Use this to prove claims with local code and tools before treating cross-platform analogies as knowledge.

7. [Linux vs Windows internals](<01-comparisons-and-maps/01-linux-vs-windows-internals.md>)

   Use this only for translation and comparison. Do not try to memorize it all before touching the security path.

8. Pick the platform spine.

   - Windows: [Source-enriched Windows mechanisms](<04-windows/06-source-enriched-windows-mechanisms.md>), then [Windows deep-understanding Q&A](<02-question-banks/02-windows-deep-understanding-qa.md>).
   - Linux: [Linux project README](<03-linux/README.md>), [Linux source map](<03-linux/source-map.md>), then [Linux deep-understanding Q&A](<02-question-banks/01-linux-deep-understanding-qa.md>).

## Windows Priority Track

Use this order for Windows offensive low-level research:

1. [Source-enriched Windows mechanisms](<04-windows/06-source-enriched-windows-mechanisms.md>)

   Baseline Executive/Object Manager/process/thread/memory/scheduler/driver/telemetry vocabulary.

2. [Windows deep-understanding Q&A](<02-question-banks/02-windows-deep-understanding-qa.md>)

   Active recall for the Windows concepts most likely to appear in interviews or research conversations.

3. [Windows object handles, references, and tokens](<05-topic-notes/windows-object-handles-references-and-tokens.md>)

   Highest priority for authority: handle tables, granted access, object identity, pointer references, tokens, impersonation, inherited handles, and kernel object residency.

4. [Windows kernel memory, sections, privileges, and ASLR](<05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>)

   Highest priority for translation and memory security: sections, mapped views, file cache, pagefile-backed memory, pool choices, PEB/TEB discovery, DLL sharing, KASLR, and privilege semantics.

5. [Paging, residency, page lists, and shared memory](<05-topic-notes/paging-residency-page-lists-and-shared-memory.md>)

   Read with the Windows kernel-memory note so "resident," "pageable," "swappable," "standby," "free," and "zeroed" do not blur together.

6. [Process memory access and memory API flags](<01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md>)

   Needed for cross-process access, injection/reversing permissions, `VirtualAlloc*`, `mmap`, `mprotect`, and related access flags.

7. [Windows IPC named pipes, RPC, ALPC, and security](<05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>)

   Highest priority for broker/service boundaries: endpoint ACLs, SQOS/QoS, named-pipe races, RPC binding/auth, ALPC attributes, handle/view transfer, and failed impersonation.

8. [Related system calls and API semantics](<01-comparisons-and-maps/05-related-system-calls-and-api-semantics.md>)

   Read when Win32, Native API, POSIX, and Linux syscall analogies start to blur.

9. [ELF, PE, loaders, and linkers Q&A](<02-question-banks/04-binary-loaders-linkers-qa.md>)

   Required for loader abuse, DLL side-loading, manual mapping, API hashing, export walking, TLS, relocations, and process startup/destruction.

10. [User-mode heaps, runtime APIs, and toolchains](<05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)

    Required for heap/API layering, `malloc`/UCRT/`HeapAlloc`/`VirtualAlloc`, LFH, segment heap, SEH/C++ constraints, and compiler/runtime fingerprints.

11. [C++ and modern C++ internals for security researchers](<02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>)

    Required for real-world user-mode products and drivers: vtables, destructors, RAII, smart pointers, COM-style refcounts, atomics, intrinsics, and optimizer artifacts.

12. [Vulnerability research and exploitation primitives](<05-topic-notes/vulnerability-research-and-exploitation-primitives.md>)

    Read after the OS mechanism model. Primitives are only useful when you can say which authority, mapping, dispatch, or telemetry invariant they violate.

13. [Flare-On Windows internals notes](<04-windows/04-flareon-windows-internals-notes.md>)

    Case-study reinforcement for reversing and Windows mechanism recognition.

14. [Windows low-level security resources](<04-windows/07-windows-low-level-security-resources.md>)

    Source list and external reading queue.

Lower-priority Windows support files:

- [Windows long-term mastery roadmap](<04-windows/01-windows-long-term-mastery-roadmap.md>)
- [Windows roadmap know-cold explanations](<04-windows/08-windows-roadmap-know-cold-explanations.md>)
- [Windows case-study resource map](<04-windows/02-windows-case-study-resource-map.md>)
- [Local Hebrew and Digital Whisper paper reading map](<04-windows/05-local-hebrew-paper-reading-map.md>)

Use those when you need checklist coverage, not as the main path.

## Linux Priority Track

Use this order for Linux offensive low-level research:

1. [Linux deep-understanding Q&A](<02-question-banks/01-linux-deep-understanding-qa.md>)
2. [Linux project README](<03-linux/README.md>)
3. [Linux source map](<03-linux/source-map.md>)
4. [Address space, `mm_struct`, VMAs, page tables, TLBs, and faults](<03-linux/01-address-space-mm.md>)
5. [Page cache, reclaim, pinned pages, and allocators](<03-linux/02-page-cache-reclaim-allocators.md>)
6. [Syscall entry, exceptions, interrupts, and ELF loading](<03-linux/03-entry-exceptions-elf.md>)
7. [Bug-to-primitive reasoning and mitigations](<03-linux/07-primitives-mitigations-attacker-patterns.md>)
8. [Linux and Android memory internals for vulnerability research](<03-linux/08-linux-android-memory-vulnerability-research.md>)
9. [Modern Linux memory manager reading map](<03-linux/09-modern-linux-mm-reading-map.md>)
10. [Android internals](<03-linux/04-android-internals.md>)
11. [Architecture special cases](<03-linux/05-architecture-special-cases.md>)
12. [Veteran interview FAQ](<03-linux/06-veteran-interview-faq.md>)

Read Linux through the same offensive lens: `cred`, capabilities, namespaces, seccomp, fd tables, VMAs, page tables, page cache, ELF/linker behavior, eBPF/io_uring, LSM, netfilter, module/driver state, audit/logging, systemd/cron/PAM/NSS/loader persistence.

## Cross-Platform Subsystem Track

Use these when a mechanism crosses platform boundaries:

1. [Hands-on internals labs](<06-hands-on-labs/README.md>)
2. [Memory, filesystems, and network Q&A](<02-question-banks/03-memory-filesystems-network-qa.md>)
3. [Paging, residency, page lists, and shared memory](<05-topic-notes/paging-residency-page-lists-and-shared-memory.md>)
4. [Process memory access and memory API flags](<01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md>)
5. [Related system calls and API semantics](<01-comparisons-and-maps/05-related-system-calls-and-api-semantics.md>)
6. [ELF, PE, loaders, and linkers Q&A](<02-question-banks/04-binary-loaders-linkers-qa.md>)
7. [C++ and modern C++ internals for security researchers](<02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>)
8. [Mobile OS and coding interview traps Q&A](<02-question-banks/07-mobile-os-and-coding-interview-traps-qa.md>)
9. [User-mode heaps, runtime APIs, and toolchains](<05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)

## Hardware, Firmware, And Architecture

Read these when the chain reaches kernel, driver, hypervisor, DMA, boot, or hardware-backed security:

1. [Low-level security critical terms](<05-topic-notes/low-level-security-critical-terms.md>)
2. [Hardware and OS security Q&A](<02-question-banks/05-hardware-security-relationship-qa.md>)
3. [x86 privilege rings, descriptors, and syscall entry](<05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md>)
4. [ARM architecture differences](<01-comparisons-and-maps/03-arm-architecture-differences.md>)

Treat these as high priority only when your research path touches PPL, SRM, privileged control state, CPL/DPL/RPL, syscall MSRs, CR registers, GDT/LDT/IDT/TSS, page tables/PTEs, DMA/IOMMU, virtualization, EL levels, x86-64 versus arm64, Secure Boot, measured boot, VBS/HVCI, PatchGuard, firmware, or device trust.

## Source And Case-Study Maps

These are support maps, not first-pass reading:

- [Digital Whisper issues 134-185 internals map](<05-topic-notes/digital-whisper-134-185-internals-map.md>)
- [Journey PDF source map](<05-topic-notes/journey-pdf-source-map.md>)
- [Windows low-level security resources](<04-windows/07-windows-low-level-security-resources.md>)
- [Flare-On Windows internals notes](<04-windows/04-flareon-windows-internals-notes.md>)

Use them when you need a paper, case study, or source bridge for a mechanism already identified as relevant.

## What To Deprioritize On First Pass

Do not start by trying to complete every roadmap or source map. Deprioritize:

- broad resource lists before mechanism notes;
- paper maps before the primary OS mechanism model;
- exploitability details before authority/memory/dispatch invariants;
- hardware/firmware unless the chain reaches those layers;
- full cross-platform comparison tables unless you are translating between Linux and Windows.

The first pass should leave you able to explain this sentence for any mechanism:

```text
Given this execution context, this object/state controls this authority or boundary; if corrupted, confused, or reused, it yields this capability; these mitigations and evidence sources decide whether it matters on the target build.
```
