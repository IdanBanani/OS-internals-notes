# Windows Case-Study Resource Map

Value Score: 68/100
Role: Windows case-study resources
Proof Level: Resource-map

Date: 2026-05-13

Scope: focused resource map for PE structure, PEB/TEB/TLS/SSN, DLL loading/debugging, and Windows APIs commonly seen in keylogging, process injection, DLL hooking, and DLL side-loading analysis. Use this as a long-term case-study map for study, reversing, interview preparation, and defensive analysis, not for building malware.

For the larger Hebrew/local PDF set, use [Local Hebrew and Digital Whisper Paper Reading Map](<05-local-hebrew-paper-reading-map.md>). That file places each paper into the study order and says what to extract from it.

For the newly added Digital Whisper issues 134-185 PDFs, use [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>). It is cross-platform and covers newer Windows identity, loader, syscall, driver, EDR, Linux, firmware, and reversing papers.

For mechanism explanations derived from the local Pluralsight subtitles and PDFs/books, keep [Source-enriched Windows mechanisms](<06-source-enriched-windows-mechanisms.md>) open beside this file. It explains the terms behind the checklist: Executive versus lower-kernel responsibilities, Object Manager, handles, PEB/TEB, loader state, VADs, sections, working sets, scheduler state, dispatcher objects, `CreateEvent`/event waits, thread pools/WorkerFactory, IRQL, DPC/APC, jobs/silos, drivers, IOCTLs, and telemetry views.

For the local Journey PDFs, use [Journey PDF source map](<../05-topic-notes/journey-pdf-source-map.md>). The Windows Concept Journey is useful before PE/PEB/loader questions, the Windows Security Journey before access-check and token questions, and the Windows Forensic Journey before artifact and telemetry triage.

For defensive technique framing, use [Attacker-relevant structures and components](<../05-topic-notes/attacker-relevant-structures-and-components.md>). It directly answers how attackers misuse handles, VADs, PEB/TEB metadata, section objects, at-rest PE content, image-backed/private memory, process injection variants, reflective/manual mapping, cross-process memory writes, shellcode/generated code, hooks/detours/pointer tables, kernel dispatch/callback paths, tokens, persistence configuration, spyware collection surfaces, UAC/elevation-policy confusion, anti-debug state, telemetry gaps, and network APIs.

## Study Order

1. PE structure: headers, sections, imports/exports, relocations, resources, TLS directory, and entry point.
2. Loader and DLL behavior: implicit linking, explicit linking, DLL search order, `DllMain`, API sets, loader lock, and module lists.
3. Process/thread internals: PEB, TEB, stacks, loader lists, process parameters, TLS slots, handles, sections, and memory regions.
4. Native API and SSN: Win32 -> `kernelbase`/`kernel32` -> `ntdll` -> syscall -> kernel service. Understand SSNs as build-specific implementation details.
5. Debugging workflow: attach to process, list modules, inspect PE headers, inspect PEB/TEB, break on DLL load, trace suspicious API use.
6. Malware-analysis patterns: at-rest PE mutation, signature/check-use races, input capture, process injection, cross-process memory patching, user-mode hooking/detours, reflective DLL loading, side-loading/search-order hijacking, kernel dispatch/callback tampering at a defensive level, and ClickFix-style social engineering chains.

## Local Resources

### Larger Hebrew and Local Paper Set

- [Local Hebrew and Digital Whisper Paper Reading Map](<05-local-hebrew-paper-reading-map.md>) covers PE, TLS callbacks, anti-debugging, process hollowing, Process Doppelganging, AtomBombing, BlackEnergy driver reversing, Windows notify routines, rootkits, PatchGuard/DSE history, Win32k/GDI exploitation history, native hypervisor notes, SMM, disk internals, SRUM, and local malware-analysis papers.
- [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>) covers the newer issue PDFs: Kerberos, LSASS, ETW, Event Logs, Windows Authorization, NTLM, WinAPI hashing, injection, DLL side-loading, direct/tampered syscalls, minifilters, BYOVD/DSE, Windows Kernel, AFDUMP, eBPF, SLUB, UEFI, PCI, memory barriers, and pointer authentication.

