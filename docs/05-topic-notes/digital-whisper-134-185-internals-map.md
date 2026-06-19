# Digital Whisper Issues 134-185 Internals Map

Value Score: 70/100
Role: Digital Whisper source route
Proof Level: Source-map

Date: 2026-05-16

Scope: local Hebrew Digital Whisper PDFs from issues 134-185 that can support deeper Windows, Linux, hardware, reversing, and defensive-analysis understanding. These are not primary OS references. Use them as case studies and Hebrew explanations after learning the current mechanism from primary sources.

Local inventory found 52 issue folders and 263 PDFs under `digital whisper-old/articles`. The paths are stored with a scraper-style `DWScraper-main` prefix in each issue directory name.

For older issue folders and topic-organized PDFs, see [Local Hebrew and Digital Whisper Paper Reading Map](<../04-windows/05-local-hebrew-paper-reading-map.md>) and the Hebrew section in [Linux source map](<../03-linux/source-map.md>). Those maps now include selected older high-value additions such as WSL, Docker/container, SELinux, Linux kernel rootkit/keylogger, glibc `FILE`, PrintNightmare, Zerologon, SIGRed, DCOM, and Windows Event Viewer forensics.

## Freshness Rule

Treat these papers as mechanism support, not as the final word on current implementation:

- Windows kernel, syscall, DSE, BYOVD, LSASS, token, ETW, EDR, and boot articles must be checked against the target Windows build, PPL/Credential Guard/VBS/HVCI/WDAC/driver-blocklist policy, and current Microsoft behavior.
- Linux kernel, glibc, eBPF, SLUB, process hollowing, and kernel exploitation articles must be checked against the target kernel, distro config, compiler hardening, LSM/seccomp/cgroup policy, and current source.
- Hardware and firmware articles are valuable for mental models, but firmware, TPM, UEFI, DMA/IOMMU, PCIe, and cache behavior are platform-specific.
- Malware and offensive papers should be used for defensive recognition: object involved, authority boundary, memory/dispatch primitive, mitigation, and telemetry.

## Highest-Value Reading Order

1. Windows object/security/authentication: access tokens, authorization, Kerberos, NTLM, LSASS, NTDS, Event Logs, ETW.
2. Windows loader/malware triage: API hashing, code injection, DLL side-loading, Proxy DLL, direct/tampered syscalls, obfuscated malware.
3. Windows kernel/driver: minifilters, Windows Kernel papers, unsigned-driver detection, BYOVD/DSE, AFDUMP, kernel traffic rootkit.
4. Linux internals/security: glibc heap, PwnKit, eBPF, modprobe_path, GOT overwrite, Linux process hollowing, persistence, SLUB.
5. Hardware/firmware: firmware analysis, PCI, bootkits, UEFI disk attacks, firmware ring bugs, cache coherence, memory barriers.
6. Reversing and exploit primitives: ROP, packing/unpacking, anti-analysis, vulnerability scanner, pointer authentication, CVE case studies.

## Windows Internals And Security

