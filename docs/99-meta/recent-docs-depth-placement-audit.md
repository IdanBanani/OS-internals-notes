# Recent Docs Depth And Placement Audit

Value Score: 68/100
Role: Placement/depth audit
Proof Level: Meta

Date: 2026-05-19

Scope: Markdown files added since 2026-05-05 according to git history, plus currently edited recent companions. This is a depth and placement audit for the broad recent-doc set, not only the x86/ring0 cluster.

Depth score is 1-10 for causal explanation quality: mechanism, authority, boundary, invariant, failure mode, relevance, constraints, and evidence. A 10 would be book-chapter or deep-dive blogpost quality with concrete source/build walkthroughs.

Placement score is 1-10 for whether the content lives in the right file and routes to the right owner. Some files intentionally have lower depth because they are navigation or source-map files.

## Ownership Rules

- README and roadmap files own reading order, priority, and routing. They should not become deep mechanism notes.
- Question banks own active recall and direct answers. They should explain enough to answer without chasing five links.
- Cross-platform maps own analogy and boundary translation. They should link to topic notes for mechanism depth.
- Topic notes own deep mechanism explanations for a focused area.
- Source maps and resource maps own source placement and freshness caveats. Low depth is acceptable when routing is strong.
- Meta files own audit state, coverage, and writing standards.

## High-ROI Findings

- The recent set is not uniformly shallow. The six question banks, the Windows source-enriched mechanism note, the Linux/Windows comparison, the component map, and the major security topic notes are already substantive.
- The highest placement risk is broad topic overlap: memory/PTE/page-table concepts appear in the component map, hardware Q&A, process-memory map, Linux memory notes, Windows memory notes, and the glossary. The fix is ownership rules, not deleting every repeated sentence.
- The weakest "depth versus title" files are mostly resource maps, roadmaps, and source maps. That is acceptable if they clearly route to deeper owner docs.
- The strongest future depth ROI is source-level walkthroughs for a few high-value paths: Windows handle open/access check, Windows IOCTL/IRP dispatch, Linux page fault/reclaim, Linux syscall/entry, and one end-to-end loader/memory mapping trace.

## Priority-Ordered Scores

Reader value answers: after reading this file, what concrete understanding or capability should the reader gain? Sorted by `priority = 0.50 * importance + 0.35 * depth + 0.15 * placement`. Importance means centrality to the repo's offensive low-level security goal, not file size. Lower-depth routing/source-map files can still be important, but they should not outrank deep mechanism owners unless they are core entry points.

