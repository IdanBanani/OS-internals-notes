# Hands-On Internals Labs

Value Score: 99/100
Role: Practical lab spine
Proof Level: Lab-backed template

Date: 2026-06-18

Purpose: turn OS-internals statements into local experiments. Each lab should start from a claim, run code or tools, collect evidence, then explain which assumption was proved, disproved, or narrowed.

This is the practical spine for the repo. Use it when a section feels like vocabulary instead of understanding.

Concept companion: use [Practical concept anchors](<../05-topic-notes/practical-concept-anchors.md>) when a lab or note mentions an abbreviation without enough context. It maps terms such as IOMMU, page cache, VMA/VAD, PTE/PFN, IRP/MDL, LSM, RCU, eBPF, io_uring, ETW, AMSI, PPL, VBS/HVCI, CFG, and CET to their owning layer, practical evidence path, and deeper owner docs.

Runnable snippet companion: use [Practical snippet pack](<01-practical-snippet-pack.md>) when you want direct toy code for VMA/COW, fd/path lifetime, syscall user-pointer validation, C++ atomic-vs-volatile behavior, Windows handle granted access, and Windows private-vs-section memory evidence.

## Lab Method

For every lesson, write the result in this shape:

```text
Claim:
Experiment:
Expected observation:
Actual observation:
What changed in kernel/runtime state:
What this proves:
What it does not prove:
Next mutation:
```

The "what it does not prove" line matters. Elite-level understanding is not just making an experiment work once. It is knowing which hidden assumptions remain: compiler version, optimization level, architecture, kernel build, Windows build, privileges, policy, filesystem, CPU features, debugger side effects, and tool visibility limits.

## Track Order

Do platform-clean labs before cross-platform comparison.

1. Linux memory and user/kernel boundary.
2. Linux files, fds, credentials, namespaces, and tracing.
3. Windows handles, tokens, VADs, sections, and ETW/Sysinternals.
4. C/C++ concurrency, undefined behavior, atomics, and compiler output.
5. Loader and binary-format labs.
6. Cross-platform comparison writeups.
7. Scenario composition: RCE, privilege boundary, telemetry, and persistence reasoning.

## Linux Labs

### L1 - VMA, Page Fault, Residency, And COW

Claim: a valid virtual range is not the same as a resident physical page, and `fork` initially shares pages until a write causes COW.

Experiment:

1. Write a small C program that allocates a large anonymous mapping with `mmap`.
2. Print its address and sleep.
3. Inspect `/proc/<pid>/maps` and `/proc/<pid>/smaps`.
4. Touch one byte per page and inspect `smaps` again.
5. `fork`, then write to half the pages in the child.
6. Compare RSS/PSS/private dirty/shared clean fields for parent and child.

Evidence:

- `/proc/<pid>/maps` shows the legal VMA range.
- `/proc/<pid>/smaps` shows residency and dirty/private/shared accounting.
- `perf stat -e page-faults` or `/usr/bin/time -v` can show fault counts.

What this proves: VMA policy, PTE presence, physical residency, and COW transition are separate states.

Next mutation: change `MAP_PRIVATE` to `MAP_SHARED` over a temporary file and prove which writes become visible to another process.

### L2 - Page Fault Is Not Always A Bug

Claim: a page fault can be normal demand paging, COW, stack growth, or a fatal protection/invalid access.

Experiment:

1. Read from a freshly mapped anonymous page.
2. Write to it.
3. `mprotect` it to read-only, then write again under a signal handler or debugger.
4. Map a file, truncate it from another process, then access the truncated part.

Evidence:

- `strace -e mmap,mprotect,munmap,rt_sigaction`
- `/proc/<pid>/maps`
- signal type: `SIGSEGV` for invalid/protection cases, `SIGBUS` for some bad mapped-file backing cases.

What this proves: "page fault" is a mechanism; the kernel's fault handler and backing object decide whether execution resumes or a signal is delivered.

### L3 - fd, Path, And Object Lifetime

Claim: an fd points at an open file description/object; the pathname is not the object.

Experiment:

1. Open a temp file.
2. Print the fd and sleep.
3. Delete or rename the pathname while the process keeps the fd open.
4. Inspect `/proc/<pid>/fd/<n>`.
5. Read/write through the fd after unlink.

Evidence:

- `ls -l /proc/<pid>/fd`
- `strace -e openat,unlink,read,write,close`
- inode number from `stat` before unlink and fd link after unlink.

What this proves: path strings, directory entries, inodes, and open file descriptions have different lifetimes.

### L4 - Credentials, Capabilities, And Namespace Boundaries

