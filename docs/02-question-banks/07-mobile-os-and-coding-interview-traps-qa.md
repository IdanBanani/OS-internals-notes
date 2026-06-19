# Mobile OS And Coding Interview Traps, Scored

Value Score: 86/100
Role: Mobile/coding trap Q&A owner
Proof Level: Conceptual, lab-routed

Date: 2026-06-18

Purpose: turn several deceptively small interview prompts into full mechanism answers. The target reader is preparing for Android/iOS, OS internals, native runtime, C/C++, and security-research interviews where a one-line "cheat sheet" answer is not enough.

Use this beside:

- [Linux deep-understanding Q&A](<01-linux-deep-understanding-qa.md>)
- [Android internals](<../03-linux/04-android-internals.md>)
- [C++ and modern C++ internals for security researchers](<06-cpp-modern-cpp-internals-security-qa.md>)
- [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>)
- [Memory, filesystems, and network Q&A](<03-memory-filesystems-network-qa.md>)

Publication hygiene note: the recursive-product drill below preserves the conclusions and internals from a challenge-style prompt, but it intentionally avoids copying the original file name, command transcript, exact source strings, and full program text. The goal is to keep the learning value without creating an easy GitHub string-search fingerprint for the original question.

## Priority Index

| Score | Area | Deep-understanding question | Strong answer must cover |
|---:|---|---|---|
| 100 | Processes, threads, and mobile sandboxing | Under what conditions can one thread read or write another thread's memory, in the same process or across processes, on Android/iOS-like systems? | Process address space, thread stacks/TLS, virtual vs physical addresses, shared mappings, Binder/Mach/XPC, ptrace/task ports, SELinux, entitlements, and the fact that same-process memory is not a sandbox boundary. |
| 99 | Non-atomic increment trap | Many threads run `counter++` in a loop. What final values are possible, and what changes with atomics? | C/C++ data-race UB, optimizer assumptions, load/add/store lowering, stale-store schedules, minimum/maximum under stated assumptions, cache coherence, `volatile`, `fetch_add`, x86 locked ops, and AArch64 LL/SC or LSE atomics. |
| 88 | Fibonacci and runtime tradeoffs | How should Fibonacci be implemented and explained in C, C++, and Python beyond memorized Big-O slogans? | Naive recursion, iteration, memoization, fast doubling, Python `lru_cache`, recursion limits, native stack overflow, big integers, overflow in fixed-width C/C++, precomputation, and cache/threading effects. |
| 87 | Recursive numeric overflow drill | Why can a tiny recursive numeric function return zero for a medium input, crash for a huge input, and change behavior under `-O3`? | Native stack exhaustion, guard pages and `SIGSEGV`, unsigned wrap modulo 2^N, why a medium factorial can be exactly zero modulo 2^32, input validation, overflow checks, `atoi` pitfalls, and optimizer-dependent recursion elimination. |

## Best Answers

### 100 - Processes, Threads, And Mobile Sandbox Memory

A process is the isolation container. It owns a virtual address space, credentials, open file or handle tables, mappings, signal/disposition state, sandbox labels, and platform policy state. A thread is an execution context inside a process: program counter, registers, stack pointer, scheduling state, thread-local storage, signal mask or equivalent state, and a distinct stack region.

Threads in the same native process normally share the same virtual address space. If thread A has the address of a global, heap object, mapped page, code page, or thread B's stack slot, the hardware does not stop thread A from reading or writing it merely because it "belongs" to another thread. "Each thread has its own stack" means each thread has its own stack pointer and stack range for calls and locals. It does not mean the stack is protected from other threads in the same process.

That is why same-process bugs are so powerful. A C/C++ overflow, use-after-free, bad JNI/native bridge, Objective-C runtime misuse, or unsafe pointer can corrupt another thread's work queue, callback object, stack frame, heap object, or synchronization state. Managed runtimes add language-level safety, but they do not create a kernel security boundary between threads once native code, unsafe code, JIT code, or memory corruption enters the picture.

Different processes are different. The numeric virtual address `0x12345678` in process A is just a number in A's page-table/VM-map context. The same number in process B can mean a different physical page, no valid mapping, a shared library page, or a deliberately shared memory object. A user-mode load in process A does not use process B's page tables, so A cannot simply dereference B's pointer.

Cross-process memory access requires a kernel-mediated relationship or a vulnerability:

