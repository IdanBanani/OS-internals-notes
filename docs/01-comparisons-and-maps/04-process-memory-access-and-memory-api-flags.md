# Cross-Platform Process Memory Access and Memory API Flags

Value Score: 86/100
Role: Process-memory API translation
Proof Level: Conceptual, lab-routed

Date: 2026-05-15

Purpose: make the Windows-to-Linux analogies precise for APIs such as `ReadProcessMemory`, `PROCESS_VM_READ`, `VirtualAllocEx`, `mmap`, `mprotect`, and `madvise`. Study this after the VMA/VAD and handle/fd basics, and before malware triage, debugger internals, injection detection, or memory-forensics work.

Runtime allocation companion: [User-mode heaps, runtime APIs, and toolchains](<../05-topic-notes/user-mode-heaps-runtime-apis-and-toolchains.md>) covers the layer above these page-oriented APIs: `malloc`/`new`, UCRT, `LocalAlloc`/`GlobalAlloc`, `HeapAlloc`, `HeapCreate`, LFH, segment heap, `VirtualFree`, and allocator/toolchain security implications.

Windows kernel-memory companion: [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>) covers section objects, `MapViewOfFile`, `OpenFileMapping`, `NtMapViewOfSection`, pagefile-backed mappings, file cache, token privileges, `kernel32` address reuse, and KASLR.

What to focus on:

- Authority: who is allowed to inspect or modify another process?
- Range policy: which VMA/VAD says the virtual range is valid and with which protections?
- Backing object: anonymous/private memory, file mapping, image section, shared section, page cache, or pagefile-backed storage.
- Hardware state: what PTE permissions eventually reach the MMU?
- Telemetry: which handle opens, ptrace relationships, memory maps, protection changes, section mappings, and thread starts are visible?

## Offensive Priority Index

| Score | Section | Why it matters |
|---:|---|---|
| 100 | One mental model; policy bits, translation bits, page-record bits | Separates access checks from VAD/VMA/PTE reality and physical page metadata. |
| 100 | Windows process handles and `PROCESS_VM_*` rights; Linux ptrace/dumpable/capability checks | Determines whether cross-process read/write/injection should be possible. |
| 99 | `VirtualAllocEx`, `WriteProcessMemory`, sections, `mmap`, `mprotect`, `process_vm_readv` | Core APIs for debugger, injector, memory-forensics, and agent-runtime reasoning. |
| 98 | Protection transitions, COW, file/image/shared/private backing | Explains RX/RW transitions, image-private mismatch, patching, and shared-memory behavior. |
| 97 | Telemetry and evidence | Lets you prove the model through handles, maps, VADs, section objects, ptrace state, and memory protections. |
| 95 | Nearby API semantics and platform analogy traps | Useful after the authority and mapping model is solid. |

## One Mental Model

The shared abstraction is:

1. Obtain authority over a target process or memory object.
2. Identify or create a virtual range.
3. Decide whether the range is private, file-backed, image-backed, shared, or copy-on-write.
4. Set protections.
5. Read, write, fault, execute, discard, prefetch, lock, dump, or remap pages.

The implementations differ:

- Windows makes authority concrete through handles with granted access masks. If a process handle lacks `PROCESS_VM_READ`, `ReadProcessMemory` is not supposed to work, even if the caller knows the address.
- Linux usually does not have a durable "process handle with memory rights" equivalent. It checks the operation against credentials, dumpable state, ptrace access mode, namespaces, capabilities, and LSM/Yama policy at the point of use.
- A Linux pid or pidfd is not the same thing as a Windows process handle with `PROCESS_VM_*` rights. A pidfd is mainly an identity/lifetime reference; memory access still needs a separate permission path.

## Policy Bits, Translation Bits, And Page-Record Bits

Memory tools show different truth layers. A `/proc/<pid>/maps` line, a VMMap VAD row, a PTE dump, and a physical-page/PFN record can all describe the same address while answering different questions.

| Layer | What it records | Examples of bits/state | Security use |
|---|---|---|---|
| VMA/VAD range policy | Whether an address range is valid and what it is allowed to become. | Linux read/write/exec/shared/may-permission, grow-down, locked, dump, I/O, huge-page, COW policy. Windows protection, guard/noaccess, private/mapped/image, reserve/commit, section view, COW policy. | Tells whether a fault should be legal and which backing object/policy applies. |
| Page table / PTE | Current hardware translation or a software-encoded nonpresent state. | Present/valid, PFN, writable, user/supervisor, NX/XN, accessed, dirty, cache type, global, huge page; OS-specific swap/transition/prototype/demand-zero encodings. | This is what the CPU enforces after a translation is installed and visible to the TLB. |
| Physical page record | Lifetime, ownership, residency, and reclaim state for a physical page. | Linux `struct page`/folio refcount, mapcount, LRU, dirty/writeback, slab, pinned, swap-backed. Windows PFN database page-list state, share/reference counts, modified/standby/free/zeroed, working-set relationship. | Explains leaks, pins, COW, reclaim, DMA, page-cache confusion, and forensic residency. |
| Backing object | Where bytes come from and who can share them. | Linux file `address_space`, page cache, anon_vma/rmap, swap. Windows section object, control area, prototype PTEs, file object, pagefile backing. | Decides sharing, file/image identity, COW, and persistence. |
| Enforcement cache/lower layer | Cached or secondary translations. | CPU TLB/page-walk cache, I-cache/D-cache coherency, IOMMU tables, EPT/NPT/stage-2 translation. | Can preserve stale access, constrain DMA, or let a hypervisor enforce a lower truth than the guest OS. |

