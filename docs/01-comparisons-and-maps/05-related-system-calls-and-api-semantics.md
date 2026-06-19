# Related System Calls and API Semantics

Value Score: 82/100
Role: API semantics translation
Proof Level: Conceptual

Date: 2026-05-16

Purpose: clarify nearby Linux syscalls/libc APIs and Windows Win32/Native APIs that are easy to conflate. The goal is not memorizing names; it is knowing what state changes, what authority is required, and what telemetry or security boundary is affected.

## Core Rule

Do not compare names. Compare contracts:

- Does it create a kernel object, clone state, replace an image, or only wrap another operation?
- Is it a public stable ABI, a libc/CRT convenience API, a Win32 compatibility API, or a lower Native API?
- What authority is checked: credentials/capabilities/LSM, fd rights, handle granted access, token privileges, integrity/PPL, or policy?
- What state is inherited, reset, shared, or newly created?
- Where would a tracer see it: syscall trace, loader event, ETW, Procmon, audit/eBPF, `/proc`, handle table, or debugger view?

## Windows API Variant Naming Rules Of Thumb

Windows API names often carry useful hints, but the suffix is never the contract by itself. Treat the name as a triage clue, then read the parameters, return value, required rights, encoding, cleanup rule, and policy layer.

| Pattern | Usual meaning | Security/reversing rule of thumb |
|---|---|---|
| `A` / `W` suffix | ANSI/code-page versus wide UTF-16 API. Unsuffixed names are often macros selected by build settings. | Prefer reasoning about the `W` form. `A` variants can introduce code-page conversion, lossy paths, and string-length confusion. In binaries, imports usually reveal the concrete `A` or `W` target. |
| `Ex` suffix | Extended form: extra flags, attributes, access masks, callbacks, target handles, or output fields. | `Ex` does not mean "safer" or "newer replacement" by default. Ask what extra authority or policy is exposed. `VirtualAllocEx` is not just a bigger `VirtualAlloc`; it targets another process through a process handle. |
| Numeric suffixes such as `2`, `3`, `Ex2` | Newer extension point when the old signature could not be changed. Usually adds flags, structs, larger fields, or newer policy. | Check default compatibility behavior carefully. These APIs often exist because old defaults could not be broken. |
| `Create*` versus `Open*` | `Create*` may create a new object, open an existing named object, or do either depending on flags. `Open*` normally requires an existing object. | Do not assume `Create*` proves freshness. For named objects, check `GetLastError() == ERROR_ALREADY_EXISTS`, DACLs, namespace, and race/squatting behavior. |
| `*AsUser`, `*WithToken`, `*WithLogon`, `Impersonate*` | Explicit identity, logon, or impersonation semantics. | This is an authority boundary. Name the primary token, impersonation token, privilege requirements, session, integrity, profile/environment handling, and when the server reverts. |
| `*Ex` with process/thread handles: `VirtualAllocEx`, `VirtualProtectEx`, `VirtualQueryEx`, `ReadProcessMemory`, `CreateRemoteThreadEx` | Operation is performed against another process or with extended thread/process attributes. | The important object is the target handle and its granted access. Review `PROCESS_VM_*`, `PROCESS_CREATE_THREAD`, query rights, PPL/integrity, callbacks, and telemetry, not just the API name. |
| `*ByHandle`, handle-taking variants, and object-info APIs | Operate on an already opened object instead of resolving a path again. | Usually better for TOCTOU-resistant reasoning because the handle stabilizes object identity and granted rights. Validate the opened object, not just the original string. |
| `Get*`, `Query*`, `Enum*` | Read/query/list state. Many use two-call buffer sizing or return partial data. | Buffer length units, truncation, snapshot staleness, and required access matter. A successful enumeration is not proof the object still exists or is still accessible. |
| `Set*`, `Adjust*`, `Change*`, `Update*` | Mutate policy or object state. | Ask what authority is required and which persistent state changes: token privileges, security descriptors, registry values, service config, mitigation policy, file attributes, or object flags. |
| `Register*`, `Subscribe*`, `Set*Callback`, threadpool APIs | Install callbacks or async work. | Lifetime is the risk. Captured pointers, handles, COM interfaces, buffers, and cancellation state must outlive callback delivery. Telemetry may show later callback execution rather than the original registration as the interesting event. |
| `Overlapped` parameter or IOCP/threadpool variant | Asynchronous I/O or completion-based dispatch. | The request buffer and context must live until completion or cancellation is complete. Confusing submission with completion is a common UAF pattern. |
| `Transacted*` | Transactional NTFS or registry-style transactional API families where present. | Often legacy or rarely used. Treat as a different policy layer with compatibility and support caveats, not as a general-purpose safety upgrade. |
| `Nt*` / `Zw*` | Native API layer beneath Win32; from user mode these are `ntdll` entry points/stubs into kernel services where applicable. | Not the stable public app contract. Syscall numbers and some semantics vary by build. In kernel-mode driver code, caller mode, probing/capture, and handle interpretation make `Nt`/`Zw` distinctions important; follow documented driver contracts. |
| `Rtl*` | Runtime library helpers in `ntdll` or kernel equivalents: strings, heap, security descriptors, compression, balanced trees, bitmaps, exception/runtime support, and more. | Many `Rtl*` calls are helpers, not syscalls. They can still be security-critical because they parse, copy, compare, allocate, zero, or build object/security data. |
| `Ldr*` | Loader internals such as DLL loading and export resolution beneath Win32 loader APIs. | Useful for reversing and malware analysis, but not the ordinary stable app contract. Loader lock, API sets, manifests, KnownDLLs, search policy, TLS, and `DllMain` still matter. |
| `SH*`, `WTS*`, `Net*`, `SetupDi*`, `CfgMgr*`, `WMI`, COM APIs | Subsystem APIs above or beside the direct kernel object layer. | Expect policy, service mediation, RPC/COM, registry state, shell behavior, device-install policy, or network identity to matter before a low-level syscall is visible. |