| Path | What makes it possible | Security question |
|---|---|---|
| Shared memory | `mmap(MAP_SHARED)`, `memfd`, Android shared-memory fds, DMA-BUF, Mach VM mappings, or mapped file/section objects. | Who created the object, who received the fd/port/handle, what permissions and lifetime rules apply, and which process can mutate it? |
| IPC copying | Binder, XPC, Mach messages, Unix sockets, pipes, RPC-like services, or framework brokers. | What identity is attached to the request, what policy does the broker enforce, and what parsing/lifetime rules exist? |
| Debug/inspection | `ptrace`, `process_vm_readv/writev`, `/proc/<pid>/mem`, Mach task ports, debugger entitlements, development profiles. | Does the caller have the required credential, entitlement, dumpability, capability, sandbox exception, or policy approval? |
| Privileged/kernel path | Kernel bug, driver bug, platform service bug, sandbox escape, or root/kernel authority. | Which boundary failed: object authorization, pointer validation, refcounting, page permissions, or a broker policy check? |

Android starts from Linux process isolation but adds Android-specific authority. Apps usually run under distinct UIDs, are placed in SELinux domains such as untrusted-app domains, and talk to system services mostly through Binder. Shared buffers are often carried as fds through Binder rather than discovered through a public POSIX shared-memory name. SELinux matters when a process crosses a kernel or service boundary: opening device nodes, using Binder services, reading procfs state, attaching as a debugger, or receiving a shared-memory handle. SELinux does not protect one thread from another thread inside the same process.

iOS and macOS use Mach tasks, threads, VM maps, ports, entitlements, sandbox profiles, code signing, and hardened runtime policy. A task port is a capability-like handle to a task; with a sufficiently powerful task port, APIs can inspect or mutate another process's memory and threads. Normal apps cannot obtain those rights for arbitrary protected targets because entitlement, sandbox, platform policy, and SIP/hardened protections constrain the path.

The interview-ready answer is:

> Same-process threads share one virtual address space, so hardware does not isolate their heap, globals, mappings, code, or even stack regions from each other. Different processes have different VM maps, so the same virtual address number does not imply the same physical memory. Cross-process memory requires an explicit shared mapping, IPC/broker transfer, debugger-style authority, a powerful port/handle, or a vulnerability. Android SELinux and iOS entitlements mainly matter at those syscall/IPC/object-access boundaries, not between threads already running inside one process.

### 99 - Non-Atomic Increment Trap

For C or C++, the first answer is the language-law answer: if several threads access a normal non-atomic `int` or `unsigned` counter concurrently, at least one access writes, and no synchronization orders those accesses, the program has a data race. In C++ this is undefined behavior. That means there is no guaranteed range of final values in the standard model.

A strong answer then says: if the interviewer wants the hardware/interleaving model, we must state assumptions. The usual assumptions are:

- the compiler does not fold the whole loop into one add or make a stronger UB-based transformation;
- no signed overflow occurs;
- the object is naturally aligned and stores do not tear;
- each `counter++` behaves like load, add, store;
- all threads eventually finish.

Under those assumptions, the conceptual lowering is:

```asm
load  r, [counter]
add   r, r, 1
store [counter], r
```

On AArch64 a non-atomic increment often visibly lowers into `ldr`, `add`, `str`. On x86 an optimized build may use a single memory `add`, but without a `lock` prefix it is not an inter-core atomic read-modify-write. It is still not a C++ atomic operation.

Let `T` be the number of threads and `K` the number of loop iterations per thread.

| Model | Possible final answer |
|---|---|
| C/C++ non-atomic object | Undefined behavior; no guaranteed range. |
| Simplified load/add/store interleaving, `K == 1` | Minimum `1`, maximum `T`. |
| Simplified load/add/store interleaving, `T >= 2`, `K >= 2` | Minimum can be `2`, maximum `T * K`. |
| Atomic read-modify-write and all threads joined | Exactly `T * K`, assuming no arithmetic overflow. |

The surprising part is the `2` minimum for `K >= 2`. Many people answer `K`, but that assumes only same-iteration lost updates. A stale store can overwrite a much later, larger value.

One schedule with two threads A and B:

```text
counter = 0

A iteration 1: load 0, pause before store
B iteration 1: load 0, pause before store
A iteration 1: store 1
A runs iterations 2 through K-1, so counter becomes K-1
B iteration 1: store stale 1, overwriting the larger value
A final iteration: load 1, compute 2, pause before store
B runs its remaining iterations, raising counter again
A final iteration: store stale 2 as the last write
```

Final value: `2`.

Cache coherence does not save this. Coherence makes cores agree on an order of writes to a cache line. It does not understand that a load/add/store sequence was intended to be one indivisible increment. A later stale store of "old value plus one" can still overwrite a newer value.

`volatile` is not the fix. It can make an access observable to the compiler, which matters for MMIO and some signal-like cases, but it does not make a compound read-modify-write atomic and does not create inter-thread synchronization in the C++ memory model.

The correct C++ counter is:

```cpp
std::atomic<unsigned> counter{0};

void worker(unsigned rounds) {
    for (unsigned i = 0; i != rounds; ++i) {
        counter.fetch_add(1, std::memory_order_relaxed);
    }
}
```