This split is deliberate. Range policy can be created lazily before physical pages exist. Hardware PTEs are compact and architecture-specific, so kernels use software metadata for commit, backing files, COW, guard pages, dump policy, page-cache identity, reclaim, and sharing. Physical pages can outlive or be shared by many virtual mappings. A serious memory-security answer therefore asks which layer changed, which layer enforces the next access, and which layer a tool is showing.

Large/huge pages are the page-size case where this split becomes very visible. A normal 4 KB x64 mapping ends in a final PTE; a 2 MB mapping stops at a PDE/PMD leaf; a 1 GB mapping stops at a PDPTE/PUD leaf. The higher-level leaf supplies the PFN and permissions for the whole range, so there may be no final 4 KB PTEs to inspect. The TLB caches the resulting translation at that larger page size, so a TLB hit avoids lower page-table reads and covers far more virtual memory per entry. This is why `MAP_HUGETLB`, THP, `MEM_LARGE_PAGES`, and `SEC_LARGE_PAGES` are not just performance flags: they change TLB reach, page-table memory, alignment requirements, residency behavior, protection granularity, stale-invalidation risk, and the blast radius of PTE/PDE corruption.

## Shared, Private, Copy-On-Write, And Resident Pages

"Shared memory" can mean several different things. A virtual range can be backed by a shared object, can currently point at a physical page also mapped elsewhere, can be clean file-cache data, or can be private COW data after a write. Always separate mapping policy from current physical page state.

| Question | Linux answer | Windows answer |
|---|---|---|
| What is private anonymous memory? | Heap, stack, anonymous `mmap`, and COW-private pages. The VMA may be valid before any physical page exists; first touch faults in a zero page or private page. | `VirtualAlloc` private memory and private VADs. Reserving address space, committing backing, and resident physical pages are separate states. |
| What is file-backed sharing? | File data is cached in the page cache. Multiple processes mapping or reading the same file can use the same clean cached pages. | File data is cached through Cache Manager/section machinery. Multiple mapped views or reads can converge on cached file data and section-backed pages. |
| What does `MAP_PRIVATE` mean? | It is file-backed copy-on-write. Clean pages can be physically shared through the page cache, but a write creates a private anonymous page for that process. | Similar to copy-on-write mapped views such as `FILE_MAP_COPY` and image COW behavior. The view may initially share backing pages, then diverge when written or relocated/patched. |
| What does `MAP_SHARED` mean? | Writes go to the shared backing object and can be visible to other mappings of that object, subject to coherence, filesystem, and durability rules. | Shared section views let processes see updates through the same section object, subject to mapping protections, cache manager, and flush semantics. |
| Are executable files/libraries shared? | Usually the clean executable/text pages of ELF binaries and shared objects are shared through file-backed mappings. Writable data, GOT/relocation-touched data, TLS, heap, stack, and modified code pages are private per process. | Clean image-section pages for EXEs/DLLs can be shared through section objects/control-area style backing. Writable data, TLS, loader state, relocation/COW pages, hooks/patches, and private image modifications are per process. |
| Does mapped mean resident? | No. A VMA can exist with no resident page. The page may fault from file, zero-fill, swap, or COW later. `/proc/<pid>/smaps` helps distinguish RSS, shared clean, shared dirty, private clean, and private dirty. | No. A VAD/view can exist without a resident page. Working set, prototype PTEs, transition pages, pagefile, image/file backing, and standby/cache state decide current residency. VMMap and WinDbg views help distinguish private, image, mapped, shared, and working-set state. |
| Does shared mean writable by all? | No. Sharing and permissions are separate. A page can be shared read-only, shared writable, private writable, executable read-only, or COW. | Same. A section can have a maximum protection and each view has view access/protection. A shared image page can be read/execute while writable data becomes per-process COW. |

DLLs and shared libraries are therefore not "always shared between processes." The accurate statement is narrower: if two processes map the same backed image normally, clean image/text pages are strong candidates for physical sharing; pages that are writable, relocated, copy-on-written, patched, manually mapped, differently backed, or not resident are not the same shared physical page. A manually mapped or reflective DLL-shaped region is especially different because it may be private memory with PE-like bytes rather than a normal image section created by the loader.

### What Happens If A Shared Image Page Is Written?

A normal loaded DLL or shared object should not be modeled as one writable physical blob shared by every process. On both Windows and Linux, clean image/text pages can be shared, but writable image data and modified image pages are normally isolated through copy-on-write or private mappings.

| Write scenario | Usual result | Security meaning |
|---|---|---|
| Same-process write to a writable global inside a DLL/shared object | The writing process gets or already has a private writable page for that image data. | The write corrupts that process's module state, not every process using the same DLL or `.so`. |
| Same-process `VirtualProtect`/`mprotect` plus patch of image code | The code page normally becomes a private COW page in that process. | Inline hooks and hot patches are usually process-local evidence: compare the process bytes to the clean backing image. |
| `WriteProcessMemory`, debugger write, or ptrace write into another process's module | The target process's mapping is modified or COW-split. | This affects the target process, not a global copy of the system DLL/shared library. |
| Shared writable data-file mapping, named section, POSIX shm, SysV shm, or `MAP_SHARED` mapping | Writes can be visible to other mappings of the same object, subject to permissions and synchronization. | This is true shared writable state and is much more boundary-sensitive. |
| Kernel/PTE/control-area/backing-file modification | Can affect broader system state, depending on exactly what is modified. | This requires kernel/trusted authority or a powerful primitive and runs into integrity defenses, signing policy, cache/section lifetime, and crash risk. |

