# 07. From Bug to Primitive: Researcher Mental Models, Mitigations, and High-End Attacker Patterns

Value Score: 82/100
Role: Linux primitive reasoning
Proof Level: Conceptual

This file is intentionally conceptual. It focuses on how experienced researchers think, not on exploit procedures.

## 1. Think in primitives, not CVE labels

Bug names are weak descriptions. Primitives are what matter.

Examples of primitives:

- relative read
- relative write
- arbitrary read
- arbitrary write
- controlled free
- type confusion
- refcount corruption
- stale-pointer reuse
- page-table or mapping-metadata corruption
- pure info leak

A senior interviewer usually wants to hear how you translate:

```text
bug class -> primitive -> stability constraints -> mitigations -> impact
```

The reason this translation matters is that a bug name does not tell you what control the researcher actually has. A UAF, overflow, race, or missing check can each collapse into very different primitives depending on allocator state, lifetime, reachable objects, mitigations, and the authority of the calling context.

## 2. Metadata beats bulk data

Attackers usually prefer corrupting metadata over large raw buffers.

Why:

- metadata changes interpretation
- small changes can affect large regions
- policy objects often multiply power

High-value metadata examples:

- VMA bounds or flags
- page-table entries
- refcounts
- function pointers / callbacks
- allocator freelist metadata
- Binder object metadata
- credentials or policy fields
- runtime or loader dispatch structures

Metadata matters because it tells the system how to interpret data, not merely what the data is. A small metadata change can resize a buffer, redirect a dispatch path, change a page's permissions, alter an object's lifetime, or change who the kernel believes has authority.

## 3. Life-cycle violations are usually stronger than plain bounds violations

A temporal bug often gives better leverage than a spatial bug because it attacks ownership:

- use-after-free
- double free
- stale reference after deferred teardown
- pinning/revoke mismatch
- refcount underflow/overflow

Why these are so powerful:

- validation logic often still trusts the stale object identity
- the slot can be reclaimed as a different type
- cross-context reuse becomes possible

---

> **▸ Case Study — io_uring linked-timeout UAF (CVE-2022-29582)**
>
> **What broke:** In Linux io_uring, a "linked timeout" is a special request that automatically cancels its predecessor request if it fires. When the parent request was cancelled and the linked timeout fired simultaneously, two independent code paths both attempted to release the same `io_kiocb` (I/O completion block) object. The reference counting between the cancellation path and the timeout-firing path was not properly coordinated, producing a double-decrement that freed the object while a stale reference still existed in the timeout path.
>
> **Primitive gained:** Use-after-free on a `kmalloc-256` slab object (`io_kiocb` is approximately 256 bytes). With slab grooming using `sendmsg()` to fill the freed slot with a controlled `msg_msg` structure, the stale reference provided a controlled write into the groomed object's body. This was escalated to an arbitrary kernel write via the standard `msg_msg.m_ts` oversizing technique.
>
> **Why it worked:** The lifecycle of an io_uring request is complex — it can be referenced by the submission queue, completion callbacks, linked request chains, timeout mechanisms, and cancellation paths simultaneously. Reference drops in each path were meant to be coordinated, but the linked-timeout + cancellation interaction created a window where two paths each believed they held the last reference. This is a pattern that recurs across io_uring: the async machinery creates many implicit lifetime relationships between objects that are easy to get subtly wrong.
>
> **In the wild:** Discovered and weaponized by Bing-Jhong Billy Jheng (DEVCORE Research Team), 2022. Full root exploit demonstrated on Ubuntu 22.04 kernel. io_uring-sourced UAFs became one of the most productive kernel vulnerability classes of 2021–2023, with multiple distinct CVEs exploited publicly.
>
> **What changed:** The specific reference counting bug was patched. More broadly, Linux security policies began restricting io_uring access by default: some distributions disabled io_uring for unprivileged users, and Android explicitly disables io_uring in its seccomp-bpf policy for apps, recognizing it as a structurally complex and historically bug-rich surface.

---

## 4. Info leak quality often determines the whole chain

Modern systems layer:

- ASLR / KASLR
- PAC
- MTE
- RELRO
- W^X
- CET / BTI / CFI-like hardening

So in practice:

- a great write with no layout knowledge may be weak
- a great leak can turn an ordinary primitive into a reliable chain

Senior-level sentence:

> Reliability often depends more on the leak than on the corruption primitive.

---

