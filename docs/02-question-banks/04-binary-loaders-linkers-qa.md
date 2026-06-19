# ELF, PE, Loaders, Linkers, and Runtime Resolution Deep Questions, Scored

Value Score: 88/100
Role: Loader/linker Q&A owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-15

Purpose: fill the low-level binary-format and loader/linker depth gap for Linux-to-Windows transition, reverse engineering, exploit research, and defensive malware analysis. The focus is understanding mechanisms and attacker-relevant reasoning without becoming an operational playbook.

Use [C++ and modern C++ internals for security researchers](<06-cpp-modern-cpp-internals-security-qa.md>) beside this file when the binary is compiled C++ or when vtables, smart pointers, templates, exceptions, STL containers, atomics, intrinsics, or optimizer behavior explain the assembly.

Use [Windows kernel memory, sections, privileges, and ASLR](<../05-topic-notes/windows-kernel-memory-sections-privileges-and-aslr.md>) beside this file for the Windows-specific follow-ups around `kernel32` address reuse, PEB/TEB export walking, section-backed DLL sharing, pagefile-backed mappings, and KASLR.

Score meaning:

| Score range | Meaning |
|---|---|
| 95-100 | Core binary/loading model. Missing this breaks many other explanations. |
| 90-94 | High-value reversing, debugging, and malware-analysis depth. |
| 85-89 | Important attacker/defender reasoning depth. |
| 80-84 | Practical specialist detail. |

## Priority Index

| Score | Area | Question |
|---:|---|---|
| 100 | ELF | What parts of an ELF matter at runtime, and why are program headers more important than sections for loading? |
| 100 | PE | What parts of a PE matter at runtime, and how do DOS header, NT headers, optional header, data directories, and sections fit together? |
| 99 | Loaders | What happens when Linux executes a dynamically linked ELF versus when Windows starts a PE process? |
| 99 | Process lifetime | What actually invokes `main`, `WinMain`, and thread routines, and what runs during normal versus abnormal teardown? |
| 98 | Process launch APIs | How do `execve`, `posix_spawn`, `CreateProcessW`, `NtCreateUserProcess`, and `ShellExecuteEx` differ? |
| 98 | Dynamic linking | How do ELF symbol resolution, PLT/GOT, relocations, and lazy binding work conceptually? |
| 98 | PE imports | How do PE imports, IAT, delay-load imports, bound imports, and forwarded exports work conceptually? |
| 97 | Exports/symbols | How do ELF dynamic symbols compare with PE export tables and ordinal/name lookup? |
| 97 | Relocations/ASLR | How do ELF relocations/PIE and PE base relocations/ASLR differ, and why do attackers and packers care? |
| 96 | TLS/pre-entry | What code can run before `main` or the nominal entry point on Linux and Windows? |
| 96 | Search order | How do Linux shared-object search rules compare with Windows DLL search rules and KnownDLL/API-set behavior? |
| 95 | Runtime loading | How do `dlopen`/`dlsym` compare with `LoadLibrary`/`GetProcAddress`/`LdrLoadDll`/`LdrGetProcedureAddress`? |
| 94 | API hiding | What patterns indicate runtime API resolution, API hashing, or manual export parsing? |
| 94 | Manual loading | What is manual mapping or reflective loading at a conceptual level, and how do defenders recognize it? |
| 93 | Packers | What binary-format clues indicate packing, unpacking, or staged code loading? |
| 93 | Sections/permissions | Why are segment/section permissions, W^X, RELRO, DEP/NX, CFG, CET, and code signing relevant? |
| 92 | Loader metadata | How do Linux `link_map`/`r_debug` and Windows PEB loader lists help or mislead analysts? |
| 92 | vDSO/ntdll | How do Linux vDSO/vvar and Windows `ntdll` syscall stubs differ? |
| 91 | ABI/calling | Which ABI and calling-convention details matter for reversing and exploitability? |
| 91 | Exception/unwind | How do DWARF/unwind metadata and Windows x64 unwind/function tables matter for analysis? |
| 90 | Symbol/debug info | How do DWARF/build IDs/split debug files compare with PDB/CodeView/public symbols? |
| 90 | Static vs dynamic | What changes when a binary is static, PIE, stripped, statically linked CRT, or packed? |
| 89 | File-memory mismatch | How do you reason about mismatches between on-disk binary and in-memory image? |
| 89 | Loader lock/init | Why are loader locks and initialization callbacks dangerous for both bugs and analysis? |
| 89 | Code-cache coherency | Do instruction/data caches create a shellcode detection or bypass model? |
| 88 | Syscall/API boundary | How do direct syscalls and Native API use change analysis without making Win32 irrelevant? |
| 88 | Interposition/hooks | How do ELF interposition and Windows IAT/EAT/inline hooks differ? |
| 87 | Cross-arch | What low-level differences matter for x86, x64, WOW64, and arm64 binaries? |
| 87 | Resources/manifests | How do PE resources, manifests, SxS, and version/signature metadata affect behavior and trust? |
| 86 | Integrity | How do Authenticode/catalog signing and Linux package/signature trust differ from loader mechanics? |
| 86 | Forensics | What binary-format artifacts matter in memory dumps and incident response? |
| 85 | Attacker relevance | Which loader/binary-format mechanisms are most relevant to attacker tradecraft, and how should defenders discuss them safely? |