Old Linux `__malloc_hook`/`__free_hook` exploitation is a useful analogy. Those symbols lived in libc's writable data, while normal libc mappings are file-backed private mappings for writable segments. Overwriting a hook through a heap bug changed that process's libc data page; it did not rewrite one global `libc.so` data page used by every process. Modern glibc also removed those hooks as the old practical exploitation target, but the memory-management lesson remains: a shared library's clean text can be shared while its mutable runtime state is per process.

Windows KnownDLLs follow the same broad rule. KnownDLLs make trusted image section objects available through `\KnownDlls`, but a user-mode patch to `ntdll.dll` or `kernel32.dll` inside one process normally produces private modified pages for that process. To affect other processes, an attacker generally needs to patch each target process, abuse a genuinely shared writable section, modify the backing image before mapping under policy constraints, or gain kernel-level control over memory-manager state.

The edge case is deliberate shared writable image state, such as a PE section marked shared or an explicit named section/file mapping used as IPC. Treat that as shared memory, not as the normal "system DLL code pages are shared" case. The security question becomes who can map it writable, who consumes the data, and whether the reader crosses a trust boundary.

Cache also has to be named precisely:

- Linux page cache stores file-backed pages. It can feed `read`/`write` and `mmap` paths; `MAP_PRIVATE` writes break away into private anonymous pages.
- Windows Cache Manager and section objects cooperate with the memory manager for cached file I/O, mapped files, and image sections. Image views and data-file views have different semantics.
- The CPU cache is another layer entirely. It caches physical memory contents/translations at hardware level and does not decide whether a mapping is private, shared, COW, or file-backed.

## Who Controls Sharing, And Why It Matters

The important distinction is not only "private versus shared." It is:

- Shareable backing: the range points at a file, image, section, shm object, memfd, or other object that more than one process could map.
- Currently shared page: the PTEs in two processes currently resolve to the same physical page.
- Shared writable state: one process can write data that another process can later read or execute through the same backing object.
- Private-after-COW state: the mapping started from shared/file/image backing, but this process now has a private page after a write, relocation, hook, or patch.

| Memory situation | Who controls access | Security meaning |
|---|---|---|
| Clean file/image page | Linux file permissions, mount/namespace/LSM policy, open fd rights, and kernel mapping policy. Windows file object access, section creation, image-section semantics, DACLs, and handle rights. | Usually normal and memory-efficient. It is "can be shared" and often "currently shared", but read-only code sharing does not by itself grant write authority over another process. |
| Private anonymous memory | The owning process controls its own mappings, subject to OS policy. Other processes need debugger/cross-process authority, a shared object, or kernel/driver authority to affect it. | Stronger isolation. A normal unrelated process cannot decide to map another process's heap or stack just because it knows an address. |
| `MAP_PRIVATE` / copy-on-write image or data view | The backing object controls initial bytes. The writing process controls only its private COW copy after the write. | Good for loading common code/data while isolating modifications. A hook or patch in one process's private image page usually does not modify the clean page used by others. |
| `MAP_SHARED` / shared section view | The creator or opener needs access to the backing file/shm/section object. Other processes need a name, inherited/duplicated fd or handle, or a brokered transfer plus sufficient permissions. | Integrity-sensitive. A lower-trust writer and higher-trust reader over the same writable mapping can become a privilege boundary bug. |
| POSIX shm / SysV shm / `memfd` | Creator sets mode/ownership or holds the fd; namespaces, ACLs, LSMs, seals, fd passing, and lifetime rules decide who can map it. | No pathname does not mean no authority model. For `memfd`, the fd is the authority; for named shm, name and permissions matter. |
| Windows file mapping / section object | Section creator sets maximum protection and security attributes; Object Manager/SRM enforce DACLs; handles carry granted access; handles can be inherited or duplicated. A view cannot exceed the section's allowed access/protection. | Not any process can join. A process must obtain a suitable section/file-mapping handle or open a named object allowed by its DACL. Weak DACLs, inherited handles, and predictable names are common mistakes. |
| Page combining / dedup-like sharing | Controlled by OS policy and, on Linux KSM-style paths, usually process/admin opt-in. Windows memory combining is system policy, not ordinary shared-memory IPC. | Mostly a memory-efficiency and side-channel/forensics concern. It does not mean one process has write access to another; writes normally break sharing through COW. |

Security consequences:

- Confidentiality: shared readable mappings can expose data if names, fds, handles, DACLs, mode bits, or inherited descriptors are too broad. Uninitialized shared memory is a classic leak.
- Integrity: shared writable mappings are dangerous across trust boundaries because the writer can change what the reader observes. If the reader treats shared data as trusted commands, lengths, pointers, or code, the mapping becomes an attack surface.
- Code execution: executable shared mappings deserve special scrutiny. The highest-risk shape is writable by one party and executable or load-like for another, or a remote process chain that maps/writes/protects/executes through shared sections.
- Forensics: clean shared image pages usually support the normal-loader story. Private dirty executable pages inside an image range support "this process diverged from the backing image."
- Control: normal processes cannot arbitrarily turn someone else's private memory into shared memory. They can only affect mappings where they hold the right fd/handle/object permission, have debugger/cross-process authority, or use a kernel/driver path.