Fast variant checklist:

1. Did the variant change the target context, such as current process versus remote process, current user versus another token, or path string versus stable handle?
2. Did it add flags, desired access, share mode, security attributes, object attributes, inheritance, or callback state?
3. Did it change encoding, length units, buffer ownership, allocator/free function, or cleanup responsibility?
4. Did it move the operation through a higher policy layer such as shell, COM/RPC, SCM, WMI, loader policy, or device setup?
5. Does success mean a new object was created, an existing object was opened, a request was submitted, or work actually completed?
6. What evidence would distinguish the variants: import name, ETW provider, Procmon stack, handle table, token, registry write, VAD, section object, or driver/IRP trace?

## Sync, Async, Interruption, And Cancellation Rules Of Thumb

Synchronous versus asynchronous is not just a performance choice. It changes who owns buffers, which thread can continue, where completion is reported, whether a wait can be interrupted, and what "cancel" can safely mean. For security review, the key distinction is: did the API finish the operation, or did it create future work whose lifetime now outlives the caller's stack?

| Question | Windows rule of thumb | Linux rule of thumb |
|---|---|---|
| Did the call finish the work before returning? | Blocking Win32 calls usually return after completion, timeout, or failure. Overlapped I/O, IOCP, APC completion, and threadpool APIs often return after submission; `ERROR_IO_PENDING` means completion will arrive later. Some overlapped operations can still complete inline. | A plain blocking syscall normally returns after completion, error, timeout, or signal interruption. `O_NONBLOCK`, readiness APIs, POSIX AIO, and `io_uring` split submission from completion. Some async submissions can complete immediately. |
| What does success mean? | For sync APIs, success usually means the requested operation completed. For async APIs, success may mean the operation was queued, not finished. Check `GetLastError`, `OVERLAPPED`, IOCP packets, events, callbacks, or `GetOverlappedResult`. | For sync syscalls, a nonnegative return usually reports completed bytes/items. For nonblocking readiness, success may only mean "would not block now." For `io_uring`, the CQE result is the completion truth, not only the SQE submission result. |
| Where is completion delivered? | Waitable handle/event, `OVERLAPPED.hEvent`, IOCP, APC completion routine, threadpool callback, status block, or explicit polling. | Return value, signal, fd readiness through `poll`/`epoll`, eventfd, callback-like userspace runtime, or `io_uring` completion queue. |
| Can it be interrupted while waiting? | Ordinary non-alertable waits are not Unix-signal-like. Alertable waits can return for APC delivery. Wait APIs can return timeout, abandoned mutex, failure, signaled object, or `WAIT_IO_COMPLETION` for alertable APC completion. | Many blocking syscalls can return `-1`/`EINTR` when a caught signal is delivered, unless restart behavior applies. `pselect`/`ppoll` exist partly to make signal mask changes around waits race-resistant. |
| Can it be cancelled? | `CancelIo` cancels pending I/O issued by the current thread for a handle. `CancelIoEx` can cancel pending I/O for a handle more broadly. `CancelSynchronousIo` targets synchronous I/O issued by a thread. Threadpool APIs have wait/cancel/close patterns and cleanup groups. Cancellation is a request; a completion can still arrive and must be drained/observed. | Signals can interrupt waits, `pthread_cancel` is cooperative at cancellation points, nonblocking mode avoids sleeping, and `io_uring` has cancellation operations. Cancellation is still race-prone: the operation may already have completed, partially completed, or produced a CQE/error that must be consumed. |
| Does closing the handle/fd stop it? | Closing a handle is not a universal cancellation primitive. It drops a reference and may cause later operations to fail, but pending I/O, duplicated handles, driver references, or completion packets can outlive the close. | Closing an fd drops that process's reference. Other duplicated fds, in-flight kernel work, socket state, blocked syscalls in other threads, or subsystem semantics may keep effects alive. Do not rely on close alone as a precise stop signal. |
| What is the dangerous forced stop? | `TerminateThread` and forceful process termination can leave locks held, heap state inconsistent, DLL detach incomplete, and shared state corrupted. They are last-resort containment, not normal cancellation. | `SIGKILL`/forced process death stops execution but skips orderly cleanup. Shared memory, locks, temp files, sockets, and external state can remain inconsistent unless the protocol handles owner death. |
| What is the safe stop pattern? | Cooperative cancellation: cancellation flag/event, cancel-safe queue or cleanup group, bounded waits, refcounted contexts, then wait for callback/I/O completion before freeing memory. | Cooperative cancellation: fd/eventfd/pipe wakeup, signal-aware wait loop, cancellation flag, timeout, robust mutex or owner-death recovery, then reap completions and release resources after users are gone. |

