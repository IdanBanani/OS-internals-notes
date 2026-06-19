# 05. Architecture Special Cases: x86-64, arm64, and 32-bit Edge Cases

Value Score: 76/100
Role: Linux architecture caveats
Proof Level: Conceptual

This file exists specifically because the deep-dive should not flatten important architecture differences into generic MM language.

## 1. What absolutely changes by architecture

The big categories that really differ are:

- privilege model and entry/exit mechanics
- page-table format and translation roots
- executable-permission model
- TLB tagging and invalidation details
- userspace pointer conventions
- mitigation set
- address-space size and pressure

If a candidate gives one totally generic answer for x86-64, arm64, and 32-bit Linux, that is a warning sign.

## 2. x86-64 highlights

Important x86-64-specific topics:

- CR3-rooted page tables
- four- or five-level paging
- LA57 and 57-bit canonical-address assumptions
- PCID for address-space tagging
- `swapgs` and x86-specific entry-path complexity
- SMEP and SMAP
- PTI/KPTI
- CET shadow stack and IBT
- direct-map/physmap importance

Research rule: `CR3` is not just another writable kernel variable. It is the CPU's active page-table root register, and only privileged execution can load it directly. Linux stores address-space state in memory structures such as `mm_struct` and the page-table root pages, and the kernel loads the hardware root during context-switch and entry/exit paths. A kernel or physical write primitive can tamper with page-table pages or stored address-space metadata, but it does not instantly rewrite every CPU's active `CR3`. TLB state, PCID tags, KPTI user/kernel roots, and cross-CPU synchronization decide when the hardware actually observes the change.

The first root is a bootstrapping artifact, not a process artifact. Early x86-64 Linux creates initial `pgd`/PML4-style tables from reserved boot memory, maps the kernel enough to execute, and privileged setup code loads `CR3`. Later process roots are allocated by MM code through `mm_struct` setup and page-table allocation helpers; `mm->pgd` records the kernel virtual address of the root page, and the physical CR3 value is derived from it when the architecture switch path runs.

Counting roots follows the same rule. Linux does not have one machine-wide PML4, and it is not exactly one per PID. The normal user address-space unit is `mm_struct`: threads sharing `CLONE_VM` share one root, `fork()` creates a separate root, `execve()` replaces the old address space under the continuing task identity, and kernel threads borrow an `active_mm` because they usually have no user `mm`. With PTI/KPTI, a single memory context may have a full kernel view and a restricted user view, so the hardware-visible root can change on syscall/interrupt/exception entry and exit.

LA57 is the x86-64 five-level paging mode that expands canonical linear addresses from the older 48-bit model to 57 significant bits. This matters to security mostly through layout and assumption pressure. More virtual space can support more ASLR/KASLR entropy, wider guard gaps, huge sparse mappings, and roomier kernel virtual layouts. But the benefit depends on OS policy and leaks still defeat randomized layout. The sharper review point is brittle code: checks that assume bits 63:48 are just sign-extension, pointer compression that discards useful address bits, hard-coded `TASK_SIZE`/kernel-base style constants, JIT sandboxes with stale bounds, and low-level tooling that assumes the `p4d` level is always folded.

Why x86-64 researchers care about PTI:

- it changes the shared user/kernel mapping story
- it affects entry/exit cost and page-table management
- it is part of the post-Meltdown security model

---