## Memory-Mapped Files And Image Sections

Memory-mapped files are not just file I/O with a different API. They create virtual address ranges whose pages are supplied by a backing object on demand. The closest cross-platform invariant is: open or create a backing object, map a range, let page faults instantiate pages, then synchronize dirty data and lifetime according to the mapping mode.

| Step | Linux | Windows | Why it matters |
|---|---|---|---|
| Get backing authority | Open an fd to a file, shm object, memfd, device, or tmpfs object. | Open a file handle or create a pagefile-backed section/file mapping object. | The fd/handle/object permissions decide who can map, write, execute, or pass the mapping. |
| Create the mapping | `mmap(fd, ..., MAP_SHARED/MAP_PRIVATE, PROT_*)` creates the VMA directly. | `CreateFileMapping`/`NtCreateSection` creates a section/file mapping; `MapViewOfFile`/`NtMapViewOfSection` maps a view. | Linux combines decisions in one call; Windows splits section maximum protection from per-view access. |
| Describe range policy | `vm_area_struct` records range, permissions, flags, file pointer, and operations. | A VAD records the mapped view, protection, type, commit/image/mapped/private classification, and section backing. | This is the policy layer before any physical page is resident. |
| Resolve first access | Fault handler reads/fills from page cache, anonymous zero page, COW, swap, or device ops. | Memory manager resolves through section/prototype-PTE state, Cache Manager/file backing, pagefile backing, image backing, COW, or demand-zero. | Mapping existence is not residency. First access may be the expensive or failing operation. |
| Write behavior | `MAP_SHARED` writes dirty shared backing; `MAP_PRIVATE` writes allocate private COW pages. | Writable mapped views dirty shared section/cache state; `FILE_MAP_COPY` and image writes produce private COW pages. | This decides whether another process or the file can observe the write. |
| Flush and durability | `msync`, `fsync`, writeback, filesystem/journal policy. | `FlushViewOfFile`, `FlushFileBuffers`, lazy writer, Cache Manager/filesystem policy. | Visibility to another mapping and durable storage are different guarantees. |
| Lifetime after close/unlink | Mapping can survive fd close; unlink removes the name but existing mappings/fds can keep data alive. | Views/section handles can outlive the original file handle; image/file backing can remain referenced while section views exist. | Path state, handle state, section state, and memory state can disagree. |

Windows image sections are a special case. A PE mapped as an image section is not just a byte-for-byte data mapping:

- The image section is created with image semantics, often through loader paths or `SEC_IMAGE`.
- PE headers and section table shape alignment and initial protections.
- Clean code pages can be physically shared between processes mapping the same image.
- Writes to image pages usually become private COW pages for that process.
- User-mode loader work then adds imports, API-set resolution, relocations, TLS callbacks, `DllMain`, and PEB loader metadata.

Linux ELF executable/shared-object mappings are conceptually similar at the "file-backed executable mapping" level, but the runtime mechanics differ: ELF program headers drive `PT_LOAD` mappings, the interpreter/dynamic linker maps dependencies, and `/proc/<pid>/maps` exposes VMA ranges and file paths rather than Windows private/mapped/image VAD categories.

Security review checklist:

1. Is this a data-file mapping, shared-memory section, pagefile-backed section, or image section?
2. Who can obtain the fd/handle/name and with which access?
3. Is the view shared writable, copy-on-write, executable, or writable-and-executable?
4. Can writes persist to the file, only affect a private COW page, or only affect a pagefile-backed section?
5. Does loader metadata agree with mapping evidence: `/proc/<pid>/maps`, PEB loader lists, VADs, ETW image-load events, backing file, and memory bytes?
6. Did control flow actually enter this mapped range through a thread start, APC/callback, function pointer, import thunk, JIT entry, or exception path?

## Cross-Process Memory Access