Security and reversing heuristics:

- Treat async submission as an ownership transfer until completion says otherwise. Stack buffers, `this` pointers, COM interfaces, handles, `OVERLAPPED` structures, `iovec`s, registered buffers, and request contexts must outlive completion or be reference-counted.
- A cancellation API normally means "please try to stop pending work", not "the work never happened." Code must handle completed-before-cancel, cancelled-before-start, partial completion, and completion-after-cancel races.
- Timeouts are not cancellation unless the API says so. A wait timeout may leave the underlying operation still pending.
- Readiness is not completion. `select`/`poll`/`epoll` report that an operation may be possible; IOCP and `io_uring` CQEs report completed work.
- In drivers and low-level runtime code, ask whether the current context is allowed to wait. Windows IRQL, Linux atomic context, interrupt context, locks held, and APC/signal state can make "just block until done" illegal or deadlock-prone.
- Evidence should include both submission and completion: API return, error/status code, wait result, event state, IOCP packet, APC/callback stack, `io_uring` CQE, ETW/Procmon, `strace`, eBPF/audit trace, and object/fd/handle lifetime.

## Process Creation and Image Replacement

| Linux call/API | What it really means | Common confusion | Windows counterpart or contrast |
|---|---|---|---|
| `fork()` | Create a child task/process as a near-copy of the parent, usually with a COW address space. | It does not load a new program by itself. | No normal Win32 equivalent. Windows normally creates a fresh process around an image. |
| `vfork()` | Create a child that temporarily shares the parent's address space until `execve` or `_exit`; parent is suspended. | Treating it like safe general-purpose `fork`. | No normal equivalent. Its danger comes from shared address-space constraints. |
| `clone()` / `clone3()` | General Linux primitive for creating tasks with selected shared resources. Threads are created by sharing VM, files, signal handlers, and related state. | Thinking `clone` always means process or always means thread. | Windows has separate process and thread creation APIs; sharing choices are not exposed as Linux-style clone flags. |
| `execve()` | Replace the current process image in the same PID/thread group leader context; rebuild mappings, stack, auxv, credentials, and loader state. | Thinking it creates a new process. | No direct normal equivalent. `CreateProcess` creates a new process; it does not replace the caller image. |
| `execveat()` | `execve` variant using a directory fd and flags such as empty-path execution. | Treating it as a different lifecycle model. | Closest Windows questions involve object handles/paths and image sections, not a direct API twin. |
| `posix_spawn()` | POSIX API that creates a new process and executes a program, often implemented with optimized fork/vfork/clone plus exec-like behavior and file actions. | Thinking it is a kernel syscall equivalent to `execve`. It is an API contract, not the same primitive. | Closest practical peer is `CreateProcessW`: one API asks for "start this program" without exposing a fork stage. |
| `system()` / shell launch | Library helper that invokes a shell command. | Treating it as direct execution of the target binary. | `ShellExecuteEx` is similarly higher-level: file association, shell policy, verbs, and UI can matter. |
| `_exit()` | Terminate immediately through the kernel path, bypassing most libc cleanup. | Treating it like `exit()`. | Similar caution to `TerminateProcess`: orderly destructors are not the model. |
| `exit()` | libc/runtime termination path: runs `atexit`, destructors, stdio cleanup, then exits. | Treating it as a raw syscall. | CRT `exit` differs from `ExitProcess` in where runtime cleanup happens. |

