# C++ And Modern C++ Internals For Security Researchers, Scored

Value Score: 92/100
Role: C++ internals Q&A owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-17

Purpose: fill the compiled C++ depth gap for reverse engineering, Windows driver analysis, browser/client research, EDR/malware triage, and exploitability interviews. This file focuses on mechanism-level understanding: how C++ source turns into objects, calls, code generation, atomics, containers, ownership wrappers, and optimizer behavior that a security researcher can recognize in assembly and reason about safely.

This is not a C++ style guide and not an exploit cookbook. The goal is to explain invariants, failure modes, binary artifacts, and defensive evidence.

Use this beside:

- [ELF, PE, loaders, and linkers Q&A](<04-binary-loaders-linkers-qa.md>)
- [Vulnerability research and exploitation primitives](<../05-topic-notes/vulnerability-research-and-exploitation-primitives.md>)
- [Hardware and OS security Q&A](<05-hardware-security-relationship-qa.md>)
- [ARM architecture differences](<../01-comparisons-and-maps/03-arm-architecture-differences.md>)
- [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>)
- [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)

Score meaning:

| Score range | Meaning |
|---|---|
| 95-100 | Core compiled C++ and concurrency model. Missing this breaks reversing and bug-class reasoning. |
| 90-94 | High-value binary-analysis, driver, and vulnerability-research depth. |
| 85-89 | Practical specialist detail that often separates strong analysts from surface-level analysts. |
| 80-84 | Role-dependent depth, useful for hard targets or toolchain-heavy work. |

## Priority Index

| Score | Area | Question |
|---:|---|---|
| 100 | Object lifetime | What is a C++ object at runtime, and why are lifetime, type, storage, and value not the same thing? |
| 100 | Undefined behavior | Why does undefined behavior change the generated assembly and security model? |
| 99 | Virtual dispatch | How do vtables, vfptrs, RTTI, thunks, and multiple inheritance appear in binaries? |
| 99 | Atomics core model | What does `std::atomic` guarantee, and what does it not guarantee? |
| 98 | Atomic opcodes | What enables an operation to be atomic at the CPU level, and which opcodes/instructions should a reverser recognize? |
| 98 | Memory ordering | How do acquire, release, relaxed, seq_cst, fences, and compiler barriers differ? |
| 98 | RAII and cleanup | How do constructors, destructors, scope exits, exceptions, and abnormal termination affect security analysis? |
| 97 | Smart pointers | How do `unique_ptr`, `shared_ptr`, `weak_ptr`, intrusive refs, and COM-style refs differ internally? |
| 97 | Refcount security | Why do reference counting and ownership bugs become UAF, leaks, races, or object resurrection? |
| 97 | Move semantics | How do move constructors, moved-from states, and forwarding affect ownership and binary shape? |
| 96 | Templates | How do templates, specialization, CRTP, concepts, and type erasure affect binary size and reversing? |
| 96 | Optimization | How do inlining, devirtualization, copy elision, NRVO, LTO, PGO, and alias analysis change assembly? |
| 95 | Containers | What are the security-relevant invariants of `vector`, `string`, `deque`, `map`, and `unordered_map`? |
| 95 | Iterator invalidation | Why are stale iterators, references, spans, and views a serious lifetime class? |
| 95 | Windows wrappers | How do Windows/Google-style C++ wrappers around handles, COM pointers, locks, and NT types change the analysis? |
| 94 | Intrinsics | How do compiler intrinsics, builtins, inline asm, and volatile differ from C++ atomics? |
| 94 | Lock-free patterns | What are CAS loops, ABA, hazard pointers, epochs, seqlocks, and RCU-style publication? |
| 94 | C stdio locking | How do `_unlocked`, `flockfile`, and stdio internal locks affect thread-safety and audit meaning? |
| 93 | Layout | How do padding, alignment, bitfields, empty-base optimization, strict aliasing, and ABI rules affect bugs? |
| 93 | Exceptions/unwind | How do C++ exceptions, unwind metadata, SEH interop, and cleanup funclets appear in Windows and Linux binaries? |
| 93 | Lambdas/callbacks | How do lambdas, captures, `std::function`, callbacks, and member-function pointers lower into data structures? |
| 92 | Allocation | How do `new`, `delete`, sized delete, placement new, allocators, over-alignment, and pools affect exploitability? |
| 92 | Driver C++ | What is special about reversing or writing C++ inside `.sys` drivers and kernel-adjacent code? |
| 91 | ABI differences | Which MSVC versus Itanium/GCC/Clang ABI details matter to a reverser? |
| 91 | Data races | Why is a C++ data race not just a normal race condition, and how can it invalidate source-level reasoning? |
| 90 | Synchronization APIs | How do C++ mutexes and condition variables relate to futexes, `WaitOnAddress`, SRW locks, events, and interlocked operations? |
| 90 | Control-flow integrity | How do vtable verification, CFG/XFG, CET, CFI, and devirtualization constrain or reveal C++ dispatch? |
| 89 | Strings and spans | What are the security pitfalls of `std::string`, `wstring`, `string_view`, `span`, UTF-16, and Windows string wrappers? |
| 89 | Integer and size types | Why do signedness, truncation, `size_t`, iterator differences, and template deduction create boundary bugs? |
| 88 | Sanitizers and hardening | What do ASan, UBSan, TSan, CFI, `/GS`, stack cookies, iterator debugging, and hardened allocators prove or not prove? |
| 88 | Reverse-engineering workflow | How should an analyst recover C++ classes, ownership, atomics, containers, and dispatch from optimized binaries? |
| 87 | Compiler fingerprinting | What compiler, standard library, CRT, and build-mode fingerprints matter in a C++ binary? |
| 86 | MMIO and devices | Why are atomics, volatile, memory barriers, cacheability, and MMIO ordering different but related? |
| 85 | Interview drills | What C++ internals questions should a security researcher be able to answer without source? |

## Best Answers

### 100 - Object Lifetime: Type, Storage, Value, And Lifetime

A C++ object is not just a region of bytes. The important pieces are storage, dynamic type, lifetime, value, alignment, and ownership. Storage can exist before an object lifetime begins, such as raw allocator memory. An object's lifetime begins through construction, implicit lifetime rules for some types, or placement construction. It ends through destruction, deallocation, or reuse of the storage for another object.

Security bugs often appear when code confuses these layers. A pointer may still point to the same address after destruction, but the object no longer exists. Bytes may still look like the old type, but reading them through the old pointer can be undefined behavior or a stale-object access. Placement new can create a new object in the same storage, so address equality does not prove type or lifetime equality.

For reversing, object lifetime appears as constructor calls, destructor calls, vptr stores, allocator calls, cleanup funclets, reference-count transitions, and error-path cleanup. In optimized binaries, many calls disappear, but lifetime still leaves traces: stores that initialize fields, guard variables for static locals, unwind metadata, refcount updates, container growth, and calls to delete/free on exceptional or early-return paths.

Security phrasing: identify who owns the storage, who owns the object lifetime, who is allowed to observe it, and what transition makes stale pointers invalid. A refcount, lock, handle, or smart pointer may keep memory alive, but it does not automatically prove the object is in a valid semantic state.

### 100 - Undefined Behavior: Optimizer Contract And Security Impact

Undefined behavior is not just "the program may crash." It means the C++ abstract machine imposes no requirements for that execution, so the compiler can optimize under the assumption that the undefined case never occurs. This affects assembly directly. Signed overflow, out-of-bounds access, invalid downcasts, use-after-lifetime, strict-aliasing violations, uninitialized reads, and data races can let the optimizer remove checks, hoist loads, fold branches, or transform loops in ways that surprise source-level readers.

The security consequence is that a source check may not exist in the final binary if the compiler proves it unnecessary under the language rules. For example, if a pointer is dereferenced before a null check, the compiler may treat later null checks as dead. If signed overflow is impossible in defined C++, overflow checks written after overflowing arithmetic may optimize away. If a race exists on non-atomic data, source ordering becomes unreliable.

Do not analyze optimized C++ as line-by-line C with classes. Ask which assumptions the compiler was allowed to make: no UB, correct alignment, valid object lifetime, no illegal aliasing, no data races, no impossible enum values, no out-of-bounds iterators. Then compare source intent to actual emitted branches, memory references, and sanitizer or hardening build flags.

In vulnerability research, UB is both a bug source and a triage constraint. A proof should name the concrete violated invariant and show the binary effect: missed bounds check, stale pointer use, type confusion, bad length, wrong dispatch, or unreachable-looking path that is reachable with attacker-controlled input.

### 99 - Virtual Dispatch: Vtables, RTTI, Thunks, And Multiple Inheritance

Most C++ implementations lower virtual dispatch to a hidden pointer in the object, often called a vfptr or vptr, that points to a vtable. A virtual call loads the vptr from the object, loads a function pointer from a fixed vtable slot, adjusts `this` if needed, and branches indirectly. Constructors and destructors write vptr values as the object moves through base and derived construction states, so a constructor-time virtual call may dispatch differently than a normal post-construction call.