| Goal | Windows vocabulary | Linux vocabulary | Important difference |
|---|---|---|---|
| Open authority to a process | `OpenProcess(desiredAccess)` returns a handle with granted rights | pid, pidfd, `/proc/<pid>`, ptrace attach, capability/LSM checks | Windows stores granted authority in the handle table. Linux mostly re-checks authority per operation. |
| Read memory | `ReadProcessMemory`, `NtReadVirtualMemory`; handle needs `PROCESS_VM_READ` | `process_vm_readv`, `ptrace(PTRACE_PEEK*)`, `/proc/<pid>/mem`, core dump | Closest API analogy is `process_vm_readv`, but Linux authorization is ptrace-style, not a `PROCESS_VM_READ` bit. |
| Write memory | `WriteProcessMemory`, `NtWriteVirtualMemory`; handle needs `PROCESS_VM_WRITE` and `PROCESS_VM_OPERATION` | `process_vm_writev`, ptrace pokes, `/proc/<pid>/mem` writes | Windows separates write authority from address-space operation authority. Linux checks ptrace-like authority and the target mapping semantics. |
| Allocate in target | `VirtualAllocEx`, `NtAllocateVirtualMemory`; handle needs `PROCESS_VM_OPERATION` | no direct "mmap into arbitrary process" syscall; use target cooperation, ptrace-controlled syscall, or shared mapping | Windows exposes a direct remote allocation API. Linux usually requires debugger-like control or prearranged shared memory. |
| Change target protection | `VirtualProtectEx`, `NtProtectVirtualMemory`; handle needs `PROCESS_VM_OPERATION` | `mprotect` inside the target, usually through target code or ptrace-controlled syscall | Linux `mprotect` affects the calling process, so remote protection changes require control of the target. |
| Map shared memory | section object, `CreateFileMapping`, `MapViewOfFile`, `NtCreateSection`, `NtMapViewOfSection`, `FILE_MAP_*` | shared file mapping, `shm_open`, SysV SHM, `memfd_create`, `mmap(MAP_SHARED)` | Windows section objects are first-class kernel objects; Linux uses fd-backed mappings and VMA state. |
| Query maps | `VirtualQueryEx`, VMMap, WinDbg `!address`/`!vad` | `/proc/<pid>/maps`, `/proc/<pid>/smaps`, `pmap` | Windows usually assembles memory truth from APIs, VADs, section state, and debugger views. Linux exposes a filesystem-shaped map view. |
| Start execution | `CreateRemoteThread`, `NtCreateThreadEx`, APC, context hijack, debug APIs | ptrace register/context control, signals, remote dynamic-linker call, target cooperation | Do not map one API to one API. The invariant is authority, memory placement, and control-flow redirection. |

## Windows Process Access Rights Worth Recognizing

| Right | Meaning in memory/security analysis | Linux analogy |
|---|---|---|
| `PROCESS_VM_READ` | Required for `ReadProcessMemory`; also a common sign of debuggers, scanners, dumpers, EDR, or credential theft tooling. | `process_vm_readv`, ptrace read, `/proc/<pid>/mem` read after ptrace-style permission checks. |
| `PROCESS_VM_WRITE` | Required for `WriteProcessMemory`; suspicious when aimed at sensitive or unrelated processes. | `process_vm_writev`, ptrace write, `/proc/<pid>/mem` write. |
| `PROCESS_VM_OPERATION` | Required for address-space operations such as `VirtualAllocEx`, `VirtualProtectEx`, and `WriteProcessMemory`. | Remote `mmap`/`mprotect` only through target cooperation or ptrace-controlled execution. |
| `PROCESS_QUERY_INFORMATION` / `PROCESS_QUERY_LIMITED_INFORMATION` | Used to query process metadata; often appears with memory scanning or dump tooling. | Reading `/proc/<pid>/status`, `/proc/<pid>/maps`, `/proc/<pid>/fd`, subject to procfs and ptrace/read checks. |
| `PROCESS_CREATE_THREAD` | Enables remote thread creation paths. | No direct equivalent; ptrace can redirect a stopped thread or arrange a syscall/call path. |
| `PROCESS_DUP_HANDLE` | Enables handle duplication from or into a process; useful for stealing already-open object authority. | Passing fds over Unix sockets or inspecting `/proc/<pid>/fd` are related concepts, but not equivalent. |
| `PROCESS_SUSPEND_RESUME` | Lets a tool freeze/resume the process; useful for dump consistency and manipulation. | `SIGSTOP`/`SIGCONT`, ptrace stops, cgroup freezer-like mechanisms. |
| `PROCESS_TERMINATE` | Lets a holder kill the process. | `kill` subject to signal permission checks and namespace rules. |
| `SYNCHRONIZE` | Lets a caller wait on process termination. | `waitpid` for children or pidfd polling/wait-like patterns. |
| `PROCESS_ALL_ACCESS` | Broad authority request; noisy and version-sensitive. | "root/CAP_SYS_PTRACE plus permissive policy" is closer than any single flag, but still not identical. |

`SeDebugPrivilege` can help a Windows caller obtain otherwise denied process access, but it is not a universal bypass. Protected Process Light, integrity boundaries, kernel callbacks, policy, and security products may still matter.

On Linux, remember these gates instead of looking for access-mask bits:

- same UID and dumpable state;
- ptrace attach/read access mode;
- `CAP_SYS_PTRACE` in the relevant user namespace;
- Yama `ptrace_scope`;
- LSM policy such as SELinux or AppArmor;
- procfs mount options and namespace visibility;
- seccomp restrictions on the caller's available syscalls.

## `mmap` Flags Versus Windows Allocation and Mapping

