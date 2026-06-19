# Windows Low-Level Security Resources - Clean References

Value Score: 66/100
Role: Windows resource route
Proof Level: Resource-map

This is a cleaned export of the research result. The broken Deep Research citation markers were replaced with normal Markdown links and raw URLs so the file works outside ChatGPT.

## Recommended order

### 1. Lord of the Ring0 - Ido Veltzman / idov31

**Why it matters:** One of the most directly relevant hands-on series for Windows kernel offensive internals: drivers, callbacks, process/thread/image notifications, IOCTLs, kernel/user interaction, and security mechanism bypass concepts.

**Best for:** Learning the practical kernel-driver side of Windows internals security.

**Link:** https://idov31.github.io/posts/lord-of-the-ring0-p6

Note: The p6 page was the directly referenced page from the previous report. The rest of the series is likely discoverable from the author's posts index: https://idov31.github.io/posts/

---

### 2. PatchGuard Peekaboo - Outflank

**Why it matters:** Modern view of PatchGuard, VBS/HVCI, VTL separation, and why older kernel patching tricks are much harder on current Windows systems.

**Best for:** Understanding the modern mitigation landscape rather than only old-school SSDT/IDT hooks.

**Link:** https://www.outflank.nl/blog/2026/01/07/patchguard-peekaboo-hiding-processes-on-systems-with-patchguard-in-2026/

---

### 3. Melting Down PatchGuard - Fortinet / enSilo

**Why it matters:** A classic example of how a mitigation-era architectural change, KPTI/KVAS, created an unexpected PatchGuard bypass surface.

**Best for:** Kernel address spaces, syscall transitions, PatchGuard assumptions, and mitigation side effects.

**Link:** https://www.fortinet.com/blog/threat-research/melting-down-patchguard-leveraging-kpi-to-bypass-kernel-patch-protection

---

### 4. GhostHook - CyberArk

**Why it matters:** Shows an advanced hardware-assisted hooking idea using Intel Processor Trace without traditional code patching.

**Best for:** Hardware tracing, PatchGuard evasion concepts, and non-obvious hook implementation models.

**Link:** https://www.cyberark.com/resources/threat-research-blog/ghosthook-bypassing-patchguard-with-processor-trace-based-hooking

---

### 5. Bypassing ETW for Fun and Profit - White Knight Labs

**Why it matters:** ETW is a major Windows telemetry surface used by defenders and EDRs. This guide is useful for understanding where attackers try to blind telemetry and what defenders should verify.

**Best for:** ETW internals, telemetry trust boundaries, and user-mode patching detection ideas.

**Link:** https://whiteknightlabs.com/2021/12/11/bypassing-etw-for-fun-and-profit/

---

### 6. AMSI bypass guides - use carefully

**Why it matters:** AMSI is an important Windows security inspection interface. Many public posts focus on bypasses, but the useful learning goal is understanding where inspection happens and how to detect tampering.

**Best for:** Defender-side understanding of AMSI trust boundaries.

**Example link from previous report:** https://medium.com/@R3dLevy/evading-windows-security-bypass-amsi-65d639e2f35d

---

## Flare-On challenges most relevant to Windows internals

These are the ones from the previous research output that are most worth checking against official Mandiant/Google Cloud solution posts.

Local enriched notes: [04-flareon-windows-internals-notes.md](<04-flareon-windows-internals-notes.md>) distills the official PDFs and selected community writeups into Windows-internals takeaways. Use that file for mechanism mapping; use the linked writeups only when you want the full flag path.

### Flare-On 6, 2019 - `help`

**Core relevance:** Windows memory forensics, kernel drivers, hidden activity in memory, Volatility-style analysis.

**Official solutions page:** https://cloud.google.com/blog/topics/threat-intelligence/2019-flare-on-challenge-solutions/

---

### Flare-On 8, 2021 - `evil`

**Core relevance:** Windows exception handling, VEH/SEH-style control-flow redirection, runtime API/import resolution.

**Official solutions page:** https://cloud.google.com/blog/topics/threat-intelligence/flare-on-8-challenge-solutions/

---

### Flare-On 10, 2023 - `HVM`