## Best Answers

### 100 - ELF: Runtime-Relevant Structure

At runtime, the ELF loader mostly cares about the ELF header and program headers, especially `PT_LOAD` segments. Program headers describe what ranges of the file should be mapped into memory, at what virtual addresses, with what permissions, and with what alignment. The dynamic segment, interpreter segment, TLS segment, GNU stack/RELRO notes, and relocation/symbol information also matter for dynamically linked programs.

Sections are primarily link-time and analysis metadata: `.text`, `.data`, `.bss`, `.dynsym`, `.rela.*`, `.got`, `.plt`, and so on. They are useful to humans and tools, but the kernel and dynamic linker load by segments. A stripped ELF can remove section headers while remaining loadable. The key low-level lesson is: segments explain runtime memory layout; sections explain build/link organization.

### 100 - PE: Runtime-Relevant Structure

A PE begins with a DOS header/stub that points to NT headers. The NT headers contain the PE signature, file header, optional header, data directories, and section table. Despite the name, the optional header is required for executable images and contains critical loader information: image base, entry point RVA, section/file alignment, subsystem, DLL characteristics, stack/heap sizes, and data directory RVAs.

Data directories point to runtime structures such as imports, exports, base relocations, TLS, resources, exception/unwind data, load config, security/certificate data, and delay-load imports. Sections describe how file ranges map into memory with names, RVAs, raw data offsets, sizes, and characteristics. For Windows analysis, you must connect section layout, data directories, and the memory image the loader creates.

### 99 - Loaders: Linux ELF Start Versus Windows PE Start

For a dynamically linked ELF, `execve` validates the file, maps loadable segments, sees the interpreter path such as `ld-linux`, prepares the initial stack with argv/envp/auxv, maps vDSO/vvar, and transfers control to the interpreter. The dynamic linker maps dependencies, applies relocations, resolves symbols as needed, runs TLS/constructors, and eventually reaches the program's runtime entry path.

For a Windows PE process, process creation opens the image, creates an image section, maps it into a new process, creates process parameters and PEB/TEB state, creates the initial thread, then user-mode loader code in `ntdll` initializes DLL dependencies, resolves imports, handles API sets, runs TLS callbacks and `DllMain`, and reaches the executable's entry point/CRT. Linux puts more visible emphasis on ELF interpreter/dynamic linker; Windows puts more emphasis on PE image sections, PEB loader state, and `ntdll` loader machinery.

### 99 - Process Startup And Destruction

`main` is not a kernel entry point on either platform. It is a language/runtime convention reached after the image, loader, and runtime have done significant work.

On a typical dynamically linked Linux/glibc process, `execve` replaces the current image, the kernel maps the ELF `PT_LOAD` segments, prepares the initial stack with `argc`, `argv`, `envp`, and auxiliary vector entries, maps the ELF interpreter named by `PT_INTERP`, and transfers control to the dynamic linker. The dynamic linker maps dependencies, applies relocations, initializes TLS, handles IFUNC and symbol-resolution work, and runs loader initialization. The executable's `_start` code from the C runtime startup objects calls `__libc_start_main`, which performs libc/runtime initialization, runs pre-main constructors such as `.preinit_array` and `.init_array`, and then invokes `main`.

Normal Linux process exit usually flows from `main` returning into `exit`, which runs `atexit` handlers, C++ static destructors, libc cleanup, and finalizer paths such as `.fini_array` before reaching `_exit`/`exit_group`. Direct `_exit`, fatal signals, `execve`, or forced termination skip much of that user-mode cleanup. Thread exit has its own TLS destructor and pthread cleanup behavior, so process teardown and thread teardown are related but not identical.

