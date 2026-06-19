# OS Internals Study Notes

Value Score: 96/100
Role: Entry point and reading order
Proof Level: Lab-routed

This repository is organized as a security-internals study tree. The primary entrypoint is now [Offensive low-level security researcher path](<docs/00-offensive-low-level-security-researcher-path.md>), which prioritizes the files by relevance to RCE, privilege escalation, agent runtime, persistence, telemetry, and vulnerability research.

The folder layout is intentionally stable. Use the priority path to decide what to read first; use the numbered folders as storage and reference organization.

Several high-impact notes also contain an `Offensive Priority Index` near the top. Use those local score tables when reading inside a large markdown file; the physical order is sometimes explanatory rather than priority-first.

## Fast Start

For offensive low-level security research, read:

1. [Offensive low-level security researcher path](<docs/00-offensive-low-level-security-researcher-path.md>)
2. [Security internals research: 0/1-click RCE+PE to agent](<docs/05-topic-notes/remote-attacker-low-level-mechanisms.md>)
3. [Low-level security component map](<docs/01-comparisons-and-maps/02-low-level-security-component-map.md>)
4. [Attacker-relevant structures and components](<docs/05-topic-notes/attacker-relevant-structures-and-components.md>)

Then pick the platform spine:

- Windows: [Source-enriched Windows mechanisms](<docs/04-windows/06-source-enriched-windows-mechanisms.md>) and [Windows deep-understanding Q&A](<docs/02-question-banks/02-windows-deep-understanding-qa.md>)
- Linux: [Linux project README](<docs/03-linux/README.md>), [Linux source map](<docs/03-linux/source-map.md>), and [Linux deep-understanding Q&A](<docs/02-question-banks/01-linux-deep-understanding-qa.md>)

For the deceptively small interview traps around mobile process/thread memory, non-atomic `counter++`, Fibonacci/runtime tradeoffs, and recursive numeric overflow, use [Mobile OS and coding interview traps Q&A](<docs/02-question-banks/07-mobile-os-and-coding-interview-traps-qa.md>).

For proof-oriented study, use [Hands-on internals labs](<docs/06-hands-on-labs/README.md>) before relying on cross-platform comparison tables. The labs map claims to code, commands, debugger/tool views, expected observations, and "what this does not prove" caveats.

When an answer drops compact terms such as IOMMU, PTE, PFN, VAD, VMA, page cache, IRP, MDL, LSM, RCU, ETW, AMSI, PPL, VBS, or HVCI, use [Practical concept anchors](<docs/05-topic-notes/practical-concept-anchors.md>). That file expands the abbreviations, names the owning OS layer, gives a practical evidence path, and points to deeper owner docs/labs.

When a claim needs direct toy code, use [Practical snippet pack](<docs/06-hands-on-labs/01-practical-snippet-pack.md>). It contains small Linux, Windows, and C++ snippets for VMA/COW, fd/path lifetime, user-pointer validation, handle rights, memory mapping categories, and atomics.

## General Reading Order

Use this order when you want the repo to build up OS concepts instead of following the offensive priority path.

1. [Hands-on internals labs](<docs/06-hands-on-labs/README.md>)

   Start here when the notes feel too theoretical. The lab method is claim -> experiment -> evidence -> caveat. Use it to prove page faults, COW, fds, handles, VADs/VMAs, tokens/creds, atomics, stack exhaustion, and loader behavior.

2. [Linux vs Windows internals](<docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md>)

   Use this after at least one platform-clean lab pass. It is for translation: process objects, address spaces, VMA/VAD trees, handles/fds, object lifetime, and cross-view enumeration.

3. [Low-level security component map](<docs/01-comparisons-and-maps/02-low-level-security-component-map.md>)

   Read this early so policy checkers, authority state, and real enforcement points stay separate in your head.

4. Pick the OS track you care about most.

   - Windows-first: start with [Source-enriched Windows mechanisms](<docs/04-windows/06-source-enriched-windows-mechanisms.md>), then drill [Windows deep-understanding Q&A](<docs/02-question-banks/02-windows-deep-understanding-qa.md>).
   - Linux-first: start with [Linux project README](<docs/03-linux/README.md>) and [Linux source map](<docs/03-linux/source-map.md>), then drill [Linux deep-understanding Q&A](<docs/02-question-banks/01-linux-deep-understanding-qa.md>).

5. [Process memory access and memory API flags](<docs/01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md>)

   Read this after the address-space and handle/fd basics. It maps cross-process access, page-oriented allocation/protection APIs, and the flags that decide authority.

   Focused companions:

   - [Windows kernel memory, sections, privileges, and ASLR](<docs/05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>)
   - [Windows object handles, references, and tokens](<docs/05-topic-notes/windows-object-handles-references-and-tokens.md>)
   - [Windows IPC named pipes, RPC, ALPC, and security](<docs/05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>)

