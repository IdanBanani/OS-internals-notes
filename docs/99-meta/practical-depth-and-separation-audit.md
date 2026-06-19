# Practical Depth And Linux/Windows Separation Audit

Value Score: 88/100
Role: Quality and separation gate
Proof Level: Meta

Date: 2026-06-18

Purpose: record the honest state of the repo after the user's depth critique. The issue is not only "are there answers?" The harder issue is whether the notes produce practical, separable operating-system understanding: can a reader prove a claim with code, tools, traces, or source inspection, and can they study Linux without constantly carrying Windows vocabulary in their head, or the reverse?

## Verdict

The project is useful but still too concept-heavy for the stated goal of maximum practical understanding. Several files explain mechanisms deeply enough for interview answers, but the learning path overuses cross-platform comparison and scenario maps before the reader has built clean Linux-only or Windows-only mental models. That makes correct analogies harder to separate from false equivalence.

The previous structural audits checked prompt/answer coverage and shallow section counts. They did not fully solve three problems:

1. Repeated high-level terms: authority, handle/fd, VAD/VMA, token/cred, page table, section/mapping, object lifetime.
2. Entangled Linux/Windows presentation: cross-platform files are prominent enough that they can become the primary path instead of the translation layer.
3. Not enough proof-oriented labs: many claims say what happens, but fewer sections tell the reader exactly how to observe it, falsify it, or build a toy reproduction.
4. Dense abbreviations without teaching anchors: terms such as IOMMU, PTE, PFN, VAD, VMA, IRP, MDL, LSM, RCU, ETW, and AMSI sometimes appear without enough expansion, owner link, or practical use path.

This cleanup also removes the tracked `linux_internals_interview_project/` draft. That folder was useful as raw planning material, but it had already been processed into the curated `docs/03-linux` track and source maps. Keeping it as a second top-level Linux entry point reduced educational value because it mixed local machine paths, time-boxed planning, and source routing beside the cleaner notes.

## Separation Rule

Use platform ownership first, translation second.

| Layer | Owns | Should avoid |
|---|---|---|
| Linux owner docs | `task_struct`, `mm_struct`, VMA, PTE, `struct file`, fd tables, `cred`, capabilities, namespaces, seccomp, LSM, futex, eBPF, io_uring, Binder/Android when explicitly in Android track. | Explaining every Linux idea through a Windows handle/token/VAD analogy. |
| Windows owner docs | Object Manager, handles, granted access, tokens, SRM, VADs, sections, IRPs, dispatcher objects, APC/DPC, ETW, services, ALPC/RPC/COM, PPL/VBS/HVCI. | Explaining every Windows idea through Unix fd/root/process-tree analogies. |
| Cross-platform maps | Semantic translation after one platform model is known: fd vs handle, VMA vs VAD, `mmap` vs section/view, `cred` vs token, LSM/seccomp vs AppContainer/integrity/PPL. | Being the first or only place where a mechanism is learned. |
| Scenario maps | How mechanisms compose in RCE, privilege escalation, agent runtime, telemetry, and persistence scenarios. | Replacing platform mechanism study or becoming a list of technique names. |
| Lab docs | Code, commands, debugger views, traces, and expected observations. | Long theory without a claim-to-evidence loop. |
| Practical concept anchors | Expansion plus "how to observe/use this" for dense abbreviations and compact mechanism names. | Becoming another glossary with no labs, owner docs, or evidence paths. |

The desired mental workflow is:

```text
learn Linux mechanism cleanly
prove it with a Linux experiment
learn Windows mechanism cleanly
prove it with a Windows experiment
then compare the semantics
then apply to security scenarios
```

## Shallow-Repetition Findings

These are the patterns to watch, not accusations that every occurrence is wrong.

| Pattern | Why it feels shallow | Fix |
|---|---|---|
| "X is authority-bearing" repeated across many files. | True, but it becomes a slogan if the reader does not see the table entry, permission check, later use, and failure mode. | Add a lab or walkthrough showing the authority artifact before and after an operation. |
| "VMA/VAD/PTE/page table" repeated in comparison files. | The terms blur if Linux range policy, Windows range policy, and hardware PTE state are introduced together too early. | Keep Linux VMA proof in Linux labs, Windows VAD proof in Windows labs, then compare. |
| "The OS checks policy, hardware enforces" repeated. | Correct but broad. It needs concrete entry state: syscall arguments, object lookup, PTE bits, CPU mode, handle access mask, token/cred. | For each boundary, write one claim-to-evidence card. |
| "Binder/ALPC/RPC/IPC is security-relevant." | It names a surface but not the object lifetime and identity transfer. | Add transaction/handle/fd/message-lifetime labs or trace walkthroughs. |
| "Mitigation X degrades primitive Y." | Good vocabulary, but easy to memorize without seeing what changes in a binary or runtime. | Add build/config experiments: DEP/NX, ASLR/PIE, CFG, stack cookies, sanitizer, verifier, or `/proc`/WinDbg views. |
| "IOMMU/PTE/IRP/ETW/etc." appears without expansion. | The reader may memorize a powerful acronym without knowing the owner layer, evidence source, or practical use. | Link first meaningful use to [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) or a deeper owner doc/lab. |

## Files With Highest Entanglement Risk

