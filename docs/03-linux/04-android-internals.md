# 04. Android Internals: Zygote, ART, Binder, Sandbox Policy, and Native Hardening

Value Score: 80/100
Role: Android internals owner
Proof Level: Conceptual, needs more labs

Journey companion: [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>) maps `TheAndroidConceptJourney_v1_May2025 (1).pdf` into this track. Use it as the Android concept bridge before diving into AOSP, device kernels, SELinux policy, or monthly bulletin context.

## 1. The right way to frame Android

Android is not "Linux plus Java."

The correct framing is:

- Linux kernel memory management and isolation primitives at the base
- Android-specific process model, runtime, IPC, and security policy above it

That means good Android answers talk about:

- Linux MM
- Zygote
- ART
- Binder
- app sandboxing
- `lmkd`
- native heap hardening

## 2. App sandbox

Android's app sandbox begins with kernel primitives:

- per-app UIDs
- process isolation
- filesystem ownership

Then Android adds:

- SELinux mandatory access control
- seccomp-bpf restrictions for apps
- framework permission checks
- app-specific SELinux domains for unprivileged apps

Strong interview line:

> Native code in an Android app is still inside the same kernel-enforced sandbox as the managed part of the app, because the boundary is UID, SELinux, seccomp, and process isolation, not Java.

### Threads, Processes, And Memory Access

Inside one app process, threads share the same virtual address space. Each thread has its own registers, stack pointer, stack range, TLS, and scheduling state, but the heap, globals, code mappings, shared mappings, and other thread stacks are still addressable by same-process native code if it has the address. SELinux does not isolate one thread from another thread inside the same process.

Across app processes, the same numeric pointer value has no general meaning. It is interpreted through a different VM map and page-table root. Cross-process memory requires a deliberate carrier: Binder-transferred fds, `memfd` or older ashmem-style objects, DMA-BUF/graphics buffers, mapped files, debugger-style authority, or a bug in a broker/kernel/service path. The security answer is to name the carrier and the policy: UID, SELinux domain, Binder service permission, fd lifetime, mapping protections, and who can mutate the shared bytes.