6. [Memory, filesystems, and network Q&A](<docs/02-question-banks/03-memory-filesystems-network-qa.md>)

   This is the main subsystem bridge after process, thread, object, and address-space basics.

   Focused companion:

   - [VAD and VMA management internals](<docs/05-topic-notes/vad-vma-management-internals.md>)
   - [Paging, residency, page lists, and shared memory](<docs/05-topic-notes/paging-residency-page-lists-and-shared-memory.md>)

7. [Related system calls and API semantics](<docs/01-comparisons-and-maps/05-related-system-calls-and-api-semantics.md>)

   Read this once the mechanism names are familiar and nearby APIs start to blur together.

8. [ELF, PE, loaders, and linkers Q&A](<docs/02-question-banks/04-binary-loaders-linkers-qa.md>)

   Read before malware analysis, process startup/destruction questions, DLL side-loading, manual mapping, API resolution, or loader-lock discussions.

9. [C++ and modern C++ internals for security researchers](<docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>)

   Read before compiled C++ reversing, browser/client bug triage, `.sys` driver analysis, vtable/object-lifetime questions, STL/container edge cases, or atomic/intrinsics/assembly memory-ordering interviews.

   Runtime companion:

   - [User-mode heaps, runtime APIs, and toolchains](<docs/05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)

10. [Attacker-relevant structures and components](<docs/05-topic-notes/attacker-relevant-structures-and-components.md>)

   Use this after the core mechanisms to connect structures to defensive security research, reversing, telemetry, and driver/device state.

11. [Security internals research: 0/1-click RCE+PE to agent](<docs/05-topic-notes/remote-attacker-low-level-mechanisms.md>)

    Use this for the main interview scenario: client compromise to RCE, privilege escalation or sandbox escape, then the OS internals that let an authorized agent run.

12. [Vulnerability research and exploitation primitives](<docs/05-topic-notes/vulnerability-research-and-exploitation-primitives.md>)

    Keep this as the secondary track for bug classes, primitives, mitigation impact, exploitability constraints, public writeup digestion, and safe authorized validation.

13. [Low-level security critical terms](<docs/05-topic-notes/low-level-security-critical-terms.md>), [Hardware and OS security Q&A](<docs/02-question-banks/05-hardware-security-relationship-qa.md>), [x86 privilege rings, descriptors, and syscall entry](<docs/05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md>), and [ARM architecture differences](<docs/01-comparisons-and-maps/03-arm-architecture-differences.md>)

    Read when the discussion touches PPL, SRM, driver dispatch, IRPs, MDLs, ACPI tables, CPL/DPL/RPL, syscall MSRs, GDT/LDT/IDT/TSS, MMU/TLB behavior, DMA/IOMMU, virtualization, firmware, mitigations, x86-64 versus arm64, Android, or hardware-backed security.

    Practical abbreviation companion:

    - [Practical concept anchors](<docs/05-topic-notes/practical-concept-anchors.md>)

14. Source and case-study maps.

    - [Digital Whisper issues 134-185 internals map](<docs/05-topic-notes/digital-whisper-134-185-internals-map.md>)
    - [Journey PDF source map](<docs/05-topic-notes/journey-pdf-source-map.md>)

    Use these as supporting maps after the core path, or when you need a specific paper/source bridge.

## Folder Layout

| Folder | Purpose |
|---|---|
| [docs/01-comparisons-and-maps](<docs/01-comparisons-and-maps>) | Cross-platform maps and conceptual translations. |
| [docs/02-question-banks](<docs/02-question-banks>) | Scored question banks with answer sections. |
| [docs/03-linux](<docs/03-linux>) | Linux-focused long-term roadmap, source map, and topic notes. |
| [docs/04-windows](<docs/04-windows>) | Windows-focused long-term roadmap, case resources, and reversing notes. |
| [docs/05-topic-notes](<docs/05-topic-notes>) | Specialized notes that are not pure question banks. |
| [docs/06-hands-on-labs](<docs/06-hands-on-labs>) | Practical experiments for proving OS-internals claims with code, commands, debugger views, and traces. |
| [docs/99-meta](<docs/99-meta>) | Coverage audit and cleanup metadata. |

## Scored Question Banks

These files are the ones to use for active recall. They include priority indexes and full answer sections.