| File | Risk | Keep or split? |
|---|---|---|
| `docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md` | Very valuable, but huge and likely to become the reader's first source of truth. It mixes many subsystems by design. | Keep as a translation map. Do not use as first-pass learning. Add links from platform labs back into specific anchors later. |
| `docs/02-question-banks/03-memory-filesystems-network-qa.md` | Cross-platform memory/files/network answers can blur platform ownership. | Keep for after platform-specific memory/file/network labs. |
| `docs/01-comparisons-and-maps/04-process-memory-access-and-memory-api-flags.md` | Useful but easy to read as API equivalence. | Keep, but require Linux and Windows process-memory labs first. |
| `docs/05-topic-notes/remote-attacker-low-level-mechanisms.md` | Scenario-first map can overload a learner with both OSes, attack stages, and telemetry at once. | Keep as the security scenario map after mechanism/lab passes. |
| `docs/05-topic-notes/attacker-relevant-structures-and-components.md` | High-density list of structures and attacker uses. | Keep as a checklist after labs. It should not be the first explanation of the structures. |

## Practical Depth Standard

A section is "deep enough" only when the reader can answer all six:

| Check | Question |
|---|---|
| Mechanism | What exact object/table/path changes? |
| Authority | Which credential, handle, fd, token, capability, label, privilege, or policy decides access? |
| Transition | Which boundary is crossed: user/kernel, process/process, file/path/object, broker/client, device/memory, kernel/hypervisor? |
| Invariant | What must remain true for correctness or security? |
| Failure mode | What breaks if the invariant is false? |
| Evidence | What command, trace, debugger view, source file, or toy code proves or falsifies the claim? |

The missing part in the repo is usually the last row: evidence.

## High-ROI Lab Backlog

These labs should be the next practical spine. They are safe, local, and proof-oriented.

| Priority | Lab | Claim it proves |
|---:|---|---|
| 1 | Linux VMA/page-fault/COW lab | `mmap`, `fork`, first write, page faults, RSS/PSS, and COW are observable, not just vocabulary. |
| 2 | Linux fd/VFS/page-cache lab | `openat`, fd tables, `struct file` lifetime, deleted-open files, and page cache behavior differ from path strings. |
| 3 | Linux credentials/capability/namespace lab | UID 0, capabilities, namespaces, and LSM/seccomp are separate authority layers. |
| 4 | Windows handle/token/access-check lab | A handle carries granted access, and later operations use the handle's access mask rather than reopening the path/name. |
| 5 | Windows VAD/section/view lab | `VirtualAlloc`, `CreateFileMapping`, `MapViewOfFile`, image-backed memory, private dirty pages, and protection changes are visible in VMMap/WinDbg. |
| 6 | Windows IPC/impersonation lab | Named-pipe/RPC-style server authority depends on endpoint DACLs, client identity, SQOS/impersonation level, and timing. |
| 7 | C/C++ race and optimizer lab | Data-race UB, atomics, `volatile`, `-O0` vs `-O3`, and x86/AArch64 lowering are different layers. |
| 8 | Loader/ASLR/import lab | ELF/PE loader state, relocations, imports, and runtime API resolution are visible in tools and memory maps. |

The initial lab owner is [Hands-on labs](<../06-hands-on-labs/README.md>).

The initial acronym/practical-use owner is [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>).

The first runnable code owner is [Practical snippet pack](<../06-hands-on-labs/01-practical-snippet-pack.md>). Use it when a claim needs a toy program instead of another paragraph.

## Recommended Refactor Direction

Do not delete the big cross-platform maps yet. They contain useful synthesis. Instead:

1. Add lab-backed platform spines first.
2. Add a small "Before comparing, prove these" checklist at the top of major cross-platform files.
3. Move repeated high-level slogans into owner docs only when the repetition is not adding a new boundary, failure mode, or evidence source.
4. Add explicit "Linux-only model" and "Windows-only model" summaries before cross-platform comparison tables.
5. Treat cross-platform maps as indexes of semantic differences, not as the main teaching text.

The target standard is not "shorter." It is "every important claim eventually points to proof."

## Quality Gate For Future Notes

Do not add or keep a note just because it contains correct facts. Keep it only if it has a job in the learning system.

### Value Score Scale

Each curated Markdown document should carry a compact metadata block directly under its H1 title:

```text
Value Score: N/100
Role: owner / comparison / roadmap / source map / lab / archive / meta
Proof Level: lab-backed / lab-routed / source-backed / conceptual / source-map / meta
```

Use the score as a triage signal, not as decoration.

| Score | Meaning |
|---:|---|
| 90-100 | Core owner, lab spine, or primary path. Removing it would damage the learning system. |
| 80-89 | High-value focused note or comparison that should stay, but may need more proof/captured evidence. |
| 70-79 | Useful router, source map, recall aid, or support note. It should not pretend to be the main explanation. |
| 60-69 | Low-to-medium support value. Keep only if it routes to better material or preserves a useful source map. |
| 50-59 | Archive or old summary. Delete, merge, or demote when its useful content has been processed. |
| Below 50 | Usually should not remain in the curated repo. Move out of the public path or delete after processing. |

| Keep | Delete, merge, or demote |
|---|---|
| Platform owner doc with mechanism, invariant, failure mode, evidence, and labs. | Duplicate roadmap/source-map text after the curated owner exists. |
| Cross-platform map that explains semantic differences after platform models are learned. | Comparison table that becomes the first explanation of both platforms. |
| Lab note that proves a claim with local code/tool evidence. | Abstract "important terms" list with no experiment, source path, or owner link. |
| Source map that points to current primary sources and states freshness caveats. | Machine-specific path dump or raw reading list that has already been processed. |
| Scenario map that composes already-understood mechanisms into security reasoning. | Technique-name pile that does not explain authority, boundary, invariant, or telemetry. |

Before keeping a large file, ask:

1. What can the reader do after reading it that they could not do before?
2. Which platform owns the mechanism?
3. Which lab or tool view proves the main claim?
4. Which existing file would become redundant if this stays?
5. Is this curated output, or is it raw material that has already served its purpose?
