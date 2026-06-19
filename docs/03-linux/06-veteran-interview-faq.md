# 06. Veteran Interview FAQ and Reasoning Patterns

Value Score: 74/100
Role: Linux rapid recall
Proof Level: Recall, not primary owner

## 1. What senior interviewers are usually testing

They are usually not testing whether you memorized every struct field.

They are testing whether you can:

- distinguish policy from implementation
- track ownership and lifetime
- explain how mitigations change primitives
- move comfortably between CPU, kernel, runtime, and policy layers
- reason from a bug to a primitive to an outcome

## 2. Strong reasoning template

When you are handed a memory-corruption bug, ask:

1. What object or region is corrupted?
2. What allocator or backing source produced it?
3. Who still references it?
4. Is the key outcome read, write, free, aliasing, type confusion, or a leak?
5. What mitigations stand in the way?
6. Is control-flow even the best target, or is data-only impact stronger?

That six-step shape is often enough to sound materially more senior.

---

> **▸ Case Study — Applying the six-step template: CVE-2021-33909 (Sequoia)**
>
> **What broke:** A `size_t` integer overflow in the kernel's `seq_file` implementation. When a process with a very long pathname (more than 1 GB of path depth, achieved by creating a large directory tree) read its own mountpoint information via `/proc/self/mountinfo`, the path length calculation overflowed a `size_t` field. The resulting allocation was far too small, and the subsequent string write overflowed into adjacent kernel memory.
>
> **Step 1 — What object:** An undersized `seq_file` buffer in the kernel heap, `kmalloc`-backed. The overflow destination was the adjacent `msg_msg` structure (via grooming).
>
> **Step 2 — Allocator:** `kmalloc` slab, predictably adjacent to other `kmalloc`-sized allocations. `msg_msg` objects from `msgsnd()` were used as the landing pad, the same grooming primitive as CVE-2021-22555.
>
> **Step 3 — Who references it:** The `seq_file` buffer is referenced by the kernel's procfs read path. `msg_msg` objects are referenced by the message queue subsystem.
>
> **Step 4 — Key outcome:** Write. The overflow wrote path bytes into the adjacent `msg_msg.m_ts` size field, producing an oversized message that could then be used for an out-of-bounds read — eventually leaking kernel addresses and enabling a subsequent write primitive.
>
> **Step 5 — Mitigations:** SMEP/SMAP present (no userspace-shellcode injection). KASLR in play (leak needed first). SLUB freelist hardening partially relevant. No MTE on x86-64.
>
> **Step 6 — Control-flow vs data-only:** The final impact was `cred` structure overwrite — a data-only privilege escalation. No function pointer or return address was needed. Writing a zero UID into the `cred` struct at the right address was sufficient.
>
> **In the wild:** Discovered by Qualys Research Team, July 2021. Full root exploit on default Ubuntu, Debian, and Fedora installations released simultaneously with disclosure.

---

## 3. Rapid-fire questions and answers

### Q: What is the difference between a VMA and a PTE?

A VMA is a policy object for a virtual-address range: allowed permissions, backing object, sharing mode, growth behavior, and fault handler context. A PTE is the current hardware-consumed translation state for one page-sized chunk inside that range: present/not present, physical frame, writable, executable, user/supervisor, dirty/accessed, and related architecture bits. The reason the split matters is that an address can be legal by VMA policy while still needing a fault to instantiate or change the PTE.

### Q: Can an address be valid but still fault?

Yes. It may be in a legal VMA but not yet populated, swapped out, write-protected for COW, file-backed but not resident, or waiting for stack-growth or permission resolution. A page fault is the CPU reporting that the current translation cannot satisfy the access; the kernel then decides whether that is normal demand paging or a real violation. This is why "fault" is not the same as "bug."

Evidence is the fault error code, VMA permissions/backing, signal reason, and whether the fault handler can legally install or update a PTE.

### Q: Why is `MAP_PRIVATE` subtle?

Because it begins by sharing file-backed data and becomes anonymous on write. Before the first write, multiple mappings can refer to the same page-cache page; after a write fault, the process receives a private anonymous copy. If you miss that transition, you get reclaim, dirty accounting, page-cache aliasing, forensics, and exploit primitive reasoning wrong.