| Rank | File | Importance | Depth | Placement | Reader value | Priority | Best next action |
|---:|---|---:|---:|---:|---|---:|---|
| 1 | `docs/01-comparisons-and-maps/02-low-level-security-component-map.md` | 9.9 | 9.0 | 9.2 | Learn who really enforces each boundary and why that enforcement makes sense. | 9.48 | Primary mental-model map |
| 2 | `docs/05-topic-notes/remote-attacker-low-level-mechanisms.md` | 10.0 | 8.9 | 8.5 | Map RCE or privilege escalation to the OS agents, objects, checks, and failure modes involved. | 9.39 | Top scenario map; maybe split later |
| 3 | `docs/04-windows/06-source-enriched-windows-mechanisms.md` | 9.8 | 8.8 | 8.7 | Build Windows mechanism vocabulary with source and symbol anchors instead of memorized slogans. | 9.28 | High ROI source-citation target |
| 4 | `docs/02-question-banks/02-windows-deep-understanding-qa.md` | 9.7 | 8.8 | 8.8 | Self-test whether Windows internals answers are causal, precise, and interview-ready. | 9.25 | Refresh build-specific claims later |
| 5 | `docs/05-topic-notes/attacker-relevant-structures-and-components.md` | 9.6 | 8.7 | 8.4 | Know which structures attackers care about, what authority they carry, and what corrupting them changes. | 9.10 | Consider future split |
| 6 | `docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md` | 9.6 | 8.5 | 8.5 | Transfer Linux intuition to Windows, and Windows intuition to Linux, without false equivalence. | 9.05 | Consider future split |
| 7 | `docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md` | 9.1 | 8.8 | 8.7 | Reason about C++ object lifetime, ABI, allocator, and concurrency bugs at exploit-relevant depth. | 8.94 | Strong deep-dive Q&A |
| 8 | `docs/05-topic-notes/windows-object-handles-references-and-tokens.md` | 9.2 | 8.5 | 8.9 | Understand handles, references, tokens, and access checks as separate authority and lifetime mechanisms. | 8.91 | High ROI access-check walkthrough target |
| 9 | `docs/05-topic-notes/paging-residency-page-lists-and-shared-memory.md` | 9.1 | 8.6 | 9.0 | Understand residency, backing store, page tables, PTE/PFN state, pinning, and shared mappings. | 8.91 | High ROI source walkthrough target |
| 10 | `docs/04-windows/08-windows-roadmap-know-cold-explanations.md` | 9.2 | 8.4 | 8.8 | Turn Windows roadmap checklist items into explanations you can defend under questioning. | 8.86 | Strong explanation companion |
| 11 | `docs/05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md` | 9.1 | 8.4 | 8.8 | Understand Windows sections, kernel/user mappings, privilege checks, and ASLR as interacting mechanisms. | 8.81 | Strong focused owner |
| 12 | `docs/01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md` | 9.1 | 8.4 | 8.8 | Compare cross-process memory APIs and flags by what validation, copying, and authority they imply. | 8.81 | Keep as bridge |
| 13 | `docs/03-linux/01-address-space-mm.md` | 9.1 | 8.4 | 8.8 | Understand Linux `mm_struct`, VMAs, faults, page tables, and permission checks as one path. | 8.81 | High ROI source walkthrough target |
| 14 | `docs/02-question-banks/01-linux-deep-understanding-qa.md` | 9.0 | 8.5 | 8.8 | Self-test Linux internals answers beyond names of structs and subsystems. | 8.80 | Strengthen source links later |
| 15 | `docs/05-topic-notes/x86-privilege-rings-descriptors-and-syscall-entry.md` | 8.8 | 8.7 | 9.0 | Understand x86 privilege enforcement under the hood: CPL, DPL, page bits, gates, MSRs, and entry paths. | 8.80 | Strong after expansion |
| 16 | `docs/02-question-banks/03-memory-filesystems-network-qa.md` | 9.0 | 8.3 | 8.7 | Self-test memory, filesystem, and networking explanations across Linux and Windows. | 8.71 | Network depth can grow |
| 17 | `docs/02-question-banks/05-hardware-security-relationship-qa.md` | 9.0 | 8.2 | 8.8 | Connect OS security decisions to hardware enforcement such as page bits, exception levels, DMA, and SLAT. | 8.69 | Good companion-linked Q&A |
| 18 | `docs/05-topic-notes/vulnerability-research-and-exploitation-primitives.md` | 8.9 | 8.2 | 8.6 | Reason about exploitation primitives and mitigations conceptually without treating them as magic labels. | 8.61 | Keep conceptual and safe |
| 19 | `docs/05-topic-notes/windows-ipc-named-pipes-rpc-alpc-security.md` | 8.8 | 8.2 | 8.8 | Understand Windows IPC and broker boundaries through object namespaces, tokens, ACLs, RPC, and ALPC. | 8.59 | Deepen ALPC/RPC later |
| 20 | `docs/02-question-banks/04-binary-loaders-linkers-qa.md` | 8.8 | 8.1 | 8.8 | Self-test ELF, PE, loader, linker, relocation, import, and mapping internals. | 8.56 | Add loader walkthroughs later |
| 21 | `docs/05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md` | 8.6 | 8.0 | 8.7 | Understand heap/runtime/toolchain behavior as the user-mode substrate for memory bugs and mitigations. | 8.40 | Deepen allocator internals later |
| 22 | `docs/03-linux/03-entry-exceptions-elf.md` | 8.6 | 7.9 | 8.6 | Understand Linux syscall entry, exceptions, signal delivery, and ELF loading at a practical level. | 8.35 | Add syscall/exception walkthrough |
| 23 | `docs/05-topic-notes/low-level-security-critical-terms.md` | 8.5 | 7.6 | 9.2 | Quickly disambiguate dense low-level terms and know which owner doc explains each one deeply. | 8.29 | Keep compact |
| 23a | `docs/05-topic-notes/practical-concept-anchors.md` | 8.8 | 7.8 | 9.1 | Expand dense acronyms and route them to practical experiments, evidence paths, and owner docs. | 8.52 | Keep as acronym-to-practice index |
| 24 | `docs/03-linux/02-page-cache-reclaim-allocators.md` | 8.5 | 7.8 | 8.5 | Understand Linux page cache, reclaim, writeback, slab allocation, and pressure behavior. | 8.26 | Deepen reclaim/slab later |
| 25 | `docs/03-linux/08-linux-android-memory-vulnerability-research.md` | 8.5 | 7.6 | 8.3 | Connect Linux and Android memory internals to vulnerability research questions. | 8.16 | Keep scenario-focused |
| 26 | `docs/00-offensive-low-level-security-researcher-path.md` | 8.8 | 6.7 | 9.4 | Choose the highest-value reading path for low-level offensive security study. | 8.15 | Keep routing-focused |
| 27 | `docs/01-comparisons-and-maps/05-related-system-calls-and-api-semantics.md` | 8.3 | 7.6 | 8.9 | Avoid confusing similar APIs and syscalls by comparing semantics, authority, and side effects. | 8.14 | Good disambiguation |
| 28 | `docs/03-linux/07-primitives-mitigations-attacker-patterns.md` | 8.3 | 7.4 | 8.4 | Frame Linux primitives and mitigations in terms of object corruption, control transfer, and policy bypass. | 8.00 | Add concrete examples later |
| 29 | `docs/03-linux/05-architecture-special-cases.md` | 7.9 | 7.5 | 8.5 | Recognize architecture-specific caveats before overgeneralizing from x86 or one kernel build. | 7.85 | Good caveat router |
| 30 | `docs/01-comparisons-and-maps/03-arm-architecture-differences.md` | 7.8 | 7.4 | 8.8 | Translate x86 assumptions to ARM/AArch64 exception levels, page attributes, and interrupt architecture. | 7.81 | Add source-level ARM later |
| 31 | `docs/03-linux/06-veteran-interview-faq.md` | 7.7 | 7.6 | 8.1 | Rapid-drill senior Linux interview topics and identify weak explanations. | 7.72 | Recall format is fine |
| 32 | `docs/03-linux/04-android-internals.md` | 7.8 | 7.3 | 8.2 | Orient Android runtime, Binder, SELinux, zygote, and platform-specific security internals. | 7.68 | Deepen Binder/ART/SELinux later |
| 33 | `docs/04-windows/04-flareon-windows-internals-notes.md` | 7.8 | 7.2 | 8.0 | Learn Windows internals through concrete reverse-engineering and challenge-style case studies. | 7.62 | Keep as support examples |
| 34 | `docs/99-meta/recent-docs-depth-placement-audit.md` | 7.6 | 7.0 | 9.1 | See the recent-doc set by priority, depth, placement, and reader payoff. | 7.62 | Human-readable audit index |
| 35 | `docs/04-windows/01-windows-long-term-mastery-roadmap.md` | 8.0 | 7.1 | 8.9 | Plan Windows mastery modules by dependency, evidence, and deeper owner docs instead of calendar pressure. | 7.91 | Route to know-cold explanations and labs |
| 36 | `docs/03-linux/09-modern-linux-mm-reading-map.md` | 7.3 | 6.7 | 8.8 | Find current Linux memory-management source material without wasting time on stale routes. | 7.32 | Correct source-routing role |
| 37 | `docs/99-meta/why-depth-standard.md` | 7.0 | 7.0 | 9.0 | Apply the repo's depth standard when judging or editing a doc. | 7.30 | Keep concise |
| 38 | `docs/03-linux/source-map.md` | 7.1 | 6.5 | 8.7 | Find Linux source anchors quickly for major subsystem topics. | 7.13 | Keep source-routing role |
| 39 | `docs/03-linux/README.md` | 7.1 | 6.4 | 8.8 | Navigate the Linux track and pick the next Linux doc intelligently. | 7.11 | Keep routing-focused |
| 40 | `docs/99-meta/coverage-audit.md` | 6.8 | 6.5 | 8.8 | See coverage, gaps, and where the repo needs more depth. | 7.00 | Meta summary only |
| 41 | `README.md` | 7.0 | 6.0 | 9.2 | Navigate the full repository and choose the right starting point. | 6.98 | Use for routing only |
| 42 | `docs/99-meta/deep-why-audit.md` | 6.7 | 6.4 | 8.8 | See structural deep-why audit status and recurring explanation gaps. | 6.91 | Meta audit only |
| 43 | `docs/05-topic-notes/digital-whisper-134-185-internals-map.md` | 6.8 | 6.1 | 8.4 | Place Digital Whisper papers by topic and decide which ones support which docs. | 6.80 | Keep source-map role |
| 44 | `docs/04-windows/05-local-hebrew-paper-reading-map.md` | 6.7 | 6.0 | 8.3 | Place local Hebrew Windows papers into the Windows internals study path. | 6.69 | Keep source-map role |
| 45 | `docs/04-windows/07-windows-low-level-security-resources.md` | 6.7 | 5.9 | 8.5 | Find Windows low-level security resources and know which deeper doc they support. | 6.69 | Keep resource-routing role |
| 46 | `docs/04-windows/02-windows-case-study-resource-map.md` | 6.5 | 5.9 | 8.3 | Place Windows case-study resources beside the mechanism modules they reinforce. | 6.58 | Keep as resources only |
| 47 | `docs/05-topic-notes/journey-pdf-source-map.md` | 6.2 | 5.8 | 8.8 | Place Journey PDFs in the study plan without duplicating their content. | 6.45 | Keep shallow and fresh |