| Windows API | What it really means | Common confusion | Linux counterpart or contrast |
|---|---|---|---|
| `CreateProcessW()` | High-level Win32 process creation: image path, command line, environment, handles, attributes, token context, initial thread, loader startup. | Thinking it is just a syscall. Significant user-mode and loader behavior surrounds it. | Practical peer to `posix_spawn`, not to `fork`. |
| `NtCreateUserProcess()` | Lower Native API used beneath process creation paths; exposes NT-style attributes and object semantics. | Treating it as the stable public contract. | Linux syscalls are public ABI; Windows Native/syscall details are less stable. |
| `CreateProcessAsUser` / `CreateProcessWithToken` / `CreateProcessWithLogon` | Process creation with explicit token/logon semantics. | Thinking "create process" ignores identity. | Linux equivalent questions involve credentials, setuid/file capabilities, PAM/session setup, namespaces, and LSM policy. |
| `ShellExecuteEx()` | Shell-mediated launch: verbs, file associations, elevation prompts, App Paths, URL handlers, and shell policy can participate. | Treating it like `CreateProcessW`. | More like launching through a shell/desktop policy layer than `execve`. |
| CRT `_spawn*` | C runtime family that starts another program using platform process creation. | Confusing CRT API naming with Linux `posix_spawn`. | Similar high-level intent; different OS contract underneath. |
| `CreateThread()` | Create a thread in the current process. | Treating it like process creation. | Closer to `pthread_create`/`clone(CLONE_VM...)` than to `fork`. |
| `ExitProcess()` | Terminate the current process through OS termination path, with DLL detach behavior where possible. | Assuming CRT destructors necessarily ran before it. | Compare `exit` versus `_exit` distinction. |
| `TerminateProcess()` | Force termination of a target process by handle authority. | Treating it as graceful shutdown. | Closer to a forceful `kill` than to `exit`, but Windows handle rights are central. |

Security angle: `execve` is where Linux applies setuid/file capabilities, `no_new_privs`, dumpability changes, `FD_CLOEXEC`, and LSM checks. `CreateProcess*` is where Windows handle inheritance, token choice, parent-process attributes, mitigation policy, AppContainer, integrity, and image-load telemetry matter.

## Linux Libc And Process-State APIs That Are Easy To Misread

Some Linux names look like kernel mechanisms but are actually libc/runtime contracts, while others are real process-state syscalls. Distinguish the layer before assigning security meaning.