> **▸ Case Study — KASLR defeat and the value of a single kernel pointer leak**
>
> **What broke (as a class):** KASLR randomizes the kernel's virtual base address at boot, adding entropy to prevent attackers from using hard-coded addresses in write primitives. In principle, an attacker with a write primitive but no layout knowledge cannot reliably target a function pointer, a `cred` struct, or a page-table entry without first knowing where in the virtual address space the kernel image landed.
>
> **Primitive gained from a single pointer leak:** Any kernel virtual address that falls within the kernel image or kernel data region immediately reveals the KASLR slide, because the kernel image is loaded as a single contiguous block and its internal layout (symbol offsets) is public for the running kernel version. One leaked kernel text pointer → full image base → all symbol offsets → precise addresses of `cred` structs, function tables, and page-table pages. One leaked kernel stack pointer may reveal the per-CPU offset. One leaked heap pointer to a well-known object type may reveal both the SLUB cache address and slab base.
>
> **Why this multiplies primitive value:** A write primitive without a leak is often useless: blind writes to guessed addresses crash the system. A write primitive paired with even a single controlled kernel pointer is often sufficient to complete the chain. This asymmetry means that a research investment into leak quality — finding better read primitives, wider-range OOB reads, or information disclosures in procfs, sysfs, or IPC paths — directly multiplies the value of any write primitive found separately.
>
> **In the wild:** Virtually every modern kernel LPE chain published since ~2017 includes an explicit KASLR defeat step. Common techniques include: OOB reads off heap objects with known neighbor structures, `msg_msg`-based OOB reads after size-field corruption, procfs or `/proc/kallsyms` (restricted on hardened configs), side-channel inference of kernel allocations, and Spectre-class transient-execution disclosures. The Sequoia (CVE-2021-33909) and Dirty Pipe (CVE-2022-0847) exploits both include explicit KASLR defeat before the privilege escalation step.
>
> **What changed:** Kernel `perf` event access was restricted, `/proc/kallsyms` was made unreadable without `CAP_SYSLOG`, and numerous info-disclosure CVEs in procfs, sysfs, and driver interfaces were patched. These are all "close the leak" fixes rather than "harden against the write." This confirms the research community's view that leaks are often the operative bottleneck.

---

## 5. Common high-end reasoning patterns

### Reinterpretation

Take bytes allocated for one type and reclaim or reinterpret them as another type.

The invariant being broken is type identity. Code still follows the old pointer or callback path, but the bytes now belong to a different object layout with different fields and meaning.

### Aliasing

Arrange for the same physical or logical resource to be visible through two views with different assumptions.

The power comes from policy mismatch. One view may be read-only, file-backed, or private while another view can write, pin, map, or observe the same underlying resource.

### Fault-time orchestration

Use demand paging, COW, or fault-driven behavior as a synchronization surface.

The key idea is that faults are not just errors; they are moments when the kernel resolves ownership, backing, permissions, and residency. Racing that resolution can expose stale assumptions.

### Deferred cleanup abuse

Exploit the gap between "logically dead" and "actually unreachable."

Deferred cleanup is dangerous because timers, workqueues, RCU callbacks, completion handlers, and async requests can keep references alive after the apparent owner has moved on.

### Data-only impact

Skip raw PC control if policy or credential state is enough to win.

This works because many security decisions are data decisions. Changing credentials, flags, access masks, labels, or dispatch metadata can produce the desired authority without redirecting instruction pointer control.

### Cross-layer mismatch

Exploit the gap between what MM believes, what the allocator believes, what the runtime believes, and what policy still enforces.

These mismatches are common because each layer caches a different truth. The MMU enforces PTEs, the allocator tracks object lifetime, the loader tracks modules, and policy code tracks identity; impact appears when those truths diverge.

## 6. Classes of "creative tricks" good researchers talk about

Without being procedural, these are the kinds of tricks senior people recognize:

- targeting metadata instead of payload buffers
- converting private/file-backed transitions into semantic confusion
- abusing shared-memory or IPC object lifetime rather than only buffer parsing
- turning a fault or pin into a timing primitive
- using one leak to neutralize multiple mitigations at once
- preferring data-only persistence or policy change when control-flow is too expensive
- chaining app compromise, service compromise, kernel bug, and policy escape instead of expecting one bug to do everything

That is much closer to how real high-end chains are reasoned about than the old "smash stack, jump to shellcode" mental model.

## 7. Syscall surfaces that signal "researcher thinking"

