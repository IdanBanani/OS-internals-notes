# 02. Page Cache, Reverse Mapping, Pinned Pages, Reclaim, and Allocators

Value Score: 86/100
Role: Linux page-cache/reclaim owner
Proof Level: Conceptual, lab-routed

Cross-platform companion: [Paging, residency, page lists, and shared memory](<../05-topic-notes/paging-residency-page-lists-and-shared-memory.md>) explains how this Linux page-cache/reclaim model maps to Windows standby/free/zero lists, section objects, PFN/PTE state, demand-zero faults, and the nonpageable versus non-swappable distinction.

## 1. Page cache is central, not peripheral

One of the most common weak answers in interviews is to treat the page cache as a side topic.

It is not. It is one of the main places where files, memory mappings, reclaim, and I/O all meet.

High-level model:

- `read()` commonly pulls data through the page cache
- file-backed `mmap()` commonly faults pages from the page cache
- clean file-backed pages can often be discarded and faulted back later

So if someone asks whether `read()` and `mmap()` are "separate copies," the mature answer is:

> Usually no. They often converge on the same page-cache-backed data.

## 2. Anonymous vs file-backed memory

You should be able to explain the difference quickly and precisely.

### Anonymous memory

- heap
- stack
- anonymous `mmap`
- zero-fill regions
- backed by RAM and possibly swap

Anonymous memory has no ordinary file as its backing identity, so the kernel must account it as private process memory and recover it through reclaim, swap, or process exit. The important invariant is that dirty anonymous state belongs to that address space unless it is explicitly shared, so a private heap page cannot simply be discarded like a clean file-cache page.

### File-backed memory

- executable segments
- shared libraries
- mapped files
- APK/DEX/OAT/VDEX-related mappings on Android
- backed through the page cache

Exploit relevance:

- clean file-backed pages are easier to reclaim
- anonymous dirty memory has different lifetime and pressure behavior
- `MAP_PRIVATE` file mappings start file-backed and become anonymous on write

File-backed memory has an external identity: inode, offset, page-cache entry, and mapping relationship. That identity is why two processes can fault the same library page, why clean pages can be dropped and later reread, and why page-cache corruption bugs are so powerful: they can change what many mappings believe is immutable file data.

## 3. `MAP_PRIVATE` is a transition story

This is worth saying explicitly in interviews:

- `MAP_PRIVATE` file pages start by referencing shared file-backed cache state
- after a write fault, the modified page becomes a private anonymous page

That one sentence shows you understand:

- page-cache-backed sharing
- COW
- why writes do not mutate the underlying file
- why reclaim behavior changes after private modification

---

> **▸ Case Study — Dirty Pipe (CVE-2022-0847)**
>
> **What broke:** The Linux pipe subsystem failed to clear the `PIPE_BUF_FLAG_CAN_MERGE` flag when recycling a pipe buffer slot. If a prior `splice()` had backed a pipe buffer with a page-cache page, that flag survived into the next write operation on the same slot.
>
> **Primitive gained:** Write to arbitrary read-only page-cache content without any explicit write permission on the file. This included SUID binaries and other root-owned executables readable by the process.
>
> **Why it worked:** Zero-copy `splice()` is designed to let a pipe buffer borrow a reference to an existing page-cache page rather than copying data. The "can merge" flag tells `pipe_write()` to append new data directly into the backing page rather than allocating a fresh buffer. Because the flag was not cleared on slot reuse, a write after a `splice()` would land directly on the page-cache page — bypassing the `MAP_PRIVATE` write-isolation guarantee entirely. The file-backed page was mutated in place, meaning the underlying file was also modified, exactly as if the process had write permission.
>
> **In the wild:** Discovered by Max Kellermann and disclosed in March 2022. A working exploit modifying `/etc/passwd` was published within hours. Container escape variants followed quickly because container runtimes commonly allow read access to host-side binaries. Affected all kernels from 5.8 (when the pipe merge optimization was added) through 5.16.10 / 5.15.24 / 5.10.101.
>
> **What changed:** `pipe_write()` now explicitly initializes the flags field on new pipe buffer slots, clearing `PIPE_BUF_FLAG_CAN_MERGE`. A broader audit of page-cache write paths followed to verify that zero-copy operations never grant implicit mutation rights.