| Issue | Paper | Use for | Caveat |
|---:|---|---|---|
| 134 | [1-st Step to Tame a Kerberos - Know Your Enemy.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 134 - 30.09.2021/1-st Step to Tame a Kerberos - Know Your Enemy.pdf>) | Kerberos vocabulary, tickets, KDC flow, domain identity mental model. | Pair with Forshaw and Microsoft docs; protocol behavior is stable, deployment and detections change. |
| 135 | [2nd Step to Tame a Kerberos - Hit It Where It Hurts.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 135 - 31.10.2021/2nd Step to Tame a Kerberos - Hit It Where It Hurts.pdf>) | Kerberos abuse case-study reasoning and defensive artifact mapping. | Do not treat offensive flow details as current; focus on token/session/credential boundaries. |
| 138 | [Kerberos Delegation 101.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 138 - 31.03.2022/Kerberos Delegation 101.pdf>) | Delegation models, service tickets, domain privilege boundaries. | Validate against current AD hardening, constrained delegation policy, and auditing. |
| 149 | [Inside LSASS.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 149 - 31.03.2023/Inside LSASS.pdf>) | LSASS role, credential material, logon sessions, SSP/auth package context. | Modern answer must include PPL, Credential Guard, LSA protection, and telemetry. |
| 149 | [ETW עוקבים אחרי.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 149 - 31.03.2023/ETW עוקבים אחרי.pdf>) | ETW provider/consumer thinking and Windows observability. | Provider schemas and EDR usage evolve; verify events on the target build. |
| 152 | [Mimikatz Internals.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 152 - 30.06.2023/Mimikatz Internals.pdf>) | Credential-theft internals as a defensive LSASS/logon-session study. | Historical/offensive. Use to understand what protections changed, not to memorize old assumptions. |
| 156 | [Windows Lateral Movement from Scratch - Part 1 - Access Tokens Granted Right.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 156 - 30.11.2023/Windows Lateral Movement from Scratch - Part 1 - Access Tokens Granted Right.pdf>) | Access tokens, granted rights, impersonation, handle authority. | Good conceptual support; pair with Forshaw for access checks and auditing. |
| 157 | [Windows Lateral Movement from Scratch - Part 2.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 157 - 31.12.2024/Windows Lateral Movement from Scratch - Part 2.pdf>) | Token/session/service-boundary case study. | Treat as defensive reasoning and telemetry mapping. |
| 158 | [Windows Authorization 101.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 158 - 31.01.2024/Windows Authorization 101.pdf>) | SIDs, groups, DACLs, access checks, privileges. | Good support for the Windows Q&A; still verify edge cases against current Windows. |
| 158 | [NTLM Authentication Manipulation.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 158 - 31.01.2024/NTLM Authentication Manipulation.pdf>) | NTLM flow and attack/defense vocabulary. | Pair with current NTLM hardening, auditing, and enterprise policy guidance. |
| 160 | [פיצוח סודות ה-NTDS.dit.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 160 - 31.03.2024/פיצוח סודות ה-NTDS.dit.pdf>) | AD database, credential storage, offline-forensics context. | Identity/forensics case study, not a general OS internals source. |
| 163 | [Primary Refresh Token וכל מילה נוספת מיותרת.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 163 - 30.06.2024/Primary Refresh Token וכל מילה נוספת מיותרת.pdf>) | Cloud-adjacent Windows identity and token material. | Useful for endpoint identity story, but Azure behavior changes quickly. |
| 179 | [ShadowHound - חלופה ל-SharpHound באמצעות Native PowerShell .pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 179 - 31.10.2025/ShadowHound - חלופה ל-SharpHound באמצעות Native PowerShell .pdf>) | PowerShell, AD enumeration, native tooling telemetry. | Treat as detection-engineering and identity-boundary context. |
| 183 | [The Perfect Cover Masking Password Sprays as Microsoft Traffic.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 183 - 28.02.2026/The Perfect Cover Masking Password Sprays as Microsoft Traffic.pdf>) | Identity telemetry, attribution pitfalls, cloud/endpoint correlation. | Campaign/detection details age quickly. |

## Windows Loader, Syscalls, And Malware Triage