Multiple inheritance can create multiple base subobjects inside one complete object, each with its own vptr or layout view. Calls through a secondary base pointer may require a thunk that adjusts `this` before entering the real function. Destructors may have deleting and non-deleting variants. RTTI structures, type descriptors, complete-object locators, and class hierarchy descriptors can help recover class relationships when present, especially in MSVC binaries.

Security relevance is direct. A corrupted vptr, stale object reused as another type, or overwritten callback-like field can redirect control flow without patching code bytes. A CFI or CFG-like mitigation may restrict some indirect calls, but data-only object corruption can still change which valid target is chosen. Defenders should verify whether vtable pointers land in expected read-only image ranges and whether the pointed table belongs to the expected module and class family.

For `.sys` drivers, vtable-like dispatch may appear in C++ driver classes, WDF callback tables, manually built operation tables, or C-style `DRIVER_OBJECT` dispatch arrays. The analysis question is the same: what object owns the dispatch pointer, what code is an allowed target, and who can mutate the object or table?

### 99 - Atomics Core Model: What `std::atomic` Guarantees

`std::atomic<T>` gives operations on a specific atomic object indivisible behavior according to the selected memory order. It prevents ordinary data races on that atomic object and gives the compiler a synchronization contract it must preserve. For lock-free atomic types, the compiler often emits a single hardware atomic instruction or a short retry loop. For non-lock-free widths or unusual types, the implementation may call a runtime lock-based helper.

Atomic does not mean "the whole algorithm is safe." An atomic counter can be correct while the object it counts is already logically dead. A relaxed atomic increment can prevent torn counter updates but may not publish initialized object fields to another thread. A compare-exchange can update a pointer atomically while still suffering ABA if the same address is removed, freed, reused, and reinserted.

The C++ memory model is about both compiler and CPU ordering. The compiler must not reorder atomic operations in ways forbidden by the standard, and the emitted machine code must be strong enough for the target architecture. On x86/x64, the hardware memory model is relatively strong, so many acquire/release operations compile to plain loads/stores plus compiler constraints. On ARM/AArch64, the compiler often needs acquire/release instructions or explicit barriers.

A good answer separates atomicity, ordering, visibility, and lifetime. Atomicity says whether an individual operation tears or interleaves. Ordering says which other memory operations become visible before or after it. Visibility says when another core can observe writes. Lifetime says whether the pointee or containing object is still valid. Only the combination makes a concurrent design secure.

### 98 - Atomic Opcodes: What Enables CPU-Level Atomicity

Hardware atomicity is enabled by the CPU, cache-coherence protocol, memory type, alignment, operation width, and instruction semantics. On normal cacheable memory, aligned naturally sized loads and stores are usually atomic up to architectural limits. Read-modify-write operations need stronger machinery: the core must obtain exclusive ownership of the cache line or use an architecture-specific exclusive monitor so no other core can interleave a conflicting update.

On x86/x64, common atomic instructions include `lock cmpxchg`, `lock xadd`, `lock inc`, `lock dec`, `lock or`, `lock and`, and `xchg` with memory. `cmpxchg16b` supports 16-byte compare-exchange where available and correctly aligned. Fences include `mfence`, `sfence`, and `lfence`, though locked operations also provide strong ordering. Many ordinary aligned loads/stores are already atomic, but not all are ordering fences.

On AArch64, older or portable code often uses load-linked/store-conditional style instructions such as `ldxr`/`stxr` and acquire/release variants such as `ldaxr`/`stlxr`. Newer Large System Extensions can use single-instruction atomics such as `cas`, `swp`, `ldadd`, and acquire/release variants where the target CPU and compiler flags allow them. Barriers include `dmb`, `dsb`, and `isb`, and acquire/release loads/stores include forms such as `ldar` and `stlr`.

What affects the emitted opcode:

| Factor | Why it matters |
|---|---|
| ISA and CPU feature flags | Determines whether the compiler can use `cmpxchg16b`, AArch64 LSE atomics, AVX-sized operations, or helper calls. |
| Type size and alignment | Misaligned or too-wide atomics may be slower, fault, be non-lock-free, or call a library helper. |
| Memory order | Relaxed, acquire, release, acq_rel, and seq_cst can require different barriers, especially on weakly ordered architectures. |
| Memory type | Normal cacheable RAM differs from uncacheable, write-combined, device, or MMIO memory. |
| Compiler and standard library | MSVC, GCC, Clang, libstdc++, libc++, and MS STL can choose different lowering strategies. |
| Optimization level and inlining | Debug builds may call helpers; optimized builds inline atomic sequences. |
| Kernel/user context | Kernel code may use architecture or OS primitives with IRQL/preemption constraints instead of `std::atomic`. |

For reversing, recognize the loop shape: load old value, compute new value, `cmpxchg` or `stxr`, retry on failure. Also recognize that the absence of a visible `lock` prefix does not prove non-atomicity on every architecture or for every operation; some atomic loads/stores lower to ordinary instructions plus ordering rules.

### 98 - Memory Ordering: Acquire, Release, Relaxed, Seq_Cst, And Fences

Memory ordering answers which operations become visible before or after an atomic operation. `memory_order_relaxed` gives atomicity for the object but no cross-object ordering. It is useful for counters, statistics, and cases where ordering is supplied elsewhere. It is dangerous when used to publish pointers or state that other threads dereference.

Release stores publish prior writes before making a flag or pointer visible. Acquire loads consume that published state after observing the flag or pointer. Together they form the usual "initialize object, release-publish pointer; acquire-load pointer, then read object" pattern. `memory_order_acq_rel` is common for read-modify-write operations that both observe prior state and publish new state.

`memory_order_seq_cst` adds a single global order among sequentially consistent atomic operations. It is easier to reason about but can be more expensive or obscure the real invariant if used everywhere. Fences order operations without necessarily touching the same atomic object, but they are easy to misuse because a fence needs a synchronization partner.

Compiler barriers and CPU barriers are different. A compiler barrier stops compile-time reordering around a point but may emit no hardware fence. A CPU barrier constrains hardware visibility or speculation but does not automatically make non-atomic data race-free. `volatile` is not a substitute for atomics; it is primarily about observable accesses, signal/MMIO-like cases, and implementation-specific behavior.

Security relevance: many race bugs are ordering bugs rather than missing-lock bugs. If a consumer sees a "ready" flag before the payload is initialized, the bug may only reproduce on ARM or under optimization. A strong analysis names the publication variable, the protected payload, the required ordering, and the lifetime rule after publication.

### 98 - RAII And Cleanup: Constructors, Destructors, Exceptions, And Abnormal Exit

RAII ties resource lifetime to object lifetime. A constructor acquires or initializes a resource; a destructor releases it. This pattern is common for memory, handles, locks, COM references, mapped views, registry keys, tokens, device handles, and driver objects. In normal scope exit, destructors run in reverse construction order. If an exception unwinds the stack, destructors for fully constructed objects run as cleanup.

This matters in binaries because cleanup code may appear far from the source line that acquired the resource. MSVC may emit cleanup funclets and unwind maps; Itanium-style EH uses personality routines and landing pads. Optimized code may merge cleanup paths, inline destructors, or delete apparently redundant stores. A reverser should look for paired acquire/release calls and for cleanup reachable from both success and error edges.

Abnormal termination changes the model. `TerminateProcess`, fatal signals, bugchecks, power loss, `_exit`, driver unload failure, and some low-level abort paths can bypass ordinary C++ cleanup. In kernel code, exceptions may be disabled or restricted, and many destructors must not run at an IRQL or lock state that makes blocking illegal.

Security consequence: RAII reduces leaks and UAFs when the lifetime model is correct, but it can hide dangerous side effects in destructors. Destructors can release locks, close handles, decrement refs, unregister callbacks, free memory, flush data, or execute arbitrary code. A destructor running under loader lock, a kernel lock, or during process teardown can become a deadlock, reentrancy, or use-after-free surface.

### 97 - Smart Pointers: Unique, Shared, Weak, Intrusive, And COM-Style

`std::unique_ptr<T>` is usually just a raw pointer plus possibly a deleter. It expresses exclusive ownership and destroys the object when the unique pointer is destroyed or reset. With a stateless deleter it is often pointer-sized; with a stateful deleter it grows. In assembly, it may disappear entirely after inlining, leaving only conditional delete calls.

`std::shared_ptr<T>` uses a control block that holds strong and weak reference counts plus deleter/allocator state. The object may be allocated separately from the control block or together via `make_shared`. `std::weak_ptr<T>` observes the control block without keeping the object alive; `lock()` tries to create a strong reference if the object still exists. The control block itself remains until weak refs are gone.

Intrusive reference counting stores the count inside the object. COM-style `AddRef`/`Release`, Chromium-style ref-counted objects, kernel object refs, and many driver/framework wrappers follow this shape. Intrusive refs improve locality and let existing APIs control lifetime, but they make counter corruption or wrong ownership transfers directly affect the object.

Security questions:

| Pointer model | Main invariant | Common failure |
|---|---|---|
| `unique_ptr` | Exactly one owner destroys once. | Raw alias outlives owner, wrong deleter, moved-from misuse. |
| `shared_ptr` | Object lives while strong count is nonzero. | Cycles, aliasing constructor confusion, control-block split, racing raw pointer use. |
| `weak_ptr` | Observer must promote before use. | Check-then-use without strong ownership. |
| Intrusive ref | Ref transitions are balanced across all paths. | Refcount underflow/overflow, missing ref on async callback, release while still reachable. |
| COM pointer | `AddRef`/`Release` and apartment/threading rules match interface use. | Borrowed interface treated as owned, stale callback, wrong thread/context. |

Smart pointers are evidence of intent, not proof of safety. A raw pointer obtained from `get()`, a captured `this`, a callback registered with a borrowed pointer, or an async operation that outlives the owner can bypass the smart-pointer invariant.

### 97 - Refcount Security: UAF, Leak, Race, And Resurrection

Reference counts protect lifetime by delaying destruction until the last reference is released. They do not protect semantic validity, authorization, state transitions, or object membership in a table. An object can be alive but closed, revoked, disconnected, canceled, or logically removed.

Refcount bugs become security bugs when an attacker can create an imbalance or race. A missing increment before publishing a pointer can lead to UAF. A missing decrement can leak resources and cause denial of service. An extra decrement can prematurely destroy an object. Overflow can wrap a count back to a low value. Object resurrection can happen when code obtains or publishes a reference during or after destruction.

Concurrency makes refcounts harder. The refcount operation must be atomic if multiple threads can change it, but the last-release path also needs ordering: all prior object updates must be visible before destruction, and no new refs should appear after the object is marked unreachable unless the design explicitly supports that. Linux RCU, Windows rundown protection, hazard pointers, epochs, and weak-to-strong promotion are different ways of managing this boundary.

For auditing, draw the ownership graph. Name each edge: table owns object, callback owns reference, async request owns reference, caller borrows pointer, handle owns reference, weak observer does not own. Then inspect every transition: insert, lookup, publish, cancel, unregister, callback start, callback end, close, final release, destructor, and memory free.

### 97 - Move Semantics: Ownership Transfer And Moved-From State

Move semantics let C++ transfer resources without deep copying. A move constructor or move assignment usually steals pointers, handles, buffer ownership, or control-block references from one object to another, then leaves the source in a valid but unspecified or explicitly empty state. In optimized binaries, move operations often look like a few pointer copies and stores that zero or sentinel the source.

The security risk is using a moved-from object as if it still owns the resource. A moved-from `unique_ptr` is null, but a moved-from wrapper type may still carry flags, lengths, callbacks, or partially cleared fields. Move assignment also has to release the destination's previous resource and handle self-move or exception paths correctly.

Forwarding references and `std::move` can make ownership transfer less visible at the source level. `std::move` is only a cast; the actual move happens when a move constructor or assignment is invoked. Template code may accidentally move from a value more than once, capture references that outlive their target, or forward a borrowed object into an async task.

For reverse engineering, look for wrapper objects being passed by hidden address, field-wise pointer stealing, source field clearing, and destructor calls that conditionally release only if a field remains non-null. For security review, ask whether every moved-from state still satisfies class invariants and whether observers were invalidated.

### 96 - Templates: Specialization, CRTP, Concepts, And Type Erasure

Templates are compile-time code generation. A function template or class template can produce many concrete instantiations with different types, sizes, layouts, and calling patterns. This is why optimized C++ binaries can contain many similar functions with long mangled names or no names at all after stripping.

Specialization changes behavior for specific types. Partial specialization, overload resolution, SFINAE, and concepts can select different code paths based on type traits. A reviewer cannot assume one instantiation validates the same way as another; signedness, width, iterator category, allocator, deleter, and exception guarantees can all change the generated code.

CRTP uses templates for static polymorphism: the base template calls into the derived type without virtual dispatch. It may inline heavily and leave no vtable. Type erasure, by contrast, hides concrete types behind an erased wrapper such as `std::function`, `std::any`, `std::shared_ptr` deleters, allocator interfaces, COM interfaces, or custom operation tables.

Reversing implication: templates can make one source abstraction appear as many unrelated machine-code bodies, while type erasure can make many source types appear through one dispatch wrapper. Recover the concrete instantiation by inspecting argument sizes, allocator/deleter fields, vtable or manager function pointers, mangled names if present, and call targets after inlining.

### 96 - Optimization: Inlining, Devirtualization, Copy Elision, LTO, PGO, And Alias Analysis

Modern C++ performance depends on optimization. Inlining removes function-call boundaries and exposes fields, bounds checks, and destructor paths to further transformations. Copy elision and NRVO can eliminate temporary objects. Devirtualization can turn an indirect virtual call into a direct call when the compiler can prove the dynamic type. LTO and whole-program optimization give the compiler visibility across translation units. PGO uses runtime profiles to lay out hot paths and guide branch decisions.

Security analysts care because the binary may not preserve source structure. A bounds check may be merged with another check, a virtual call may become a direct call, a destructor may be inlined into multiple exits, and a container operation may lower to raw pointer arithmetic. Conversely, debug builds may contain helper calls and iterator checks that do not exist in release builds.

Alias analysis is especially important. The compiler assumes accesses through incompatible types do not alias except under allowed rules. Violating strict aliasing can make the optimizer reuse stale values or reorder memory operations. `char`/byte views, `std::bit_cast`, `memcpy`, unions, and compiler extensions each have different rules.

When triaging a vulnerability, answer at the binary level: did the check survive, what range was used for the copy, which pointer was trusted, did the branch depend on signed or unsigned comparison, and were object fields read before or after publication? Source intent is not enough.

### 95 - Containers: Vector, String, Deque, Map, And Unordered Map

`std::vector<T>` is usually a contiguous buffer with begin/end/capacity pointers or equivalents. Growth reallocates and moves/copies elements, invalidating pointers, references, iterators, spans, and views into the old buffer. Bugs often involve stale references after `push_back`, size/capacity confusion, integer overflow in allocation sizing, or trusting unvalidated indices.

`std::basic_string` often uses small-string optimization, where short strings live inside the object rather than a heap allocation. This changes memory layout and can confuse naive heap assumptions. String bugs often involve UTF-8/UTF-16 unit confusion, null-termination assumptions, signed length conversions, and views outliving the string.

`std::deque` stores elements in blocks, so it is not one contiguous array. `std::map` and `std::set` are tree-shaped node containers with stable node addresses but pointer-heavy metadata. `std::unordered_map` is bucket plus node or implementation-specific hash-table state; collision behavior, rehashing, iterator invalidation, and attacker-controlled keys matter for performance and sometimes DoS.

Security review should name the container invariant:

| Container | Key invariant | Security failure |
|---|---|---|
| `vector` | `size <= capacity`, elements contiguous, reallocation invalidates aliases. | Stale pointer/view, OOB index, length overflow. |
| `string` | Length is not necessarily same as C-string visible bytes; SSO changes storage. | Truncation, encoding confusion, stale `c_str()`. |
| `deque` | Segmented storage, not flat contiguity. | Treating blocks as one array. |
| `map` | Ordered tree nodes and comparator define identity. | Bad comparator, iterator lifetime, logic bypass. |
| `unordered_map` | Hash/equality and bucket state define lookup. | Collision DoS, bad equality/hash mismatch, rehash invalidation. |

Do not overgeneralize across standard library implementations. MS STL, libstdc++, libc++, debug iterator mode, sanitizer mode, and ABI versions can change layout and checks.

### 95 - Iterator Invalidation: Stale Iterators, References, Spans, And Views

Iterator invalidation is a lifetime problem. Many C++ APIs return lightweight objects that do not own the underlying storage: iterators, references, pointers, `string_view`, `span`, ranges views, and `c_str()` pointers. They are safe only while the underlying container and the relevant elements remain alive and unmoved.

Security bugs arise when a non-owning view crosses a mutation, reallocation, erase, async boundary, callback boundary, or lock boundary. A vector reallocation can make a saved element pointer stale. A string view can outlive a temporary string. An iterator into an unordered map can become invalid after rehash. A span can outlive a stack buffer.

This is especially relevant in parser and broker code. A parser may keep a view into an input buffer, then normalize or append to the buffer and continue using the old view. A broker may validate a path string through one view, then later use a different mutable string. A callback may capture `this` or a reference to a container element that is erased before the callback runs.

The fix model is not "use modern C++" by itself. The fix is to make ownership explicit: copy the data that must outlive the source, keep an owning object alive, prevent mutation while views exist, use stable node containers where appropriate, or store indexes/generations instead of raw iterators when the container can reallocate.

### 95 - Windows Wrappers: Handles, COM, Locks, And NT Types

Large Windows C++ codebases often wrap low-level OS resources in RAII types. Examples include `unique_handle`, `wil::unique_handle`, `base::win::ScopedHandle`, `WRL::ComPtr`, `wil::com_ptr`, `CComPtr`, `base::win::ScopedCOMInitializer`, `std::lock_guard`, `wil::scope_exit`, `unique_hlocal`, mapped-view wrappers, registry-key wrappers, token wrappers, and NTSTATUS/HRESULT helper types.