On Windows, the kernel creates a process object, address space, image section mapping, PEB, initial TEB, and initial thread. User-mode startup then runs through `ntdll` loader machinery: dependencies are mapped, imports are resolved, API-set redirection is applied, relocations are handled, TLS callbacks run, and DLL `DllMain` routines receive process attach notifications. The PE address-of-entry-point is commonly a CRT startup routine such as `mainCRTStartup`, `wmainCRTStartup`, or `WinMainCRTStartup`, not the application `main` itself. That CRT startup initializes runtime state, security-cookie support, process arguments/environment, static initializers, and finally calls `main`, `wmain`, or `WinMain`. `wmain` is the Microsoft wide-character variant of `main`; it receives `wchar_t` arguments after CRT parsing of Windows' Unicode command line. `_tmain` is only a source-level compatibility macro that selects narrow or wide at build time.

Windows thread routines are also reached through runtime wrappers. A debugger commonly shows frames such as `ntdll!RtlUserThreadStart` and `kernel32!BaseThreadInitThunk` around the user thread procedure, although exact details vary by Windows build and symbol view. Normal process exit through the CRT and `ExitProcess` runs user-mode cleanup such as `atexit` handlers, C++ destructors, FLS/TLS cleanup, and DLL process-detach notifications. `TerminateProcess` is much harsher and can bypass orderly user-mode cleanup.

Security implication: pre-entry and post-main code are execution surfaces. Constructors, TLS callbacks, IFUNC resolvers, delay-load helpers, loader notifications, `DllMain`, `atexit` handlers, destructors, FLS/TLS callbacks, and exception/unwind paths can all execute outside the analyst's naive `main`-only model.

### 98 - Process Launch APIs

`execve` is Linux's image-replacement primitive. It does not create a new PID; it transforms the current process image, rebuilds mappings and the initial stack, applies executable/interpreter loading, handles credential transitions, and enters the new runtime/loader path. In the common shell pattern, a child exists first because `fork` or a related primitive created it, then the child calls `execve`.

`posix_spawn` is a higher-level POSIX API for "create a new process running this program with these attributes and file actions." Implementations can use optimized `vfork`, `clone`, or fork-like internals plus exec-like behavior. It is therefore closer to a launch API contract than to a raw syscall equivalent of `execve`.

Windows `CreateProcessW` is the common Win32 launch API: it creates a new process object, address space, image section mapping, process parameters, and initial thread around an executable image. `NtCreateUserProcess` is lower-level Native API machinery below normal Win32 creation and should not be treated as the stable application contract. `ShellExecuteEx` is higher-level than `CreateProcessW`: shell verbs, file associations, App Paths, elevation prompts, URL handlers, and shell policy can participate.

Security implication: pick the correct layer. On Linux, `execve` is where setuid/file capabilities, `no_new_privs`, `FD_CLOEXEC`, dumpability, namespaces, seccomp/LSM effects, and loader policy matter. On Windows, process launch analysis must include token choice, handle inheritance, mitigation policy, parent-process attributes, AppContainer/integrity/PPL context, shell mediation where used, and ETW process/thread/image-load events.

### 98 - ELF Dynamic Linking: Symbols, PLT/GOT, Relocations

ELF dynamic linking relies on dynamic symbols, relocation records, and loader-managed writable tables. The GOT holds addresses used by generated code and data references. The PLT provides stubs for external function calls. With lazy binding, an initial PLT call jumps through resolver machinery so the dynamic linker can locate the symbol and patch the GOT entry; later calls go directly to the resolved address.

Relocations tell the dynamic linker what memory locations must be adjusted based on load address or symbol values. PIE and shared libraries need relocations because their final address is not known at link time. RELRO hardens this by making some relocation-resolved tables read-only after relocation. Attackers care because GOT/PLT state historically offered overwrite targets; defenders care because RELRO, W^X, and symbol-resolution telemetry explain what is mutable and when.

### 98 - PE Imports: IAT, Delay-Load, Bound Imports, Forwarders

PE imports describe DLL dependencies and imported functions. The loader maps dependent DLLs, resolves imported functions by name or ordinal, and writes final addresses into the Import Address Table. The program calls through IAT slots rather than resolving the symbol every time. Delay-load imports defer this process until the function is first used through compiler/runtime helper code.

Bound imports are an optimization where imported addresses were precomputed for a specific DLL timestamp/base, but ASLR and updates often reduce their practical value. Forwarded exports let one DLL export a function that actually resolves to another DLL/function, which is common in Windows API layering. Analysts must inspect IAT, delay-load tables, and forwarders because static import lists can understate what the program eventually calls.

### 97 - Exports And Symbols