| API | Layer | What it means | Attacker/security relevance |
|---|---|---|---|
| `fputc_unlocked`, `getc_unlocked`, `putc_unlocked`, `fwrite_unlocked` | libc stdio | Same broad stdio operation, but without taking the stream's internal lock. | Relevant when the same `FILE *` can be touched concurrently. Bugs are usually application-level races, corrupted/interleaved output, stale buffer state, or logging/audit confusion, not a kernel privilege boundary. |
| `flockfile`, `ftrylockfile`, `funlockfile` | libc stdio | Explicitly lock a `FILE *` so a caller can perform multiple stdio operations as one serialized region, often around `_unlocked` calls. | Correct use can make `_unlocked` safe and faster. Incorrect lock/unlock pairing can deadlock, expose inconsistent logs, or create cleanup bugs on cancellation/error paths. |
| `prctl` | syscall/API wrapper | Mutates or queries miscellaneous process/thread attributes: dumpability, `no_new_privs`, seccomp mode, process/thread name, parent-death signal, ptrace policy interactions, child-subreaper behavior, and newer mitigation knobs where supported. | High relevance. It affects post-RCE blast radius, inspectability, anti-debugging, sandboxing, child process privilege transitions, and telemetry. Always identify the exact `PR_*` option. |
| `readlink`, `readlinkat` | syscall/API wrapper | Read the contents of a symbolic link or magic link into a caller buffer. It does not append a NUL byte. | Relevant for path confusion and introspection: `/proc/self/exe`, `/proc/<pid>/fd/N`, namespace-dependent paths, deleted files, and truncation bugs. The security question is what object the link names now, not just the string returned. |

`*_unlocked` is not "turn off kernel locking." It skips libc's per-stream stdio lock. It is safe only if the stream is thread-local, the caller holds `flockfile`, or a higher-level lock serializes all access to that `FILE *`. A remote attacker usually cannot exploit `_unlocked` by name; they exploit the surrounding concurrency mistake if remote-controlled requests can make multiple threads write to the same stream, rotate/close it, or rely on log ordering for security decisions.

`prctl` is different: it changes process attributes the kernel uses later. `PR_SET_NO_NEW_PRIVS` can block future setuid/file-capability privilege gain and is usually required before unprivileged seccomp filters. `PR_SET_DUMPABLE` affects core dumps and ptrace/procfs inspectability. `PR_SET_NAME` changes thread names and can confuse weak telemetry. `PR_SET_PDEATHSIG` and child-subreaper behavior affect process supervision and cleanup. Treat `prctl` calls as state changes, not as harmless metadata.

## Files, Paths, and Object Opens

| Linux call/API | What changes | Windows contrast |
|---|---|---|
| `open()` | Open by process current directory and pathname; returns fd. | `CreateFileW` returns a handle with granted access and share-mode semantics. |
| `openat()` | Resolve relative to a directory fd, reducing ambient current-directory dependence. | NT object attributes can carry root handles; Win32 has different path normalization layers. |
| `openat2()` | Adds explicit resolution constraints such as no symlinks, beneath root, no magic links, no crossing mounts. | Windows hardening uses reparse-point policy, `FILE_FLAG_OPEN_REPARSE_POINT`, final-object checks, file IDs, and careful `CreateFile` flags. |
| `creat()` | Historical shorthand for opening/truncating/creating a file. | Do not treat it as a separate object model. |
| `stat()` / `lstat()` / `fstat()` / `statx()` | Query metadata by path, symlink itself, fd, or extended modern interface. | Windows uses `GetFileInformationByHandle*`, file IDs, reparse tags, and object/file information classes. |
| `readlink()` / `readlinkat()` | Read symlink or procfs magic-link target bytes; result is not NUL-terminated by the syscall contract. | Windows counterparts depend on reparse-point queries, final-path queries, and handle-based file identity; not a direct string twin. |
| `unlink()` | Remove a directory entry; open files can remain alive. | Windows delete disposition and share modes can prevent or defer deletion depending on open handles. |
| `rename()` / `renameat2()` | Atomic namespace update with flags on Linux. | Windows rename/delete semantics are handle/share/disposition-heavy and often visible through IRPs/minifilters. |

Security angle: path APIs are TOCTOU surfaces. Strong code opens the intended object under constraints and then validates the opened object, not just the string.

## Memory and Execution

| Linux call/API | What changes | Windows contrast |
|---|---|---|
| `mmap()` | Creates a VMA: address choice, backing object, sharing/COW, and initial protections. | Windows splits this across `VirtualAlloc`, `CreateFileMapping`, `MapViewOfFile`, section objects, and view access. |
| `mprotect()` | Changes protections in the calling process. | `VirtualProtect` changes current process; `VirtualProtectEx` changes another process if the handle has `PROCESS_VM_OPERATION`. |
| `madvise()` | Provides hints or policy changes for an existing range. | Windows has separate APIs such as `PrefetchVirtualMemory`, `DiscardVirtualMemory`, `MEM_RESET`, working-set trimming, and dump policy. |
| `memfd_create()` | Creates anonymous fd-backed memory that can be sealed, mapped, and sometimes executed. | Roughly compare to unnamed section objects, not to plain heap allocation. |
| `process_vm_readv()` / `process_vm_writev()` | Cross-process copy after ptrace-style authorization. | `ReadProcessMemory` / `WriteProcessMemory` require a process handle with appropriate granted rights. |
| `ptrace()` | Debugger-style control over tracee threads, registers, memory, and syscall stops. | Windows debug APIs and thread/process handles cover related but not identical control. |