> **▸ Case Study — KPTI and the direct-map as a persistence surface (post-Meltdown kernel-text reasoning)**
>
> **What broke:** Meltdown (CVE-2017-5754) demonstrated that the pre-KPTI kernel mapping model — where kernel physical memory was mapped into every user process's page tables as supervisor-only — allowed speculative reads of kernel memory from userspace. The fix (KPTI) removed kernel mappings from user-mode page tables. But KPTI created its own complexity.
>
> **Primitive gained (attacker perspective, post-KPTI):** Under KPTI, the kernel's direct map (physmap) — the region mapping all physical memory at a fixed virtual offset — remains present in kernel-mode page tables. Any kernel write primitive that reaches the physmap can write to arbitrary physical memory through a predictable, unlocked mapping. The physmap does not disappear with KPTI; it only becomes invisible to user-mode speculative execution. A kernel-mode write primitive that lands anywhere in the physmap can overwrite kernel code, data, or page tables depending on what physical pages back the target VA.
>
> **Why it worked:** The physmap's design goal — fast kernel access to all physical memory without individual per-page mappings — is also what makes it a powerful write amplifier. Physical pages backing a target object (such as a page table page or a `cred` struct) have a predictable physmap alias. A kernel arbitrary-write primitive does not need to compute the exact kernel virtual address of a target; it can compute the physmap alias of the target's physical page instead, which is often easier.
>
> **In the wild:** physmap-alias targeting appeared in multiple x86-64 kernel exploit chains and was extensively discussed in kernel exploitation research papers from 2016 onward. It became a standard step when a kernel write primitive existed but the precise virtual address of a target object was uncertain.
>
> **What changed:** Various kernel hardening efforts have focused on making the physmap less uniformly writable (randomizing its base, restricting permissions at finer granularity) and on making page-table pages themselves harder to reach through the physmap. `XPFO` (eXclusive Page Frame Ownership) proposals attempt to unmap physical pages from the physmap when they are in active use as page tables or other high-value targets, though full deployment remains incomplete in mainline kernels.

---

## 3. arm64 highlights

Important arm64-specific topics:

- TTBR0 for userspace and TTBR1 for kernel space
- translation and access control via arm64 descriptors instead of x86-style PTE flag naming
- `UXN` and `PXN` execute-never distinctions
- PAN as a privileged access hardening mechanism
- TBI and tagged pointers
- PAC
- BTI
- MTE

arm64 has the same conceptual split with different names. Translation-table base registers are privileged CPU state, while descriptors and kernel-owned address-space metadata live in memory. A powerful write primitive can corrupt descriptors or metadata that a privileged path later consumes, but direct TTBR changes require EL1/EL2 authority. PAN, PXN/UXN, ASIDs, TLB invalidation rules, KPTI-like designs, and hypervisor stage-2 translation all affect whether a descriptor corruption becomes useful or just crashes the device.

Good interview line:

> On arm64, pointer semantics and mitigation design are much more tied to the top-byte/tagging and pointer-authentication story than on x86-64.

## 4. arm64 tagged addresses and TBI

arm64 can ignore the top byte of userspace virtual addresses for translation.

That matters because:

- userspace can carry pointer tags in the top byte
- the kernel needs clear ABI rules about when tagged pointers are accepted
- pointer interpretation bugs can become ABI or validation bugs, not just memory bugs

This is especially relevant on Android because tagged-pointer and MTE-related behavior is much more visible there than on desktop Linux.

## 5. arm64 PAC, BTI, and MTE

These deserve separate mention because they change exploitation strategy.

### PAC

- protects certain pointer uses with cryptographic signing
- raises the cost of raw pointer corruption
- makes leaks and pointer reuse strategy more important

### BTI

- constrains valid indirect branch landing sites
- makes JOP-style control-flow abuse less forgiving

### MTE

- associates allocation tags with 16-byte granules
- compares pointer tag and allocation tag
- raises the cost of many spatial and temporal memory-safety failures

Good maturity signal:

> MTE is not just another sanitizer. It changes runtime memory semantics on supported arm64 systems and can surface otherwise silent bugs as architectural tag-check failures.

---