| File | Answer coverage |
|---|---|
| [01-linux-deep-understanding-qa.md](<docs/02-question-banks/01-linux-deep-understanding-qa.md>) | Full `Best Answers` section for the scored questions. |
| [02-windows-deep-understanding-qa.md](<docs/02-question-banks/02-windows-deep-understanding-qa.md>) | Full `Best Answers` section for the scored questions. |
| [03-memory-filesystems-network-qa.md](<docs/02-question-banks/03-memory-filesystems-network-qa.md>) | Full `Best Answers` section for the scored questions. |
| [04-binary-loaders-linkers-qa.md](<docs/02-question-banks/04-binary-loaders-linkers-qa.md>) | Full `Best Answers` section for the scored questions. |
| [05-hardware-security-relationship-qa.md](<docs/02-question-banks/05-hardware-security-relationship-qa.md>) | Full `Best Answers` section for the scored questions. |
| [06-cpp-modern-cpp-internals-security-qa.md](<docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>) | Full `Best Answers` section for the scored questions. |
| [07-mobile-os-and-coding-interview-traps-qa.md](<docs/02-question-banks/07-mobile-os-and-coding-interview-traps-qa.md>) | Full `Best Answers` section for mobile process/thread memory, non-atomic counter races, Fibonacci/runtime tradeoffs, and recursive numeric overflow. |

## Are All Questions Answered?

The scored question-bank files above have full answer sections, and the attacker-relevant technique prompts in the topic notes are written as answered explanations. Some roadmap files still include reading checkpoints or mock-interview drills; those are navigation aids rather than standalone unanswered question banks.

This distinction exists because the repo has two different document types: active-recall files should answer the question directly, while source maps and roadmaps are allowed to route the reader to the deeper explanation. Do not treat that routing rule as proof that every non-trivial claim has already passed a deep manual audit.

Use this rule:

- If it is in [docs/02-question-banks](<docs/02-question-banks>), it should have direct answers.
- If a topic note uses a question heading, it should answer that question in the same section.
- If it is in [docs/03-linux](<docs/03-linux>) or [docs/04-windows](<docs/04-windows>), checklist items and mock-interview drills may point to the companion explanation files rather than duplicate those answers inline.
- [Linux veteran interview FAQ](<docs/03-linux/06-veteran-interview-faq.md>) has short rapid-fire Q&A, but it is not a full scored question bank.

## Deep Why Standard

Use [Deep why standard](<docs/99-meta/why-depth-standard.md>) when editing or auditing the notes. Any non-trivial fact, term, mechanism, or question should explain the causal "why": mechanism, authority, boundary, invariant, failure mode, relevance to the 0/1-click RCE+PE-to-agent scenario, constraints, and evidence. Short index rows are acceptable only when they link to a section that provides the deeper why.

The first structural audit is tracked in [Deep why audit](<docs/99-meta/deep-why-audit.md>). It is a triage record, not a claim that every paragraph has been manually certified.

## Linux-Focused Track

Use this when Linux is the primary target:

1. [Linux project README](<docs/03-linux/README.md>)
2. [Source map](<docs/03-linux/source-map.md>)
3. [Linux deep-understanding Q&A](<docs/02-question-banks/01-linux-deep-understanding-qa.md>)
4. [Modern Linux memory manager reading map](<docs/03-linux/09-modern-linux-mm-reading-map.md>)
5. [Address space, `mm_struct`, VMAs, page tables, TLBs, and faults](<docs/03-linux/01-address-space-mm.md>)
6. [Page cache, reclaim, pinned pages, and allocators](<docs/03-linux/02-page-cache-reclaim-allocators.md>)

   Cross-platform memory companion:

   - [Paging, residency, page lists, and shared memory](<docs/05-topic-notes/paging-residency-page-lists-and-shared-memory.md>)

7. [Syscall entry, exceptions, interrupts, and ELF loading](<docs/03-linux/03-entry-exceptions-elf.md>)

   x86 privilege companion:

   - [x86 privilege rings, descriptors, and syscall entry](<docs/05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md>)

8. [Android internals](<docs/03-linux/04-android-internals.md>)
9. [Architecture special cases](<docs/03-linux/05-architecture-special-cases.md>)
10. [Veteran interview FAQ](<docs/03-linux/06-veteran-interview-faq.md>)
11. [Bug-to-primitive reasoning and mitigations](<docs/03-linux/07-primitives-mitigations-attacker-patterns.md>)
12. [Linux and Android memory internals for vulnerability research](<docs/03-linux/08-linux-android-memory-vulnerability-research.md>)
13. [C++ and modern C++ internals for security researchers](<docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>)

    Runtime companion:

    - [User-mode heaps, runtime APIs, and toolchains](<docs/05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)