Security angle: executable memory triage asks how bytes became executable: image mapping, JIT, unpacking, `mprotect`, `VirtualProtect`, mapped section, modified image page, or remote write plus thread/APC/context redirection.

## Waiting, Signaling, and Lifetime

| Linux call/API | What it means | Windows contrast |
|---|---|---|
| `waitpid()` / `waitid()` | Parent or eligible waiter reaps child status; zombies exist until reaped. | Process objects are waitable by handle; there is no zombie reaping model. |
| `kill()` | Send a signal subject to credential, namespace, and LSM checks. | `TerminateProcess` requires a handle with `PROCESS_TERMINATE`; other control uses events, console control, job policy, service control, or window messages. |
| `pidfd_open()` / pidfd waits | Stable process identity/lifetime reference for selected operations. | Closer to a process handle for identity/waiting, but not a handle with broad granted access rights. |
| `tgkill()` / `pthread_kill()` | Target a specific thread with a signal. | Windows APCs, thread suspension, and alerts are not Unix signals; user APCs require alertable waits. |

Security angle: Linux parent-child lifecycle and signal permission are central. Windows handle rights, jobs, services, sessions, and tokens are central.

## Dynamic Loading and Symbol Resolution

| Linux call/API | What it means | Windows contrast |
|---|---|---|
| `dlopen()` | Ask the dynamic linker to load a shared object under ELF search/scope rules. | `LoadLibraryEx` enters Windows loader policy: DLL search, KnownDLLs, API sets, manifests, packaged-app policy. |
| `dlsym()` | Resolve a symbol according to ELF handle/scope/versioning/interposition rules. | `GetProcAddress` resolves PE exports by name or ordinal, including forwarders. |
| `LD_PRELOAD` / `LD_AUDIT` | Loader-supported interposition/auditing where policy allows. | No direct twin; compare DLL search-order abuse, AppInit legacy behavior, IFEO, COM/shell/service extension points. |
| `dlclose()` | Decrement loader reference; actual unload can be constrained by references, TLS, threads, and runtime state. | `FreeLibrary` has similar "request unload, but loader state matters" caveat. |

Security angle: loader APIs are normal extension mechanisms and common abuse surfaces. Attribute behavior by actual loaded path, backing file, signature/package, loader metadata, and memory mappings.

## Syscall Versus API Layer

| Topic | Linux | Windows |
|---|---|---|
| Stable public low-level ABI | Syscalls are a public per-architecture ABI. | Win32 is the stable application contract; syscall service numbers are build-specific implementation details. |
| Typical wrapper work | libc may handle cancellation points, `errno`, vDSO fast paths, buffering, and compatibility. | Win32/CRT may normalize paths, convert parameters, apply app-compat policy, use RPC/ALPC, or call multiple Native APIs. |
| Direct syscall meaning | Normal in low-level Linux code. | Often a malware/EDR-evasion signal, but still only one layer of semantics. |
| Best first tracing view | `strace`, audit, eBPF tracepoints often explain much of the behavior. | Procmon/ETW often explains intent better than raw syscall traces. |

Security angle: a Windows direct syscall may bypass user-mode hooks but does not bypass kernel object security, tokens, handles, PPL, memory-manager checks, or driver validation. A Linux raw syscall bypasses libc behavior but not kernel checks, LSM, seccomp, namespaces, or capabilities.

## Interview Rule

When asked "what is the equivalent of X?", answer with the operation, not a memorized twin:

1. What object or state is created, replaced, shared, or destroyed?
2. Which authority check decides it?
3. Which cleanup/inheritance rules apply?
4. What would prove it happened from telemetry or debugger state?
5. Which similarly named API is a wrapper, convenience function, or higher-level policy layer?