The invariant is that private writes must not modify the shared file page visible to other mappings.

### Q: Why does TLB invalidation matter after changing a PTE?

Because the CPU may still use a stale cached translation after the kernel changes the page table. MM correctness lives in the table update plus the ordering and invalidation story: local invalidation, shootdowns on other CPUs, and architecture-specific barriers where needed. Without that, a page can remain writable, executable, or mapped in practice after policy says it changed.

That makes TLB behavior a security boundary whenever permissions, ownership, or executable state are being tightened.

### Q: Why is `vmalloc` different from slab-backed allocations?

Because it gives virtually contiguous kernel memory backed by non-contiguous physical pages, while slab-backed `kmalloc` objects usually come from physically contiguous pages organized into size/type caches. That changes adjacency, reuse, cache coloring, DMA suitability, and exploitation assumptions. A bug that relies on neighboring objects in one allocator may not transfer to the other.

The evidence is the allocation API and backing layout, not just the pointer looking like a normal kernel virtual address.

### Q: Why is page-table corruption so powerful?

Because it changes the semantics of memory itself: presence, writability, executability, privilege, physical backing, and aliasing. A corrupted PTE can turn a policy decision into a hardware-enforced lie, for example by making protected memory writable or mapping one physical page through an unexpected virtual address. The evidence is not only a bad pointer; it is the translation state the MMU will actually consume.

This is why page-table bugs can bypass higher-level object checks even when credentials, file permissions, or VMA policy look correct.

### Q: Why is a leak often more important than a write primitive?

Because modern mitigations punish blind writes. KASLR, heap randomization, freelist hardening, pointer masking, and type isolation often mean a write primitive is only useful if you know where the target object or code/data pointer lives. A leak turns an abstract primitive into a reliable primitive by revealing layout, object identity, or mitigation state.

Good analysis asks what the leak identifies: code base, heap object, slab cache, kernel stack, physical map, or a reusable pointer relationship.

### Q: Why are pinned pages dangerous to MM correctness?

Because they create external lifetime obligations for physical pages that MM may otherwise want to COW, migrate, reclaim, write back, or revoke. Long-term pins are especially tricky when DMA or userspace mappings can keep touching a page while the memory manager believes it can move or replace it. The invariant is that every subsystem must agree who is allowed to keep using the physical page.

Break that invariant and the failure may look like corruption in storage, networking, RDMA, GPU, or filesystem code rather than in the pinning caller.

### Q: Why is Binder such a high-value Android surface?

Because it is central privileged IPC with complex cross-process object, reference, handle, and lifetime semantics. Android security depends heavily on Binder-mediated services, SELinux domains, per-UID identity, and service-manager policy, so a Binder bug can cross a more meaningful boundary than an ordinary app-local bug. Interview depth is explaining the authority and lifetime model, not just naming Binder as "IPC."

Evidence includes the calling UID/domain, target service, Binder object references, transaction path, and whether a broker enforces the intended policy.

### Q: Why does SELinux still matter after app compromise?

Because the resulting domain controls what the compromised component can actually do. UID alone is not the whole story: SELinux type enforcement decides which services, files, device nodes, sockets, and Binder operations are allowed from that domain. For an authorized agent or post-RCE analysis, the question is which boundary remains after code execution, not only which Linux UID the process has.

That is why two processes with similar Unix permissions can have very different real reach on Android.

### Q: Why do veteran interviewers care whether you know page cache?

Because page cache is where file I/O, `mmap`, reclaim, writeback, COW, and backing-object semantics all meet. The same physical page can be read through `read`, mapped into a process, reclaimed under pressure, dirtied and written back, or observed in forensics as a file-backed mapping. If you do not know page cache, your answers about memory and files become artificially separate.

The deep question is always which object owns the data now: page cache, anonymous memory, swap, disk, or a private COW copy.

### Q: Why is a UAF often better than a linear overflow?

Because it attacks ownership and type interpretation, not just bounds. A freed object can be reallocated as a different object while stale references still treat it as the old type, creating read/write or dispatch effects through legitimate code paths. That often produces more controlled primitives than a linear overflow, although allocator hardening and object isolation can make reliability harder.