| Linux flag/concept | Windows counterpart | Security and debugging focus |
|---|---|---|
| `PROT_READ`, `PROT_WRITE`, `PROT_EXEC`, `PROT_NONE` | `PAGE_READONLY`, `PAGE_READWRITE`, `PAGE_EXECUTE_READ`, `PAGE_EXECUTE_READWRITE`, `PAGE_NOACCESS` | The protection requested at mapping/allocation time becomes VMA/VAD policy and later PTE permissions. Watch `RWX` and `RW -> RX` transitions. |
| `MAP_PRIVATE` | copy-on-write mapped view such as `FILE_MAP_COPY`; image COW; private `VirtualAlloc` is related but not identical | A private file mapping initially shares file-backed pages, then becomes private on write. Windows image/mapped COW has similar forensic consequences. |
| `MAP_SHARED` | shared section view, `FILE_MAP_READ`, `FILE_MAP_WRITE`, `FILE_MAP_EXECUTE` | Shared executable or writable mappings between unrelated processes are high-value triage clues. |
| `MAP_ANONYMOUS` | `VirtualAlloc` private memory; paging-file-backed section for shared anonymous memory | Private anonymous executable memory is common in JITs and packers; context matters. |
| `MAP_FIXED` | `VirtualAlloc`/`VirtualAllocEx` at a chosen address; `MapViewOfFileEx` | Dangerous because it can collide with or replace expected layout. `MAP_FIXED_NOREPLACE` is safer for collision detection. |
| `MAP_FIXED_NOREPLACE` | no exact Win32 twin; address-specific allocation that fails on conflict is the rough idea | Useful when address placement must be atomic with respect to other threads. |
| `MAP_NORESERVE` | not equivalent to `MEM_RESERVE`; Windows separates reserve and commit explicitly | Linux can defer swap/commit reservation depending on overcommit policy. Windows commit charge is first-class. |
| `MAP_POPULATE` | `PrefetchVirtualMemory` or explicit touching/locking, not exact | Reduces later page-fault latency but can create memory pressure. |
| `MAP_LOCKED` | `VirtualLock` | Tries to keep pages resident; important for secrets, low-latency code, and memory-pressure side effects. |
| `MAP_HUGETLB` | `MEM_LARGE_PAGES`, `SEC_LARGE_PAGES`, `FILE_MAP_LARGE_PAGES` | Requires special setup/privilege and changes the page-walk leaf level. Large pages reduce TLB pressure but make protection, COW, and corruption impact coarser. |
| `MAP_GROWSDOWN`, `MAP_STACK` | Windows stack VADs and `PAGE_GUARD` behavior, not a direct mapping flag | Stacks are not just anonymous memory; guard growth and exception behavior matter. |
| `MAP_SYNC` with DAX | no everyday equivalent; compare persistent-memory mappings plus flush discipline | Relevant for crash consistency, not ordinary malware triage. |

Study rule: `mmap` conflates several decisions in one call: address choice, backing object, sharing/COW behavior, and protections. Windows splits those decisions across `VirtualAlloc`, `CreateFileMapping`, `MapViewOfFile`, `VirtualProtect`, section objects, and view access rights.

## `mprotect` Versus `VirtualProtect`

| Linux | Windows | Why it matters |
|---|---|---|
| `mprotect(addr, len, PROT_*)` changes protections in the calling process | `VirtualProtect` changes current-process page protections; `VirtualProtectEx` changes a target process with `PROCESS_VM_OPERATION` | Both mutate range policy and PTE permissions. |
| `PROT_NONE` | `PAGE_NOACCESS` | Guarding, sandboxing, red zones, and fault-based instrumentation. |
| `PROT_READ | PROT_WRITE` | `PAGE_READWRITE` | Writable data; also staging area before executable transition. |
| `PROT_READ | PROT_EXEC` | `PAGE_EXECUTE_READ` | Normal code mapping on W^X systems. |
| `PROT_READ | PROT_WRITE | PROT_EXEC` | `PAGE_EXECUTE_READWRITE` | High-signal for JITs, packers, exploit stagers, and loose memory policy. |
| `pkey_mprotect` | no common Win32 equivalent | Linux protection keys add per-thread hardware-assisted permission control where available. |
| stack-growth protection flags | `PAGE_GUARD` | Guard pages are a fault mechanism, not ordinary access rights. |
| no direct CFG flag in `mprotect` | `PAGE_TARGETS_INVALID`, `PAGE_TARGETS_NO_UPDATE`, `FILE_MAP_TARGETS_INVALID` | Windows Control Flow Guard adds valid-target metadata on top of executable permission. |

For reversing and defense, the high-value pattern is not simply "executable memory exists." Ask how it became executable: image load, JIT, unpacking, `mprotect`, `VirtualProtect`, mapped section, or modified image page.

## Defensive Triage: High-Signal Memory Flag Patterns

These patterns are not proof of malware. JIT engines, debuggers, EDRs, profilers, browsers, DRM/protectors, emulators, and language runtimes can produce similar artifacts. Treat them as prompts to ask who requested the mapping, what backs it, whether the process normally needs it, and what control flow reaches it.

Linux high-signal patterns:

| Pattern | Why it matters defensively |
|---|---|
| Anonymous private executable memory: `MAP_ANONYMOUS` plus `PROT_EXEC`, especially `PROT_WRITE | PROT_EXEC` | Common shape for JITs, unpackers, shellcode-like staging, and loose W^X policy. Context decides whether it is expected. |
| `RW -> RX` transition through `mprotect` | Common in JITs and packers: bytes are generated or unpacked writable, then made executable. Correlate writer, call stack, mapping name, and thread start. |
| Executable `memfd` or deleted-file-backed mapping | Can be legitimate for loaders/sandboxes, but it is also a common "fileless-looking" artifact. Inspect fd provenance, seals, executable permission, and loader metadata. |
| `MAP_PRIVATE` library page becomes private dirty/executable | Indicates COW divergence from the clean shared object: relocation, hot patching, hooks, unpacking, or self-modification. Compare bytes to the backing file. |
| `MAP_SHARED` plus executable or writable-executable use between unrelated processes | Shared code/data channels deserve review because modification can affect multiple participants. Identify the backing fd/object and permissions. |
| `MAP_FIXED` address placement | Can be normal in loaders/emulators, but it is high-risk because it can collide with or replace expected mappings. `MAP_FIXED_NOREPLACE` is safer when fixed placement is required. |
| `MADV_DONTDUMP`, `MADV_WIPEONFORK`, `mlock`, huge pages, or unusual dump/residency policy on executable/private regions | These can be legitimate secret/performance controls. In malware triage they are evidence to correlate with unpacked code, credential handling, or anti-forensics. |