---

## 4. `struct page`, folios, and reverse mapping

### `struct page` / folio

Linux historically models physical pages with `struct page`. Newer MM work increasingly uses **folios** to represent one or more physically contiguous base pages as one higher-level unit.

Concepts worth knowing:

- refcount
- flags
- mapping owner
- mapcount or reverse-mapping relationships
- reclaim/LRU state

The reason this metadata matters is that MM often acts on physical memory, not only on virtual addresses. Reclaim, migration, COW, pinning, writeback, and page-cache lookup all need a stable way to ask what this page is, who owns it, how many users it has, and whether it can safely move or disappear.

### Reverse mapping

Reverse mapping answers:

> For this physical page or folio, who maps it?

That matters for:

- reclaim
- unmapping
- migration
- COW
- aging and access tracking

Good interviewer answer:

> Reverse mapping exists because MM often starts from the physical page and needs to find the virtual mappings, not the other way around.

The security angle is that unmapping or write-protecting a page is only correct if every relevant mapping is found. A stale reverse-map relationship can leave a process with access that policy believes was revoked, while an incorrect mapcount can make reclaim, migration, or COW act on a page that is still visible.

## 5. Swap and state-machine complexity

Swap is not just "page absent." It adds another layer of identity and state:

- resident page
- swapped-out backing
- swap-cache involvement
- eventual fault-back in

That state machine is a fertile source of subtle bugs:

- refcount mismatches
- stale references
- migration or reclaim races
- wrong assumptions about liveness

The "why" is that swap separates virtual identity from immediate physical residency. A PTE can name a swap entry instead of a present frame, the swap cache can temporarily make swapped data look page-cache-like, and a later fault can re-materialize the page with new physical identity. Any code that assumes "not present means gone" will reason incorrectly about lifetime.

## 6. Pinned pages and `get_user_pages()`

This is one of the most senior MM topics you can discuss.

Subsystems sometimes need a page to remain stable for:

- DMA
- networking
- storage
- graphics
- RDMA-like behavior

So they pin user pages rather than merely observing a mapping.

Why this is hard:

- MM wants to COW, migrate, reclaim, unmap, and write-protect pages
- pinning says some other subsystem depends on that physical page staying valid

Good sentence:

> GUP-style pinning is dangerous because it turns a virtual mapping relationship into an external physical-page lifetime obligation.

That is exactly why COW, revoke, and migration logic get tricky.

---

> **▸ Case Study — GUP vs COW: the Dirty COW GUP angle**
>
> **What broke:** `get_user_pages()` with `FOLL_FORCE | FOLL_WRITE` could obtain a "write" pin on a file-backed, read-only page-cache page without actually performing the copy that COW requires. The force flag was intended for legitimate kernel subsystems (like `ptrace`) that need controlled write access to pages they would not otherwise own for writing.
>
> **Primitive gained:** A write-capable GUP pin on a page-cache page that the virtual memory policy said should be read-only and copy-on-write protected. Writes through the pin land on the shared cache page rather than on any private copy.
>
> **Why it worked:** `FOLL_FORCE` suppressed the VMA permission check. `FOLL_WRITE` was supposed to trigger a COW fault, allocating a private page before issuing the write pin. But the COW page could be immediately discarded if a concurrent `madvise(MADV_DONTNEED)` freed the private allocation, and the retry omitted `FOLL_WRITE`, obtaining a direct pin on the shared page instead. The GUP caller then held a pin that allowed writes the VMA explicitly forbade.
>
> **In the wild:** This is the core GUP-layer mechanism behind Dirty COW. It also illustrates a class of bugs that appeared later in KVM and vhost subsystems, where GUP pins were obtained under insufficient locking, allowing concurrent VMA teardown, truncation, or remapping to invalidate the pin's assumptions about backing physical memory.
>
> **What changed:** `FOLL_WRITE` retry semantics were fixed in the Dirty COW patch. Subsequent kernel work introduced `FOLL_PIN` as a semantically distinct operation from `FOLL_GET`, with explicit protocols around COW, migration, and revocation — making the difference between "observe this page" and "write to this page" explicit and auditable rather than implicit flag combinations.

---

## 7. Reclaim: performance policy with security consequences