The invariant being broken is lifetime: no code should dereference an object after ownership has been released.

### Q: Why do Android apps share so much memory?

Because Zygote preloads runtime and framework state, then forks app processes, so clean pages remain COW-shared until modified. This design saves memory and startup time, but it also means Android memory analysis must distinguish shared clean pages, private dirty pages, ashmem/memfd regions, ART/JIT state, and per-app heap growth.

That distinction matters when deciding whether memory pressure, suspicious code, or an apparent data artifact is app-private or inherited/shared runtime state.

### Q: Why is "root" not necessarily the end of the Android story?

Because SELinux, service boundaries, verified boot state, namespaces, mount layout, and vendor/system separation still determine post-compromise reach. Android has many privileged services and partitions with different policy domains, so "root" may still be constrained by what can be mounted, what services can be called, what policy is enforcing, and whether persistence survives reboot or integrity checks.

The meaningful question is which trust boundary remains enforceable after the privilege change.

## 4. Common red flags

If you say these without qualification, a strong interviewer will usually push back:

- "The kernel maps sections."
- "A page fault means the page was not allocated."
- "Android memory management is mostly garbage collection."
- "Changing a PTE changes access immediately."
- "ASLR/NX/Scudo prevents exploitation."

Better alternatives:

- runtime loading is segment/program-header oriented
- faults are often ordinary demand-paging events
- Android memory behavior is Linux MM plus Android runtime/process policy
- TLB and invalidation matter
- mitigations degrade primitives, they do not magically erase bugs

## 5. The best one-paragraph answer to "how do you think about exploitation?"

This is a good mature answer:

> I try to reason in terms of ownership, aliasing, and who is allowed to reinterpret memory at each layer. A bug matters when it breaks an invariant across allocator state, mapping state, cached translation state, or security policy. Then I ask what primitive I really gained, what mitigations still apply, and whether the best impact is control-flow, data-only policy change, sandbox escape, or a more stable staging step.

---

> **▸ Case Study — Data-only impact as the strongest path: CVE-2022-1786 (io_uring)**
>
> **What broke:** A use-after-free in io_uring's fixed buffer registration path. When a fixed buffer list was updated and the old list freed, the io_uring context could still reference the freed memory through an outstanding request that had not been properly unlinked from the old buffer list. The freed buffer metadata remained accessible through the stale reference.
>
> **Reasoning chain applied:**
>
> The UAF was in a `kmalloc`-backed io_uring buffer vector. The freed region was reallocatable by any other `kmalloc` slab user. With appropriate grooming (using `sendmsg()` or `msgsnd()` to fill the freed slot with a controlled structure), the stale reference provided read and write access into the groomed object. The write path through the stale reference could reach `cred` or `file` structures placed in the same size class with additional grooming.
>
> Mitigations present: SMEP/SMAP, KASLR, SLUB hardening. No direct code-execution path was needed. The chosen impact was overwriting the `uid`/`gid` fields of the process's `cred` structure — a pure data-only privilege escalation. No return address, no ROP chain, no code pointer. Just write zeroes to the right offsets in a kernel heap object.
>
> **Why data-only was the right call:** Control-flow hijacking on a modern kernel requires a valid code pointer (PAC on arm64, CFI on some configs, SMEP on x86). A `cred` overwrite requires only a heap write to a predictable offset. The data-only path was both more reliable and less likely to crash the system.
>
> **What changed:** io_uring's buffer registration lifetime tracking was reworked. The broader pattern — io_uring as a rich source of kernel UAFs due to its complex async lifecycle — drove a wave of security audits and defensive patches through 2022–2023.

---

## 6. Final interview advice

The candidate who sounds senior is usually the one who:

- says "policy vs implementation"
- says "lifetime and aliasing"
- says "what does the TLB still believe?"
- says "what does this become after COW?"
- says "what does SELinux or seccomp still block?"
- says "what allocator or cache is this object actually in?"

That is the voice of someone who genuinely understands the system under the bug, not just the bug itself.