At a conceptual level, experienced people pay attention to interfaces that are:

- structurally complex
- heavily asynchronous
- rich in lifetime/state transitions
- hard to monitor from simple syscall hooks

Examples of categories worth naming in interviews:

- fault-related interfaces like `userfaultfd`
- high-performance async submission/completion interfaces
- cross-process memory access interfaces
- shared-memory / buffer-passing interfaces
- highly structured IPC like Binder

The point is not to list "dangerous syscalls." The point is to explain why some interfaces are disproportionately rich in race surfaces, hidden work, or state machines.

## 8. Mitigations should be described as primitive degraders

The mature way to describe hardening:

- NX/W^X degrades direct code-injection value
- RELRO degrades writable-relocation abuse
- PAC degrades raw pointer corruption value
- MTE degrades many spatial/temporal heap tricks
- Scudo degrades immediate reuse and silent heap corruption
- SELinux/seccomp degrade post-compromise freedom and reachable kernel surface

Good phrase:

> Mature exploitation is mostly about finding the residual primitive after the obvious primitive has been degraded by hardening.

---

> **▸ Case Study — Mitigation stacking in a full Android chain (conceptual composition)**
>
> **The scenario:** An attacker has an n-day kernel UAF bug on a target Android device. The device runs a recent Android version with: KASLR enabled, SMEP/PXN preventing user-shellcode injection, Scudo for native userspace heap, SELinux enforcing with a strict app domain, and seccomp filtering most unusual syscalls for app processes.
>
> **How each mitigation degrades the straightforward path:**
>
> — *KASLR* means a blind write to a guessed kernel address will crash the device. A KASLR-defeating leak step is required before the write primitive can be usefully targeted. The UAF alone is not sufficient.
>
> — *SMEP/PXN* means placing shellcode in userspace memory and redirecting kernel execution to it is blocked at the hardware level. The primitive must be used for data corruption or a ROP/JOP chain entirely within kernel text.
>
> — *Scudo* in the app process means the native heap in the attacking process has quarantine and header isolation. Grooming the kernel slab from the app requires syscall-accessible primitives (`msgsnd`, `sendmsg`, socket buffers) rather than relying on userspace heap adjacency.
>
> — *SELinux app domain* means that even if kernel root UID is achieved, the process's SELinux context is still `untrusted_app`. Accessing sensitive files, communicating with privileged services, or installing persistence requires either a separate SELinux bypass, a transition to a less-confined process, or a data-only path (writing directly to sensitive kernel structures like credentials) that doesn't require filesystem or IPC access.
>
> — *seccomp* filter means io_uring, `userfaultfd`, and other rich async surfaces may be entirely blocked for app processes, narrowing the available grooming and timing primitives.
>
> **The residual path:** The remaining viable approach involves: (1) a `msg_msg`-based slab grooming technique using `msgsnd()` (typically not seccomp-filtered); (2) a leak step through the groomed object to defeat KASLR; (3) a `cred`-overwrite data-only privilege escalation to root UID; (4) a second capability — either a separate SELinux policy bug or a privileged transition path — to escape the SELinux app domain. The chain requires at least two bugs, not one.
>
> **What this illustrates:** The mitigations did not prevent exploitation of the UAF. They forced the attacker from a simple one-bug code-execution chain into a more complex multi-step chain. That is exactly what "primitive degraders" means in practice: each layer shifts the cost upward and forces composition of multiple bugs or techniques.

---

## 9. Why mercenary-grade chains feel different

At a very high level, high-end attackers typically optimize for:

- stealth
- reliability
- minimal crash rate
- clean staging
- flexible post-exploitation under policy constraints

That usually means:

- strong leaks
- precise targeting
- multi-bug chains
- policy-aware post-exploitation
- less dependence on noisy or brittle one-shot payload ideas

This is why interviews referencing groups like NSO often sound different from commodity exploit discussions. The emphasis is not only on "can you get code execution?" but on "can you reason about the whole chain under real mitigations and operational constraints?"

## 10. The short version to say aloud

If you want one compact answer that sounds senior:

> I try to reduce every bug to the primitive it actually gives me, then I ask what metadata, aliasing, or lifetime rule that primitive lets me violate. Modern mitigations usually do not remove every route to impact, but they force you toward better leaks, better semantic targets, and cleaner cross-layer reasoning. That is the difference between knowing exploit tropes and thinking like a vulnerability researcher.