`memory_order_relaxed` is enough for a pure final counter when the only required property is that every increment is counted and the main thread joins all workers before reading the answer. It gives atomic read-modify-write on the counter but does not publish unrelated payload data. If the counter also signals that other data is ready, the answer must discuss acquire/release or a lock.

Typical atomic lowering:

| Architecture | Pattern |
|---|---|
| x86/x64 | `lock add`, `lock xadd`, or `lock cmpxchg` loop, depending on operation and compiler. |
| AArch64 without LSE | `ldxr`/`stxr` retry loop, with acquire/release variants when required. |
| AArch64 with LSE | Single-instruction atomics such as `ldadd` or acquire/release variants, when target features allow. |

The interview discipline is to answer in layers: language model, compiler, assembly, CPU/cache, and synchronization. Skipping the first layer produces a nice-looking but technically false answer. Stopping at the first layer misses the point of the trap.

### 88 - Fibonacci And Runtime Tradeoffs

Fibonacci is only a shallow question if the answer stops at "recursive is exponential, memoized is O(n), iterative is O(n)." A deeper answer connects algorithm, numeric representation, stack behavior, runtime caches, and threading.

Assume:

```text
F(0) = 0
F(1) = 1
```

Naive recursion:

```c
uint64_t fib_rec(unsigned n) {
    if (n < 2) return n;
    return fib_rec(n - 1) + fib_rec(n - 2);
}
```

This mirrors the mathematical recurrence and is useful for teaching, but it repeats subproblems. Time is exponential, stack depth is O(n), and the call overhead is enormous. In C/C++, deep recursion risks stack overflow; in Python it normally hits `RecursionError` before true C stack exhaustion unless the recursion limit is raised dangerously.

Simple iteration is usually the best one-off implementation:

```c
bool fib_u64(unsigned n, uint64_t *out) {
    uint64_t a = 0;
    uint64_t b = 1;

    for (unsigned i = 0; i != n; ++i) {
        if (UINT64_MAX - b < a) return false;
        uint64_t next = a + b;
        a = b;
        b = next;
    }

    *out = a;
    return true;
}
```

It is O(n) time, O(1) auxiliary space, and has no recursion stack. For fixed-width integers, overflow must be part of the answer. `F(93)` fits in `uint64_t`; `F(94)` does not. Python integers grow to arbitrary precision, so Python's limiting factor becomes time and memory for huge values rather than native integer overflow.

Fast doubling is the better algorithmic answer for very large `n`:

```text
F(2k)   = F(k) * (2 * F(k+1) - F(k))
F(2k+1) = F(k)^2 + F(k+1)^2
```

It takes O(log n) recursive levels, though the arithmetic itself gets more expensive as the numbers grow. In C++ with fixed-width integers, overflow still must be checked or replaced with arbitrary precision such as `boost::multiprecision::cpp_int`. In Python, big-integer multiplication eventually dominates.

Memoization changes the shape from repeated work to cached subproblems:

```python
from functools import lru_cache

@lru_cache(maxsize=None)
def fib_cached(n: int) -> int:
    if n < 2:
        return n
    return fib_cached(n - 1) + fib_cached(n - 2)
```

This is O(n) calls and O(n) cache space, but still uses recursion. CPython's cache key is built from the call arguments; the unbounded cache behaves like a dictionary-backed memo table. Bounded LRU designs also maintain recency ordering, conceptually a linked list or equivalent structure plus a dictionary. CPython uses optimized C paths in normal builds, but the important model is key -> result with eviction policy when bounded.

The cache is protected enough to keep its internal structure coherent across threads, but it is not a universal "single flight" promise. Concurrent misses can compute the same missing value more than once. If a service uses memoization for expensive work, the interviewer may want to hear about duplicate-miss work, cache locks, eviction, memory growth, and whether the function being cached has side effects.

Precomputation is best for many repeated queries, especially if queries increase over time:

```python
class FibTable:
    def __init__(self) -> None:
        self.values = [0, 1]

    def get(self, n: int) -> int:
        values = self.values
        while len(values) <= n:
            values.append(values[-1] + values[-2])
        return values[n]
```

That gives O(max_n) build cost, O(1) lookup by index afterward, and O(max_n) storage. In multithreaded code, the growth path needs a lock or another publication protocol. Otherwise two threads can race while appending, observe partially updated state, or waste work.

Cross-core cache behavior matters more for shared memo tables than for the Fibonacci formula itself. A single shared dictionary/vector can become a hot lock and cache-line-bouncing point. A naive attempt to parallelize recursion often makes things worse because scheduling overhead and duplicated work dominate. A strong answer says when parallelism is useful, when it is fake work, and which shared state becomes the bottleneck.

Interview summary:

| Situation | Best answer |
|---|---|
| Teaching recurrence | Naive recursion, while clearly saying it is exponential. |
| One normal query | Iterative loop. |
| Very large index | Fast doubling plus appropriate integer type. |
| Many repeated queries | Memo table or precomputed growing table. |
| Python | Prefer iteration or fast doubling; explain recursion limit, big ints, and `lru_cache` internals. |
| C/C++ | Discuss fixed-width overflow and return status, not only algorithmic complexity. |
| Multi-threaded service | Avoid hot shared cache locks or protect/shard/precompute carefully. |

### 87 - Recursive Numeric Overflow Drill

Consider a tiny unsigned recursive function that multiplies `n` by the result for `n - 1` until it reaches a base case. With a small input it prints the expected product. With a medium input such as 50 it prints zero on a common 32-bit `unsigned`. With a huge input it crashes in an unoptimized native build.

There are two different bugs or failure modes:

1. Stack exhaustion from deep recursion.
2. False numeric output from unsigned wraparound.

The crash is stack overflow in the native-call-stack sense. Each recursive call needs a stack frame: return address, saved registers where needed, spill slots, alignment, and sometimes frame metadata. A huge input creates a huge chain of calls before any call can return. The thread's stack is finite. When the stack pointer crosses into an unmapped page or a guard page, the next stack access faults. On Linux-like systems this often becomes `SIGSEGV`; on Windows the analogous failure is surfaced through stack-overflow exception behavior. The exact stack direction and guard implementation are platform details, but the invariant is the same: the program consumed the thread's stack reservation.

The simple crash fix is not memoization. For a single linear recursive product, memoization does not reuse anything before the deepest call is reached, so it still needs one stack frame per value. The simple fix is either:

- reject large inputs before calling the recursive function; or
- rewrite the function iteratively.

The iterative shape is:

```c
bool product_u32(unsigned n, unsigned *out) {
    unsigned acc = 1;

    for (unsigned i = 2; i <= n; ++i) {
        if (acc > UINT_MAX / i) return false;
        acc *= i;
    }

    *out = acc;
    return true;
}
```

That removes recursive stack growth and also detects overflow. If the assignment asks only for the simplest crash prevention, an input limit is acceptable. If the assignment asks for correct output, a limit or overflow check is required too.

Why can the medium input print zero? Assuming `unsigned` is 32 bits, unsigned arithmetic is modulo `2^32`. That is defined behavior in C/C++. It is not undefined behavior and not random garbage.

For `50!`, count how many factors of 2 appear:

```text
floor(50 / 2)  = 25
floor(50 / 4)  = 12
floor(50 / 8)  = 6
floor(50 / 16) = 3
floor(50 / 32) = 1
total          = 47
```

So `50!` is divisible by `2^47`. Because `2^32` divides it, the value modulo `2^32` is exactly zero. The zero is mathematically explainable wraparound, not merely "too large."

To prevent false outputs, keep it simple:

| Fix | What it prevents |
|---|---|
| Clamp input to the largest representable exact result | For 32-bit `unsigned`, accept at most `12!`; for 64-bit unsigned, accept at most `20!`. |
| Check before multiply | `acc > max / i` detects that the next multiplication would overflow. |
| Return status plus output parameter | Separates "computed value" from "error." |
| Use a larger or arbitrary-precision type | Extends or removes the representable limit, but still needs resource limits. |
| Parse with `strtoul`/`strtoull` style checks | Avoids `atoi` ambiguity, silent zero, trailing junk, and out-of-range behavior. |
| Match print format to type | Avoids a second, unrelated variadic-call bug. |

The `-O3` question is about compiler freedom and target behavior. For unsigned arithmetic, overflow is defined modulo arithmetic, so the compiler must preserve the observable modulo result. The medium input remains zero on a normal 32-bit `unsigned` model. For the huge input, an optimizer may inline, convert recursion into a loop-like form, or otherwise avoid building one native stack frame per input value. If that happens, the stack crash disappears and the function eventually returns the modulo result, likely zero for sufficiently large inputs. If the compiler does not make that transformation, the unbounded recursion still overflows the stack.

Do not promise one `-O3` behavior without looking at the generated assembly for the exact compiler, version, target, and flags. Also keep the signedness caveat clear: if the arithmetic were signed and overflowed, signed overflow would be undefined behavior, giving the optimizer much more freedom to remove checks or transform code in surprising ways.

The interview-ready answer is:

> The huge-input crash is native stack exhaustion from linear recursion, usually observed as a guard-page fault and process crash. The medium-input zero is defined unsigned modulo arithmetic; on a 32-bit unsigned result, `50!` contains more than 32 factors of 2, so the result is exactly 0 modulo `2^32`. The simple fix is an iterative implementation plus an input limit or pre-multiply overflow check, and the `-O3` result must be verified because the optimizer may remove the recursive stack growth while preserving unsigned modulo semantics.