Reclaim decides what memory stays resident under pressure:

- clean file cache
- dirty file cache
- anonymous pages
- active vs inactive or multigenerational hot/cold pages
- pinned vs movable vs unevictable pages

This affects vulnerability research because reclaim changes:

- page reuse timing
- allocation latency
- fault frequency
- whether memory shaping remains stable

Reclaim is security-relevant because it changes when objects disappear, when clean file data is refaulted, and when allocator pressure reshapes heap layout. It is also policy-heavy: the kernel prefers to reclaim cold or clean memory, preserve hot working sets, respect pins/unevictable state, and avoid stalls, so pressure can expose races that never appear in a quiet system.

## 8. `kswapd`, direct reclaim, and memcg

Important distinctions:

- background reclaim by `kswapd`
- direct reclaim by the allocating task itself

Direct reclaim matters because code that "just allocates" can suddenly:

- block
- recurse into MM
- run under memory pressure in a very different timing regime

And memcg matters because:

- accounting is not purely global
- reclaim and OOM decisions can become cgroup- or app-scoped
- containerization and Android app pressure depend heavily on this

The difference matters mechanically because `kswapd` runs background balancing work, while direct reclaim makes the allocating task enter reclaim paths at a point where callers may not expect blocking, filesystem writeback, lock contention, or recursion into MM. Memcg adds another authority boundary: a process can be under pressure because its cgroup is over limit even when the machine still has memory.

## 9. PSI and Android `lmkd`

Modern Android uses userspace `lmkd` with PSI-backed memory pressure signals.

Key point:

- Android prefers killing less-important processes over allowing long thrash-induced stalls on interactive devices

Good short explanation:

> Linux provides reclaim, memcg, and PSI; Android layers process-importance-aware policy on top through `lmkd`.

PSI matters because it measures stall pressure, not just free memory. Android uses that signal to decide when memory pressure is harming responsiveness enough to kill lower-importance processes, so the policy boundary is partly userspace: kernel pressure accounting feeds a process-priority decision made by `lmkd`.

## 10. Physical memory is not one uniform pool

Linux organizes physical memory by:

- NUMA node
- zone
- pageblock/migratetype behavior

Common zones:

- `ZONE_DMA`
- `ZONE_DMA32`
- `ZONE_NORMAL`
- `ZONE_MOVABLE`

Why it matters:

- device constraints
- kernel placement
- fragmentation management
- high-order allocation success or failure

The mechanism is that the allocator is constrained by both physical topology and intended use. DMA-capable devices may only reach certain address ranges, movable pages are easier to compact, and NUMA locality changes latency. A free page in the wrong zone, node, or migratetype is not equivalent to a free page in the right one.

## 11. Buddy allocator

The page allocator works in powers of two:

- order-0 is one base page
- order-1 is two contiguous pages
- order-2 is four
- and so on

Why exploit researchers care:

- fragmentation leaks information
- physical contiguity is not random
- high-order success depends on compaction and pageblock state

Buddy allocation matters because it is the layer that decides physical page contiguity. Splitting and coalescing power-of-two blocks creates predictable pressure and fragmentation effects, and high-order failure can force fallback behavior that changes timing, placement, and side effects in drivers or subsystems that assumed contiguous memory.

## 12. Per-CPU pagesets

Frequent small page allocations and frees often go through per-CPU fast paths first.

That matters because:

- locality is stronger than many people assume
- reuse can become more predictable
- timing behavior may differ sharply from global-buddy intuition

The reason is that per-CPU caches deliberately avoid taking global allocator locks on common paths. That improves performance, but it also means recent frees on one CPU are more likely to be reused on that CPU, and cross-CPU behavior can differ from a simple "global free list" model.

## 13. SLUB, `kmalloc`, typed caches, and `vmalloc`

You should clearly distinguish:

- `kmalloc` / `kzalloc`
- `kmem_cache_alloc`
- `alloc_pages`
- `vmalloc`
- `kvmalloc`

### `kmalloc` and slab-backed objects

These are typically:

- physically contiguous at page granularity
- grouped by size class or typed cache
- heavily influenced by per-CPU freelists