ELF dynamic symbols live in dynamic symbol tables with names, bindings, visibility, versions, and relocation interactions. ELF symbol resolution can be affected by global/local scope, interposition, `LD_PRELOAD`, symbol versioning, and lookup order. This makes ELF symbol behavior flexible but sometimes surprising.

PE exports are listed in an export directory with function RVAs, names, ordinals, and possible forwarder strings. Windows callers can import by name or ordinal, and `GetProcAddress` can resolve either. PE exports are usually a more explicit API surface, while ELF symbol tables often participate in broader process-wide symbol resolution rules.

### 97 - Relocations And ASLR

ELF PIE executables and shared objects are designed to load at variable addresses, so dynamic relocations adjust addresses and symbol references at load time. Non-PIE executables historically had fixed load addresses, though distro hardening commonly favors PIE. REL/RELA relocation forms differ in where the addend lives.

PE images have a preferred image base and a base relocation table. If the image cannot load at its preferred base, the loader applies base relocations. ASLR depends on relocation information and image flags. Packers and custom loaders care because relocation correctness determines whether an unpacked or manually loaded image works at a nonpreferred address. Defenders care when relocation tables are missing, malformed, or inconsistent with claimed ASLR behavior.

Attackers do exploit predictable module bases, but the precise cause matters. The classic cases are non-PIE ELF main executables, old or misbuilt PE images without ASLR, modules without usable relocation metadata, or leaked module bases that turn known offsets into absolute targets for ROP, return-to-libc, IAT/GOT targeting, vtable targeting, or data-only writes. "Shared library" does not automatically mean "fixed address": modern ELF shared objects are normally position-independent `ET_DYN` objects, and modern PE DLLs normally carry relocation data and ASLR flags.

Windows has an extra nuance: many system DLLs are section-backed and may appear at the same chosen base across many processes for a boot/session, especially for common KnownDLL-style images, because sharing image sections is valuable. That is not the same as "the DLL is non-relocatable." A single reliable base leak can sometimes make another process's copy of the same module easier to reason about, but conflicts, bitness, process mitigation policy, high-entropy VA, rebasing, updates, and section lifetime mean analysts should verify the actual mapped base instead of assuming a universal address.

`kernel32.dll` is the classic Windows example. In ordinary Win32 processes it is usually loaded early and exposed through KnownDLL/API-set loader policy, so old shellcode and ROP material often used it as an anchor for `LoadLibrary*`, `GetProcAddress`, process/thread APIs, and simple payload startup. On modern Windows, do not treat `kernel32.dll` as a hard-coded address: it is ASLR-enabled and relocatable. Attackers commonly walk the PEB loader lists, leak a module pointer, or resolve through exports/forwarders instead. Also, many `kernel32` exports are forwarders or thunks into `KernelBase` and lower layers such as `ntdll`, so the real implementation address may not live in `kernel32` even when the import name does.

Do not say "DLL code can only be shared if every process maps the DLL at the same virtual address." Physical sharing is about clean file/image-backed pages resolving to the same physical frames; different processes can map the same PFN at different VAs. What destroys sharing is private modification. If relocations, import fixups, writable globals, hooks, hotpatches, or text relocations modify a page for one process, that page becomes private or dirty and no longer represents the clean shared image page for everyone. Modern ELF shared objects are normally PIC/RIP-relative for the same reason: executable text can stay clean and shareable while GOT/data/TLS state remains private per process.

Windows ASLR versus Linux ASLR should be phrased as a tradeoff, not a slogan. Windows often has cross-process reuse of common system DLL bases during a boot, which can make local module-base leaks more reusable. Linux PIE/shared-object layouts are commonly randomized per exec, but `fork` inherits a layout, non-PIE executables can still be fixed, and information leaks defeat both systems. Compare the exact binary flags, architecture, fork/exec model, loader policy, and available disclosures before claiming one OS is categorically weaker.

Linux's common fixed anchor is different: a non-PIE `ET_EXEC` main executable has fixed text/data addresses even when libc, the heap, the stack, vDSO, and other libraries move. Shared libraries are usually PIC and ASLR-friendly. Android's Zygote/ART model creates another special case: mappings inherited from a pre-fork template can share layout relationships, so leaking one pointer into a preloaded runtime region can reveal many related offsets.

### 96 - TLS And Pre-Entry Code

On Linux, code can run before `main` through the dynamic linker, relocation processing, TLS setup, `.preinit_array`, `.init_array`, constructors, and language runtime initialization. The first instruction you think of as "program start" is often not where meaningful behavior begins.

