# Local Hebrew and Digital Whisper Paper Reading Map

Value Score: 64/100
Role: Hebrew Windows paper route
Proof Level: Source-map

Date: 2026-05-15

Scope: where the listed local papers fit into the Windows internals track, when to read them, and what to extract from each. Most of these are Hebrew Digital Whisper or local malware/reversing papers. Treat older exploit/rootkit articles as historical case studies unless the interview explicitly asks about legacy Windows exploitation. The goal is defensive analysis and internals reasoning: object model, memory manager, drivers, loader behavior, telemetry, and mitigation impact.

For the newer local Digital Whisper issue folders 134-185, use the cross-platform [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>). It covers the newer Windows, Linux, firmware, and reversing papers and marks where current Windows/Linux implementation details must be revalidated.

## Short Reading Order

1. **Foundation refresh**: OS theory, processes/threads, PE, TLS callbacks, loader basics.
2. **Core Windows internals**: processes, memory manager, sections, PEB/TEB, process creation and hollowing-like behavior.
3. **Malware/reversing workflow**: anti-debugging, anti-reversing, unpacking, API resolution, process injection, module/memory mismatch.
4. **Kernel and drivers**: driver reversing, notify routines, rootkits, callbacks, PatchGuard/DSE as historical constraints.
5. **Exploit primitives**: paging, Win32k/GDI, CVE writeups, DEP/ASLR as old mitigation context.
6. **Hardware/firmware/virtualization**: hypervisor, SMM, disk internals, IOMMU/firmware trust.
7. **Telemetry and forensics**: SRUM, Threadmap, memory manager artifacts, cross-view detection.

## Priority Table