These wrappers change the analysis because the dangerous operation may be in a constructor, destructor, `reset`, `release`, `attach`, `detach`, or move assignment rather than beside the API call. `release()` often means "stop owning without closing"; `reset()` usually means "close old resource and take new one"; `attach()` may adopt a borrowed raw handle; `detach()` may leak ownership intentionally to a caller.

COM wrappers add reference-count and threading/apartment rules. `ComPtr`-style assignment may call `AddRef`; destruction calls `Release`. Interface pointers can have different vtables for the same object identity. QueryInterface changes the interface view, not necessarily the underlying object. A stale COM callback or wrong apartment transition can become a lifetime or reentrancy bug.

For security review, map wrapper operations to the underlying authority:

| Wrapper resource | Underlying authority |
|---|---|
| Handle wrapper | Object Manager handle plus granted access mask. |
| Token wrapper | Security context and privileges. |
| File mapping/view wrapper | Section object and mapped memory. |
| COM pointer | Interface pointer plus refcount and apartment context. |
| Lock wrapper | Critical section, SRW lock, mutex, push lock, spin lock, or custom primitive. |
| Scope-exit wrapper | Arbitrary cleanup code at control-flow edges. |

When reversing, identify wrapper destructors and move paths early. They often explain why handles close, refs drop, locks release, or callbacks unregister on edges that are not obvious from the main call path.

### 94 - Intrinsics: Builtins, Inline Assembly, Volatile, And Atomics

Intrinsics are compiler-recognized operations that map to special instructions or runtime helpers while still participating in optimization. MSVC `_Interlocked*`, `_ReadWriteBarrier`, `__cpuid`, `_mm_*`, and GCC/Clang `__atomic_*`, `__sync_*`, `__builtin_*`, and vector intrinsics are examples. They can be lower-level than C++ library APIs but are still compiler contracts, not ordinary function calls.

Inline assembly is different. It can express instructions the compiler does not otherwise expose, but it also creates register, memory, and optimization constraints. Bad constraints can make the compiler assume memory was unchanged or registers are available when they are not. On x64 MSVC, inline asm is not generally available, so intrinsics are common in Windows low-level code.

`volatile` is frequently misunderstood. It can force observable loads/stores for volatile objects, which is useful for memory-mapped registers and some low-level polling contracts, but it does not make compound operations atomic and does not create C++ inter-thread synchronization by itself. A volatile read can still race with non-atomic data in the C++ model.

Reversing rule: distinguish these cases:

| Source construct | Binary hint | Meaning |
|---|---|---|
| `std::atomic` | `lock` instruction, LL/SC loop, LSE op, or helper call | C++ synchronization contract. |
| Interlocked intrinsic | `lock` instruction or compiler intrinsic lowering | Windows atomic primitive, often full-barrier or documented ordering variant. |
| Compiler barrier | No hardware instruction or minimal marker | Prevents compiler reordering only. |
| CPU fence | `mfence`, `dmb`, `dsb`, etc. | Hardware ordering constraint. |
| `volatile` MMIO | Repeated visible loads/stores | Device or observable-memory access, not a mutex. |

### 94 - Lock-Free Patterns: CAS Loops, ABA, Hazard Pointers, Epochs, Seqlocks, And RCU

A compare-exchange loop reads an old value, computes a new value, and tries to swap only if the old value is still current. If another thread changed it, the loop retries. This pattern underlies many lock-free stacks, queues, counters, and state machines. Its safety depends on both the atomic operation and the lifetime of any pointed-to objects.

ABA happens when a value changes from A to B and back to A, so a compare-exchange sees the expected value but misses the intervening mutation. Pointer-based lock-free structures are vulnerable if nodes can be freed and reused at the same address. Tags, version counters, hazard pointers, epochs, reference counts, and RCU-style grace periods are common ways to manage this risk.

Seqlocks let readers retry if a sequence counter changes during the read. They are useful when reads are frequent and can tolerate retry, but readers must not follow unstable pointers unless the lifetime is protected separately. RCU lets readers traverse published pointers while updaters replace structures and defer freeing until pre-existing readers finish.

Security analysis should ask:

1. What is the atomic state variable?
2. What non-atomic payload does it protect or publish?
3. What prevents ABA or stale object reuse?
4. What memory order publishes initialization and observes removal?
5. What prevents freeing while readers still hold derived pointers?

Lock-free code is not automatically faster or safer. It trades simple mutual exclusion for a more explicit proof obligation around ordering, lifetime, progress, and reclamation.

### 94 - C Stdio `_unlocked`, `flockfile`, And Audit Meaning

The C/POSIX `_unlocked` stdio family, such as `fputc_unlocked`, `getc_unlocked`, `putc_unlocked`, and `fwrite_unlocked`, is a libc performance/concurrency contract. These calls skip the internal `FILE *` lock that ordinary stdio calls normally take. They are not Linux kernel "unlocked ioctl" style functions and they do not disable OS locking.

Correct patterns are narrow:

| Pattern | Meaning |
|---|---|
| Stream is thread-local | `_unlocked` avoids unnecessary lock overhead. |
| Caller holds `flockfile(stream)` | Multiple stdio operations can be serialized as one region, then `funlockfile(stream)` releases it. |
| Higher-level lock protects all access | Safe only if every path touching that `FILE *` obeys the same lock. |

Security relevance is usually indirect but real. In a multi-threaded service, remote-controlled requests may drive concurrent logging, error output, protocol replies, or audit records. If code uses `_unlocked` without a real serialization rule, the result can be interleaved logs, broken framing, stale buffer assumptions, cancellation/deadlock bugs around `flockfile`, or data races on a stream that another thread closes, rotates, or reassigns. Treat this as an application/runtime race surface, not as a standalone privilege-escalation primitive.

### 93 - Layout: Padding, Alignment, Bitfields, EBO, Aliasing, And ABI

C++ object layout is an ABI contract, not a universal source-language constant. Non-static data members usually appear in declaration order subject to alignment and padding, but inheritance, virtual bases, empty-base optimization, `[[no_unique_address]]`, packing pragmas, bitfields, and ABI rules can change offsets and size.

Padding bytes may contain uninitialized data. Comparing raw structs, hashing raw bytes, serializing in-memory layout, or copying across trust boundaries can leak data or create compatibility bugs. Bitfields are implementation-defined in layout details such as allocation unit and ordering, so they are risky in wire formats and reverse-engineering assumptions.

Strict aliasing and alignment matter. Reading an object through an incompatible pointer type can be undefined behavior. Misaligned access may be slower, may fault, or may be split into multiple operations depending on architecture and memory type. Atomic operations are especially sensitive to alignment and width.

For reversing, recover layout from field offsets, constructor stores, vptr writes, RTTI where available, array indexing scale, and calls that pass `this + offset`. For exploitability, identify whether a corruptible field is padding-adjacent, a length, a pointer, a vptr, a refcount, a capacity, a state enum, or an allocator metadata field.

### 93 - Exceptions And Unwind: Cleanup Paths In Binaries

C++ exceptions are runtime control flow. Throwing constructs an exception object, searches for a handler, unwinds frames, and runs destructors for fully constructed automatic objects. Windows C++ EH interacts with SEH machinery and MSVC-specific metadata. Linux and many non-MSVC environments commonly use Itanium ABI-style EH tables, personality routines, and LSDA information.

In optimized Windows x64 binaries, cleanup may appear as funclets with unwind metadata. Destructors may be reached through exceptional paths, normal returns, and partially constructed object cleanup. A constructor that fails after constructing field A but before field B must clean up A but not B. This creates multiple state-specific cleanup paths.

Security relevance:

| Area | Why it matters |
|---|---|
| Parser failures | Error paths can double-free, leak, or use partially initialized objects. |
| Locks and RAII | Unwind may release locks on paths a manual audit misses. |
| `noexcept` | Throwing through `noexcept` terminates, changing cleanup and reliability. |
| Cross-module EH | ABI/CRT mismatch can break exception propagation assumptions. |
| Malware/protectors | Exception dispatch can hide control flow or anti-analysis behavior. |

When reversing, do not treat exception metadata as mere debugging information. It can describe real cleanup and dispatch edges needed to explain resource lifetime and hidden behavior.

MSVC Structured Exception Handling is a separate language extension: `__try`/`__except` and `__try`/`__finally`, not ISO C++ `try`/`catch`. In C++ code, a function that contains SEH and also has local objects or parameters requiring destructor unwinding can fail with C2712, "cannot use `__try` in functions that require object unwinding." This includes common types such as `CString`, `std::string`, smart pointers, containers, and RAII locks.

The reason is that SEH filtering and C++ object unwinding are different cleanup models. C++ exceptions must run destructors for fully constructed automatic objects as control leaves scopes. SEH handles low-level Windows exceptions and may continue execution, continue search, or execute a handler. MSVC can make some SEH and C++ EH interactions work under selected `/EH` modes, but the safe engineering pattern is narrow: put raw SEH probing in a tiny C-like helper with no destructor-bearing locals, then call it from ordinary C++ code that owns the RAII objects. Do not wrap a complex C++ function body containing RAII state in `__try` and expect portable or clean unwinding semantics.