On Windows, TLS callbacks can run before the executable entry point, and DLL `DllMain` routines run during process/thread attach events. CRT initialization also happens before user `main`/`WinMain`. Malware and protectors often use pre-entry execution because analysts who break only on the nominal entry point may miss early anti-debugging, unpacking, environment checks, or dynamic resolution.

Linux TLS is real thread-local storage, but the mechanism differs from Windows. ELF modules can contain TLS data described by `PT_TLS`; the dynamic linker allocates and initializes per-thread TLS blocks and tracks dynamic TLS for loaded shared objects. The thread pointer reaches a Thread Control Block and TLS data: for example, x86-64 Linux commonly uses FS base, while AArch64 uses TPIDR_EL0. User code reaches this through `__thread`, C/C++ `thread_local`, libc state such as `errno`, and pthread keys/destructors.

Windows uses the TEB plus PE/Win32 mechanisms: PE TLS directory data, TLS callbacks, `TlsAlloc` slots, FLS, CRT per-thread state, stack bounds, and last-error state. On x64 Windows, the TEB is commonly reached through GS-based addressing; on 32-bit x86 Windows, FS-based TEB access is common. A reverser must identify the OS/ABI before interpreting `fs:` or `gs:` memory operands.

The security difference is mostly about where hidden work and sensitive per-thread state live. Windows has explicit TLS callbacks that are a classic pre-entry malware and packer surface. Linux usually hides pre-main behavior in dynamic linker work, constructors, IFUNC resolvers, preload/audit libraries, and C++ `thread_local` dynamic initialization rather than PE-style TLS callbacks. On both OSes, thread-local data can hold sensitive runtime state and is not a confidentiality boundary against same-process code, dumps, or cross-process memory access.

### 96 - Search Order And Loader Policy

Linux shared-object search can involve `DT_RPATH`, `DT_RUNPATH`, `LD_LIBRARY_PATH`, `/etc/ld.so.cache`, default library directories, secure-execution restrictions, and preload mechanisms such as `LD_PRELOAD` or `/etc/ld.so.preload`. Search behavior changes for privileged/setuid-like contexts because trusting environment variables would be unsafe.

Windows DLL search depends on explicit paths, application directory, system directories, KnownDLLs, SafeDllSearchMode, manifests, side-by-side assemblies, API sets, packaged-app policy, current directory rules, and `LoadLibraryEx` flags. DLL side-loading and Linux library hijacking are the same risk class but not the same mechanism. A strong analyst explains the exact loader policy that made the load possible.

### 95 - Runtime Loading APIs

`dlopen` loads a shared object into the current process according to ELF dynamic linker rules, and `dlsym` resolves a symbol according to handle/scope/versioning behavior. `dlclose` decrements a reference but does not guarantee immediate practical disappearance if other references or runtime state remain.

Windows `LoadLibrary`/`LoadLibraryEx` load DLLs through the Windows loader, while `GetProcAddress` resolves exports by name or ordinal. Lower-level `LdrLoadDll` and `LdrGetProcedureAddress` expose loader internals through `ntdll`. They are concept peers to `dlopen`/`dlsym`, but the PE export model, API sets, loader lock, DLL search policy, and `DllMain` behavior make them meaningfully different.

### 94 - API Hiding And Runtime Resolution

Runtime API resolution can be benign: plugins, optional compatibility, version checks, and delay-loaded features all use it. It becomes suspicious when static imports are tiny but the binary walks the PEB, parses ELF or PE export tables manually, hashes API names, decrypts strings just before resolution, or resolves memory/thread/process APIs immediately before suspicious behavior.

On Linux, look for `dlopen`, `dlsym`, direct ELF header walking, `/proc/self/maps` parsing, or direct syscall wrappers. On Windows, look for PEB loader-list walking, `LoadLibrary`/`GetProcAddress`, `Ldr*` calls, manual PE export parsing, API hashing, and dynamic `Nt*` resolution. The defender's job is to recover the actual resolved call graph and correlate it with behavior.

### 94 - Manual Mapping And Reflective Loading

Manual mapping conceptually means recreating enough loader work without using the normal loader path: mapping image bytes, applying relocations, resolving imports, setting protections, handling TLS, and transferring control. Reflective loading is a family of self-contained loader approaches where code maps itself or another image from memory.

This can be used by malware, packers, and some legitimate protectors. Defenders recognize it by absence from normal loader metadata, executable private memory, PE/ELF-like headers in anonymous memory, reloc/import-resolution behavior, thread starts outside known modules, image-load telemetry gaps, and VAD/map entries inconsistent with loaded-module lists. Understanding the concept is useful; implementing a stealth loader is not needed for defensive mastery.