Claim: UID, effective UID, capabilities, namespaces, seccomp, and LSM policy are separate authority layers.

Experiment:

1. Print real/effective/saved IDs and capabilities from a small program or `/proc/self/status`.
2. Use `unshare` to enter a user namespace where allowed.
3. Compare `id`, `/proc/self/uid_map`, and capability sets.
4. Try operations that need host authority versus namespace-local authority.
5. Add a simple seccomp profile if tooling is available and observe blocked syscalls.

Evidence:

- `/proc/self/status`
- `capsh --print` if available
- `strace` return codes
- audit/LSM logs if enabled.

What this proves: "root" is not one bit. The authority domain and policy layer decide what root-like state can do.

### L5 - Syscall Entry And User Pointer Validation

Claim: syscall arguments are untrusted bytes/pointers until kernel code validates and copies them.

Experiment:

1. Call `write(1, valid_buf, len)`.
2. Call `write(1, invalid_pointer, len)`.
3. Call `read` into a read-only mapping.
4. Observe return values and `errno`.

Evidence:

- `strace -e write,read`
- debugger register view before syscall if desired
- kernel source path for `copy_from_user`/`copy_to_user` on the target kernel.

What this proves: the user/kernel boundary is enforced by CPU mode plus kernel copy/probe logic, not by trusting user pointers.

## Windows Labs

Run these in a Windows VM or disposable local lab when possible. Use Sysinternals, WinDbg, and ETW tools. Keep build number in notes.

### W1 - Handle Granted Access

Claim: a Windows handle carries granted access, and later APIs check that granted mask.

Experiment:

1. Create a child process that sleeps.
2. Open it once with query-only rights and once with VM-read/write rights where allowed.
3. Call query APIs and memory APIs on each handle.
4. Inspect handles in Process Explorer or WinObjEx64.

Evidence:

- Process Explorer handle view.
- API success/failure and `GetLastError`.
- Optional WinDbg `!handle`.

What this proves: handle value, object identity, and granted access are separate. Possessing a process handle is not enough; the granted mask matters.

### W2 - Token And Integrity Evidence

Claim: Windows identity is token state, not just "admin" or "user."

Experiment:

1. Print token user SID, groups, privileges, integrity level, and elevation type from a small program or PowerShell.
2. Compare normal shell, elevated shell, and service or scheduled-task context if available.
3. Try to enable a present but disabled privilege and compare with a privilege absent from the token.

Evidence:

- `whoami /all`
- Process Explorer token tab
- PowerShell token inspection
- `AdjustTokenPrivileges` success plus `ERROR_NOT_ALL_ASSIGNED` cases.

What this proves: privileges must exist in the token before they can be enabled, integrity is a separate policy input, and elevation changes token shape.

### W3 - VADs, Private Memory, Sections, And Protection Changes

Claim: `VirtualAlloc`, mapped sections, image mappings, and protection changes produce different memory-manager evidence.

Experiment:

1. Allocate private memory with `VirtualAlloc`.
2. Change protection with `VirtualProtect`.
3. Map a file with `CreateFileMapping` and `MapViewOfFile`.
4. Load a DLL normally.
5. Inspect with VMMap and Process Hacker/Process Explorer.

Evidence:

- VMMap categories: private, mapped, image, heap, stack.
- Protection changes visible in memory-region views.
- Optional WinDbg `!address` and `!vad` where symbols/build allow.

What this proves: VAD range policy, backing object, protection, and loader metadata are not the same thing.

### W4 - File Handle, Share Mode, And Delete/Rename Behavior

Claim: Windows file access has both DACL authorization and share-mode compatibility.

Experiment:

1. Open a file with restrictive share flags.
2. From another process, try to open, delete, or rename it.
3. Repeat with permissive share flags.
4. Inspect handles and file object paths.

Evidence:

- Procmon create/open results.
- `GetLastError` values.
- Process Explorer handle view.

What this proves: a Windows open can fail even when ACLs allow access, because sharing compatibility is a separate contract.

### W5 - Named Pipe Endpoint Security And Impersonation

Claim: IPC security depends on endpoint security, client identity, impersonation level, and server behavior.

Experiment:

1. Create a local named-pipe server with explicit security descriptor.
2. Connect from a normal client and an elevated client.
3. Log client identity before and after impersonation.
4. Change SQOS/impersonation level and observe what the server can learn or do.

Evidence:

- Procmon pipe operations.
- server logs of token identity.
- Process Explorer handle/object view.

What this proves: IPC is not just bytes. It is an authority and identity-transfer boundary.

## C/C++ Runtime And Compiler Labs

### C1 - Data Race, Atomic, Volatile, And Optimization