### 93 - Lambdas, Captures, `std::function`, Callbacks, And Member Pointers

A lambda usually becomes an unnamed closure object with fields for captures and an `operator()`. Capturing by value copies data into the closure. Capturing by reference stores references or pointers to external objects. A non-capturing lambda can often decay to a plain function pointer.

`std::function` is a type-erased callable wrapper. It usually stores small callables inline through small-object optimization and larger callables on the heap. It carries manager/invoker function pointers or equivalent dispatch state. This makes it a useful reverse-engineering clue: an indirect call through a function wrapper may be a lambda, bound method, functor, or plain callback.

Member-function pointers can be more complex than raw function addresses, especially with multiple inheritance or virtual functions. They may include adjustment data or encode vtable slot information depending on ABI. Treating them as ordinary pointers is a common low-level mistake.

Security bugs often involve captured lifetime. Capturing `this` into an async callback does not keep the object alive. Capturing a reference to a stack variable into a delayed task creates a stale reference. Capturing a `shared_ptr` may fix lifetime but create cycles or unexpected object retention. A safe callback design states who owns the callable, who owns captured state, and how cancellation synchronizes with destruction.

### 92 - Allocation: New/Delete, Placement New, Allocators, Alignment, And Pools

`new` combines allocation and construction. `delete` combines destruction and deallocation. Arrays use array forms. Sized delete may pass size information to the deallocator when the compiler and ABI use it. Over-aligned types can use aligned allocation functions. Placement new constructs an object in caller-provided storage and does not allocate.

Custom allocators and pools are common in browsers, engines, EDRs, and drivers. They improve performance and control but change exploitability. Object reuse, quarantine, freelist encoding, size classes, slab caches, pool tags, and delayed free all affect UAF reliability and evidence. A type-specific pool can make replacement more predictable or, with hardening, deliberately less predictable.

Allocator-aware containers propagate allocators according to specific rules during copy, move, swap, and growth. A bug can appear when an object allocated by one allocator is freed by another, or when a container move leaves pointers into storage controlled by a different lifetime domain.

For analysis, identify allocation family and ownership pairings: `new/delete`, `new[]/delete[]`, `malloc/free`, COM task allocator, `LocalAlloc/LocalFree`, `HeapAlloc/HeapFree`, pool allocate/free, WDF object lifetime, or custom arena. Mismatched families can create corruption even when the pointer value looks valid.

On Windows, the common user-mode ladder is `new` or `malloc` -> CRT/UCRT allocator -> `HeapAlloc`/`RtlAllocateHeap` on some heap -> virtual-memory reserve/commit underneath. `LocalAlloc` and `GlobalAlloc` are compatibility APIs that wrap heap allocation on modern 32-bit and 64-bit Windows, but their allocation family still matters: free local/global allocations with the matching local/global function. Direct `VirtualAlloc` is different: it works at page granularity and usually appears as private VAD/MEM_PRIVATE data rather than as a normal heap block, although the heap manager may use virtual allocations internally for segments or large blocks.

Linux C/C++ allocation is also layered, but the vocabulary differs. `malloc` is supplied by libc or an interposed allocator such as glibc malloc, musl malloc, jemalloc, tcmalloc, mimalloc, Scudo, or a language runtime. Small allocations usually come from arenas/thread caches over `brk` or anonymous `mmap`; larger allocations often use `mmap` directly or allocator-managed extents. The compiler shapes ABI, constructors, destructors, sized delete, and optimization, but the allocator implementation usually comes from the runtime/library selected at link/load time.

### 92 - Driver C++: `.sys` Binaries And Kernel-Adjacent Constraints

C++ in drivers is constrained by kernel rules. Exceptions may be disabled or forbidden by project policy. RTTI may be absent. Standard library use may be limited. Allocation must respect IRQL, pool type, tag discipline, and nonpaged requirements. Destructors must not sleep or call pageable code at elevated IRQL. Static initialization and global destructors require careful driver-load and unload behavior.

Windows C++ driver binaries may still show constructors, destructors, vtables, thunks, template instantiations, security cookies, CFG-related metadata, WDF callback wrappers, COM-like or intrusive refcounting, and RAII wrappers around WDF objects, spin locks, remove locks, MDLs, Unicode strings, registry handles, and device interfaces.

Reverse-engineering `.sys` C++ should connect language artifacts to Windows driver artifacts:

| C++ artifact | Driver artifact to correlate |
|---|---|
| Class object | Device extension, context object, filter context, request context. |
| Virtual method | Dispatch helper, WDF callback, operation table, internal state-machine edge. |
| Destructor | Unregister callback, free pool, release WDF object, detach device, delete symbolic link. |
| Refcount | Remove lock, rundown protection, WDF object reference, custom lifetime. |
| Atomic/interlocked op | Reference transition, queue state, cancel state, fast path counter. |

Security research should focus on reachable interfaces: IOCTLs, IRPs, WDF queues, callbacks, registry/process/image callbacks, minifilters, WFP callouts, and device-controlled MMIO/DMA state. The C++ layer explains internal lifetime and dispatch; the OS layer explains who can reach it and with what authority.

### 91 - ABI Differences: MSVC Versus Itanium/GCC/Clang

C++ has no single binary ABI. MSVC and Itanium-style ABIs differ in name mangling, vtable layout details, RTTI structures, exception handling, member-function pointers, object construction/destruction variants, and standard-library layout. Linux GCC/Clang commonly use Itanium C++ ABI conventions for user-mode C++ on many architectures. Windows user-mode and kernel-mode MSVC code use MSVC ABI conventions.

Name mangling can reveal namespaces, classes, overloads, calling conventions, template arguments, and special member functions when symbols remain. RTTI can reveal class names and hierarchy, but it may be stripped or disabled. Standard-library type layouts are implementation-specific and can change by version and debug mode.

For reverse engineering, first fingerprint the compiler and ABI. Then use ABI-specific expectations for vtables, thunks, EH metadata, and object layout. Do not import Linux Itanium assumptions into a Windows MSVC driver, and do not assume MSVC standard-library layouts apply to a Clang/libc++ binary.

For security, ABI mismatches matter at module boundaries. Passing C++ objects, exceptions, allocators, STL containers, or ownership wrappers across DLL/shared-object boundaries can break if the modules disagree about compiler, CRT, allocator, or ABI. C-compatible APIs and explicit ownership contracts are safer boundaries.

### 91 - Data Races: C++ Race Versus Ordinary Race

In C++, a data race occurs when two threads access the same memory location concurrently, at least one access writes, and the accesses are not ordered by synchronization, unless the object is atomic or special rules apply. A data race is undefined behavior. This is stronger than saying "the result is nondeterministic."

The compiler may assume data races do not happen in well-defined code. It can cache a value in a register, hoist a load out of a loop, merge stores, or remove checks based on single-threaded reasoning unless atomics or synchronization tell it otherwise. A bug that seems like a rare stale read at source level may become an optimizer-enabled security issue.

Ordinary race-condition reasoning still matters: TOCTOU, check/use gaps, callback races, cancellation races, and object lifetime races can exist even with atomics. But C++ data-race UB adds another layer: non-atomic shared access can invalidate the entire source-level interleaving model.