### PE File Structure

- [Reversing Malware Analysis Training Part 3 - Windows PE File Format Basics.pdf](<Reversing Malware Analysis Training/Presention/Reversing _ Malware Analysis Training Part 3 - Windows PE File Format Basics.pdf>)
- [Portable Executable.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/Portable Executable.pdf>)
- [TLS Callbacks.pdf](<digital whisper-old/articles/רשתות/חולשות/TLS Callbacks.pdf>)
- [Reversing Malware Analysis Training Part 7 - Unpacking UPX.pdf](<Reversing Malware Analysis Training/Presention/Reversing _ Malware Analysis Training Part 7 - Unpacking UPX.pdf>)

### PEB, TEB, TLS, Native API, SSN

- [Yosifovich Pavel - Windows Native API Programming - 2024.pdf](<Yosifovich Pavel - Windows Native API Programming - 2024.pdf>)
- [Pluralsight Windows 11 Internals - Foundations](<Pluralsight - Windows 11 Internals by Pavel Yosifovich/Foundations>)
- [Pluralsight Windows 11 Internals - Processes and Jobs](<Pluralsight - Windows 11 Internals by Pavel Yosifovich/Processes and Jobs>)
- [Pluralsight Windows 11 Internals - Threads](<Pluralsight - Windows 11 Internals by Pavel Yosifovich/Threads>)
- [Pluralsight Windows 11 Internals - Memory Management](<Pluralsight - Windows 11 Internals by Pavel Yosifovich/Memory Management>)
- [Windows Architecture.pdf](<digital whisper-old/articles/low-level/operating systems/kernel1/windows2/Windows Architecture.pdf>)
- [API Set Map & AVRF.pdf](<digital whisper-old/articles/low-level/operating systems/kernel1/windows2/API Set Map & AVRF.pdf>)

### DLL Loading, Attaching, and Debugger Analysis

- [Pluralsight Windows 11 Internals - Introduction to WinDbg](<Pluralsight - Windows 11 Internals by Pavel Yosifovich/Foundations/5. Introduction to WinDbg>)
- In [Processes and Jobs](<Pluralsight - Windows 11 Internals by Pavel Yosifovich/Processes and Jobs/2. Processes>), prioritize `Dll Search Order`, `Demo- Loader`, `Dll Implicit Linking`, `Explicit Linking`, and their demos.
- [היכרות עם WinDbg.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/היכרות עם WinDbg.pdf>)
- [אוטומציה וסקריפטינג ב-WinDbg.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/אוטומציה וסקריפטינג ב-WinDbg.pdf>)
- [Reversing על DLL מוצפן וכוס קפה.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/Reversing על DLL מוצפן וכוס קפה.pdf>)
- [Reversing Malware Analysis Training Part 5 - Reverse Engineering Tools Basics.pdf](<Reversing Malware Analysis Training/Presention/Reversing _ Malware Analysis Training Part 5 - Reverse Engineering Tools Basics .pdf>)
- [Reversing Malware Analysis Training Part 6 - Practical Reversing (I).pdf](<Reversing Malware Analysis Training/Presention/Reversing _ Malware Analysis Training Part 6 - Practical Reversing (I).pdf>)

### Injection, Hooking, and Side-Loading Analysis