| Issue | Paper | Use for | Caveat |
|---:|---|---|---|
| 140 | [Fileless Attacks - הסיפור שאינו נגמר.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 140 - 31.05.2022/Fileless Attacks - הסיפור שאינו נגמר.pdf>) | In-memory execution, script/runtime telemetry, process lineage. | Map to AMSI, ETW, Defender, script logging, and modern EDR behavior. |
| 150 | [WinAPI Hashing.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 150 - 30.04.2023/WinAPI Hashing.pdf>) | Import hiding, PEB/export parsing, runtime API resolution. | Pair with loader/API-set notes; focus on recognition and recovery. |
| 152 | [טכניקות להזרקת קוד ב-Windows.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 152 - 30.06.2023/טכניקות להזרקת קוד ב-Windows.pdf>) | Injection families as handle/memory/thread primitive composition. | Use defensively: access rights, VADs, section mapping, thread/APC telemetry. |
| 158 | [Malware-less Persistence (Done) Right.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 158 - 31.01.2024/Malware-less Persistence (Done) Right.pdf>) | Persistence surfaces without obvious dropped malware. | Map to registry, WMI, scheduled tasks, services, COM, script logging. |
| 162 | [Packing and Unpacking in Malicious Files.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 162 - 31.05.2024/Packing and Unpacking in Malicious Files.pdf>) | Packed-vs-unpacked memory, entry point/OEP, import reconstruction. | Pair with PE loader and memory-region classification. |
| 168 | [Dealing With Obfuscated Malware.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 168 - 30.11.2024/Dealing With Obfuscated Malware.pdf>) | Obfuscation, reversing workflow, dynamic/static correlation. | Technique-specific details age; workflow remains useful. |
| 170 | [המדריך המקיף ל-DLL-Sideloading.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 170 - 31.01.2025/המדריך המקיף ל-DLL-Sideloading.pdf>) | DLL search order, signed-host/untrusted-DLL triage, KnownDLL/API-set contrast. | Validate search-order behavior by app type, manifest, packaged app, and Windows build. |
| 172 | [Syscalls, Direct Syscalls וכל מה שביניהן.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 172 - 31.03.2025/Syscalls, Direct Syscalls וכל מה שביניהן.pdf>) | `ntdll`, syscall stubs, direct syscalls, user-mode hook bypass concepts. | Must be paired with "Win32 is the stable contract" and build-specific SSN caveats. |
| 175 | [Invoke- Malware Development - Creating A Spyware From Scratch.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 175 - 30.06.2025/Invoke- Malware Development - Creating A Spyware From Scratch.pdf>) | Spyware telemetry surfaces: input, screenshots, process lineage, persistence. | Use only for defensive recognition and lab vocabulary. |
| 177 | [Proxy DLL.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 177 - 31.08.2025/Proxy DLL.pdf>) | Export forwarding/proxy DLL behavior and side-loading variants. | Pair with PE exports, loader path policy, and module telemetry. |
| 184 | [Tampered Syscalls.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 184 - 31.03.2026/Tampered Syscalls.pdf>) | Syscall-stub integrity, hooked/tampered `ntdll`, EDR evasion/detection concepts. | Highly build/tool specific. Verify against clean image and current EDR assumptions. |

## Windows Kernel, Drivers, And Telemetry

| Issue | Paper | Use for | Caveat |
|---:|---|---|---|
| 146 | [תפיסות שגויות נפוצות לגבי Windows Event Logs.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 146 - 31.12.2022/תפיסות שגויות נפוצות לגבי Windows Event Logs.pdf>) | Event Log evidence quality and misconceptions. | Pair with ETW/Sysmon/Defender telemetry; Event Log is one view. |
| 156 | [מפלטרים Minifilters.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 156 - 30.11.2023/מפלטרים Minifilters.pdf>) | File-system minifilter stack, altitudes, security products. | Validate API/altitude details against current WDK and target product behavior. |
| 162 | [Windows Kernel ממבט התקפי.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 162 - 31.05.2024/Windows Kernel ממבט התקפי.pdf>) | Kernel object/driver attack-surface vocabulary. | Offensive framing; use to ask what PatchGuard, HVCI, callbacks, and signing change. |
| 163 | [מעקף DSE בעזרת שיטת BYOVD.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 163 - 30.06.2024/מעקף DSE בעזרת שיטת BYOVD.pdf>) | BYOVD and driver-signing boundary reasoning. | Current answer must include Microsoft vulnerable-driver blocklist, HVCI, WDAC, and Secure Boot policy. |
| 164 | [הנדסת דרייברים לאחור - מתודולוגיה ושימוש פרקטי.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 164 - 31.07.2024/הנדסת דרייברים לאחור - מתודולוגיה ושימוש פרקטי.pdf>) | Driver reversing workflow, dispatch/IOCTL/object thinking. | Use as method support; verify symbols and APIs by build/WDK. |
| 165 | [Windows Kernel Manual - חלק ד'.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 165 - 31.08.2024/Windows Kernel Manual - חלק ד'.pdf>) | Windows kernel concepts in Hebrew. | Treat as support next to Yosifovich/Windows Internals, not replacement. |
| 165 | [Rootkit קרנלי לניצול תעבורה רשתית.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 165 - 31.08.2024/Rootkit קרנלי לניצול תעבורה רשתית.pdf>) | Kernel/network rootkit detection thinking. | Validate against WFP/NDIS/minifilter/callback realities and modern integrity protections. |
| 168 | [זיהוי טעינת דרייברים לא חתומים.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 168 - 30.11.2024/זיהוי טעינת דרייברים לא חתומים.pdf>) | Driver-load telemetry and code-integrity detection. | Must be checked against CI policy, test signing, HVCI, WDAC, and blocklist state. |
| 176 | [ניצול ה-Kernel על מנת לבצע Code Execution.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 176 - 31.07.2025/ניצול ה-Kernel על מנת לבצע Code Execution.pdf>) | Kernel code-execution primitive reasoning. | Use only for bug-to-primitive-to-mitigation discussion. |
| 181 | [AFDUMP - Sniffing Network From The Kernel.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 181 - 31.12.2025/AFDUMP – Sniffing Network From The Kernel.pdf>) | AFD/network/kernel observation, driver/network boundary. | Validate against current network stack, WFP/ETW, PatchGuard/HVCI, and driver-signing policy. |

