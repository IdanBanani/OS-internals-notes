# User-Mode Heaps, Runtime APIs, and Toolchains

Value Score: 87/100
Role: Runtime allocation owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-18

Scope: Windows and Linux user-mode allocation APIs, runtime allocator layers, heap families, `VirtualAlloc`/`VirtualFree`, `malloc`/`new`, `LocalAlloc`/`GlobalAlloc`, Visual Studio debugging, compiler/runtime fingerprints, and the security meaning of heap choice. Read this with [Paging, residency, page lists, and shared memory](<paging-residency-page-lists-and-shared-memory.md>) and [C++ and modern C++ internals for security researchers](<../02-question-banks/06-cpp-modern-cpp-internals-security-qa.md>).

Primary source anchors:

- Microsoft Learn: [comparing memory allocation methods](https://learn.microsoft.com/en-us/windows/win32/memory/comparing-memory-allocation-methods), [HeapCreate](https://learn.microsoft.com/en-us/windows/win32/api/heapapi/nf-heapapi-heapcreate), [low-fragmentation heap](https://learn.microsoft.com/en-us/windows/win32/memory/low-fragmentation-heap), [VirtualFree](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualfree), [CRT memory allocation](https://learn.microsoft.com/en-us/cpp/c-runtime-library/memory-allocation), [`malloc`](https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/malloc), [SEH in C/C++](https://learn.microsoft.com/en-us/cpp/cpp/structured-exception-handling-c-cpp), [C2712](https://learn.microsoft.com/en-us/cpp/error-messages/compiler-errors-2/compiler-error-c2712), [Just My Code](https://learn.microsoft.com/en-us/visualstudio/debugger/just-my-code), [Immediate window](https://learn.microsoft.com/en-us/visualstudio/ide/reference/immediate-window), and [packaged-app heap policy](https://learn.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-heap-heappolicy).
- Linux: [kernel programming language](https://www.kernel.org/doc/html/next/process/programming-language.html), [building Linux with Clang/LLVM](https://docs.kernel.org/kbuild/llvm.html), glibc/musl allocator source for the target distribution, and allocator-specific docs for jemalloc, tcmalloc, mimalloc, Scudo, or language runtimes.

## Offensive Priority Index

| Score | Section | Why it matters |
|---:|---|---|
| 100 | Allocation API ladder; Windows versus Linux layering | Prevents confusing `malloc`, `HeapAlloc`, `VirtualAlloc`, `mmap`, and language allocation contracts. |
| 99 | `VirtualAlloc`/`VirtualFree` semantics and page-granular private VADs | Central to executable-memory, injection, allocator bypass, and memory-forensics reasoning. |
| 98 | Default heap, private heaps, LFH, segment heap, arenas | Heap choice changes metadata, fragmentation, synchronization, exploitation constraints, and telemetry. |
| 97 | C/C++ runtime APIs, `new`/`delete`, Local/Global/COM allocators | ABI ownership and matching-free rules create real bugs across module boundaries. |
| 96 | SEH with C++ destructors and compiler/runtime fingerprints | Important for Windows C++ reversing, exception paths, and toolchain attribution. |
| 94 | Visual Studio debugging notes and C++17 inline static | Useful support details after allocator behavior is clear. |

## Allocation API Ladder

Do not treat every allocation call as the same layer.

| Layer | Windows examples | Linux examples | What it owns |
|---|---|---|---|
| Language API | `new`, `delete`, `new[]`, STL allocators, `std::pmr` | same C++ layer | Object construction/destruction and C++ allocation-family contract. |
| C/CRT runtime API | UCRT `malloc`, `calloc`, `realloc`, `free`, `_aligned_malloc`, debug CRT heap | glibc/musl `malloc`, `calloc`, `realloc`, `free`, allocator interposition | C allocation contract, alignment, `errno`, debug wrappers, runtime global state. |
| OS heap API | `HeapAlloc`, `HeapFree`, `HeapCreate`, `GetProcessHeap`, `RtlAllocateHeap` internally | no exact universal OS heap API; libc allocator manages arenas over `brk`/`mmap` | Sub-page block allocation, free lists/buckets/segments, per-heap locking and metadata. |
| Legacy/compat API | `LocalAlloc`, `GlobalAlloc`, `LocalFree`, `GlobalFree` | historical `sbrk`/`brk` direct use in allocators | Compatibility semantics; on modern Windows local/global functions wrap heap allocation but still require matching free APIs. |
| Shared-owner API | `CoTaskMemAlloc`, `SysAllocString`, COM/WinRT allocators | library-specific allocators, plugin ABI allocators | ABI boundary ownership where caller and callee may be different modules/runtimes. |
| Virtual-address API | `VirtualAlloc`, `VirtualFree`, `VirtualProtect`, mapped sections | `mmap`, `munmap`, `mprotect`, `brk` | Page-granular address ranges, reserve/commit/protection/backing. |

The normal stack on Windows is:

```text
new/delete or malloc/free
  -> CRT/UCRT allocator state
  -> HeapAlloc/HeapFree or RtlAllocateHeap/RtlFreeHeap on a selected heap
  -> heap manager reserves/commits pages through the VM manager
  -> PTE/PFN/pagefile or file backing machinery
```

Direct `VirtualAlloc` skips the sub-page heap manager. That makes it more powerful and more visible as a private VAD/MEM_PRIVATE region, but also coarser: allocation and protection are page-granular, and each region tends to create address-space/VAD/accounting overhead.

## Why Heaps Exist When Virtual Memory Exists

Virtual memory works on pages and VAD/VMA ranges. Most program objects are much smaller than a page.

Heaps exist because:

- a 24-byte or 200-byte object should not consume a whole 4 KB page and a separate VAD/VMA;
- small allocation/free should not require a kernel transition every time;
- the runtime needs size classes, reuse, locality, debug checks, alignment, and ownership metadata;
- allocations often need language/runtime behavior such as constructors, destructors, `new_handler`, debug CRT headers, or sanitizer redzones.

Windows makes reserve/commit explicit. A heap can reserve a larger virtual range, commit only part of it, and suballocate small blocks from committed pages. This is related to reserved versus committed memory, but the deeper reason is page granularity plus allocator metadata. Linux has the same practical reason even though the API model differs: glibc `malloc` commonly grows arenas through `brk` and uses anonymous `mmap` for larger or special allocations; other allocators use their own page/extent strategies.

## Why Some Allocations Show As Heap and Others As Private Data

Tool categories are view-dependent:

| Allocation path | Typical Windows VMMap/debugger view | Why |
|---|---|---|
| `HeapAlloc(GetProcessHeap(), ...)` small block | Heap region inside MEM_PRIVATE VADs | The heap owns segments/subsegments carved from private committed/reserved pages. |
| UCRT `malloc` / C++ `new` | Usually heap, possibly CRT/debug heap annotated | The runtime normally delegates to a heap selected by the CRT or process policy. |
| Direct `VirtualAlloc` | Private data / MEM_PRIVATE, not a heap block | No heap metadata owns the region; the caller owns pages directly. |
| Large heap allocation | May appear as heap-owned virtual allocation or separate private region | The heap may call `VirtualAlloc` for large blocks but still track ownership in heap metadata. |
| `MapViewOfFile` or section view | Mapped or image, not heap | Backed by a section/file/image object rather than private heap commit. |

Security implication: "private data" does not mean "not attacker-controlled" and "heap" does not mean "malloc specifically." First identify the owner: CRT heap, process heap, private `HeapCreate` heap, segment heap, debug/page heap, direct virtual allocation, mapped section, JIT arena, or custom allocator.

## Windows Heap Families

| Heap family | What it is | Security/reversing meaning |
|---|---|---|
| Default process heap | Heap available through `GetProcessHeap`; created for the process. | Many Win32 and runtime paths use it directly or indirectly. Good first debugger probe. |
| Private `HeapCreate` heap | A separate heap object inside the same process. | Isolation by subsystem/lifetime/lock domain, not a security boundary against code in the same process. Must free through the same heap handle. |
| Classic NT heap | Traditional Windows user-mode heap implementation with segments, free lists, lookaside/LFH-era behavior depending on version/policy. | Old exploitation writeups often target metadata that no longer matches current builds. Version and heap type matter. |
| LFH | Low-fragmentation policy/front-end for suitable small allocations, used automatically as needed on Vista and later. | Size-bucket behavior affects grooming and reuse. Microsoft documents that it is not used for allocations above roughly 16 KB in the current LFH implementation. |
| Segment heap | Newer heap implementation recommended for Windows and default for packaged apps; legacy behavior can be requested by packaged-app heap policy. | Internals are version-specific and more separated/encoded than old metadata models. Use WinDbg `!heap` to distinguish NT heap versus segment heap. |
| Page heap / verifier heap | Debugging mode that places guard pages/fill patterns around allocations. | Excellent for catching overflows/UAFs; it changes layout and exploitability, so do not assume production behavior. |

`HeapCreate` reserves address space for a heap and commits an initial portion. If the heap needs more committed pages, the heap manager commits from the reserved area or, for growable/large allocations, may obtain additional virtual memory. If `HEAP_NO_SERIALIZE` is not used, heap calls serialize access; if it is used, the caller must guarantee thread synchronization. LFH cannot be enabled on heaps created with `HEAP_NO_SERIALIZE`.

`HEAP_CREATE_ENABLE_EXECUTE` is a major security choice: it makes blocks from that heap executable. Normal heap allocations should be non-executable under DEP/NX. Executable heaps should have a strong JIT/runtime explanation.

## What Determines Which Heap Is Used?

The call and runtime decide, not the object type.

| Code shape | Heap/allocator selection |
|---|---|
| `HeapAlloc(h, ...)` | The explicit heap handle `h`. |
| `HeapAlloc(GetProcessHeap(), ...)` | Default process heap. |
| `HeapAlloc(customHeap, ...)` | That `HeapCreate` heap. |
| `malloc` / `free` | The CRT allocator linked into that module/application; on modern UCRT this usually delegates to a CRT heap handle that may be the process heap, but code should treat it as a CRT allocation family. |
| `new` / `delete` | C++ runtime/operator implementation, commonly over `malloc` or an overridden global/class-specific operator. |
| `std::pmr` / custom allocator | The allocator object/resource supplied to the container or component. |
| COM/WinRT APIs | Often `CoTaskMemAlloc`, BSTR, HSTRING, or API-specific ownership rules. |
| glibc/musl malloc on Linux | libc allocator arenas over `brk`/`mmap`, unless interposed/replaced. |
| jemalloc/tcmalloc/mimalloc/Scudo | Runtime/library selected by link order, preload, build flags, or language runtime. |

Rule: free with the same family that allocated. `HeapAlloc` pairs with `HeapFree` on the same heap handle. `LocalAlloc` pairs with `LocalFree`; `GlobalAlloc` with `GlobalFree`; `CoTaskMemAlloc` with `CoTaskMemFree`; `_aligned_malloc` with `_aligned_free`; `new[]` with `delete[]`. Mismatches are corruption, not style issues.

## Windows Versus Linux Heap Behavior

| Question | Windows | Linux |
|---|---|---|
| Is there one heap? | No. Each process has a default heap and may have many private heaps; runtimes can create or use additional heaps. | No. The process has one address space; the allocator may maintain many arenas, thread caches, extents, or custom heaps. |
| Is small allocation page-granular? | The heap suballocates small blocks from committed pages. Direct `VirtualAlloc` is page-granular. | `malloc` suballocates small blocks from arenas. Direct `mmap` is page-granular. |
| What is the kernel API underneath? | VM manager reserve/commit/protect plus section machinery. | `brk`, `mmap`, `mprotect`, `munmap`, plus overcommit and page faults. |
| Thread synchronization | Windows heaps are serialized by default unless `HEAP_NO_SERIALIZE` or custom design removes it. | Allocators use arenas, thread caches, locks, atomics, or per-thread state depending on implementation. |
| Large allocations | Heap may call `VirtualAlloc`; direct `VirtualAlloc` is common for explicit page-sized regions. | glibc and many allocators use `mmap` for large allocations or extents. |
| Security hardening | LFH/segment heap metadata encoding, termination on corruption, page heap, CFG/CET/DEP interactions. | safe-linking/tcache checks in glibc, allocator-specific quarantine/metadata isolation, ASLR, guard pages, sanitizers, Scudo/hardened allocators. |

The Windows habit of using heap APIs for small allocations is not uniquely because of commit/reserve. It is because all OSes need a sub-page allocator above page-granular VM. Windows exposes reserve/commit more explicitly, and heaps use that to grow efficiently. Linux hides more of that behind `malloc`, `brk`, `mmap`, and overcommit policy.

## `VirtualFree` Size Argument

`VirtualFree(lpAddress, dwSize, dwFreeType)` has two very different modes:

| Free type | `dwSize` meaning | Result |
|---|---|---|
| `MEM_DECOMMIT` | Size in bytes of the range to decommit. Any page containing at least one byte in that range is decommitted. If `lpAddress` is the allocation base and `dwSize == 0`, the entire region is decommitted. | Pages become reserved. Address space remains reserved; later `VirtualAlloc(..., MEM_COMMIT, ...)` can recommit. |
| `MEM_RELEASE` | Must be `0` for ordinary release. `lpAddress` must be the base address returned by the original reservation. | The entire reserved region is released back to free address space. Committed pages in it are decommitted first. |

Common bug: passing a nonzero size with `MEM_RELEASE` and expecting a partial free. That fails for ordinary virtual allocations. To return only part of a reservation to free address space, the allocation must have been structured for placeholder/split behavior or managed by separate reservations.

## Pagefile Relevance for Writable Data

The pagefile/swap is relevant when private dirty contents have no ordinary file that can reconstruct them.

Clean file-backed code/data can be discarded and reread from the file. Clean image pages from DLLs/EXEs do not need to be written to the pagefile. A dirty private heap/stack/anonymous page does need some backing if the OS evicts it and later must reproduce the same bytes. On Windows, that promise is commit charge backed by RAM plus pagefile capacity/policy; on Linux, dirty anonymous memory is swap-backed when swap is available and reclaim chooses to evict it.

Read-only does not mean "never pagefile" as a permission bit. A read-only private page can still contain data that came from a writable origin or COW path. The real question is whether the current bytes are cleanly reconstructible from a file/zero page or are private dirty state that must be preserved.

## User Heap Versus Kernel Heap

User-mode heaps are process-private data structures in user virtual address space. Corruption usually kills or compromises that process first. The kernel sees the containing private pages and VADs, not each C++ object.

Kernel heaps/pools are global privileged allocators with context constraints:

| User-mode heap | Kernel pool/heap |
|---|---|
| Owned by one process address space. | Kernel address space and global subsystem state. |
| Faulting/sleeping is usually allowed in normal user code. | IRQL, locks, DPC/interrupt paths, and pageable/nonpaged rules constrain allocation and access. |
| Metadata corruption affects process integrity and exploitability. | Metadata or object corruption can cross the user/kernel boundary and affect system integrity. |
| Debug with VMMap, UMDH, `!heap`, ASan, page heap, app verifier. | Debug with pool tags, Driver Verifier, Special Pool, `!pool`, `!verifier`, crash dumps. |

Do not transfer exploit intuitions directly. A Windows segment heap UAF and a Windows kernel pool UAF are different allocator, privilege, context, and telemetry problems.

## Compiler and Runtime Fingerprinting

The compiler does not directly decide the OS heap. The linked runtime and allocator do.

Windows:

- Microsoft system binaries are generally built with Microsoft internal/MSVC-family toolchains, but do not assume one public Visual Studio version from the OS version alone.
- Third-party Windows binaries may be MSVC, clang-cl/MSVC ABI, MinGW GCC, Rust, Go, .NET Native/AOT, Delphi, or custom toolchains.
- MSVC and clang-cl commonly use the MSVC ABI and Microsoft CRT/STL ecosystem unless configured otherwise.
- MinGW GCC uses a different C++ ABI/runtime model; crossing C++ object or allocator ownership between MSVC and MinGW modules is unsafe unless the ABI contract is explicitly C-compatible.

Linux:

- The Linux kernel is written in GNU C dialects, traditionally built with GCC; Clang/LLVM is also supported and used by some distributions/products.
- Linux userland is distribution-specific. glibc-based systems commonly use GCC or Clang; musl-based systems differ; Android uses Bionic/Clang; many services are Go/Rust/Java/etc.
- The heap implementation is usually libc/runtime-specific: glibc `malloc`, musl `malloc`, jemalloc, tcmalloc, mimalloc, Scudo, language GC, or a custom pool.

`malloc`/`free` are not "legacy" in the sense of obsolete; they are the C ABI allocation contract and still common in C libraries, low-level code, plugins, parsers, and system utilities. In C++ code, prefer RAII and containers, but reverse engineers should still expect lower-level `malloc`/`free` in runtimes, C libraries, old code, performance code, and ABI boundaries.

Implementation changes are normal. Heap internals change across Windows releases, Visual Studio/UCRT versions, glibc versions, distribution patches, and allocator builds. Security analysis should fingerprint the exact target: module imports, CRT DLL, allocator symbols, PDB/symbols, `!heap` type, `/proc/<pid>/maps`, `ldd`, `MALLOC_*`/allocator environment, and loaded allocator libraries.

## Visual Studio Debugging Checks

For native C++ heap/runtime questions:

- Disable or account for `Enable Just My Code` when stepping into CRT, Windows, STL, or allocator frames. Visual Studio classifies code as user or external based on PDBs and Just My Code metadata; it can collapse or step over the frames you are trying to study.
- Use the Modules window to confirm symbols for `ucrtbase.dll`, `vcruntime*.dll`, `ntdll.dll`, and the target module.
- The Immediate window can print expressions with `?`, for example `? GetProcessHeap()` or `? _get_heap_handle()` if the CRT symbol/prototype is visible in context.
- If the expression evaluator cannot call a function, use Watch/Memory windows, debugger pseudo-registers, or WinDbg commands such as `!heap`, `!address`, `lm`, and `x module!*heap*`.

The debugger is not changing the allocation contract, but debug CRT, page heap, Application Verifier, symbols, and Just My Code can change layout, stepping, and what you see.

## SEH, C++ Destructors, and `__try`

`__try`/`__except` is Structured Exception Handling, not ISO C++ `try`/`catch`. It exists for Windows structured exceptions such as access violations and for low-level cleanup/filtering. In C++ code, prefer C++ exceptions and RAII unless you have a narrow SEH reason.

MSVC error C2712, "cannot use `__try` in functions that require object unwinding," happens when a function using SEH also has local variables or parameters that require C++ unwinding, such as objects with destructors (`CString`, `std::string`, smart pointers, RAII locks, containers). The compiler would need to mix SEH filtering with C++ destructor cleanup in a way that the selected exception model does not support safely.

Practical pattern:

```cpp
static int seh_probe_raw(void* p) noexcept
{
    __try {
        volatile unsigned char value = *static_cast<unsigned char*>(p);
        (void)value;
        return 1;
    } __except(EXCEPTION_EXECUTE_HANDLER) {
        return 0;
    }
}

void cpp_function()
{
    CString name;            // destructor-bearing C++ object lives outside SEH frame
    int ok = seh_probe_raw(/* raw pointer */ nullptr);
}
```

Keep the SEH function small, C-like, and free of destructor-bearing locals. Let the caller own C++ objects and cleanup. `/EHa` can make SEH exceptions participate more broadly in C++ unwinding, but Microsoft still recommends standard C++ EH for C++ code, and catching access violations as recoverable application logic is usually unsafe.

## C++17 `inline static`

C++17 inline variables allow this pattern:

```cpp
struct Config {
    inline static std::atomic<unsigned> generation{0};
};
```

Before C++17, a non-const static data member usually needed one out-of-class definition in a `.cpp` file. With `inline static`, the definition can live in the header and appear in multiple translation units while still representing one program entity under the One Definition Rule.

Security/reversing relevance:

- It changes where you expect storage definitions to appear; the header contains the definition.
- It can reduce duplicate-definition and missing-definition mistakes.
- It does not make initialization-order problems disappear for complex dynamic initialization.
- In binaries, look for COMDAT/linkonce-style coalescing, guard variables for dynamic initialization where needed, and references from multiple object files to one merged symbol.

## Active Recall

1. Why does `malloc(100)` normally not call the kernel for a fresh 100-byte mapping?
2. Why can direct `VirtualAlloc` appear as private data while `malloc` appears under heap views?
3. Why is `LocalAlloc` not interchangeable with `HeapFree` even though it wraps heap allocation internally?
4. Why can one process contain multiple heaps?
5. Why does `MEM_RELEASE` require `dwSize == 0`?
6. Why is LFH not a separate heap object?
7. Why does segment heap make old NT-heap exploitation notes risky to reuse blindly?
8. Why does heap choice usually depend on the runtime/allocator, not the compiler alone?
9. Why does `__try` conflict with local objects that require destructors?
10. Why does C++17 `inline static` change linker/storage expectations but not the runtime object-lifetime rules?