| When | Priority | Paper | Relevance | Focus on |
|---|---:|---|---|---|
| Before Module 1 if OS theory is rusty | 80 | מבוא למערכות הפעלה.pdf | General OS vocabulary warm-up. Useful only if the basic theory terms are shaky. | Processes, virtual memory, kernel/user split, interrupts, scheduling vocabulary. Do not stop here; it is a primer. |
| Before Module 1 or alongside process/thread study | 85 | מערכות הפעלה - תהליכים ו-Thread-ים.pdf | Good bridge from textbook process/thread ideas to Windows/Linux internals. | PCB/TCB vocabulary, scheduling states, context switches, thread vs process, then map to `_EPROCESS`/`_ETHREAD` and `task_struct`. |
| Modules 1-2: PE and loader basics | 95 | Portable Executable.pdf | High-value PE structure primer. | DOS/NT headers, sections, imports, exports, relocations, resources, image vs file layout. Pair with the binary-loader Q&A. |
| Modules 1-2: PE and loader basics | 95 | Reversing Malware Analysis Training Part 3 - Windows PE File Format Basics.pdf | Practical PE inspection and reversing workflow. | How tools present PE metadata, imports/exports, entry point, sections, and suspicious PE anomalies. |
| Modules 1-2: pre-entry execution | 92 | TLS Callbacks.pdf | Important for loader, packer, and anti-debug questions. | TLS directory, callbacks before main/entry, debugger breakpoints before entry, why "start at entry point" can miss behavior. |
| Modules 1-2: unpacking context | 85 | Reversing Malware Analysis Training Part 7 - Unpacking UPX.pdf | Useful practical packer context, but not a core OS internals source. | Packed-vs-unpacked memory, OEP recovery concept, import reconstruction, memory sections after unpacking. |
| Module 2: process internals | 90 | The New Processes of Windows.pdf | Relevant to Windows process creation and process object evolution. | Process creation path, process attributes, PEB/process parameters, jobs/silos if covered, and how modern process types change old assumptions. |
| Module 2: memory manager | 96 | Internals of Windows Memory Management for Malware Analysis.pdf | High-value bridge between memory manager and malware triage. | VADs, sections, image/mapped/private memory, page protections, suspicious executable memory, VMMap/WinDbg-style interpretation. |
| Modules 2-3: memory and paging | 91 | Intel Paging & Page Table Exploitation on Windows.pdf | Deepens page-table and PTE intuition. Offensive details are historical/contextual. | CR3/page-table levels, PTE bits, NX/RW/user-supervisor, why PTE corruption is powerful, how modern mitigations raise the bar. |
| Module 3: reversing friction | 87 | Anti Reverse Engineering בסביבת Windows.pdf | Practical reversing context. | Anti-debug checks, timing, environment checks, packers, obfuscation, how to recognize rather than copy techniques. |
| Module 3: debugger workflow | 84 | Anti-Anti-Debugging.pdf | Useful after you understand normal debugger and PEB/TEB behavior. | PEB/TEB anti-debug fields, breakpoint/timing tricks, debugger artifacts, and how to validate with multiple tools. |
| Modules 3-4: process injection family | 88 | AtomBombing - שיטת הזרקת חדשה ל-Windows.pdf | Good case study for injection as OS primitive composition. | What object/handle/memory/control-flow primitives are used, how it differs from `CreateRemoteThread`, and what telemetry should correlate. |
| Modules 3-4: process hollowing family | 90 | Process Hollowing.pdf | Core malware-analysis pattern. | Image section vs private memory, suspended process creation, unmap/map/write/protect/resume flow, VAD and PEB mismatch. |
| Modules 3-4: process hollowing detection | 90 | Threadmap - Detecting Process Hollowing.pdf | Defensive companion to hollowing and manual mapping. | Thread start addresses, VAD region type, PEB loader lists, image-load telemetry, disk-memory mismatch. |
| Modules 3-4: transaction/process abuse | 86 | Process Doppelgänging.pdf | Good loader/memory/file-object mismatch case study. | NTFS transaction idea, section/image mapping semantics, process creation artifacts, why file and memory views can disagree. |
| Module 5: driver reversing | 92 | BlackEnergy V.2 - Full Driver Reverse Engineering.pdf | High-value driver reversing case study. | Driver object/device object, dispatch routines, IOCTLs if present, persistence/stealth behavior, static vs dynamic driver analysis. |
| Module 5: kernel callbacks | 92 | Windows Notify Routine Internals.pdf | Very relevant to EDR, kernel telemetry, and rootkit detection. | Process/thread/image/registry/object callback model, legitimate security-product use, callback ownership, enumeration and tampering risks. |
| Module 5: rootkit concepts | 82 | Kernel-Mode Rootkits.pdf | Useful historical kernel-rootkit vocabulary. | SSDT/IDT/hooks as history, DKOM concepts, driver load path, why PatchGuard/HVCI/signing changed the modern model. |
| Module 5: rootkit concepts | 80 | Rootkits - דרכי פעולה וטכניקות בשימוש (חלק א').pdf | Historical rootkit taxonomy. | Process hiding, file hiding, hooks, DKOM-style concepts, and cross-view detection. Validate all implementation assumptions against modern Windows. |
| Module 5: rootkit concepts | 80 | Rootkits - דרכי פעולה וטכניקות בשימוש (חלק ב').pdf | Continuation of historical rootkit taxonomy. | Same as part A: map techniques to modern barriers such as PatchGuard, HVCI, ETW, callbacks, signing, and vulnerable-driver abuse. |
| Module 5: stealth and detection | 84 | Now You See Me, Now You Don't.pdf | Stealth/detection case study. | Which view is hidden from, which lower-level state remains, and how to compare process, handle, VAD, module, ETW, and filesystem views. |
| Modules 5-6: PatchGuard/DSE | 76 | עקיפת ה-Patchguard וה-DSE ללא שימוש ב-Driver או בחולשה.pdf | Historical mitigation-bypass context. Do not treat details as current. | Why PatchGuard/DSE exist, what they try to protect, why modern VBS/HVCI/CI policy changes the story, and what defenders should verify. |
| Module 6: LPE case study | 82 | CVE-2016-0165 - From Security Bulletin To Local Privilege Escalation.pdf | Useful vulnerability-to-primitive case study, but old. | Bug class, reachable interface, object lifetime or memory corruption primitive, mitigation assumptions, patch reasoning. |
| Module 6: LPE case study | 82 | From Security Bulletin to Local Privilege Escalation II - CVE-2016-7255.pdf | Second LPE case study; good for patch-diff and root-cause thinking. | How a bulletin becomes a bug hypothesis, object involved, primitive, constraints, and what changed in the patch. |
| Module 6: Win32k/GDI exploitation history | 78 | Kernel Exploitation Using GDI Objects.pdf | Historical Win32k/GDI object exploitation. | User/kernel GUI boundary, handle tables, object reuse, pool/object lifetime, why modern Windows hardened many assumptions. |
| Module 6: Win32k/GDI exploitation history | 78 | Win32k Smash the Ref - full version.pdf | Advanced legacy Win32k reference-count/lifetime case study. | Refcounts, object lifetime, user-kernel callbacks, mitigation assumptions, patch direction. Read after Windows process/thread/memory basics. |
| Module 6: old kernel exploitation | 70 | Kernel Exploitation & Elevation of Privileges on Windows 7.pdf | Legacy Windows 7 exploitation overview. | Vocabulary and primitive thinking only. Modern interviews expect you to explain why this aged: KASLR, SMEP, CFG, HVCI, pool hardening, PatchGuard. |
| Module 6: mitigation history | 65 | The Art of Exploitation - Windows 7 DEP & ASLR Bypass.pdf | Historical DEP/ASLR context. | What DEP and ASLR protect, why info leaks matter, why ROP-style thinking exists. Do not prioritize for modern Windows unless asked. |
| Hardware/firmware module: virtualization | 86 | Native Hypervisor from Scratch - חלק א'.pdf | Useful after CPU privilege, page tables, and VMX/SVM concepts. | VMX root/non-root, VMCS idea, VM exits, privileged instruction interception, why hypervisors sit below the OS. |
| Hardware/firmware module: virtualization | 86 | Native Hypervisor from Scratch - חלק ב'.pdf | Continuation; useful for VBS/HVCI and hypervisor-rootkit discussion. | EPT/NPT-style second-level translation if covered, VM exits, MSR/control interception, relation to VBS/HVCI and kernel integrity. |
| Hardware/firmware module: firmware/SMM | 84 | מבוא לחולשות SMM - סקירת CVE-2020-12890.pdf | Firmware trust and SMM boundary context. | SMM privilege, firmware attack surface, why OS-level telemetry may not see below-OS tampering, relation to Secure Boot/TPM/IOMMU. |
| Hardware/firmware module: storage hardware | 76 | Harddisk and all that is hidden.pdf | Storage/firmware background. | Disk firmware, hidden areas, persistence/forensics implications, where OS filesystem view may be incomplete. |
| Module 7: telemetry and forensics | 88 | המארב הפרוע - SRUM ומבט לעתיד עולם ההגנה.pdf | Good Windows forensic/telemetry source. | SRUM artifacts, application/network/resource usage, what it proves and does not prove, correlation with ETW/Sysmon/Event Log. |

## How These Papers Map To The Main Study Track

| Main topic | Read these papers after | Why |
|---|---|---|
| PE, loader, TLS, unpacking | Portable Executable, RMA Part 3, TLS Callbacks, UPX unpacking | Builds concrete PE and loader intuition before API-resolution or manual-mapping questions. |
| Process memory and injection | The New Processes of Windows, Process Hollowing, Threadmap, Process Doppelgänging, AtomBombing | Turns VADs, sections, PEB loader lists, handles, threads, and telemetry into practical triage patterns. |
| Kernel drivers and callbacks | BlackEnergy driver RE, Windows Notify Routine Internals, Kernel-Mode Rootkits | Reinforces driver objects, dispatch routines, IOCTLs, callbacks, PatchGuard constraints, and EDR/rootkit visibility. |
| Vulnerability primitives | Intel Paging, CVE-2016-0165, CVE-2016-7255, GDI Objects, Win32k Smash the Ref | Study bug class -> primitive -> mitigation -> patch/test, not copyable exploitation steps. |
| Below-OS and hardware trust | Native Hypervisor Part A, Native Hypervisor Part B, SMM CVE-2020-12890, Harddisk hidden areas | Use after MMU/TLB/IOMMU/firmware basics to understand what sits below the OS. |
| Telemetry and cross-view detection | SRUM, Threadmap, Now You See Me, Now You Don't | Focus on evidence quality, not just APIs: process events, VADs, handles, ETW/Sysmon, SRUM, disk-memory mismatch. |

## Older Issue 120-133 Additions Worth Keeping

These came from a local scan of older issue folders and topic folders. They are useful support material, but they should not displace the newer Windows/Forshaw/Yosifovich/Microsoft sources.

| Topic | Priority | Paper | Use for | Caveat |
|---|---:|---|---|---|
| WSL and cross-OS boundary | 86 | Windows Subsystem for Linux - המכונה שתמיד רציתם.pdf | WSL architecture vocabulary and Windows/Linux boundary thinking. | WSL1 vs WSL2 behavior differs; validate against the current installed WSL version. |
| Windows update/print boundary | 84 | כל מה שרצית לדעת על חולשת האבטחה PrintNightmare.pdf | Spooler/service boundary, driver loading, remote/local privilege boundary case study. | Old CVE; focus on service trust, driver/package policy, and patch/hardening lessons. |
| Domain controller bug case study | 82 | From Zero to Admin - The Zerologon Journey.pdf | Domain authentication failure, protocol state, blast-radius reasoning. | Protocol/CVE case study, not kernel internals. Verify current domain hardening. |
| DNS/AD infrastructure bug | 78 | מ-DNS ל-Domain Admin - ניתוח מעמיק של CVE-2020-1350) SIGRed).pdf | Service attack surface, parsing bug, enterprise blast radius. | Old CVE; use for patch/primitive reasoning only. |
| Windows Event Viewer forensics | 76 | ניתוחים כירורגיים להסרת ראיות מ-Windows Event Viewer.pdf | Event-log evidence quality and anti-forensics discussion. | Treat as historical; modern answer should correlate ETW, Event Log, Sysmon, EDR, and remote logs. |
| LNK/hotkey persistence | 74 | Shortcut Hotkey Exploitation.pdf | Shell/LNK persistence and user-interaction artifact vocabulary. | Not core internals; use for artifact and telemetry awareness. |
| DCOM lateral movement | 74 | תנועה רוחבית באמצעות DCOM Objects - איך עושים את זה נכון.pdf | COM/DCOM activation, service boundary, lateral movement telemetry. | Use for COM/RPC concept support; validate current hardening and logging. |
| NTLM relay history | 72 | איך הצלחנו לעקוף את כל מנגנוני ההגנה כנגד מתקפת NTLM Relay.pdf | NTLM relay mitigation history and authentication boundary reasoning. | Validate against current EPA/channel binding/signing and enterprise policy. |

## What To Deprioritize Unless The Role Is Exploit-Dev Heavy

- The Art of Exploitation - Windows 7 DEP & ASLR Bypass
- Kernel Exploitation & Elevation of Privileges on Windows 7
- PatchGuard/DSE bypass article

They are still useful for vocabulary and historical reasoning, but the interview answer should explain how modern Windows changes the assumptions: VBS/HVCI, PPL, Kernel CFG/CET where available, vulnerable-driver blocklists, driver signing, ETW, PatchGuard, pool hardening, and stronger default mitigations.

## One-Line Study Rule

For every paper, write down: **object involved -> authority boundary -> memory/dispatch primitive -> modern mitigation -> telemetry/cross-view evidence**. If the paper does not help answer those five points, skim it and move on.
