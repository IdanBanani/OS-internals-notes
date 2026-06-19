# Deep Why Standard

Value Score: 78/100
Role: Writing standard
Proof Level: Meta

Date: 2026-05-17

Purpose: make the writing standard explicit. These notes are interview preparation for security internals. A non-trivial fact, term, mechanism, or question is not complete unless it explains the underlying "why" deeply enough to survive follow-up pressure.

## Rule

For every non-trivial claim or question, include the causal model, not just the label.

Bad shape:

```text
Windows handles are important.
```

Good shape:

```text
Windows handles are important because a handle is a per-process, rights-bearing reference to a typed kernel object. The granted access mask is checked by later operations, so authority can move through inheritance or duplication even when the target path/name would not pass a fresh open check.
```

## Required Depth Checks

Use these checks when writing or auditing a Markdown section:

| Check | Question the text must answer |
|---|---|
| Mechanism | What object, structure, API path, table, mapping, token/cred, fd/handle, request, or policy is actually involved? |
| Causality | Why does this mechanism exist, and what problem does it solve? |
| Authority | Who is allowed to act, and where is that authority represented? |
| Boundary | What trust boundary is crossed: user/kernel, process/process, broker/client, host/container, kernel/hypervisor, OS/firmware, device/memory? |
| Invariant | What must remain true for security or correctness? |
| Failure mode | What breaks if the invariant is violated? |
| Attacker/agent relevance | Why does this matter for 0/1-click RCE+PE-to-agent security internals or, secondarily, exploitability? |
| Constraint | Which build, policy, mitigation, sandbox, architecture, privilege, or runtime condition changes the answer? |
| Evidence | What independent view proves or disproves the statement: symbols, source, logs, ETW/audit, `/proc`, handles, VADs/VMAs, memory dump, packet capture, file ID, signer, token? |
| Comparison | If Linux and Windows differ, what is the real semantic difference rather than the nearest analogy? |

## Acronym And Dense-Term Rule

An abbreviation is not a teaching shortcut. On first meaningful use of dense terms such as IOMMU, PTE, PFN, VAD, VMA, page cache, IRP, MDL, LSM, RCU, eBPF, io_uring, ETW, AMSI, PPL, VBS, HVCI, CFG, or CET, the text should expand the term or link to [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) / an owner doc.

The local section should also answer at least one practical question:

- What command, toy program, trace, debugger view, or source file teaches this term?
- What security or correctness decision changes when this object/state exists?
- Which lab proves that the term is not only vocabulary?

## Question-Answer Standard

Every question in a question bank or topic note should have an answer that includes:

1. Direct answer in one or two sentences.
2. Mechanism chain.
3. Why it matters for the main interview scenario.
4. One edge case or caveat.
5. Evidence or validation path.

If an answer only defines vocabulary, it is incomplete.

## Fact Standard

Every non-trivial factual statement should satisfy at least one of these:

- It explains why the fact matters.
- It explains how the mechanism works underneath.
- It names the authority/boundary/invariant involved.
- It links to a deeper companion section that does those things.

Short index rows and reading-map bullets may be concise, but the linked target must provide the deep why.

## Audit Markers

Flag a section for expansion when it contains:

- A list of terms with no causal explanation.
- Acronyms or dense mechanism names with no expansion, owner link, or practical evidence path.
- "X is important" without "because".
- API names without object/authority semantics.
- Attack or defense technique names without the underlying OS mechanism.
- A Linux/Windows analogy without the key difference.
- A mitigation name without the primitive it degrades.
- A structure name without lifetime, ownership, and visibility rules.
- A persistence item without writer, consumer, trigger, identity, ACL, and rollback model.

## Priority

When time is limited, deepen these first:

1. Security boundaries: tokens/creds, handles/fds, privileges/capabilities, integrity, AppContainer, namespaces, seccomp, LSM, PPL.
2. Memory and loading: VMA/VAD, PTE, sections, COW, image/private/mapped memory, ELF/PE loader state, JIT/generated code.
3. RCE+PE-to-agent path: client context, sandbox escape, PE boundary, agent authority, collection, communication, telemetry, persistence.
4. Kernel/driver surfaces: syscalls, IOCTLs, IRPs/MDLs, BPF, io_uring, netfilter/WFP, callbacks, minifilters.
5. Vulnerability research: bug class to primitive, constraints, mitigations, reliability, safe validation.

The standard is not "make every file long." The standard is "do not leave a non-trivial statement as a memorized label when a real interviewer can ask why."