The core reason slab-backed allocation matters is object reuse. Kernel bugs often become useful only when a freed slot is reclaimed by an object with interesting fields, dispatch pointers, size fields, or credentials/policy data. Size class, cache isolation, constructor behavior, and freelist hardening decide whether that reuse is plausible.

### Typed caches

Some kernel objects live in dedicated slab caches.

That matters because:

- the cache may have constructors or subsystem-specific reuse patterns
- cross-type confusion is different from generic `kmalloc-N` reuse

Typed caches narrow the allocator neighborhood. That can improve performance and debugging, but it also changes exploitability: a stale pointer may only be reusable as the same family of objects, and constructors/destructors can reset fields that a generic `kmalloc` grooming model would expect to control.

### `vmalloc`

`vmalloc` gives virtually contiguous memory backed by non-contiguous physical pages.

That changes:

- adjacency assumptions
- overflow geometry
- direct-map alias reasoning
- DMA feasibility

The key invariant is that virtual adjacency no longer implies physical adjacency. A linear overflow across a `vmalloc` region may cross virtually mapped pages but not neighboring physical allocations, while DMA engines and some low-level code need physical contiguity or explicit scatter/gather handling.

Good interview line:

> If you are reasoning about reallocation, aliasing, or overflow reach, whether the target came from SLUB or `vmalloc` changes the problem completely.

## 14. Why UAF often beats overflow

Heap overflows are important, but use-after-free is often stronger because it attacks ownership instead of just adjacency.

A UAF lets the attacker try to:

- reclaim the same slot
- substitute a different type
- keep stale references alive across teardown
- exploit refcount or deferred-free logic

This is why allocator knowledge matters so much.

---

> **▸ Case Study — CVE-2021-22555 (Netfilter heap OOB → cross-type reuse)**
>
> **What broke:** The netfilter compat layer's `xt_compat_match_offset()` calculation was wrong by two bytes. An `xt_entry_match` object in an `IP_SET_OP_GET_BYINDEX` netfilter operation was allocated at the wrong size, and writing the compat structure overflowed two bytes past the end of the slab allocation into the adjacent object.
>
> **Primitive gained:** The initial primitive was a two-byte out-of-bounds write into an adjacent slab slot — modest on its face. The real power came from what the exploit made of it: by grooming the slab so that a `msg_msg` object occupied the adjacent slot, the two-byte overflow corrupted the `msg_msg.m_ts` (message text size) field. An oversized `m_ts` value on a `msg_msg` struct then allowed reading beyond the end of the message body, producing an out-of-bounds read spanning neighboring slab allocations and eventually leaking kernel addresses and other sensitive metadata. Further grooming converted this into a write-what-where primitive.
>
> **Why it worked:** The key insight is that the raw overflow was too small to be independently powerful, but the SLUB allocator's size-class bucketing predictably placed `msg_msg` objects — allocated via `msgsnd()` — adjacent to `kmalloc-64` netfilter objects. The `msg_msg` structure's size field sat exactly two bytes into the allocation header, directly in the overflow's reach. A small overflow into a carefully chosen neighbor is often stronger than a larger overflow into an unpredictable neighbor.
>
> **In the wild:** Publicly disclosed by Andy Nguyen (theflow0, Google) in June 2021 with a working exploit against Ubuntu 20.04. The exploit reliably achieved local root and was widely referenced as a clean demonstration of modern kernel heap primitive construction.
>
> **What changed:** The compat size calculation was patched. The broader lesson — that `msg_msg` objects are a powerful grooming primitive for cross-object confusion — was well-absorbed by the research community and triggered a wave of follow-on research targeting similar `msg_msg`-based patterns.

---

## 15. Hardening features worth naming

If the conversation turns to mitigations, mention what they change:

- SLUB freelist hardening
- freelist randomization
- KASAN
- KFENCE
- `init_on_alloc`
- `init_on_free`
- Scudo on Android native userspace

The mature way to phrase this is:

> These features usually do not make bugs impossible; they make temporal reuse less predictable, stale contents less reusable, and bug-to-primitive conversion noisier.

Name the primitive each feature degrades. Freelist randomization targets predictable reuse, init-on-free targets stale data, KASAN/KFENCE target detection, and allocator isolation targets cross-type substitution. That framing is stronger than treating mitigation names as magic yes/no exploit switches.