> **▸ Case Study — PAC as a pointer-corruption cost multiplier (iOS/arm64 pattern)**
>
> **What broke:** PAC (Pointer Authentication Codes) signs certain pointers — return addresses, function pointers, and optionally data pointers — using a secret key loaded into system registers that is inaccessible to unprivileged code. A stored pointer includes a cryptographic signature in its high bits. Authenticating a pointer before use checks the signature; a mismatch raises a fault. A raw arbitrary-write primitive that stores a forged pointer cannot supply a valid signature without knowing the key.
>
> **Effect on exploitation:** A write primitive that formerly converted directly into code execution (overwrite a function pointer, win) now requires either: (a) a key leak — breaking PAC requires leaking the signing key or finding a signing oracle that will sign an attacker-controlled value; (b) a pointer-reuse approach — reusing a legitimately signed pointer that already points near the target, without forging a new one; (c) a data-only path — pursuing credential or policy object corruption that produces impact without executing attacker-controlled code at all.
>
> **Why this matters architecturally:** PAC separates "I can write anywhere" from "I can redirect execution anywhere." Both were implicitly bundled in a write primitive on PAC-absent systems. On PAC-enabled arm64, the write primitive's value for code-execution impact falls significantly without a complementary signing oracle or key-material leak.
>
> **In the wild:** iPhone exploit chains targeting arm64 SoCs with PAC (A12 and later) demonstrably required additional steps compared to equivalent pre-PAC chains. Public research by Brandon Azad and others at Project Zero documented the need for PAC key material leaks or oracle constructions to restore code-execution reach from an arbitrary-write primitive. This substantially raised the cost of reliable iOS kernel exploitation.
>
> **What changed (attacker adaptation):** Research shifted toward finding PAC signing oracles — kernel code paths that would sign attacker-controlled values using a legitimate key — and toward data-only exploitation strategies that bypass the code-execution question entirely by overwriting security-sensitive data structures without needing a valid signed code pointer.

---

## 6. Android arm64 16 KB pages

This is a very real modern special case and worth calling out explicitly.

Android now supports 16 KB page-size configurations for arm64 devices. That changes more than performance:

- page alignment assumptions break
- low-level allocators and hard-coded constants break if written poorly
- fragmentation and page-table geometry change
- code that assumes 4 KB page size at compile time can fail badly

If the interviewer is modern Android-focused, mentioning 16 KB arm64 page support is a very strong signal that your knowledge is current and practical.

---

> **▸ Case Study — 16 KB page-size migration and assumption failures**
>
> **What broke (in the ecosystem, not a single CVE):** When Android began requiring 16 KB page-size support for new devices (Android 15 onward), a class of latent assumptions surfaced. Code that hard-coded `PAGE_SIZE` as 4096 — in native libraries, in JNI code, in kernel modules, and in low-level allocators — failed in ways ranging from crashes on startup to silent heap-layout corruption.
>
> **Category of primitive gained:** Not an exploitation primitive in the traditional sense — but a broad class of **alignment and arithmetic bugs** that manifested only on 16 KB page configurations. Allocators that assumed `mmap()` granularity was 4 KB would request misaligned memory regions. Parsers that iterated over memory in 4 KB steps would misread file-backed mappings. Stack or heap reservation logic would under-allocate guards.
>
> **Why it worked:** The Linux kernel exposes the actual page size via `sysconf(_SC_PAGE_SIZE)` and `getpagesize()`. Code that uses these correctly handles any page size. Code that hard-codes 4096 or uses the compile-time constant `PAGE_SIZE` on a kernel built with `CONFIG_ARM64_PAGE_SHIFT=14` encounters a mismatch between its assumptions and reality. These mismatches are not rare — they appeared in shipping open-source libraries, popular game engines, and browser code when 16 KB device images were first tested.
>
> **In the wild:** Google's 16 KB compatibility testing program (documented in AOSP) found failures in a significant fraction of native binaries submitted through the Play Store when first run on 16 KB images. Several issues were security-relevant: heap guard gaps calculated incorrectly, memory-mapped file parsers reading into guard pages.
>
> **What changed:** Android's NDK documentation was updated with explicit guidance on page-size portability. New linker and build-system checks were added to detect hard-coded 4096 page-size constants. The GKI (Generic Kernel Image) mandate extended to requiring page-size–agnostic kernel modules.

---

## 7. 32-bit is not just "smaller pointers"

The main 32-bit differences are structural:

- much smaller virtual address space
- much tighter kernel/userspace split
- greater pressure on mapping layout
- historical reliance on highmem and mapping tricks
- easier pointer truncation and sign-extension classes of bugs in mixed-width systems

Classic 32-bit pain points:

- cramped address space means allocator and layout behavior feel very different
- highmem and temporary kernel mappings complicate reasoning
- PAE/LPAE variants change page-table layout and physical-address reach

So the correct framing is:

> 32-bit changes the problem geometry, not only the integer width.

## 8. 32-bit compat processes on 64-bit kernels

This is one of the most interview-relevant mixed-architecture topics.

A 64-bit kernel can support 32-bit userspace. That creates:

- compat syscall paths
- structure-layout translation issues
- pointer-width mismatch issues
- sign-extension and truncation opportunities

Why it matters:

- the kernel may need compatibility wrappers because user-provided structures differ in layout
- parser bugs at ABI boundaries are common sources of subtle vulnerabilities
- exploit reliability changes because the kernel is 64-bit but the attacking process may be 32-bit

This is exactly the sort of detail seasoned interviewers use to separate genuine systems familiarity from textbook knowledge.

---

> **▸ Case Study — compat syscall ABI mismatch (CVE-2010-3081 class)**
>
> **What broke:** `compat_alloc_user_space()` on x86-64 Linux kernels accepted a caller-supplied `unsigned long len` parameter. When the size argument was crafted to overflow during arithmetic — subtracting the current stack pointer from the desired allocation top — the resulting computed stack pointer could wrap around to a very large value, placing the "allocated" region at a high address in the compat user stack that overlapped with sensitive kernel memory or other process state.
>
> **Primitive gained:** Stack pointer manipulation on the compat (32-bit) execution path that effectively allocated kernel-mode memory as if it were user-mode stack space. Subsequent use of that "user" allocation for kernel-to-user copies then overwrote kernel memory. Full privilege escalation from unprivileged local user to root on x86-64 systems.
>
> **Why it worked:** The 64-bit kernel's compat layer had to reconstruct 32-bit structure layouts from values provided by 32-bit userspace, then copy between them. The size and offset arithmetic happened in 64-bit kernel code, but the pointer values came from 32-bit userspace. The lack of adequate overflow checking in the size arithmetic allowed a small, crafted size value to produce a wildly incorrect stack pointer through unsigned wraparound. The kernel then used this pointer for memory operations with no further validation.
>
> **In the wild:** Exploited by "Ac1dB1tch3z" in 2010 with a public exploit targeting Red Hat/CentOS x86-64 systems. Reliably produced root from any local user account. Became a canonical reference for compat-layer arithmetic bugs because the mechanism — width mismatch enabling wraparound in the wrong arithmetic domain — recurs in subtler forms in later compat syscall implementations.
>
> **What changed:** The specific arithmetic was patched. The broader impact was increased scrutiny of all compat syscall wrappers that performed size or offset arithmetic on user-supplied values. The lesson — that a 64-bit kernel operating on data from a 32-bit process is handling values in a different numeric range than its own arithmetic normally assumes — became a standard compat-layer review criterion.

---

## 9. Highmem, PAE, and old-school 32-bit MM sharp edges

On classic 32-bit systems:

- the kernel could not keep all physical memory permanently mapped into its normal linear space
- highmem handling and temporary mappings mattered
- PAE changed physical-address capacity and page-table format

This matters mainly because:

- many old exploitation papers assume this world
- many modern candidates have never had to think about why kernel virtual address space was so constrained on 32-bit

If asked, the right answer is:

> 32-bit kernels often had to juggle limited kernel VA space with more physical memory than could be linearly mapped all at once, which created special mapping and highmem machinery that mostly disappears from mainstream 64-bit reasoning.

## 10. x86-64 vs arm64 control-flow hardening

A useful comparison:

- x86-64: CET shadow stack and IBT
- arm64: PAC and BTI

The mature framing is not "which one is stronger?" but:

- what class of corruption do they make more expensive?
- what remaining primitives stay viable?
- how much does leak quality matter afterward?

## 11. x86-64 vs arm64 page-table mentality

Another useful comparison:

- x86-64 interview answers often center on CR3, PTI, SMEP/SMAP, `swapgs`, and direct map
- arm64 answers often center on TTBR0/TTBR1, PAN, `UXN`/`PXN`, TBI, PAC, and MTE

If you answer arm64 questions using only x86 language, it is obvious.

## 12. The short version to say aloud

If you need a compact answer:

> Yes, architecture-specific behavior matters a lot. x86-64 and arm64 differ in entry paths, translation roots, execute-control bits, TLB tagging, and mitigations, while 32-bit and compat modes change the entire geometry of address space, structure layout, and pointer semantics. For Android in particular, arm64-specific features like PAC, MTE, tagged pointers, and now 16 KB page-size support are not side notes; they are part of the real exploitation and hardening model.