## Linux And Android Internals

| Issue | Paper | Use for | Caveat |
|---:|---|---|---|
| 134 | [House Every Weekend - glibc Heap Exploitation.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 134 - 30.09.2021/House Every Weekend - glibc Heap Exploitation.pdf>) | glibc allocator vocabulary and heap exploitation history. | glibc internals change; use as background, not current allocator truth. |
| 137 | [PwnKit - CVE-2021-4034.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 137 - 28.02.2022/PwnKit - CVE-2021-4034.pdf>) | Linux LPE bug-to-primitive case study. | Old CVE. Focus on environment, exec boundary, permissions, and patch reasoning. |
| 143 | [רב הנסתר על הגלוי - עולם ההצפנה ב-Linux.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 143 - 31.08.2022/רב הנסתר על הגלוי - עולם ההצפנה ב-Linux.pdf>) | Linux encryption/storage vocabulary. | Pair with current dm-crypt/LUKS documentation. |
| 144 | [D-Bus כמשטח תקיפה.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 144 - 30.09.2022/D-Bus כמשטח תקיפה.pdf>) | Linux desktop/service IPC attack surface. | Policy and service behavior are distro-specific. |
| 144 | [LUKS Encryption Deep Dive.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 144 - 30.09.2022/LUKS Encryption Deep Dive.pdf>) | LUKS/dm-crypt storage-security model. | Validate against current cryptsetup/LUKS2 and TPM/FIDO integration if relevant. |
| 145 | [eBPF - Zero to Hero.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 145 - 30.11.2022/eBPF - Zero to Hero.pdf>) | eBPF maps/programs/verifier vocabulary. | Current verifier, helpers, kfuncs, BTF, and LSM/BPF behavior change quickly. |
| 146 | [modprobe_path - Hit & Run.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 146 - 31.12.2022/modprobe_path - Hit & Run.pdf>) | Kernel write primitive impact and module autoloading history. | Treat as historical exploit primitive; current hardening and configs matter. |
| 146 | [Overwriting the Global Offset Table.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 146 - 31.12.2022/Overwriting the Global Offset Table.pdf>) | ELF/GOT relocation and memory-protection concepts. | Pair with RELRO/PIE/current loader behavior. |
| 148 | [Linux Process Hollowing.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 148 - 28.02.2023/Linux Process Hollowing.pdf>) | Linux process/memory tampering analogy to Windows hollowing. | Map to `/proc/<pid>/maps`, `ptrace`, `memfd`, `execve`, namespaces, and LSM/seccomp. |
| 171 | [טכניקות אחיזה בלינוקס.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 171 - 28.02.2025/טכניקות אחיזה בלינוקס.pdf>) | Linux persistence surface map. | Validate against distro init system, systemd, containers, and hardening. |
| 178 | [מבנה הקרנל הלינוקסי וטכניקות ניצול שלו .pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 178 - 30.09.2025/מבנה הקרנל הלינוקסי וטכניקות ניצול שלו .pdf>) | Linux kernel structure/exploitation vocabulary. | Use with current Linux source and hardening docs. |
| 180 | [Android Firmware Modding.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 180 - 30.11.2025/Android Firmware Modding.pdf>) | Android firmware/boot image/vendor partition context. | Device/vendor-specific. Pair with Android verified boot and SELinux context. |
| 185 | [BabySteps into SLUB - חלק א'.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 185 - 01.05.2026/BabySteps into SLUB - חלק א'.pdf>) | SLUB allocator vocabulary and object-cache reasoning. | Check against target kernel version, config, KASAN/KFENCE, freelist hardening. |