### 93 - Packers And Staged Loading

Packing often changes the relationship between disk and runtime. On disk, imports may be minimal, sections may have unusual entropy, names, permissions, or sizes, and the entry point may land in a small unpacking stub. At runtime, memory protections may change, new executable memory may appear, imports may be resolved dynamically, and the original code may be decompressed or decrypted.

Good analysis tracks transitions: file metadata, entry point, early API use, memory allocations, protection changes, writes into executable regions, new threads, module loads, and post-unpack code. Not every high-entropy section is malicious, and not every packer is malware, but packing is a reason to shift from static-only analysis to runtime state reconstruction.

### 93 - Permissions And Mitigations

ELF segment permissions and PE section characteristics help the loader assign page protections, but final memory protections can differ after relocation, loader hardening, or runtime changes. W^X and DEP/NX aim to prevent memory from being both writable and executable. RELRO makes relocation-resolved ELF tables read-only. Windows CFG/CET/load-config metadata constrains indirect control flow and records mitigation state.

Attackers care because these features shape useful primitives: writable GOT/IAT slots, executable heaps, return-oriented control, or data-only attacks. Defenders care because mitigation metadata and runtime protections help distinguish normal images from suspicious memory. Code signing adds trust policy but does not replace memory-permission analysis.

### 92 - Loader Metadata

Linux dynamic loader metadata includes `link_map`, `r_debug`, program headers, and `/proc/<pid>/maps`. Debuggers use this to track shared libraries and break on load/unload events. But malicious or custom-loaded code may not appear in normal link maps, while memory maps still reveal executable regions.

Windows PEB loader lists and APIs such as PSAPI/Toolhelp expose loaded modules. WinDbg `lm` and ETW image-load events provide more views. Manual mapping or unlinking can hide from friendly enumerators, so analysts compare PEB loader lists, VADs, ETW image-load events, thread starts, file objects, and memory signatures. Loader metadata is evidence, not ground truth.

### 92 - vDSO And `ntdll`

Linux vDSO/vvar mappings provide kernel-supplied user-mode code/data for selected operations, often time-related, avoiding syscall overhead. They are mapped into processes and appear in memory maps, but they are not ordinary shared libraries loaded from disk in the same way as libc.

Windows `ntdll` contains user-mode Native API routines and syscall stubs. Most Win32 APIs eventually call into `ntdll` for kernel transitions, but `ntdll` also contains loader and runtime support. Directly comparing vDSO to `ntdll` is wrong: vDSO is a fast-path helper mapping; `ntdll` is a central user-mode system DLL and Native API boundary.

### 91 - ABI And Calling Convention

Calling conventions determine where arguments go, who preserves registers, stack alignment, return values, structure returns, and variadic behavior. On Linux x86-64, the System V ABI differs from Windows x64 calling convention: register choices, shadow space, red zone, and unwind expectations differ. Syscall ABIs differ from function-call ABIs.

For reversing, bad calling-convention assumptions produce wrong prototypes and wrong stack/register interpretation. For exploitation and crash analysis, ABI details affect ROP chains, stack pivots, exception unwinding, syscall invocation, shellcode portability, and cross-architecture thunking. A strong analyst identifies architecture, mode, compiler/runtime, and syscall versus normal-call convention.

### 91 - Exception And Unwind Metadata

ELF binaries may carry DWARF unwind/debug information, frame pointers, or `.eh_frame` data used by debuggers and exception runtimes. Stripped binaries may still keep unwind metadata needed by language runtimes or stack unwinding. Missing or malformed unwind data can confuse analysis.

Windows x64 relies heavily on structured unwind metadata in `.pdata`/`.xdata` for exception handling and stack unwinding. Dynamically generated code can register function tables. Malware and protectors can abuse exception dispatch and dynamic unwind registration to hide control flow. Analysts should understand that exception metadata is not only debugging information; it can affect actual runtime control flow.

### 90 - Debug Symbols

Linux commonly uses DWARF, build IDs, split debug files, distro debug packages, and symbol tables when available. Stripped binaries remove many names, but build IDs can connect a binary to external symbols. Kernel/user debugging often depends on matching exact build artifacts.

Windows uses PDBs referenced through CodeView records, with public symbols often available from Microsoft symbol servers and private symbols held by vendors. PDBs can expose function names, types, and source mappings depending on availability. For Windows internals, symbols are essential because private structure layouts vary by build and source is not generally public.

### 90 - Static, PIE, Stripped, CRT, Packed