**Core relevance:** Windows Hypervisor Platform (`WinHvPlatform.dll`) reversing, guest physical memory mapping, virtual CPU state, VM exits, port-I/O exit handling, and low-level execution modeling. Treat VBS/HVCI-specific claims as separate from the challenge unless a primary source explicitly supports them.

**Official solutions page:** https://cloud.google.com/blog/topics/threat-intelligence/flareon10-challenge-solutions/

---

### Additional high-relevance Flare-On cases to add to the map

These were not in the earlier short list, but they are worth including because they directly exercise rootkit, bootkit, firmware, ring -1, and kernel-escalation mechanisms. The local notes now cover them with official and alternative writeups: [04-flareon-windows-internals-notes.md](<04-flareon-windows-internals-notes.md>).

| Challenge | Core relevance | Caveat |
|---|---|---|
| Flare-On 7, 2020 - `crackinstaller` | BYOVD-style chain using a signed Capcom driver, IOCTL-triggered SMEP bypass, reflective unsigned driver loading, `CmRegisterCallbackEx`, registry class strings, and COM activation. | Learn the primitives and detection questions, not the old Capcom recipe. Modern driver blocklists, WDAC, HVCI, and EDR telemetry change viability. |
| Flare-On 5, 2018 - `golf` | Ring -1 thinking: Windows driver loads a thin Intel VT-x hypervisor, user-mode `vmcall` becomes the guest-to-hypervisor boundary, and VM exits explain behavior. | Custom challenge hypervisor; not a VBS/HVCI implementation or bypass. |
| Flare-On 5, 2018 - `Suspicious Floppy Disk` | Bootkit mechanics: crafted boot sector, original boot-sector handoff, interrupt-vector-table hook for `INT 13h`, hidden sector behavior, and lower-than-filesystem deception. | BIOS/floppy-era, but excellent for bootkit reasoning. |
| Flare-On 5, 2018 - `doogie.bin` | MBR/boot-sector warm-up: 16-bit disassembly, BIOS disk reads, Disk Address Packet use, sector extraction, and rebasing loaded stages. | More boot-sector exercise than Windows rootkit. |
| Flare-On 10, 2023 - `Mbransom` | MBR ransomware: rewritten MBR, Track 0 staging, real-mode loader, partition-table state, RC4-obfuscated second stage, Blowfish disk decryption. | Legacy BIOS/MBR style, but still useful for disk image and boot trust analysis. |
| Flare-On 11, 2024 - `CATBERT Ransomware` | UEFI firmware analysis: OVMF image, FAT12 disk, modified EFI shell, UEFI PE extraction, `EFI_SYSTEM_TABLE`, boot/runtime services, and VM bytecode password checks. | Firmware/UEFI case study, not Windows kernel code. |

## Better primary/reference material

Use these alongside blog posts so you do not learn only attacker folklore.

- Microsoft - Kernel Patch Protection / PatchGuard: https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/patchguard
- Microsoft - Virtualization-based protection of code integrity / HVCI: https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity
- Microsoft - Event Tracing for Windows: https://learn.microsoft.com/en-us/windows/win32/etw/event-tracing-portal
- Microsoft - AMSI: https://learn.microsoft.com/en-us/windows/win32/amsi/antimalware-scan-interface-portal
- Intel SDM, Volume 3: https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html
- Windows Internals, 7th/8th edition, by Russinovich, Solomon, Ionescu, and Yosifovich.

## Practical reading path

1. Start with Windows Internals chapters on processes, memory, system calls, drivers, and security.
2. Read idov31's Ring0 series to connect driver code to real Windows mechanisms.
3. Read the Microsoft docs for PatchGuard, HVCI, ETW, and AMSI.
4. Read Fortinet's PatchGuard/KPTI writeup to understand mitigation side effects.
5. Read Outflank's PatchGuard/HVCI piece to update your mental model for modern Windows.
6. Read GhostHook last, because it is more niche and hardware-assisted.
7. Use Flare-On challenges as exercises, not as your primary explanation source.

## Notes on quality control

The previous Deep Research Markdown used internal citation markers like `【82†L101-L105】`, which break when copied into a normal Markdown file. This version replaces them with explicit links.

I also softened claims that were too speculative. For example, the official `HVM` solution supports Windows Hypervisor Platform and VM-exit analysis, but not a VBS/HVCI-specific conclusion by itself.