## Hardware, Firmware, And Architecture

| Issue | Paper | Use for | Caveat |
|---:|---|---|---|
| 134 | [The Hitchhiker's Guide to firmware analysis.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 134 - 30.09.2021/The Hitchhiker's Guide to firmware analysis.pdf>) | Firmware RE workflow and below-OS attack surface. | Platform-specific; pair with UEFI/ACPI/TPM reading. |
| 138 | [משחקים ונהנים עם PCI.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 138 - 31.03.2022/משחקים ונהנים עם PCI.pdf>) | PCI/PCIe device model, MMIO/config-space intuition. | Hardware-specific; relate to DMA/IOMMU and driver trust. |
| 140 | [Bootkits - It's Never Deep Enough.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 140 - 31.05.2022/Bootkits - It's Never Deep Enough.pdf>) | Boot-chain persistence and trust-boundary vocabulary. | Must be updated with Secure Boot, measured boot, ELAM, TPM, HVCI, and firmware policy. |
| 171 | [Cache Coherence.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 171 - 28.02.2025/Cache Coherence.pdf>) | CPU cache/coherency mental model for OS and concurrency. | Architecture-specific details vary. |
| 174 | [Ordering & Memory Barriers .pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 174 - 31.05.2025/Ordering & Memory Barriers .pdf>) | Memory ordering, barriers, lock-free/concurrency reasoning. | Pair with target CPU architecture and kernel memory model docs. |
| 175 | [Memory models.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 175 - 30.06.2025/Memory models.pdf>) | Cross-language/CPU memory-model concepts. | Use for theory before reading kernel locking code. |
| 178 | [Booty Call - When the Firmware Answers the Wrong Ring.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 178 - 30.09.2025/Booty Call - When the Firmware Answers the Wrong Ring.pdf>) | Firmware privilege boundary and below-OS attack-surface case study. | Verify against platform firmware and current mitigations. |
| 182 | [פורצים את הדיסק - מתקפות UEFI ב-20₪.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 182 - 31.01.2026/פורצים את הדיסק - מתקפות UEFI ב-20₪.pdf>) | UEFI/disk/physical trust and boot-chain thinking. | Pair with Secure Boot, TPM, BitLocker, measured boot, and physical-access caveats. |
| 184 | [אימות מצביעים (Pointer Authentication).pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 184 - 31.03.2026/אימות מצביעים (Pointer Authentication).pdf>) | ARM pointer authentication and control-flow integrity concepts. | Architecture/OS support varies; pair with ARM architecture map. |

## Reversing, Exploit Primitives, And Defensive Engineering