14. [Security internals research: 0/1-click RCE+PE to agent](<docs/05-topic-notes/remote-attacker-low-level-mechanisms.md>)
15. [Vulnerability research and exploitation primitives](<docs/05-topic-notes/vulnerability-research-and-exploitation-primitives.md>)
16. [Digital Whisper issues 134-185 internals map](<docs/05-topic-notes/digital-whisper-134-185-internals-map.md>)
17. [Journey PDF source map](<docs/05-topic-notes/journey-pdf-source-map.md>)

## Windows-Focused Track

Use this when Windows is the primary target:

1. [Source-enriched Windows mechanisms](<docs/04-windows/06-source-enriched-windows-mechanisms.md>)
2. [Windows deep-understanding Q&A](<docs/02-question-banks/02-windows-deep-understanding-qa.md>)
3. [Windows object handles, references, and tokens](<docs/05-topic-notes/windows-object-handles-references-and-tokens.md>)
4. [Paging, residency, page lists, and shared memory](<docs/05-topic-notes/paging-residency-page-lists-and-shared-memory.md>)
5. [Windows kernel memory, sections, privileges, and ASLR](<docs/05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>)
6. [User-mode heaps, runtime APIs, and toolchains](<docs/05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)
7. [Windows IPC named pipes, RPC, ALPC, and security](<docs/05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>)
8. [Process memory access and memory API flags](<docs/01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md>)
9. [Related system calls and API semantics](<docs/01-comparisons-and-maps/05-related-system-calls-and-api-semantics.md>)
10. [ELF, PE, loaders, and linkers Q&A](<docs/02-question-banks/04-binary-loaders-linkers-qa.md>)
11. [C++ and modern C++ internals for security researchers](<docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>)
12. [Attacker-relevant structures and components](<docs/05-topic-notes/attacker-relevant-structures-and-components.md>)
13. [Security internals research: 0/1-click RCE+PE to agent](<docs/05-topic-notes/remote-attacker-low-level-mechanisms.md>)
14. [Vulnerability research and exploitation primitives](<docs/05-topic-notes/vulnerability-research-and-exploitation-primitives.md>)
15. [Flare-On Windows internals notes](<docs/04-windows/04-flareon-windows-internals-notes.md>)
16. [Windows low-level security resources](<docs/04-windows/07-windows-low-level-security-resources.md>)
17. [Windows long-term mastery roadmap](<docs/04-windows/01-windows-long-term-mastery-roadmap.md>)
18. [Windows roadmap know-cold explanations](<docs/04-windows/08-windows-roadmap-know-cold-explanations.md>)
19. [Windows case-study resource map](<docs/04-windows/02-windows-case-study-resource-map.md>)
20. [Local Hebrew and Digital Whisper paper reading map](<docs/04-windows/05-local-hebrew-paper-reading-map.md>)
21. [Digital Whisper issues 134-185 internals map](<docs/05-topic-notes/digital-whisper-134-185-internals-map.md>)
22. [Journey PDF source map](<docs/05-topic-notes/journey-pdf-source-map.md>)

For Windows, the conceptual order is: Executive versus lower-kernel responsibilities, Object Manager and handles, tokens/security descriptors, process/thread/memory structures, section objects and page residency, user-mode heaps, dispatcher objects and wait semantics, thread pools/WorkerFactory and async lifetime, IPC and impersonation boundaries, Native API and loader startup/teardown, drivers/I/O, compiled C++ object/lifetime/atomic behavior, ETW/AMSI/telemetry, then mitigations such as PPL, VBS/HVCI, CFG/CET, PatchGuard, and driver signing.

When the Windows discussion turns into ring transitions, syscall entry, KVA shadow, `swapgs`, `LSTAR`, `WRMSR`, CR registers, SMEP/SMAP, or descriptor-table state, use [x86 privilege rings, descriptors, and syscall entry](<docs/05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md>) as the hardware-level companion.

When the discussion starts accumulating compact terms such as PPL, SRM, MDL, ACPI SSDT/FADT/MADT, MSR, gates, U/S, PCID/ASID, invalid PTE state, DMA pinning, or Windows/Linux kernel-thread distinctions, keep [Low-level security critical terms](<docs/05-topic-notes/low-level-security-critical-terms.md>) open as the glossary/FAQ layer.

## Maintenance Notes