For the full interview-drill answer, including iOS/Mach task-port analogies and virtual-versus-physical address caveats, use [Mobile OS and coding interview traps Q&A](<../02-question-banks/07-mobile-os-and-coding-interview-traps-qa.md#100---processes-threads-and-mobile-sandbox-memory>).

---

> **▸ Case Study — Android sandbox escape anatomy (CVE-2020-0041 class)**
>
> **What broke:** CVE-2020-0041 was an out-of-bounds write in the Binder driver's transaction buffer management. When a Binder transaction was received, the driver validated the offsets of embedded object references within the transaction buffer. The validation did not correctly account for padding between object descriptors, allowing a crafted transaction to write a Binder object descriptor at an offset past the end of the buffer into adjacent kernel memory.
>
> **Primitive gained:** Out-of-bounds write in kernel memory from an unprivileged app process, via a normal Binder transaction — a path that every Android app has access to.
>
> **Why it worked:** The sandbox correctly restricted filesystem access, network access, and normal syscalls via seccomp and SELinux. But the Binder driver is an always-available IPC mechanism. The kernel-side object-offset validation logic was the trust boundary, and it was wrong. The app was inside the sandbox; the bug was in the kernel code the sandbox itself relied on.
>
> **In the wild:** Demonstrated by researchers at Exodus Intelligence and Zimperium. The exploit chain combined the Binder OOB write with kernel heap grooming to achieve arbitrary kernel memory writes, then escalated to root by overwriting a `cred` structure. The SELinux domain of the process was still confined even after root UID was gained — illustrating that post-compromise capability depends on the domain, not just the UID.
>
> **What changed:** Binder's transaction buffer offset validation was rewritten to correctly account for alignment padding. The broader lesson applied to Android security review: Binder parsing code is a kernel attack surface reachable by every app, and its validation logic deserves the same scrutiny as a public network parser.

---

## 3. Zygote

The Zygote is one of the most important Android-specific concepts.

What it does:

- starts early during boot
- preloads classes and runtime state
- forks app processes
- can keep unspecialized app processes ready for faster launch

Why it matters for memory:

- a lot of runtime state is shared by copy-on-write
- startup latency improves
- clean shared pages are reclaim-friendly
- memory pressure behavior differs from ordinary desktop process creation

If an interviewer asks why Android apps share so much memory, Zygote is the answer.

---

> **▸ Case Study — Zygote COW sharing as layout regularity**
>
> **What broke:** Nothing is broken here — this is an architectural consequence. Because all Android apps fork from Zygote, the virtual address layout of every app process starts from the same template: the same preloaded classes, the same boot image art mappings, the same ART runtime code, all at the same relative offsets within the address space before per-app ASLR relocations are applied.
>
> **Primitive gained:** Predictable partial layout knowledge. If an attacker can read any app's memory (via an in-app bug, a Binder information disclosure, or a `/proc`-based side channel), the offsets between ART runtime structures, boot image code, and preloaded class objects are identical across all apps on the same device and OS version. A leak in one component can substitute for a leak in a harder-to-reach component.
>
> **Why it worked:** The Zygote fork happens before per-app ASLR is applied to the forked address space. All pages that were mapped before the fork share the same relative layout. The ART boot image and Zygote-preloaded classes map at addresses derived from a single random base, and that base can often be inferred by leaking any single pointer into the shared region.
>
> **In the wild:** Widely understood in Android exploitation research. Full exploit chains targeting Android commonly use an ART or Zygote-mapped structure as the first ASLR-defeat step, because leaking any pointer into the shared pre-fork region gives the entire runtime layout. This is qualitatively different from desktop Linux, where each process's dynamic linker behavior independently randomizes its mapping base.
>
> **What changed:** Android has incrementally increased boot-image ASLR entropy and moved toward per-process layout decisions for more mappings. The shared COW efficiency is intentional and cannot be fully eliminated without destroying Zygote's launch-speed benefit, so the mitigation strategy focuses on reducing the predictability of the shared base rather than eliminating sharing.

---

## 4. ART, DEX, OAT, VDEX, `.art`

Managed code on Android is concrete memory layout, not an abstraction floating above the OS.

Core pieces:

- DEX bytecode
- ART runtime
- AOT/JIT/interpreter hybrid execution
- `dex2oat`
- generated artifacts like `.vdex`, `.odex`, and optional `.art`

Why this matters:

- bytecode, metadata, and compiled code end up as real mappings
- JIT code caches create their own permission and lifecycle concerns
- boot image state shapes layout regularity and sharing behavior

Good answer:

> ART is part loader, part runtime, part compiler pipeline. From a vulnerability perspective it matters because it creates real mapped code/data regions, not because "Java is special."

## 5. What researchers care about in ART

Conceptually, advanced researchers care about:

- stable shared runtime mappings
- boot image and preloaded state
- JIT code cache behavior and W^X transitions
- DEX verification and metadata assumptions
- managed/native crossings through JNI and system services

That does not mean every Android bug is "in ART." It means ART meaningfully changes process layout and runtime behavior.

## 6. Binder

Binder is Android's core IPC fabric.

Conceptually:

- clients talk through binder proxies
- services expose binder nodes
- transactions go through the binder driver
- the kernel mediates reference handling and buffer transfer into target processes

Why Binder is security-relevant:

- it is central
- it is complex
- it sits between trust domains
- it handles structured object metadata, not just raw bytes

Senior-level invariants to mention:

- reference ownership across processes
- buffer lifetime
- translation of binder objects/handles between contexts
- dispatch concurrency in target threads

---

> **▸ Case Study — Bad Binder (CVE-2019-2215)**
>
> **What broke:** A use-after-free in the Android Binder IPC kernel driver. The `binder_thread` structure tracking a thread's state within the Binder subsystem could be freed while an `epoll` file descriptor still held a reference to it. An attacker could trigger this by: registering an epoll watch on the `/dev/binder` fd, manipulating the binder thread state to cause the `binder_thread` to be freed via a normal teardown path, and then triggering epoll events that used the freed structure.
>
> **Primitive gained:** Kernel use-after-free on a `binder_thread` object, leading to controlled slab content reuse. With heap grooming, this yielded a read/write primitive into kernel memory, which was used to overwrite `cred` structures and achieve root. The exploit was demonstrated on Pixel 2 and Samsung Galaxy S9.
>
> **Why it worked:** Binder is accessible to every app via `/dev/binder` — it is the IPC backbone of Android. The lifetime of `binder_thread` was managed by two independent reference-counting paths (the Binder driver's own reference count and the fd reference from epoll) that were not properly coordinated. The UAF could be reliably triggered from unprivileged app code without any special permissions. SMEP/PXN prevented direct shellcode injection, so the exploit pivoted to a ROP/JOP chain using known kernel-text gadgets.
>
> **In the wild:** Discovered by Jann Horn (Project Zero), disclosed October 2019. Subsequently confirmed to have been sold and deployed as a targeted 0-day by NSO Group against specific high-value targets before the patch was available. One of the few Android kernel UAFs with confirmed in-the-wild targeted exploitation documented at this level of detail.
>
> **What changed:** Binder's `binder_thread` reference counting and epoll interaction were reworked to ensure both reference paths are properly tracked. Google also used this case to reinforce Android security patch urgency. More broadly, Binder IPC driver code became a higher-priority audit target in Android security reviews.

---

## 7. Shared memory on Android

Android historically used ashmem and ION heavily. Modern systems increasingly rely on:

- `memfd`
- DMA-BUF heaps

Do not assume generic Linux shared-memory APIs are the Android app model. System V shared memory calls such as `shmget`, `shmat`, `shmdt`, and `shmctl` exist in bionic headers/libc from API 26, but AOSP's own `sys/shm.h` labels them not useful on Android because SELinux disallows them. POSIX `shm_open` and `shm_unlink` are listed in bionic status as missing POSIX functions. In practice, Android shared-memory reasoning usually starts from Binder-mediated handles/fds, `memfd`, ashmem on older systems, DMA-BUF/graphics buffers, and SELinux policy rather than portable SysV/POSIX shm APIs.

Why this matters:

- graphics, camera, and media stacks share buffers across apps, services, and drivers
- user/kernel/device boundaries meet in shared-memory objects
- many interesting bugs are lifetime, accounting, or coherency problems rather than simple memcpy overflows
- the authority carrier is often a Binder-transferred fd/handle-like object plus SELinux/service policy, not a world-visible POSIX shm name or SysV key

## 8. Low-memory handling: `lmkd`, memcg, PSI

Android memory policy is not just "let Linux swap more."

Instead it uses:

- reclaim from the kernel
- memcg-aware accounting
- PSI-backed pressure signals
- importance-aware process killing via `lmkd`

That is the reason Android often kills a cached or background process sooner than a desktop Linux system would.

## 9. SELinux still matters after compromise

Do not talk about Android compromise as if UID 0 is the only relevant concept.

On Android:

- SELinux is enforcing by default
- policy is default-deny
- even privileged services are confined

So a better maturity signal is:

> Post-exploitation impact depends on the resulting SELinux domain and allowed interactions, not just the numeric UID.

## 10. Scudo and native heap hardening

Scudo is Android's hardened userspace allocator for native code on standard-memory devices.

What it changes:

- delayed reuse through quarantine-style behavior
- chunk-header integrity checking
- stricter validation on suspicious frees and state transitions
- more crashes on detected corruption instead of silent continuation

Important nuance:

- Scudo is a mitigation, not a full bug detector like ASan
- it raises the cost of turning a bug into a stable heap primitive

---

> **▸ Case Study — Scudo as a primitive degrader (class-level pattern)**
>
> **What broke (with earlier allocators):** Traditional `dlmalloc`-derived allocators on Android stored chunk metadata — size, flags, forward/back pointers — inline with user data. An overflow or UAF that corrupted those metadata fields could immediately be used to construct arbitrary write primitives through the allocator's own unlink or consolidation paths. Heap exploitation on older Android versions using these allocators was often straightforward once a corruption primitive existed.
>
> **What Scudo changed:** Scudo separates chunk metadata from chunk content into distinct memory regions. Chunk headers are not adjacent to the user data they describe. A linear overflow past the end of a user allocation does not reach the corresponding header — it reaches another user allocation in the same slab class. Header corruption requires a separate, more precise target. Additionally, Scudo's quarantine holds recently-freed chunks for a short period before they re-enter the free list, disrupting immediate-reuse UAF exploitation. The integrity check on headers produces a deterministic crash rather than silent metadata corruption on many common attack patterns.
>
> **Why this matters for primitive construction:** With Scudo, turning a heap bug into a write-what-where primitive typically requires either a cross-chunk metadata reach that works despite the separation, a controlled-allocation grooming sequence that places a valuable target adjacent to the corrupted region, or a temporal bug that outlasts the quarantine period. Each of these is more expensive and less reliable than the allocator-metadata-corruption path that was standard before Scudo.
>
> **In the wild:** Multiple Android full-chain exploits post-Scudo deployment (Android 11+) required additional exploitation steps compared to equivalent pre-Scudo chains. Scudo is documented in Google Project Zero analyses as a meaningful raise in cost for heap-primitive construction, even if it does not prevent exploitation of sufficiently powerful bugs.
>
> **What this does not change:** Scudo does not protect against all heap bugs. UAFs with quarantine-survivable timing, cross-chunk corruptions, and type-confusion bugs that do not rely on allocator metadata are still exploitable. Scudo is a primitive degrader, not an elimination mechanism.

---

## 11. The strongest Android answer in one paragraph

If you need one compact explanation:

> Android keeps Linux MM at the bottom, but the process model is defined by Zygote forking, the runtime is shaped by ART and DEX/OAT/VDEX artifacts, IPC is dominated by Binder, memory pressure is managed by `lmkd` with PSI and memcg signals, and post-compromise impact is heavily constrained by SELinux, seccomp, and per-app sandboxing. Native memory corruption still matters, but it plays out inside that Android-specific structure.