A static binary embeds libraries and reduces runtime dependency resolution, but it can be larger and still rely on syscalls and runtime initialization. PIE makes the main executable position-independent and ASLR-friendly. Stripping removes symbol/section information useful to analysts but not necessarily needed for execution.

On Windows, statically linked CRT code changes what library calls are visible as imports; packed binaries may show only a stub and dynamic resolution. These properties change analysis strategy. Static or stripped does not mean simple, and dynamic does not mean suspicious. The key is knowing what metadata is absent and which runtime behaviors must therefore be recovered dynamically.

### 89 - File-Memory Mismatch

Loaded code in memory does not always match bytes on disk. Relocations, import/IAT patching, COW modifications, hotpatching, JIT code, unpacking, self-modification, and deleted/replaced files all create differences. Linux can show deleted mapped files; Windows can show image-backed regions with private modified pages or section objects whose file state changed.

Forensics compares hashes, mapped ranges, page protections, private dirty pages, loader metadata, thread starts, and file object/backing path. A mismatch is not automatically malicious, but it is high-value evidence. The question is whether the mismatch is expected loader/runtime behavior or unexplained executable mutation.

### 89 - Code Caches, Instruction Caches, And Flushes

Be precise about the cache claim. On split I-cache/D-cache Arm systems, the effect people sometimes describe as "the I-cache and D-cache disagree" is real: shellcode, a JIT stub, a hook, or an unpacked block can be written through the data side while the instruction side still fetches an old instruction stream. The result can be stale-code execution, an illegal instruction, or failure to execute freshly written bytes until the correct cache-maintenance and barrier sequence runs.

That is not the same as a normal OS mitigation that compares instruction-cache contents with data-cache contents before execution and rejects a mismatch. The CPU executes bytes fetched through the instruction side of the memory hierarchy according to page permissions and control-flow rules; the OS and hardware do not generally maintain a second trusted copy in the data cache and compare it against each about-to-execute instruction.

The real defensive questions are different:

- does the virtual page have execute permission at all: NX/DEP and W^X
- did executable code come from a normal image mapping or from private/JIT memory
- did an image-backed code page become private dirty or diverge from the clean backing file
- do loader metadata, memory maps/VADs, ETW or `/proc` views, and thread start addresses agree
- do control-flow mitigations permit the indirect call, jump, or return target

Cache coherency still matters for generated or modified code. On x86/x64, instruction and data caches are coherent enough that most user-mode self-modifying-code cases do not require the same explicit maintenance sequence as some other architectures, though serialization and API contracts still matter. On Arm and other architectures with less transparent I-cache/D-cache behavior, JITs and runtimes must explicitly clean the data side, invalidate the instruction side, and execute barriers before executing newly written code. Windows exposes this contract through `FlushInstructionCache`; portable compilers expose helpers such as `__builtin___clear_cache`.

Raspberry Pi is a useful example, but do not over-attribute it to ARMv7 versus ARMv8. Raspberry Pi 3 uses Cortex-A53 and Raspberry Pi 4 uses Cortex-A72; both cores implement ARMv8-A. A 32-bit Linux userland may report an ARMv7-style ABI on either board, but the cache-maintenance difference is better explained by the core, execution state, kernel interface, and whether the payload or runtime performed the required clear-cache sequence.

Security relevance: cache flushes are a correctness and coherency issue that can accidentally harden a target against naive shellcode, especially on Arm. Discuss "cache flush bypass" narrowly as architecture-specific stale-code or coherency behavior, not as a universal bypass of NX, CFG, CET/shadow stack, RELRO, ACG, CIG, or code signing.

### 89 - Loader Lock And Initialization

Loaders must serialize parts of module loading and initialization. Windows has a loader lock, and `DllMain` runs under severe restrictions because calling loader-affecting APIs or taking conflicting locks can deadlock. Linux dynamic linker initialization also has ordering constraints around constructors, TLS, and symbol resolution.

For analysis, initialization callbacks can run before the expected entry point and can perform anti-debugging, unpacking, or environment checks. For bugs, loader-time code runs in a fragile state where dependencies, locks, and thread creation rules are constrained. A strong reverser breaks on loader events and TLS/constructor paths, not only on `main`.

### 88 - Syscall And API Boundary

Linux syscalls are a stable per-architecture ABI, so direct syscall use is normal in low-level code. libc wrappers may still add behavior, but the syscall boundary is a meaningful primary layer. vDSO can avoid syscalls for selected fast paths.

Windows direct syscall use is different because Win32 is the documented compatibility contract and syscall numbers are build-specific. Malware may use direct syscalls to avoid user-mode API hooks, but Native API and Win32 semantics still matter. Analysts should identify what semantic operation occurred, not overfocus on whether the call used `kernel32`, `ntdll`, or an inline syscall stub.