Windows high-signal patterns:

| Pattern | Why it matters defensively |
|---|---|
| `VirtualAlloc`/`VirtualAllocEx` with `MEM_COMMIT` and executable protection, especially `PAGE_EXECUTE_READWRITE` | Common shape for JIT/protector/unpacker/injection staging. For remote cases, process-handle rights and target identity are the first facts. |
| `PAGE_READWRITE` followed by `VirtualProtect`/`VirtualProtectEx` to `PAGE_EXECUTE_READ` | Common W^X-friendly generation/unpacking flow. Correlate memory writes, protection change, thread/APC/callback entry, and VAD type. |
| Pagefile-backed section mapped executable through `CreateFileMapping`/`MapViewOfFile` or Native section APIs | Can be used for legitimate shared code/data, but executable shared sections across processes are high-value injection/loader triage artifacts. |
| Image VAD page becomes private or differs from clean file bytes | Indicates COW modification of a DLL/EXE page: hotpatching, hooks, inline detours, unpacking, or tampering. Compare to file hash/signature and expected patch sources. |
| Executable mapped view with `FILE_MAP_EXECUTE`, `PAGE_EXECUTE_WRITECOPY`, or `PAGE_EXECUTE_READWRITE` | Review maximum section protection, view access, backing file, signer, and whether executable write-copy is expected for that image/runtime. |
| `PAGE_GUARD`, `PAGE_NOACCESS`, or exception-heavy guard behavior around code | Used by debuggers, stack guards, sandboxing, packers, anti-debug logic, and fault-driven dispatch. Evidence comes from exception rate, handler addresses, and region type. |
| `MEM_LARGE_PAGES`, executable large pages, or unusual locked/resident executable memory | Usually rare in ordinary desktop apps and may require privilege. Treat as a performance/security exception that needs an owner and reason. |
| Remote combination: process handle with `PROCESS_VM_OPERATION`/`PROCESS_VM_WRITE`, memory allocation or section mapping, bytes written, protection changed, then thread/APC/context/callback execution | This is a behavioral chain, not one flag. Each step has legitimate tooling uses, but the chain is central to injection triage. |

The best detection question is not "which flag is bad?" It is: which object backs this memory, who had authority to create or change it, when did it become executable, is it shared or private now, does it match loader/module metadata, and what thread or callback actually executed from it?

## `madvise` Versus Windows Memory Hints

`madvise` is mostly a policy hint. Windows has several APIs that resemble individual advice values, but there is no single one-to-one `madvise` equivalent.

| Linux advice | Windows analogy | Focus |
|---|---|---|
| `MADV_NORMAL`, `MADV_RANDOM`, `MADV_SEQUENTIAL` | file-cache and read-ahead behavior is mostly through file/cache APIs and access patterns | Performance hinting, not authority. |
| `MADV_WILLNEED` | `PrefetchVirtualMemory` | Bring likely-future pages closer to RAM and reduce later fault latency. |
| `MADV_DONTNEED` | `DiscardVirtualMemory` for committed private pages; `MEM_RESET`/`MEM_RESET_UNDO` for reusable private memory | Contents after reuse are not a normal durability promise. Dirty COW-style bugs show why discard semantics matter. |
| `MADV_FREE` | `MEM_RESET` is a rough analogy | Caller says data can be thrown away lazily if memory pressure appears. |
| `MADV_COLD`, `MADV_PAGEOUT` | working-set trimming APIs such as `SetProcessWorkingSetSize`/`EmptyWorkingSet`, not exact | Reclaim pressure and residency, not mapping existence. |
| `MADV_HUGEPAGE`, `MADV_NOHUGEPAGE` | `MEM_LARGE_PAGES`/large-page policy, not transparent huge page advice | Linux THP is advisory per range; Windows large pages are explicit allocations/mappings. |
| `MADV_DONTFORK`, `MADV_DOFORK`, `MADV_WIPEONFORK`, `MADV_KEEPONFORK` | no normal Windows `fork` counterpart | Important for secrets and fork-heavy Unix programs. |
| `MADV_DONTDUMP`, `MADV_DODUMP` | minidump selection/callback policy, not a per-region public twin | Dump visibility and secret handling. |
| `MADV_MERGEABLE`, `MADV_UNMERGEABLE` | Windows memory combining has no common per-region app flag | Page deduplication can affect side channels, memory accounting, and forensic expectations. |

## Other Security-Relevant Linux Syscalls and Windows Cases