## Highest-ROI Future Upgrades

1. Add source-level walkthroughs for a few representative paths instead of expanding every doc equally:
   - Windows: `OpenProcess`/handle access check, IOCTL-to-IRP dispatch, section mapping, process memory read/write.
   - Linux: syscall entry to handler, page fault to PTE update, reclaim/writeback, fd open to VFS object.
2. Split only the largest topic notes if navigation becomes painful:
   - `attacker-relevant-structures-and-components.md`
   - `remote-attacker-low-level-mechanisms.md`
   - possibly `01-linux-vs-windows-internals.md`
3. Keep source maps shallow and explicit. Their job is to route to authoritative material, not to duplicate it.
4. Improve primary-source freshness for Windows build-specific claims: PPL, HVCI/VBS, PatchGuard-adjacent statements, WDAC, vulnerable-driver blocklist, and kernel CET.

## Immediate Changes From This Audit

- Added ownership/placement rules to the component map, glossary, and paging note.
- Replaced the time-boxed Windows routing files with long-term module/resource-map language and removed the obsolete Windows recap.
- Deepened the x86 note with non-syscall transition mechanisms and the distinction between CPL transition and post-ring0 driver/rootkit operations.
- Recorded this broad audit so future edits can target low-depth owner docs rather than expanding navigation/resource files.