Claim: non-atomic shared access is C/C++ data-race UB; `volatile` is not atomic; atomics change both language semantics and assembly.

Experiment:

1. Write a multi-threaded counter using plain `unsigned`.
2. Repeat with `volatile unsigned`.
3. Repeat with `std::atomic<unsigned>` and `fetch_add`.
4. Compile with `-O0`, `-O2`, and `-O3`.
5. Inspect assembly for load/add/store, locked operations, or LL/SC/LSE on ARM64.

Evidence:

- final counts across runs.
- compiler assembly output.
- ThreadSanitizer if available.

What this proves: the C++ model, compiler transformations, hardware atomicity, and cache coherence are distinct layers.

### C2 - Recursive Stack Exhaustion And Integer Wrap

Claim: recursive stack growth and unsigned modulo output are different failure modes.

Experiment:

1. Write a tiny recursive product over `unsigned`.
2. Run small, medium, and huge inputs.
3. Add pre-multiply overflow checks.
4. Rewrite iteratively.
5. Compare `-O0` and `-O3` assembly.

Evidence:

- crash signal/exception.
- stack trace depth in debugger.
- modulo arithmetic explanation.
- assembly showing recursion or loop transformation.

What this proves: crash behavior, arithmetic semantics, and optimizer transformations must be separated.

### C3 - Stack, Heap, mmap, And Guard Pages

Claim: stack, heap, direct mappings, and guard pages have different ownership and failure modes.

Experiment:

1. Allocate a large local array, a heap array, and an `mmap`/`VirtualAlloc` region.
2. Add guard pages with `mprotect` or `VirtualProtect`.
3. Overrun deliberately in a disposable toy program.
4. Observe which fault occurs and where.

Evidence:

- debugger stack trace.
- `/proc/<pid>/maps` or VMMap.
- signal/exception code.

What this proves: memory bugs are shaped by allocation family, protection, and mapping layout.

## Loader And Binary Labs

### B1 - ELF Loader Trace

Claim: executing a dynamically linked ELF maps the executable, interpreter, shared libraries, stack, vdso/vvar, and relocation state.

Experiment:

1. Build a tiny dynamically linked C program.
2. Run `readelf -l -d`.
3. Run under `strace -e execve,mmap,mprotect,openat`.
4. Inspect `/proc/<pid>/maps` while it sleeps.

Evidence:

- program headers versus sections.
- interpreter path.
- mapped libraries and permissions.
- GOT/PLT symbols where relevant.

What this proves: runtime loading follows program headers and dynamic linker behavior, not source-file intuition.

### B2 - PE Loader And DLL Evidence

Claim: Windows process startup maps an image section, initializes loader state, maps DLLs, resolves imports/API sets, and records observable module metadata.

Experiment:

1. Build a tiny Windows console program.
2. Inspect imports with PE-bear, dumpbin, or similar.
3. Run and inspect modules with Process Explorer.
4. Use Procmon for image-load events.
5. Optional WinDbg: `lm`, `!peb`, loader lists.

Evidence:

- PE headers/imports.
- module list.
- image-load telemetry.
- PEB loader data, with the caveat that PEB is user-mode and tamperable.

What this proves: loader state is concrete evidence, but no single view is complete.

## Cross-Platform Comparison Labs

Do these only after the platform labs.

| Comparison | Linux proof first | Windows proof first | Difference to write down |
|---|---|---|---|
| fd versus handle | L3 | W1/W4 | fd is a table entry to an open file description; Windows handle is a typed object reference with granted access and attributes. |
| VMA versus VAD | L1/L2 | W3 | Both are range-policy structures, but backing objects, commit, section/image semantics, and tool evidence differ. |
| `mmap` versus section/view | L1 | W3 | Shared/private/backing semantics overlap conceptually but are not API-equivalent. |
| `cred`/capabilities versus token/privileges | L4 | W2 | Both encode authority, but identity, privileges, integrity, namespaces, and policy layers differ. |
| path identity | L3 | W4 | Linux pathname/inode/fd lifetime and Windows path/object/share-mode/reparse behavior diverge sharply. |

## Lab Notes Template

Copy this into a new lab note when you run one:

```text
Date:
OS/build/kernel:
Compiler/tool versions:
Claim:
Code or command:
Expected observation:
Actual observation:
Evidence captured:
What changed in OS/runtime state:
What this proves:
What this does not prove:
Next mutation:
```

## Safety Boundary

These labs are for local understanding, defensive analysis, and authorized research. Keep them to toy programs, disposable VMs, and first-party systems. Do not turn them into persistence, evasion, credential theft, or unauthorized access recipes.