| Issue | Paper | Use for | Caveat |
|---:|---|---|---|
| 135 | [פתרון אתגרי Flare-On 2021.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 135 - 31.10.2021/פתרון אתגרי Flare-On 2021.pdf>) | Windows reversing challenge context. | Challenge-specific; use after the Flare-On notes. |
| 147 | [Developing ROP chains to defeat Windows 10 DEP.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 147 - 31.01.2023/Developing ROP chains to defeat Windows 10 DEP.pdf>) | ROP/DEP vocabulary. | Historical; modern answers must include CFG/CET, ACG/CIG, and exploit mitigations. |
| 162 | [על תכנות low-level, או - כמה נמוך אפשר לרדת.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 162 - 31.05.2024/על תכנות low-level, או - כמה נמוך אפשר לרדת.pdf>) | Low-level programming vocabulary. | General support, not OS-specific authority. |
| 167 | [Detection Engineering בארץ הקודש.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 167 - 31.10.2024/Detection Engineering בארץ הקודש.pdf>) | Detection-engineering process and telemetry thinking. | Pair with actual data-source schemas and false-positive analysis. |
| 167 | [Exploiting Legitimate APIs for Data Theft.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 167 - 31.10.2024/Exploiting Legitimate APIs for Data Theft.pdf>) | API misuse, living-off-the-land, telemetry framing. | Identify objects and authorization boundaries, not only API names. |
| 168 | [פתרונות אתגרי Flare On 2024.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 168 - 30.11.2024/פתרונות אתגרי Flare On 2024.pdf>) | Recent reversing challenges. | Challenge-specific; use to practice concepts from the loader/exception notes. |
| 179 | [איך בונים Vulnerability Scanner .pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 179 - 31.10.2025/איך בונים Vulnerability Scanner .pdf>) | Scanner design and vulnerability triage workflow. | Operational details age; focus on evidence and false-positive handling. |
| 181 | [Hiding under ROP for fun and profit.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 181 - 31.12.2025/Hiding under ROP for fun and profit.pdf>) | ROP hiding/evasion concepts and detection questions. | Validate against CFG/CET/shadow-stack/EDR stack-walking behavior. |
| 185 | [כשהעיניים רואות את מה שהאוזניות לא משמיעות - ניתוח החולשה CVE-2025-20700.pdf](<../../digital whisper-old/articles/DWScraper-mainגליון 185 - 01.05.2026/כשהעיניים רואות את מה שהאוזניות לא משמיעות - ניתוח החולשה CVE-2025-20700.pdf>) | Recent CVE analysis workflow. | Product-specific; extract bug-class and patch/mitigation reasoning. |

## Where This Supports Existing Notes

| Existing note | Add these papers as support |
|---|---|
| [Windows deep-understanding Q&A](<../02-question-banks/02-windows-deep-understanding-qa.md>) | Windows Authorization 101, access-token lateral movement, Inside LSASS, ETW, Minifilters, Windows Kernel, Direct Syscalls, Tampered Syscalls. |
| [Linux deep-understanding Q&A](<../02-question-banks/01-linux-deep-understanding-qa.md>) | eBPF, PwnKit, modprobe_path, Linux Process Hollowing, Linux persistence, Linux kernel exploitation, SLUB. |
| [Memory/filesystems/network Q&A](<../02-question-banks/03-memory-filesystems-network-qa.md>) | SLUB, glibc heap, LUKS, D-Bus, AFDUMP, kernel traffic rootkit, Cache Coherence, Memory Barriers. |
| [Binary loaders/linkers Q&A](<../02-question-banks/04-binary-loaders-linkers-qa.md>) | WinAPI Hashing, DLL Sideloading, Proxy DLL, Packing/Unpacking, GOT overwrite, ret2dlresolve, Linux Process Hollowing. |
| [Hardware security Q&A](<../02-question-banks/05-hardware-security-relationship-qa.md>) | Firmware analysis, PCI, bootkits, UEFI disk attacks, firmware ring bug, pointer authentication, cache coherence. |
| [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>) | Object/token/loader/kernel/telemetry papers above as Hebrew case-study reinforcement. |

## Quick Extraction Prompts

For each selected paper, extract only what strengthens internals understanding:

1. Which kernel/user object or structure is central?
2. Which boundary is being crossed or abused?
3. Which memory, loader, driver, IPC, identity, or hardware mechanism makes it possible?
4. Which modern mitigation or policy changes the assumptions?
5. Which telemetry or debugger view would prove or disprove the behavior?