- [Code Injection.pdf](<digital whisper-old/articles/low-level/operating systems/kernel1/windows2/Code Injection.pdf>)
- [Threadmap - Detecting Process Hollowing.pdf](<digital whisper-old/articles/low-level/operating systems/kernel1/windows2/Threadmap - Detecting Process Hollowing.pdf>)
- [StackBombing - Next Gen Process Injection Technique.pdf](<digital whisper-old/articles/low-level/operating systems/kernel1/windows2/StackBombing - Next Gen Process Injection Technique.pdf>)
- [המדריך למזריק (DLL) המתחיל - Reflective DLL Injection.pdf](<digital whisper-old/articles/low-level/operating systems/kernel1/windows2/המדריך למזריק (DLL) המתחיל - Reflective DLL Injection.pdf>)
- [IAT Hooking.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/IAT Hooking.pdf>)
- [User-Land Hooking.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/User-Land Hooking.pdf>)
- [System Call Hooking.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/windows reversing/System Call Hooking.pdf>)
- [Biting the hand with DLL Load Hijacking and Binary Planting.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/low level exploitation/Biting the hand with DLL Load Hijacking and Binary Planting.pdf>)
- [Importless Malware.pdf](<digital whisper-old/articles/גליון 128 - 31.03.2021/Importless Malware.pdf>)
- [Process Herpaderping.pdf](<digital whisper-old/articles/גליון 127 - 28.02.2021/Process Herpaderping.pdf>)

### Keylogging and Input-Capture Context

- [Key-Logger, Video, Mouse - זה הזמן ללכלך את הידיים.pdf](<digital whisper-old/articles/low-level/asm-reversing-pwn/embedded-firmware-hw/Key-Logger, Video, Mouse - זה הזמן ללכלך את הידיים.pdf>)
- [Key-logger, Video, Mouse - חלק ד' - תקווה חדשה.pdf](<digital whisper-old/articles/etc/Key-logger, Video, Mouse - חלק ד' - תקווה חדשה.pdf>)

Use these as context for input-capture concepts. For Windows malware analysis, map suspicious samples to API usage and telemetry rather than copying old implementation patterns.

## Online References

### Primary Windows References

- Microsoft PE/COFF format: <https://learn.microsoft.com/en-us/windows/win32/debug/pe-format>
- Inside Windows PE format, Matt Pietrek archive: <https://learn.microsoft.com/en-us/archive/msdn-magazine/2002/february/inside-windows-win32-portable-executable-file-format-in-detail>
- PEB: <https://learn.microsoft.com/en-us/windows/win32/api/winternl/ns-winternl-peb>
- TEB: <https://learn.microsoft.com/en-us/windows/win32/api/winternl/ns-winternl-teb>
- `NtQueryInformationProcess`: <https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntqueryinformationprocess>
- Thread local storage: <https://learn.microsoft.com/en-us/windows/win32/procthread/thread-local-storage>
- DLLs: <https://learn.microsoft.com/en-us/troubleshoot/windows-client/deployment/dynamic-link-library>
- `DllMain`: <https://learn.microsoft.com/en-us/windows/win32/dlls/dllmain>
- DLL search order: <https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order>
- Load-time and run-time dynamic linking: <https://learn.microsoft.com/en-us/windows/win32/dlls/using-run-time-dynamic-linking>

### Debugging and Tooling

- WinDbg getting started: <https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/getting-started-with-windbg>
- `lm` loaded modules: <https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/lm--list-loaded-modules->
- `!dh` image headers: <https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-dh>
- `!peb`: <https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-peb>
- `!address`: <https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-address>
- Process Explorer: <https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer>
- Process Monitor: <https://learn.microsoft.com/en-us/sysinternals/downloads/procmon>
- x64dbg: <https://x64dbg.com/>
- Ghidra: <https://www.nsa.gov/ghidra>
- PE-bear: <https://github.com/hasherezade/pe-bear>
- Detect It Easy: <https://detect-it-easy.github.io/>
- pefile: <https://pefile.readthedocs.io/en/latest/modules/pefile.html>

### SSN and Syscall Tables

- j00ru Windows syscall tables: <https://github.com/j00ru/windows-syscalls>

Use this to understand version differences and syscall stub mapping. Do not rely on fixed SSN values across Windows builds.

### API Analysis Watchlist

Keylogging and input capture:

- `SetWindowsHookEx`, `LowLevelKeyboardProc`, `CallNextHookEx`, `UnhookWindowsHookEx`
- `GetAsyncKeyState`, `GetKeyState`, `GetKeyboardState`
- `RegisterRawInputDevices`, `GetRawInputData`
- MITRE ATT&CK keylogging: <https://attack.mitre.org/techniques/T1056/001/>

Process and thread injection:

- `OpenProcess`, `VirtualAllocEx`, `WriteProcessMemory`, `VirtualProtectEx`
- `CreateRemoteThread`, `CreateRemoteThreadEx`, `NtCreateThreadEx`
- `QueueUserAPC`, `SetThreadContext`, `ResumeThread`
- MITRE ATT&CK process injection: <https://attack.mitre.org/techniques/T1055/>

DLL hooking and tampering:

- `LoadLibrary`, `LoadLibraryEx`, `GetProcAddress`, `VirtualProtect`
- IAT/EAT changes, inline trampoline patches, unexpected executable private memory, suspicious module path mismatches
- Microsoft Detours: <https://www.microsoft.com/en-us/research/project/detours/>

DLL side-loading and search-order hijacking:

- `LoadLibrary*`, `SetDllDirectory`, `AddDllDirectory`, `SetDefaultDllDirectories`
- Unexpected DLL next to signed executable, unsigned DLL loaded by trusted process, unusual current-directory loads
- MITRE ATT&CK DLL search order hijacking: <https://attack.mitre.org/techniques/T1574/001/>

## Recent ClickFix and Related Attacks

ClickFix is mainly a social-engineering execution pattern: fake CAPTCHA/error/update instructions convince the user to paste or run a command. The Windows internals angle is the spawned process tree, clipboard/Run dialog path, script interpreter use, downloaded payloads, persistence, and follow-on DLL/PE behavior.

Read in this order:

1. Microsoft, 2025-08-21: <https://www.microsoft.com/en-us/security/blog/2025/08/21/think-before-you-clickfix-analyzing-the-clickfix-social-engineering-technique/>
2. Microsoft, 2026-02-05: <https://www.microsoft.com/en-us/security/blog/2026/02/05/clickfix-variant-crashfix-deploying-python-rat-trojan/>
3. Check Point, 2025-07-16: <https://blog.checkpoint.com/research/filefix-the-new-social-engineering-attack-building-on-clickfix-tested-in-the-wild/>
4. Proofpoint, 2025-04-17: <https://www.proofpoint.com/us/blog/threat-insight/around-world-90-days-state-sponsored-actors-try-clickfix>

For analysis practice, build a timeline from browser event -> clipboard or user-run command -> script interpreter -> network retrieval -> dropped PE/DLL/script -> persistence -> C2. Focus on observables and Windows APIs, not payload construction.

## Concrete Debugger Checklist

- Attach to process and confirm bitness.
- List loaded modules and paths with `lm`.
- Inspect PE headers with `!dh`.
- Inspect PEB with `!peb`; correlate loader lists with `lm`.
- Inspect memory regions with `!address`; look for private executable pages and image-backed mappings.
- Break on DLL load if needed: `sxe ld`.
- Track suspicious calls at a conceptual level: `LoadLibrary*`, `GetProcAddress`, memory allocation/protection changes, remote thread creation, hook registration, and process creation.

## What To Be Able To Explain

- Difference between PE file on disk and image mapped in memory.
- Why TLS callbacks can run before the nominal entry point.
- What the loader stores in the PEB and why malware tampers with loader lists.
- What lives in the TEB and why debuggers care about it.
- Why syscall numbers are not stable across Windows builds.
- Difference between implicit DLL loading, explicit DLL loading, reflective DLL loading, and side-loading/search-order hijacking.
- How keylogging, injection, hooking, and side-loading appear through process, thread, module, memory, and API telemetry.
- How ClickFix/CrashFix/FileFix are social-engineering execution chains that eventually become normal Windows process, script, PE, DLL, persistence, and network artifacts.
