# Deep Why Audit

Value Score: 66/100
Role: Structural audit record
Proof Level: Meta

Date: 2026-05-17

Verdict: before this file, there was no real corpus-wide deep-why audit. The prior work added the standard and improved the active files, but it did not prove that every Markdown section met the standard. This file records the first structural pass and the remaining manual-review queue.

## Scope

The audited primary corpus is the Markdown set visible to:

```text
rg --files -g "*.md"
```

That produced 38 Markdown files: `README.md` plus the curated files under `docs/`. Local PDFs, ignored source dumps, and non-Markdown source material were not audited by this pass.

## Checks Run

| Check | Result | Meaning |
|---|---:|---|
| Markdown files enumerated | 38 | Primary Markdown corpus was covered structurally. |
| `docs/02-question-banks` priority rows | 165 | Scored question-bank prompts found. |
| `docs/02-question-banks` best-answer headings | 165 | Every scored prompt has a corresponding best-answer heading. |
| Initial question headings without an obvious causal marker | 3 | All were reviewed; two were navigation/source-map sections and one was a quick comparison answer. |
| Post-fix question headings without an obvious causal marker | 0 | The three hits were clarified in this pass. |
| Leaf sections under 70 words | 161 | Manual-review queue, not automatic failure. Many are source-map rows, short recall cards, or subheads whose parent section carries the explanation. |

## Concrete Findings

The question-bank files have structurally complete answer coverage: the files in `docs/02-question-banks` have matching counts between priority rows and best-answer headings. That does not prove every answer is deep enough, but it does prove they are not merely unanswered prompt lists.

Addendum after adding `docs/02-question-banks/06-cpp-modern-cpp-internals-security-qa.md`: the current Markdown corpus is 39 files. After the Windows Executive, dispatcher-event/`CreateEvent`, threadpool/WorkerFactory, and Linux event/wait monitoring entries were added, the scored question-bank prompt and best-answer heading counts are 202/202. The low-word manual-review queue below remains the original first-pass queue and was not recomputed for this addendum.

Addendum after adding `docs/02-question-banks/07-mobile-os-and-coding-interview-traps-qa.md`: a current `rg --files -g "*.md"` check sees 50 Markdown files. The scored question-bank prompt and best-answer heading counts are 208/208 across 7 question-bank files. The added file is a focused owner for mobile process/thread memory, non-atomic counter races, Fibonacci/runtime tradeoffs, and recursive numeric overflow, with challenge-style source/transcript strings intentionally paraphrased rather than copied. This pass also added the missing priority-index row for the existing C stdio `_unlocked`/`flockfile` answer in the C++ bank.

Addendum after the practical-depth critique: a current `rg --files -g "*.md"` check sees 52 Markdown files. The scored question-bank prompt and best-answer heading counts remain 208/208 across 7 question-bank files. This pass added `docs/99-meta/practical-depth-and-separation-audit.md` to record repeated high-level terms, Linux/Windows entanglement, and missing proof loops, plus `docs/06-hands-on-labs/README.md` as the practical claim-to-evidence spine.

Cleanup addendum: the tracked `linux_internals_interview_project/` draft folder was removed after its useful Linux planning/source-map material had been superseded by the curated `docs/03-linux` track, source maps, and lab spine. This reduces the chance that an old processed draft is mistaken for the current educational path.

The remote-attacker and vulnerability-research companion files are in better shape for the user's target scenario. The first-pass scan found no shallow low-word leaf sections in `docs/05-topic-notes/vulnerability-research-and-exploitation-primitives.md`, and only the source-pointer section was short in `docs/05-topic-notes/remote-attacker-low-level-mechanisms.md`.

The biggest remaining risk is older compact material that was designed for recall or navigation rather than standalone depth. The highest-count files in the low-word queue were:

| File | Low-word leaf sections | Audit interpretation |
|---|---:|---|
| `docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md` | 31 | Needs manual pass over compact Linux/Windows analogy subsections and quick answers. |
| `docs/03-linux/06-veteran-interview-faq.md` | 16 | Rapid-fire FAQ is intentionally short; it should stay as recall only or link each answer to deeper companion sections. |
| `docs/03-linux/02-page-cache-reclaim-allocators.md` | 15 | Several short subheads depend on surrounding context; verify each one states mechanism, invariant, and failure mode clearly enough. |
| `docs/04-windows/08-windows-roadmap-know-cold-explanations.md` | 14 | Mostly compact Windows mechanism summaries; verify authority, boundary, evidence, and current-build caveats. |
| `docs/04-windows/07-windows-low-level-security-resources.md` | 11 | Resource map, not an explanation file; acceptable only if linked targets provide the depth. |

## Reviewed Question-Heading Hits

| File | Heading | Action |
|---|---|---|
| `README.md` | `Are All Questions Answered?` | Clarified that this is a navigation rule, not a claim of deep audit completeness. |
| `docs/03-linux/source-map.md` | `How To Read This` | Clarified why primary/support/future source authority matters. |
| `docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md` | `What is the closest Windows equivalent to fork?` | Expanded the quick answer with the causal Windows process-model reason. |

## Verification After This Pass

Post-fix structural checks:

| Check | Result |
|---|---:|
| Question headings without causal marker | 0 |
| Question-bank priority rows | 165 |
| Question-bank best-answer headings | 165 |
| Question-bank priority/answer count mismatches | 0 |

## Enrichment Pass

After the structural audit, the highest-ROI shallow sections were enriched rather than left as a queue item.

Files deepened in this pass:

| File | Fix |
|---|---|
| `docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md` | Expanded quick Linux/Windows analogy sections with mechanism, authority, evidence, and boundary reasoning. |
| `docs/03-linux/06-veteran-interview-faq.md` | Turned rapid-fire answers into deeper answers that explain object split, invariant, failure mode, and relevance. |
| `docs/04-windows/08-windows-roadmap-know-cold-explanations.md` | Expanded compact Windows token, MIC, AppContainer, LSASS, authentication, callbacks, telemetry, mitigation, and anti-analysis sections. |
| `docs/03-linux/02-page-cache-reclaim-allocators.md` | Added why-depth to anonymous/file-backed memory, folios, reverse mapping, swap, reclaim, memcg, PSI, buddy/per-CPU/slab/vmalloc, and hardening sections. |
| `docs/03-linux/03-entry-exceptions-elf.md` | Added why-depth to interrupts, exceptions, syscalls, entry paths, arm64 differences, deferred work, ELF program headers, loader mapping, PIE/ASLR, GOT/PLT, and evidence paths. |
| `docs/03-linux/07-primitives-mitigations-attacker-patterns.md` | Added mechanism/invariant explanations for primitive reasoning and high-end pattern labels. |

Post-enrichment structural checks:

| Check | Result |
|---|---:|
| Question headings without causal marker | 0 |
| Leaf sections under 70 words | 89 |

The remaining short sections are mostly resource maps, source maps, section headers, or intentionally compact navigational notes. They should still be reviewed over time, but the main mechanism-heavy interview files are materially deeper after this pass.

## What This Audit Does Not Prove

This pass does not prove that every non-trivial fact in every paragraph has a deep causal explanation. Regex markers can miss good explanations and can also mark shallow text as acceptable if it contains the right word. The result is a triage list, not a certificate.

This pass also did not verify every factual claim against current Linux kernels, current Windows builds, public vendor docs, or public research writeups. Build-specific Windows internals, Linux kernel-version details, mitigation availability, and public offensive-research coverage still need source-backed verification when a section is used for interview preparation.

## Next Manual Pass

1. Review `docs/01-comparisons-and-maps/01-linux-vs-windows-internals.md` quick-answer and analogy sections first.
2. Decide whether `docs/03-linux/06-veteran-interview-faq.md` should remain rapid-fire recall only or be expanded into deep answers.
3. Review compact memory-manager sections in `docs/03-linux/02-page-cache-reclaim-allocators.md`.
4. Review compact Windows mechanism summaries in `docs/04-windows/08-windows-roadmap-know-cold-explanations.md`.
5. For each accepted short source-map/resource section, verify it links to a deeper explanation that satisfies `docs/99-meta/why-depth-standard.md`.