| Linux primitive | Flags/details to know | Windows case | Why it matters |
|---|---|---|---|
| `process_vm_readv` / `process_vm_writev` | `flags` must be `0`; permission is ptrace-style | `ReadProcessMemory` / `WriteProcessMemory` with `PROCESS_VM_*` rights | Best explicit Linux analogy to Windows cross-process copy APIs. |
| `ptrace` | attach/seize, per-thread tracee model, register/memory/syscall control, LSM/capability checks | Debug APIs, `DebugActiveProcess`, context APIs, process/thread handles | Debugger authority can become inspection or manipulation authority. |
| `/proc/<pid>/mem` | procfs file interface governed by ptrace-like access checks | no single file twin; use memory APIs/debugger/dump APIs | Linux exposes process state through filesystem-shaped objects; Windows does not. |
| `memfd_create` | `MFD_CLOEXEC`, `MFD_ALLOW_SEALING`, `MFD_HUGETLB`; fd can be mapped | paging-file-backed section object; unnamed section handle | Explains fileless-looking mappings, shared anonymous objects, sealing, and deleted/in-memory artifacts. |
| System V shared memory: `shmget`, `shmat`, `shmdt`, `shmctl` | Key/id-based legacy IPC object; attach maps it into a process; detach removes the mapping; control changes permissions/lifetime or marks for removal | named or unnamed section objects are the closest Windows family, but the naming/lifetime/security model differs | Relevant for Unix compatibility and old software. Security review asks who can find the key/id, mode/owner, IPC namespace, LSM policy, lifetime after creator exit, and whether stale segments expose data. |
| POSIX shared memory: `shm_open`, `shm_unlink` plus `ftruncate`/`mmap` | Name creates/opens a shm object, fd carries authority, `mmap` maps it, unlink removes the name while existing fds/mappings can live | named file mapping/section object is the closest Windows family | Cleaner fd/path-like model than SysV. Security review asks about name predictability, mode bits/ACLs, unlink timing, fd inheritance/passing, and initialization before sharing. |
| `mremap` | `MREMAP_MAYMOVE`, `MREMAP_FIXED`, `MREMAP_DONTUNMAP` | no exact counterpart; unmap/remap/copy or section-view remapping patterns | Moving mappings can invalidate stale address assumptions. |
| `mlock`, `mlock2` | `MLOCK_ONFAULT` locks pages when faulted | `VirtualLock` | Resident pages, secrets, DMA/I/O assumptions, and reclaim pressure. |
| `openat2` | `RESOLVE_BENEATH`, `RESOLVE_IN_ROOT`, `RESOLVE_NO_SYMLINKS`, `RESOLVE_NO_XDEV`, `RESOLVE_NO_MAGICLINKS` | robust `CreateFile` handling with reparse-point policy such as `FILE_FLAG_OPEN_REPARSE_POINT`, final-object validation, file IDs | Path traversal and symlink/reparse confusion are cross-platform vulnerability classes. |
| `prctl` | `PR_SET_DUMPABLE`, `PR_SET_NO_NEW_PRIVS` | process mitigation policy, token restrictions, job/AppContainer/WDAC policy; no exact twin | Affects future privilege transitions, dumpability, and cross-process inspectability. |
| `seccomp` | syscall filtering for the calling process or sandbox | Windows process mitigation policy, AppContainer, job limits, WDAC, EDR hooks; not exact | Reduces available kernel attack surface after startup. |

## Reading Order

1. First read VMA/VAD basics in [Linux vs Windows internals](<01-linux-vs-windows-internals.md>).
2. Then read this file's `mmap`/`VirtualAlloc` and `mprotect`/`VirtualProtect` tables.
3. Then study [Memory, filesystems, and network Q&A](<../02-question-banks/03-memory-filesystems-network-qa.md>) questions about memory structures, executable memory triage, and cross-process access.
4. Only after that, study injection, rootkits, packers, and anti-debugging papers. Otherwise the API names become memorized tricks instead of consequences of OS memory and authority models.

## Primary References

- Linux man-pages: [`mmap(2)`](https://man7.org/linux/man-pages/man2/mmap.2.html), [`mprotect(2)`](https://man7.org/linux/man-pages/man2/mprotect.2.html), [`madvise(2)`](https://man7.org/linux/man-pages/man2/madvise.2.html), [`process_vm_readv(2)`](https://man7.org/linux/man-pages/man2/process_vm_readv.2.html), [`ptrace(2)`](https://man7.org/linux/man-pages/man2/ptrace.2.html), [`memfd_create(2)`](https://man7.org/linux/man-pages/man2/memfd_create.2.html), [`shm_overview(7)`](https://man7.org/linux/man-pages/man7/shm_overview.7.html), [`shmop(2)`](https://man7.org/linux/man-pages/man2/shmop.2.html), [`shm_open(3)`](https://man7.org/linux/man-pages/man3/shm_open.3.html), [`mlock(2)`](https://man7.org/linux/man-pages/man2/mlock.2.html), [`mremap(2)`](https://man7.org/linux/man-pages/man2/mremap.2.html), [`openat2(2)`](https://man7.org/linux/man-pages/man2/openat2.2.html).
- Microsoft Learn: [Process security and access rights](https://learn.microsoft.com/en-us/windows/win32/procthread/process-security-and-access-rights), [`ReadProcessMemory`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-readprocessmemory), [`WriteProcessMemory`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-writeprocessmemory), [`VirtualAlloc`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc), [`VirtualAllocEx`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualallocex), [`VirtualProtectEx`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualprotectex), [`MapViewOfFile`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-mapviewoffile), [memory protection constants](https://learn.microsoft.com/en-us/windows/win32/memory/memory-protection-constants), [`DiscardVirtualMemory`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-discardvirtualmemory), [`PrefetchVirtualMemory`](https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-prefetchvirtualmemory).