The classic shared-counter drill should be answered in layers. A normal `counter++` is not one abstract indivisible operation; under a simplified lowering it is load, add, store. Formally the C++ answer is undefined behavior, but under a stated load/add/store model the maximum is the fully serialized count and the minimum can be lower than the intuitive "one thread's loop count" because stale stores can overwrite newer larger values. The full schedule and atomic version are in [Mobile OS and coding interview traps Q&A](<07-mobile-os-and-coding-interview-traps-qa.md#99---non-atomic-increment-trap>).

Security review should label shared fields as protected by a specific lock, atomic with a specific memory order, immutable after publication, thread-local, or unsafe. If a field does not fit one of those categories, it deserves scrutiny.

### 90 - Synchronization APIs: C++ Mutexes To OS Primitives

C++ synchronization APIs sit above OS and runtime primitives. `std::mutex` may use critical sections, SRW locks, pthread mutexes, futex-backed waits, or custom runtime code depending on platform and library. `std::condition_variable` combines a predicate protected by a mutex with an OS wait/wake primitive. `std::atomic::wait` and `notify_*` can lower to futex-like or `WaitOnAddress`-like mechanisms.

Windows code may use `Interlocked*`, critical sections, SRW locks, condition variables, events, semaphores, waitable timers, I/O completion ports, `WaitOnAddress`, push locks in kernel, spin locks, guarded mutexes, rundown protection, and dispatcher objects. Linux code may use futexes, pthread locks, eventfd, epoll, RCU, seqlocks, spinlocks, mutexes, completions, waitqueues, and atomics.

The key distinction is whether the primitive protects mutual exclusion, wait/wake coordination, lifetime, one-time initialization, reader/writer access, interrupt-safe state, or cross-process signaling. Using an atomic counter where a condition variable is needed can lose wakeups. Using a mutex where an IRQL-safe spin lock is required can crash or deadlock kernel code.

For reversing, wait APIs reveal blocking boundaries and synchronization domains. Atomic fast paths may avoid syscalls entirely until contention. The absence of waits does not mean absence of synchronization; tight loops with atomic operations may be lock-free or spin-based synchronization.

### 90 - Control-Flow Integrity: C++ Dispatch Under Mitigations

C++ indirect calls include virtual calls, function pointers, member-function pointers, callbacks, erased callables, exception handlers, and jump tables. Modern mitigations try to constrain those edges. Windows CFG validates many indirect call targets against a bitmap of allowed call targets. XFG adds type-like metadata for some calls. CET can protect returns with shadow stacks and constrain indirect branches on supported hardware and policy. Clang CFI and vtable verification approaches can restrict virtual dispatch when enough type information is available.

These mitigations do not make object corruption irrelevant. If an attacker can swap a vptr to another valid vtable with compatible call targets, corrupt a state field that changes a later valid branch, or redirect through a permitted callback, control flow may remain within allowed edges while semantics are wrong. Devirtualization can also remove indirect calls entirely, changing where mitigations apply.

For defensive analysis, inspect the actual binary properties: load-config metadata, CFG flags, compiler CFI settings, EH continuation metadata, CET compatibility, code-page protections, and whether indirect targets belong to expected modules. Then combine that with object-layout analysis: valid target does not mean valid object.

### 89 - Strings And Spans: Encoding, Views, And Windows Wrappers

`std::string` is a byte string, not inherently UTF-8. `std::wstring` is wide characters, but `wchar_t` differs by platform: 16-bit on Windows, commonly 32-bit on many Unix-like systems. Windows native and Win32 APIs commonly use UTF-16 strings, `UNICODE_STRING`, `PCWSTR`, `BSTR`, and wrapper types. Length may be in bytes, `wchar_t` units, UTF-16 code units, or characters depending on API.

`string_view` and `span` do not own data. They are excellent for avoiding copies but dangerous across lifetime boundaries. A `string_view` into a temporary, a span over a vector that reallocates, or a view into a parser buffer that is normalized in place can become stale while still carrying a plausible pointer and length.

Null termination is another boundary. `std::string` tracks length and can contain NUL bytes. C APIs often stop at NUL. `UNICODE_STRING` carries explicit byte length and may not be null-terminated. `BSTR` carries length metadata and can contain embedded NULs. Converting among these without preserving length and encoding can create truncation, path confusion, policy bypass, or logging mismatch.

Security phrasing: always state the unit and owner. Is this length in bytes or UTF-16 code units? Is the buffer owned or borrowed? Is it null-terminated? Can it contain embedded NULs? Is normalization done before or after authorization? Which exact path/string object is later used?

### 89 - Integer And Size Types: Signedness, Truncation, And Units

C++ integer bugs often come from mixing signed and unsigned values, narrowing from `size_t` to `int` or `DWORD`, multiplying element counts by element sizes, subtracting iterators, and converting between bytes, characters, pages, sectors, and structure counts. Templates can hide the concrete type until instantiation.

Unsigned overflow is defined modulo arithmetic, but that does not make it safe. Signed overflow is undefined behavior. A check such as `if (count * sizeof(T) < limit)` may be too late if the multiplication overflowed. A negative signed value converted to `size_t` can become huge. A `vector::size()` compared to `int` can produce surprising results if the value exceeds the signed range.

Reverse-engineering hints include sign-extending versus zero-extending instructions, signed versus unsigned conditional jumps, multiplication before allocation, shifts used as element-size scaling, and truncating stores to 16-bit or 32-bit fields before a copy.

Security review should track units explicitly. Write down: untrusted count, element size, maximum allowed bytes, allocation size, copy size, index type, destination capacity, and API length type. The invariant is not "checked length"; it is "the checked value is the same unit and width as the allocation and copy."

A recursive numeric function can fail in two separate ways at once: stack exhaustion from too many native frames, and false output from arithmetic wraparound. For example, a recursive product over a 32-bit `unsigned` can return exactly zero for a medium input once the mathematical result is divisible by `2^32`, while a huge input may crash before returning because the thread stack is exhausted. The full guard-page, overflow-check, input-parsing, and `-O3` discussion is in [Mobile OS and coding interview traps Q&A](<07-mobile-os-and-coding-interview-traps-qa.md#87---recursive-numeric-overflow-drill>).

### 88 - Sanitizers And Hardening: What They Prove

Sanitizers and hardening features improve evidence but do not prove absence of bugs. ASan finds many heap/stack/global OOB and UAF cases in instrumented builds, but it changes layout and may miss uninstrumented code or logic bugs. UBSan finds selected undefined behavior. TSan finds many data races but can report false positives or miss races through unsupported synchronization. MSVC iterator debugging and checked iterators catch many stale iterator cases in debug-like builds but often disappear in release.

Stack cookies (`/GS`), SafeSEH, SEHOP, CFG/XFG, CET, CFI, hardened allocators, guard pages, Driver Verifier, Special Pool, KASAN, KFENCE, and fuzzing sanitizers each degrade a class of bug or improve detection. They do not replace reasoning about reachability, object lifetime, authorization, and post-crash exploitability.

For a security researcher, the strongest use is comparative: run the same path under debug iterators, sanitizers, hardened allocators, verifier, and release optimization. If a crash only appears in optimized release, suspect UB, race, lifetime, or layout-sensitive behavior. If it only appears under sanitizer, inspect whether the sanitizer exposed a real bug by changing timing/layout.

Document the build context with every finding: compiler, optimization level, sanitizer flags, standard library, iterator-debug mode, architecture, mitigations, and target OS build. C++ bug behavior is often build-shaped.

### 88 - Reverse-Engineering Workflow: Recovering C++ From Optimized Binaries

Start by fingerprinting compiler, architecture, ABI, standard library, CRT, and build mode. Look for mangled names, RTTI, EH metadata, vtable regions, security-cookie patterns, import set, CRT startup, allocator calls, and standard-library helper names. On Windows, PDB/public symbols can radically change the analysis. In stripped binaries, layout and call patterns matter more.

Recover classes by grouping functions that take the same `this` pointer, use similar field offsets, write the same vptr, or appear in the same vtable. Constructors usually initialize fields and write vptrs. Destructors release fields and may call base destructors. Virtual methods are reachable from vtable slots. Thunks adjust `this`.

Recover ownership by pairing acquire and release operations: allocation/free, handle open/close, AddRef/Release, lock/unlock, map/unmap, register/unregister, reference/dereference, start/cancel/complete. Then inspect async edges where ownership often breaks: callbacks, thread starts, timers, overlapped I/O, work items, APCs, WDF requests, COM events, and futures/promises.

Recover atomics and containers by pattern. Atomics show locked instructions, LL/SC loops, LSE ops, barriers, or helper calls. Vectors show pointer triplets and reallocation. Strings show SSO branches. Hash maps show hash, bucket, equality, node traversal, and rehash logic. Smart pointers show control-block refs or intrusive `AddRef`/`Release` pairs.

The final analysis should connect language artifacts to security primitives: stale object, corrupted dispatch, wrong length, invalidated view, missing ref, bad memory order, wrong allocator family, or policy check/use mismatch.

### 87 - Compiler Fingerprinting: Toolchain, CRT, STL, And Build Mode

Compiler fingerprinting tells you which assumptions are safe. MSVC, Clang-cl, GCC, MinGW, Clang/libc++, libstdc++, MS STL, static CRT, dynamic CRT, debug iterators, LTO, PGO, and sanitizer builds all leave different artifacts. Function prologues, security cookies, EH metadata, RTTI layouts, allocator calls, mangling, import names, and standard-library helper names are useful signals.

Build mode matters. Debug C++ may preserve frame pointers, avoid inlining, use iterator checks, initialize memory with recognizable patterns, and call helper functions. Release C++ may inline heavily, fold branches, remove checks made redundant under UB assumptions, devirtualize calls, and erase abstraction boundaries.

For security findings, toolchain context is part of the evidence. A crash in a debug iterator build may indicate a real stale iterator, but exploitability in release must be re-evaluated. A race that reproduces on ARM but not x86 may be a memory-ordering bug hidden by x86's stronger model. A driver built with different Spectre/CFG/GS settings may have different useful primitives.

Do not rely on one compiler's STL layout as a universal reversing rule. Treat layouts as versioned implementation details unless the ABI guarantees them.

Compiler and heap implementation are related but not the same. Windows system binaries are generally built with Microsoft internal/MSVC-family toolchains, while third-party Windows binaries may be MSVC, clang-cl, MinGW GCC, Rust, Go, Delphi, .NET Native/AOT, or something custom. Linux kernels are traditionally GCC-built and also Clang-buildable; userland depends on the distribution and package. In both ecosystems, the heap behavior comes from the linked runtime/allocator and OS heap policy, not from "C++" in the abstract.

C++17 `inline static` class data members are another fingerprint. They allow a static data member definition to live in a header:

```cpp
struct State {
    inline static std::atomic<unsigned> generation{0};
};
```

This avoids the old requirement for one separate `.cpp` definition for many static data members. It does not create one copy per translation unit; the linker coalesces the inline variable into one program entity under the One Definition Rule. For reversing, expect COMDAT/linkonce-style storage, possible guard variables for dynamic initialization, and references from many object files to one merged symbol. It changes storage/linkage evidence, not the ordinary lifetime hazards of complex global initialization.

### 86 - MMIO And Devices: Atomics, Volatile, Barriers, And Cacheability

Memory-mapped I/O and device memory are not ordinary RAM. Device registers may have side effects on read or write, may require specific access widths, may not be cache-coherent, and may be ordered differently from normal memory. `volatile` can force the compiler to emit the access, but it does not create the full device ordering protocol by itself.

Atomics on MMIO are usually not the same as atomics on cacheable memory. A locked CPU instruction or LL/SC sequence assumes a memory system that supports the operation. Device memory may not support atomic read-modify-write semantics, or the operation may have meaningless side effects. Kernel and driver code therefore uses OS and architecture-specific accessors and barriers, such as read/write register helpers, memory barriers, DMA barriers, and cache maintenance APIs.

What enables correct device synchronization is a stack of guarantees: hardware memory type, page attributes, bus protocol, DMA/IOMMU mapping, cache coherency, driver barriers, interrupt ordering, and device specification. A missing barrier can mean the device sees a descriptor before the data is written, or the CPU reads stale completion state.

Security relevance is high for drivers. A device-controlled register, DMA ring, or descriptor queue is untrusted input. Driver code must validate device state, order memory correctly, and not treat MMIO reads as ordinary stable variables. For reversing, look for register access helpers, barriers, spin locks, interrupt/DPC paths, and DMA descriptor ownership bits.

### 85 - Interview Drills

Answer these at mechanism level, without target-specific offsets or exploit chains:

1. A C++ crash happens on a virtual call after a vector grows. Which lifetime and invalidation rules might explain it?
2. A `shared_ptr` object is still allocated but semantically closed. Why is "refcount is nonzero" not enough?
3. A Windows driver uses C++ wrappers around WDF objects and spin locks. Which destructors or move paths are security-sensitive?
4. A release build removes a null check that exists in source. Which undefined-behavior assumption could justify that?
5. An ARM64 build fails in a lock-free queue but x64 does not. Which memory-order and atomic-lowering differences matter?
6. A binary has many `lock cmpxchg` loops. How do you distinguish refcounts, once-init, lock-free stacks, and state machines?
7. A `string_view` crosses an async boundary. What owner must remain alive, and what mutation invalidates it?
8. A COM interface pointer is stored in a callback. Which `AddRef`/`Release` and apartment/threading rules must hold?
9. A hash map accepts attacker-controlled keys. What collision, equality, rehash, and iterator invalidation issues matter?
10. A `.sys` binary has C++ vtables. How do you connect them to IOCTL reachability, WDF callbacks, and object lifetime?
11. Many threads increment a non-atomic counter in a loop. Which answer changes when you switch from the C++ model to a stated load/add/store interleaving model?
12. A small recursive numeric function returns zero for a medium input and crashes for a huge input. Which parts are arithmetic semantics, stack mechanics, input parsing, and optimizer behavior?

## AppSec Guide Audit Deltas

Source: Trail of Bits [AppSec Guide: Security Checklist for C/C++ Programs](<https://appsec.guide/docs/languages/c-cpp/>), including the bug-class, Linux usermode, Linux kernel, Windows usermode, Windows kernel, and seccomp/BPF pages. The checklist is licensed under CC BY 4.0. The notes below are paraphrased and folded into this repo's mechanism-first model.

The guide does not replace the internals sections above. Its value is as a practical audit trigger list: "which exact API or language edge should I look for in a real codebase or binary?"

### Language And Library Review Pivots

| Audit pivot | Why it matters to security/reversing |
|---|---|
| Use-after-close and descriptor reuse | File descriptors and handles are authority-bearing table entries. Closing one and later reusing the numeric value can turn a stale saved descriptor into access to a different file/socket/object. Treat this as temporal safety, not only resource hygiene. |
| Use-after-scope, use-after-return, and lambda captures | Non-owning pointers, references, views, and captured references can outlive stack objects or temporaries. In binaries this often appears as callbacks, async tasks, stored closure objects, or returned internal buffers. |
| Partial free | Freeing a field but leaving the containing object alive, or freeing an object while its owned fields remain published, creates split lifetime. Draw object and subobject ownership separately. |
| Variadic and custom `printf`-style functions | Format strings are a type contract outside the C++ type system. Mismatched specifiers, attacker-controlled format strings, or missing compiler format annotations turn calls into memory disclosure or write primitives. |
| Locale, encoding, and normalization | String comparisons can depend on locale, encoding, case mapping, and normalization. Treat authorization checks on strings as path/object-identity checks, not character-display checks. |
| Initialization order | Static initialization across translation units can make one global object observe another before construction. Reverse-engineering clues include guard variables, global constructor tables, and pre-main initialization. |
| Time and clocks | Wall clocks can move backward or change discontinuously; monotonic clocks and deadline arithmetic are the safer model for security timeouts, token expiry, and race windows. |
| Sensitive zeroization | Ordinary zeroing can disappear if the compiler proves the buffer is dead. Use secure zeroing APIs or compiler-recognized primitives when keys, tokens, passwords, or credentials are involved. |
| Constant-time constructs | Optimizers can alter code intended to be constant-time. For cryptographic code, inspect generated code and use timing-analysis tooling instead of trusting source shape. |
| Debug-only assertions | Assertions removed from production builds are not security checks. Any invariant needed for memory safety or authorization must survive release optimization. |

### Linux User-Mode Review Pivots

| Audit pivot | Security model |
|---|---|
| Mitigation inventory | Record NX, PIE, stack cookies, RELRO, `_FORTIFY_SOURCE`, stack-clash protection, SafeStack/ShadowCallStack where relevant, and whether production binaries expose debug information. This sets exploitability constraints before bug triage. |
| Non-thread-safe and non-reentrant APIs | Functions returning static buffers or using shared process state can corrupt logic in threaded code and are unsafe in signal handlers. Signal handlers also need `errno` save/restore discipline. |
| Comparison length bugs | `std::equal`, `memcmp`, and `strncmp` become OOB reads when the compared length is computed from the wrong object or mismatched collection. Treat comparisons as memory reads, not harmless predicates. |
| Environment variables | `getenv`/`setenv` and inherited environments are authority-sensitive. Privileged programs should use secure environment access patterns and avoid leaking secrets through child process state or procfs-visible environments. |
| `access` then `open` | String/path checks followed by later opens are TOCTOU-prone. Prefer opening the object under constrained resolution and checking the resulting fd/object identity. |
| `O_CLOEXEC` and inherited fds | Missing close-on-exec leaks authority into child processes. This is the Unix twin of Windows handle-inheritance bugs. |
| Privilege dropping | Dropping user, group, supplementary group, and capability state is a sequence with failure cases. Check return values, verify the final identity, and account for inherited fd, signal, scheduling, resource-limit, and `NO_NEW_PRIVS` state. |
| Ambiguous error APIs | `mmap` fails with `MAP_FAILED`, not `NULL`; `atoi` has no error signal; `strtol`/`strtoull`, `dlsym`, `clock`, and EOF-style APIs need their documented side channel such as `errno` or `dlerror`. |
| Partial I/O and `EINTR` | `read` and `write` can succeed partially; many interrupted calls can be retried, but `close` is special and should not be blindly repeated after `EINTR`. |
| Overlapping buffers | `memcpy`, formatted output, and similar APIs can become undefined behavior when source and destination overlap. Use overlap-safe primitives only when the contract allows it. |
| String helper traps | `strlen` excludes the terminator while copy APIs often include it; `strncat` and `strncpy` are frequently misunderstood. Audit units, destination capacity, and termination explicitly. |
| Non-transitive comparators | Bad comparators for `qsort`, `std::sort`, or `std::stable_sort` can break algorithm invariants and become more than correctness bugs when attacker-controlled ordering is involved. |
| Network parsing quirks | APIs such as permissive IP parsers, `connect(AF_UNSPEC)`, and half-close behavior can create policy-bypass or state-machine surprises in network-facing C/C++ code. |
| Dynamic-size structs | Zero-length and one-element tail arrays are easy to size incorrectly. Prefer explicit flexible-array patterns and checked allocation arithmetic. |

### Linux Kernel Review Pivots

| Audit pivot | Security model |
|---|---|
| User memory annotations and copies | Treat `__user`, `copy_from_user`, `copy_to_user`, `get_user`, `strncpy_from_user`, `copy_struct_from_user`, `access_process_vm`, and GUP paths as trust-boundary code. Validate lengths, destination initialization, and padding before exposing data back to user mode. |
| SMAP windows | Code between `user_access_begin` and `user_access_end` runs while user access is deliberately enabled. Keep the window small and inspect every operation inside it. |
| Double fetch | Copying or reading user memory twice creates TOCTOU unless the first copy is pinned, copied to kernel memory, or otherwise stabilized. Hooks and instrumentation can widen the gap. |
| Kernel pointer leaks | Format strings and debug output can expose kernel addresses. Treat pointer formatting policy as part of KASLR and information-leak resistance. |
| fd handoff lifetime | After `fd_install`, user mode can close or duplicate the descriptor. Kernel code must not keep using descriptor identity as if user mode cannot change it; keep the real `struct file` reference when needed. |
| Kernel string length semantics | Kernel user-string helpers can count terminators differently from user-mode `strlen`. Audit length units and null-termination assumptions. |
| Refcount type and transitions | Use the right refcount primitive for the object. `refcount_t` communicates different safety intent than generic atomics, and ref-taking functions with failure returns must be checked. |
| Init-once read-only state | `__ro_after_init` is a useful signal for data that should become immutable after setup. Mutable init-once tables deserve scrutiny. |
| Allocation family matching | Pair `kmalloc/kfree`, `vmalloc/vfree`, and other allocation families correctly; check allocation failures; prefer zeroing allocation helpers where disclosure is possible. |
| Namespace-aware capability checks | Root inside a user namespace is not the same as host authority. Check the correct credential, namespace, creator, owner, and capability domain for procfs/sysfs/device/netlink administrative paths. |
| Module ownership | File operation and filesystem type structures should keep module lifetime correct, usually through owner fields such as `THIS_MODULE`. Missing ownership creates unload/lifetime hazards. |

### Windows User-Mode Review Pivots

| Audit pivot | Security model |
|---|---|
| Mitigation inventory | Use binary-level checks for DEP/NX, ASLR/High Entropy VA, CFG, CET/shadow stack where relevant, SafeSEH on x86, Spectre options, signing, and exposed PDB/debug data. This frames exploitability before source review. |
| Failed DLL loads | Startup-time failed module loads are planting opportunities if the search path reaches attacker-writable directories. Procmon-style evidence is high value because imports alone may miss optional/localization loads. |
| `LoadLibrary` path control | Prefer full trusted paths or `LoadLibraryEx` search restrictions such as System32-only loading where appropriate. If path data comes from registry/config, audit its ACL and trust domain. |
| Unquoted process paths | `CreateProcess` with a null application name and an unquoted command line can execute an unintended path fragment. This is still relevant in services, updaters, installers, and helper launchers. |
| Handle and console inheritance | A privileged parent launching a lower-privilege or different-user child must control inherited handles and console sharing. Otherwise the child can receive authority or I/O channels it should not have. |
| Job breakaway | `CREATE_BREAKAWAY_FROM_JOB` can defeat job-based containment if a sandboxed process can influence launch parameters or helper behavior. |
| Manual signing checks | Checking a file and later loading or executing it is a check/use race. Prefer OS-supported load-time policy such as signed-target loading where it fits the design. |
| Windows path identity | Canonicalization, UTF-16 ordinal comparisons, ANSI `-A` APIs, reserved DOS device names, NT paths, UNC paths, 8.3 short names, junctions, and symlinks can all split "checked path" from "used object." |
| Named pipes | Audit pipe DACLs, remote-client rejection, multi-client state separation, first-connector lockout, and message validation. Pipes are broker/service boundaries, not just IPC convenience. |
| Allocation and zeroing families | `GlobalAlloc`, `LocalAlloc`, `HeapAlloc`, `HeapReAlloc`, and `VirtualAlloc` differ in zeroing and free-family rules. Sensitive or uninitialized data can leak if the wrong assumption is made. |
| Secure zeroing | `memset`/ordinary zeroing can be optimized away. Use `RtlSecureZeroMemory`, `memset_s`, or equivalent secure-erasure contracts for secrets. |
| Cross-process memory APIs | `VirtualAllocEx`, `VirtualProtectEx`, `WriteProcessMemory`, `ReadProcessMemory`, and `CreateRemoteThread` should trigger authority, target-process, fixed-address, source-initialization, leak, heap-spray, and repeatability questions. |
| Token privilege changes | `AdjustTokenPrivileges` is nearly always security-relevant. Name the exact privilege and resulting authority rather than saying "admin." |
| Service ACLs | Service identity is not enough; the binary path, directory, DACL, SACL, DLL search surface, and account choice determine whether service execution can be influenced. |

### Windows Kernel Review Pivots

| Audit pivot | Security model |
|---|---|
| Driver analysis tooling | CodeQL, Driver Verifier, BinSkim, VM-backed kernel debugging, and WinDbg crash capture are practical evidence sources. Their results should be tied back to object, IRP, pool, and handle invariants. |
| Object attributes | `InitializeObjectAttributes`, security descriptors, and `OBJ_KERNEL_HANDLE` decide whether kernel-created objects and handles are exposed to user mode. A null descriptor is a policy choice, not "secure by default." |
| Device object exposure | Prefer secure device creation patterns, appropriate SDDL, secure-open characteristics, unique class GUIDs, and minimal named symbolic links. A device name or symlink is an attack surface. |
| Dispatch and IOCTL rights | `DriverEntry` dispatch tables and `IRP_MJ_DEVICE_CONTROL` define reachability. IOCTL access bits and `IoValidateDeviceIoControlAccess` decide whether the caller's handle rights match the operation. |
| IRP buffer lengths and output zeroing | `SystemBuffer`, input length, and output length must agree. Output buffers should not disclose uninitialized kernel memory. |
| Previous mode and confused deputy | Code reachable from both kernel and user callers must identify caller mode and authority. User-provided paths, handles, or object names need permission checks against the right subject. |
| Shared synchronization objects | User-accessible events, mutexes, semaphores, timers, and permanent objects can deadlock or disrupt kernel work unless DACLs, references, and timeout behavior are designed carefully. |
| Section objects and mapped views | Do not trust sections created or handled by user mode. Shared mappings can change concurrently; copy to kernel memory before parsing when possible, validate every read, and account for TOCTOU. |
| User handles into kernel | Passing user handles to the kernel creates type and lifetime confusion unless the driver references and validates the underlying object correctly. |
| User-memory probing | `ProbeForRead`, structured exception handling, MDL locking, and `MmSecureVirtualMemory` exist because user mappings and protections can change under the driver. `MmIsAddressValid` is usually a weak signal. |
| Executable pool and allocation families | Prefer NX pool, validate untrusted sizes, use modern zeroing allocation APIs where available, and free with the matching routine. Wrong allocation family can corrupt kernel heap state. |
| Kernel stack and spinlock smells | Stack-limit probes, unusual stack allocation, long spinlock hold times, missing release paths, and user-triggerable contention can become DoS or bugcheck paths. |
| Unicode string helpers | `RtlCopyUnicodeString`, `RtlCopyString`, and append helpers respect maximum lengths or return status. Silent truncation and ignored return values are policy and path bugs. |

### Seccomp And BPF Review Pivots

| Audit pivot | Security model |
|---|---|
| Architecture and ABI checks | A filter must distinguish architecture, ABI, and x32-style syscall numbering where relevant. Syscall numbers without ABI context are not a stable policy. |
| Equivalent syscall coverage | Blocking one spelling of an operation is not enough. Group semantic equivalents such as chmod variants, seccomp/prctl variants, filesystem mount variants, and module-loading paths. |
| vDSO, restart, and io_uring | Fast paths and restart behavior can bypass naive syscall reasoning. `io_uring` in particular changes how operations reach the kernel relative to simple seccomp filters. |
| User notification and tracing | `seccomp_unotify`, syscall user dispatch, and ptrace-mediated policies are broker designs, not simple filters. They add race, lifecycle, and tracer-compromise risks. |
| Ptrace handler completeness | Trace fork/clone/exec, use exit-kill semantics, prevent tracee operations against the tracer, identify syscall tables correctly, and treat register width/truncation as ABI-critical. |
| Tracee memory races | If a handler reads tracee memory, other threads or shared mappings can modify it. Freezing the right task set, copying stable data, or avoiding memory inspection is part of the security proof. |
| Enter versus exit stops | Dropping a syscall after it already executed only changes the reported result. Enforcement must happen before the kernel performs the operation. |
| Clone and clone3 | Clone flags and memory-based clone3 arguments are easy to mishandle. If a policy relies on inspection that BPF cannot perform safely, block or force fallback deliberately. |

## What This File Does Not Replace

| Topic | Where to keep primary focus |
|---|---|
| PE/ELF loader mechanics, imports, relocations, TLS, packers | [ELF, PE, loaders, and linkers Q&A](<04-binary-loaders-linkers-qa.md>) |
| OS memory managers, page tables, VAD/VMA, sections, working sets | [Memory, filesystems, and network Q&A](<03-memory-filesystems-network-qa.md>) |
| Kernel structures and bug-to-primitive reasoning | [Vulnerability research and exploitation primitives](<../05-topic-notes/vulnerability-research-and-exploitation-primitives.md>) |
| CPU privilege, TLB, DMA, IOMMU, hardware mitigations | [Hardware and OS security Q&A](<05-hardware-security-relationship-qa.md>) |
| Windows Object Manager, tokens, IRPs, drivers, ETW | [Windows deep-understanding Q&A](<02-windows-deep-understanding-qa.md>) |

The split is intentional: this file teaches how C++ language and toolchain mechanisms produce binary behavior. The OS files teach what authority, memory, driver, and security boundaries that binary behavior runs inside.