- [Coverage audit](<docs/99-meta/coverage-audit.md>) tracks what the material covers and what remains partial.
- [Deep why standard](<docs/99-meta/why-depth-standard.md>) defines the writing/audit rule for non-trivial claims and questions.
- [Deep why audit](<docs/99-meta/deep-why-audit.md>) records the first corpus-wide structural pass and the remaining manual-review queue.
- [Practical depth and separation audit](<docs/99-meta/practical-depth-and-separation-audit.md>) records the current critique: repeated high-level terms, Linux/Windows entanglement, and the need to prove claims with labs before relying on cross-platform analogies.
- [Hands-on internals labs](<docs/06-hands-on-labs/README.md>) is the practical spine for claim-to-evidence experiments across Linux, Windows, C/C++, and loaders.
- [Practical snippet pack](<docs/06-hands-on-labs/01-practical-snippet-pack.md>) provides runnable toy code for the highest-repetition claims that otherwise risk staying theoretical.
- [Recent docs depth and placement audit](<docs/99-meta/recent-docs-depth-placement-audit.md>) scores the Markdown files added since 2026-05-05, states the reader payoff for each file, and records which files should be deep mechanism owners versus routing/source-map files.
- [Remote-attacker low-level mechanisms](<docs/05-topic-notes/remote-attacker-low-level-mechanisms.md>) is the cross-platform security-internals map for reasoning from 0/1-click RCE+PE to authorized agent execution, collection, communication, telemetry, and persistence surfaces.
- [Vulnerability research and exploitation primitives](<docs/05-topic-notes/vulnerability-research-and-exploitation-primitives.md>) is the separate secondary track for bug-to-primitive reasoning, structures of interest, mitigation impact, and safe authorized validation.
- [Paging, residency, page lists, and shared memory](<docs/05-topic-notes/paging-residency-page-lists-and-shared-memory.md>) is the focused memory note for nonpageable/non-swappable distinctions, shared-memory backing, PFN/PTE relationships, demand-zero faults, standby/free/zero page lists, and stale-byte security boundaries.
- [User-mode heaps, runtime APIs, and toolchains](<docs/05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>) is the focused runtime note for Windows/Linux heap APIs, allocator layering, `VirtualFree` size semantics, LFH/segment heap, SEH and C++ unwinding, compiler/runtime fingerprints, C++17 inline static, and Visual Studio heap debugging.
- [Windows kernel memory, sections, privileges, and ASLR](<docs/05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>) is the focused Windows note for special kernel APCs, file-system cache, paged/nonpaged pool, section objects and mapped views, `Nt`/`Zw`, `SeLockMemoryPrivilege`, `kernel32` address reuse, PEB/TEB export walking, DLL sharing, and KASLR.
- [Windows object handles, references, and tokens](<docs/05-topic-notes/windows-object-handles-references-and-tokens.md>) is the focused Windows note for handles versus kernel pointer references, object refcounts, handle-entry fields, token handle APIs, object-address comparisons, kernel-object pool residency, and NX nonpaged pool.
- [Windows IPC named pipes, RPC, ALPC, and security](<docs/05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md>) is the focused Windows IPC note for named-pipe DACL/SQOS/race issues, RPC endpoint/binding/auth/QoS behavior, ALPC port/message-attribute/resource lifetime, and impersonation/non-impersonation failure modes.
- [x86 privilege rings, descriptors, and syscall entry](<docs/05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md>) is the focused x86 note for CPL/DPL/RPL, GDT/LDT/IDT/TSS, syscall MSRs, `swapgs`, CR registers, SMEP/SMAP, and vulnerable-driver privileged-state bridges such as exposed `wrmsr`.
- [Low-level security critical terms](<docs/05-topic-notes/low-level-security-critical-terms.md>) is the compact glossary/FAQ for PPL, SRM, driver dispatch, IRPs, MDLs, ACPI tables, MSRs, gates, U/S, SMEP/SMAP, privileged control state, PTE states, page-table residency, DMA pinning, reverse mappings, and Windows/Linux kernel-thread terminology.
- [Practical concept anchors](<docs/05-topic-notes/practical-concept-anchors.md>) is the practical acronym/index layer for terms like IOMMU, page cache, VMA/VAD, PTE/PFN, IRP/MDL, LSM/RCU/eBPF/io_uring, ETW/AMSI, PPL/VBS/HVCI, and CFG/CET. Use it when a term needs expansion plus "how do I observe or use this?" guidance.
- [C++ and modern C++ internals for security researchers](<docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>) is the compiled C++ track for object lifetime, vtables, smart pointers, templates, containers, atomics/opcodes/intrinsics, ABI, optimization, and `.sys` driver reversing implications.
- [Journey PDF source map](<docs/05-topic-notes/journey-pdf-source-map.md>) maps the companion Journey PDFs into the Linux, Windows, Android, networking, security, and forensic study flow.