### 88 - Interposition And Hooks

ELF interposition is a normal design feature. `LD_PRELOAD`, symbol scope, PLT/GOT mechanics, audit libraries, and linker wrapping can redirect calls without patching code in the same way. This is used by profilers, tests, compatibility shims, and sometimes malware.

Windows hooking more often appears as IAT patching, EAT patching, inline trampolines, VEH/SEH tricks, COM/proxy registration, or DLL side-loading. Hooking is not inherently malicious; security tools hook too. The analysis question is ownership, integrity, target process, hook location, expected product behavior, and whether independent telemetry agrees.

### 87 - Cross-Architecture Details

x86, x64, WOW64, and arm64 change instruction encoding, calling conventions, syscall mechanisms, exception behavior, pointer size, structure layout, and mitigation features. WOW64 adds thunking between 32-bit user mode and 64-bit kernel transitions, with separate 32-bit and 64-bit module views.

arm64 adds PAC, BTI, MTE, different exception levels, and different page-size possibilities. x64 Windows uses unwind metadata differently from x86 SEH. A low-level analyst must always establish architecture and mode before trusting disassembly, stack traces, or exploitability assumptions.

### 87 - PE Resources, Manifests, SxS, Metadata

PE resources can contain icons, dialogs, version info, manifests, embedded payloads, configuration, or encrypted blobs. Manifests affect requested privileges, side-by-side assembly binding, DPI/UI behavior, and compatibility. Version metadata and signatures affect trust and triage but can be forged or misleading unless verified.

Side-by-side policy can redirect DLL loading in ways that are invisible from a simple import table. Attackers may hide configuration in resources or abuse manifests/search policy; defenders inspect resources, manifests, version info, signatures, and actual loaded module paths.

### 86 - Integrity And Signing

Linux loader mechanics are usually separate from distribution trust. ELF files are commonly trusted through package signatures, repository metadata, IMA/EVM, filesystem policy, or distro mechanisms rather than an Authenticode-like signature embedded in every ELF. Some systems add measured/verified boot or file appraisal policy.

Windows has Authenticode signatures, catalog signing, WDAC policy, SmartScreen reputation, and kernel driver signing. The PE certificate table is not mapped as part of the image in the same way as code sections. A valid signature means identity/integrity under a trust policy, not benign behavior. BYOVD cases show why signed code can still be dangerous.

### 86 - Forensics

Binary-format artifacts in memory dumps include mapped image headers, section permissions, import tables, export tables, relocation state, PEB loader lists, ELF link maps, deleted backing files, private dirty pages, and executable anonymous memory. Analysts compare the process's loader view with raw memory.

Incident response cares about persistence and provenance: path, signer/package, timestamp metadata, load time, parent process, command line, environment, module list, memory protections, and whether disk bytes match memory bytes. Low-level binary knowledge lets you distinguish normal loader mutations from suspicious in-memory images.

### 85 - Attacker Relevance And Safe Defender Framing

The most attacker-relevant mechanisms are search-order abuse, pre-entry execution, runtime API resolution, import/export manipulation, writable function-pointer tables, relocation/ASLR behavior, manual mapping, packing/unpacking, direct syscall use, and metadata tampering. These matter because they affect stealth, execution timing, control-flow redirection, and static-analysis visibility.

The safe defender framing is: understand the mechanism, know the normal legitimate uses, recognize suspicious deviations, and correlate views. Avoid reducing the topic to recipes. For each mechanism ask: what metadata should exist, what loader event should occur, what memory protection should be present, what API resolution should be visible, and what telemetry would prove or disprove normal behavior?

## Remaining Gaps After This File

| Gap | Why it remains |
|---|---|
| Deep compiler implementation and code-generation internals for GCC/Clang/MSVC/link.exe/lld | The C++ internals bank now covers security-relevant C++ codegen, atomics, ABI, and optimization effects. Full compiler-internals implementation remains a separate toolchain-specialist track. |
| Full exploit-development treatment of GOT/IAT overwrites, ROP, shellcode, and loader abuse | Intentionally omitted as operational detail. The file covers concepts and defensive analysis. |
| Format-specific edge cases such as TLS model variants, COMDAT, SEH SafeSEH, CHPE/ARM64EC, and obscure relocation types | Worth separate notes if targeting advanced binary reversing roles. |
| Hands-on labs with `readelf`, `objdump`, `dumpbin`, PE-Bear, CFF Explorer, WinDbg, and GDB | Should be a separate lab companion file. |
