# Flare-On Windows Internals Case Notes

Value Score: 78/100
Role: Windows case-study support
Proof Level: Case-study

Date: 2026-05-16

Purpose: extract Windows-internals lessons from the Flare-On challenges named in [Windows Low-Level Security Resources](<07-windows-low-level-security-resources.md>). These are not primary Windows references. Use them as case studies after learning the mechanisms from Windows Internals, Microsoft docs, Pavel Yosifovich material, and James Forshaw's Windows security material.

## Source Set

| Challenge | Main source | Useful secondary source | Windows mechanisms worth extracting |
|---|---|---|---|
| Flare-On 6, 2019, `help` | [Official challenge 12 solution PDF](https://services.google.com/fh/files/misc/flare-on-6-challenge-12-help-en.pdf) | [XLOYE writeup](https://unhere.com/2019/11/23/help-flare-on-6-challenge-12/), [Attify writeup](https://blog.attify.com/flare-on-6-ctf-writeup-part12/amp/), [hasherezade writeup](https://hshrzd.wordpress.com/2019/09/30/flare-on-6-tasks-10-12/) | Crash dump triage, driver objects, `DeviceIoControl`, IRPs, hidden drivers, WFP callouts, PCAP correlation |
| Flare-On 5, 2018, `doogie.bin` | [Official challenge 8 solution PDF](https://services.google.com/fh/files/misc/flareon5-challenge8-solution.pdf) | [Thomas W. writeup](https://thomasw.dev/post/flareon-2018-8-doogie.bin/), [Attify part 5](https://blog.attify.com/flare-on-5-writeup-part5/) | MBR/boot-sector triage, 16-bit disassembly, BIOS `INT 13h`, Disk Address Packet reads, sector rebasing |
| Flare-On 5, 2018, `golf` | [Official challenge 10 solution PDF](https://services.google.com/fh/files/misc/flareon5-challenge10-solution.pdf) | [Attify part 7](https://blog.attify.com/flare-on-5-writeup-part7/amp/), [HackMD writeup](https://hackmd.io/hWJYSNq4S0GJpoo3FEguiA) | Windows driver loading, Intel VT-x, `vmcall`, VMX capability checks, VM exits, thin hypervisor/rootkit thinking |
| Flare-On 5, 2018, `Suspicious Floppy Disk` | [Official challenge 12 solution PDF](https://services.google.com/fh/files/misc/flareon5-challenge12-solution.pdf) | [HackMD writeup](https://hackmd.io/hWJYSNq4S0GJpoo3FEguiA), [Anquanke writeup](https://www.anquanke.com/post/id/161272) | Bootkit analysis, interrupt-vector hooks, `INT 13h` read/write interception, hidden sectors, subleq VM |
| Flare-On 7, 2020, `crackinstaller` | [Official challenge 9 solution PDF](https://services.google.com/fh/files/misc/flare-on-seven-challenge-nine.pdf) | [explained.re writeup](https://explained.re/posts/flare-on7-crackinstaller/), [xEHLE writeup](https://blog.p1.gs/ctf%2C/reverse/engineering/2020/10/24/FLARE-ON-7-writeup/), [Starfleet Cadet writeup](https://starfleetcadet75.github.io/posts/flareon-2020-9-crackinstaller/) | BYOVD-style kernel execution, Capcom `DeviceIoControl`, SMEP bypass, reflective unsigned driver loading, registry callbacks, COM |
| Flare-On 8, 2021, `evil` | [Official challenge 9 solution PDF](https://services.google.com/fh/files/misc/challenge-9-evil-en.pdf) | [rainbowpigeon writeup](https://rainbowpigeon.me/posts/flare-on-8-2021/challenge-9-evil/), [d0minik writeup](https://d0minik.me/posts/flare-on-8-9/), [hasherezade writeup](https://hshrzd.wordpress.com/2021/10/23/flare-on-8-task-9/) | VEH/SEH ordering, x86 TEB/SEH state, exception-driven control flow, API hashing, anti-disassembly |
| Flare-On 10, 2023, `Mbransom` | [Official challenge 9 solution PDF](https://services.google.com/fh/files/misc/9-mbransom-flareon10.pdf) | [Mustafa Dur writeup](https://www.mustafadur.com/blog/flareon-2023/), [VNPT part 2](https://sec.vnpt.vn/2023/12/part-2-flare-on-10-write-up), [Joost Rijneveld notes](https://joostrijneveld.nl/posts/2023-11-13-write-ups-for-flare-on-10/) | MBR ransomware, real-mode boot code, Track 0 staging, partition-table state, BIOS disk reads, RC4/Blowfish routines |
| Flare-On 10, 2023, `HVM` | [Official challenge 12 solution PDF](https://services.google.com/fh/files/misc/12-hvm-flareon10.pdf) | [Joost Rijneveld writeup](https://joostrijneveld.nl/posts/2023-11-13-write-ups-for-flare-on-10/) | Windows Hypervisor Platform, guest physical memory, virtual CPU state, VM exits, port I/O exits, CPU mode transitions |
| Flare-On 11, 2024, `CATBERT Ransomware` | [Official challenge 10 solution PDF](https://services.google.com/fh/files/misc/flare-on11-challenge10-catbert-ransomware.pdf) | [Tien D. Phan writeup](https://blog.tiendphan.com/posts/flare-on-11-catbert-ransomware/), [0xdf writeup](https://0xdf.gitlab.io/flare-on-2024/catbert), [nullablevoidptr notes](https://nullablevoidptr.github.io/flareon-11/) | UEFI firmware triage, OVMF, EFI shell modification, UEFI PE extraction, boot services/runtime services, VM-based password checks |

## Reading Rules

- Treat official challenge PDFs as the source of record for what the challenge did.
- Treat community writeups as workflow examples: which breakpoint, view, script, or triage path helped.
- Do not upgrade a challenge technique into a claim about current Windows unless a current primary source supports it.
- Do not learn only the flag path. Extract the invariant: which Windows structure, boundary, extension point, or tool view mattered.
- Compare alternative writeups for method diversity. The best learning often comes from seeing one solver use crash/object state, another use Volatility/YARA/string pivots, another repair static analysis, and another hook or emulate runtime behavior.
- Preserve alternatives when they teach a different Windows view, not when they merely repeat the same final script.

## Flare-On 6 `help`: Memory Dump To Driver And WFP

The official solution frames `help` as a malware-analysis problem built from a crash dump, a PCAP, user-mode components, kernel-mode components, and shellcode. The initial triage shows the crash happened in the `System` process and that `man.sys` was on the stack. From there, the useful Windows lesson is not the flag. It is the method:

1. Use crash context first: bugcheck, exception record, context record, stack, current process, and suspicious return addresses.
2. Walk from stack evidence to kernel objects. A `DRIVER_OBJECT` gives useful ground truth such as `DriverStart`, `DriverSize`, `DriverInit`, `DriverName`, `DeviceObject`, and dispatch routines.
3. Dump driver memory even when normal file artifacts are missing. A wiped PE header is an obstacle, not an endpoint.
4. Rebuild enough PE structure for tooling, but keep the memory image as ground truth.
5. Treat `DeviceIoControl` as a protocol boundary. User mode sends IOCTLs; the I/O Manager delivers `IRP_MJ_DEVICE_CONTROL`; the driver decides what each code means.
6. Look for secondary drivers and extension points. In this case, IOCTL handling leads to drivers named like `FLARE_Loaded_%d`, and one of the loaded components is a Windows Filtering Platform callout driver.
7. Correlate PCAP data with driver state. The WFP component tracks ports and XOR keys, so traffic only becomes meaningful after driver memory and callout configuration are understood.

Alternative solving approaches worth preserving:

| Approach | Seen in | What it teaches |
|---|---|---|
| Crash-first WinDbg path | Official solution, XLOYE | Start from `!analyze -v`, context records, call stack, module ranges, `DRIVER_OBJECT`, and `DeviceIoControl` semantics. This is the cleanest Windows internals path. |
| Volatility/YARA/string pivot | Attify | Search memory for PDB paths, challenge strings, and module names, then use `yarascan`, process context, and `.writemem` to recover components that the initial module list does not explain. |
| Traffic/artifact-first pivot | hasherezade | Use decoded or partially understood streams to identify screenshots, keylogger data, and stolen files, then work backward to the DLL/driver state that explains the transform. |
| Object-namespace/protocol pivot | XLOYE | Follow names such as `\??\FLID`, driver dispatch routines, accepted IOCTL codes, and WFP rule tables to reconstruct the user/kernel protocol. |

The important point is that these routes converge from different evidence. A mature analyst should be able to start from a crash, a suspicious driver object, a PCAP stream, a memory string hit, or a device name and still build the same system model.

Key mechanisms to carry into the Windows docs:

| Mechanism | What the challenge teaches |
|---|---|
| `DRIVER_OBJECT` | The object is often more reliable than a friendly module list. Its start/size/init/dispatch fields can recover an otherwise hidden driver. |
| Object namespace | Names under `\Driver` and device symbolic links are investigation pivots. A user-visible `\\.\Name` path usually maps back to an NT device object. |
| IOCTLs | An IOCTL is an authenticated handle-based request plus driver-private command semantics, not just "calling kernel code." |
| IRPs | The I/O Manager normalizes user requests into IRPs and stack locations. Bugs and rootkit protocols often hide in dispatch functions. |
| WFP | Network inspection can live in supported filter/callout infrastructure. WFP callouts can classify, track, and modify stream data. |
| Memory forensics | Cross-view analysis beats one API list: stack, object namespace, driver objects, memory scans, loaded modules, PCAP, and plugin artifacts all matter. |

Freshness caveat: this is a Windows 7 SP1 x64-era challenge. The internals vocabulary remains valuable, but modern systems add stronger driver-signing policy, HVCI/VBS options, vulnerable-driver blocklists, ETW coverage, and EDR callback/filter inventory.

## Flare-On 8 `evil`: Exceptions As The Dispatcher

The official `evil` solution describes a 32-bit Windows binary whose API calls are hidden behind exception-driven patching and resolution. Community writeups show the practical workflow: invalid instructions and deliberate faults are not dead ends; they are part of the dispatcher.

What matters:

- VEH runs before traditional stack-based SEH. `AddVectoredExceptionHandler` can register a process-wide handler that receives exceptions before normal SEH frames are consulted.
- On x86, SEH state is historically reachable through thread state in the TEB/TIB path. That is useful for reversing old 32-bit protectors, but it is not the x64 exception model.
- The challenge uses faults and invalid byte patterns to defeat linear disassembly. The exception handler resolves APIs by hash and patches nearby bytes so the intended call can proceed.
- Static imports are intentionally misleading. Recovering the API set requires reconstructing the hash algorithm, enumerating exports, and naming calls after resolution.
- Breakpoints on `AddVectoredExceptionHandler`, exception dispatch, and suspicious fault sites are often more useful than breaking on `main`.

Alternative solving approaches worth preserving:

| Approach | Seen in | What it teaches |
|---|---|---|
| Handler-registration breakpoint | d0minik | Break on `AddVectoredExceptionHandler`, recover the handler address, and inspect how the exception context supplies API-hash arguments. This is the fastest way to find the real dispatcher. |
| Exception-dispatch trace and dump | hasherezade | Trace `KiUserExceptionDispatcher`, observe where exceptions become API calls, let the sample patch itself, then dump the cleaner memory image for static analysis. |
| Rewrite or hook the handler | hasherezade | Replace the original VEH logic with an analyst-controlled version that writes aligned instructions. This turns anti-disassembly into a code-normalization pass. |
| Static patch-and-enumerate path | Official solution, community scripts | NOP known exception-generating byte sequences and rebuild API-hash enums/import knowledge. This is slower but useful when dynamic execution is unreliable. |

The creative lesson is to change levels when the binary lies. If static CFG fails, observe exception registration. If runtime flow is too noisy, rewrite the handler. If APIs are hashed, generate names from exports. If only executed branches are cleaned, drive more inputs or finish remaining branches manually.

Key mechanisms to carry into the Windows docs:

| Mechanism | What the challenge teaches |
|---|---|
| VEH vs SEH | VEH is process-wide and precedes SEH dispatch. SEH is stack/function-frame oriented and differs strongly between x86 and x64. |
| `KiUserExceptionDispatcher` path | User-mode exception dispatch is observable and can be instrumented. A high exception rate can be deliberate control flow, not only a crash loop. |
| TEB | Thread-local exception and stack state makes the TEB important to debuggers, runtimes, and malware. |
| API hashing | Sparse imports are not enough. Hash-based export walking moves the import table into runtime logic. |
| Anti-disassembly | Invalid opcodes, divide-by-zero, null dereferences, and patched calls can make static CFGs lie until exception flow is modeled. |

Freshness caveat: the challenge is x86. For modern x64 Windows, tie the lesson to unwind metadata, `.pdata`, runtime function tables, and dynamic function-table registration rather than assuming old x86 SEH-chain behavior.

## Flare-On 10 `HVM`: Windows Hypervisor Platform As The Runtime

`HVM` should not be described vaguely as "probably VBS/HVCI." The official solution is more precise: the Windows x64 host executable imports Windows Hypervisor Platform APIs from `WinHvPlatform.dll`, creates a VM, maps memory into guest physical address space, and runs a small guest payload.

Important low-level observations:

- The guest payload starts like real x86 code: 16-bit reset-style startup, GDT setup, CR0 protected-mode transition, far jumps, then 32-bit and 64-bit execution.
- Windows Hypervisor Platform exposes APIs for partitions, guest physical memory mappings, virtual processors, register state, and exit handling to a user-mode virtualization stack.
- `WHvRunVirtualProcessor` returns when guest execution hits something the user-mode virtualization stack must handle, such as I/O port access, unmapped memory access, MSR access, CPUID, or exceptions.
- The challenge uses `IN`/`OUT` port I/O as a host/guest communication channel. Those instructions trigger VM exits, and the host-side handler reads virtual CPU registers and decrypts or re-encrypts transient guest code.
- The command-line inputs are copied into fixed guest memory locations. Solving requires mapping host-visible buffers, guest physical addresses, guest virtual addresses, and register state.

Alternative solving approaches worth preserving:

| Approach | Seen in | What it teaches |
|---|---|---|
| Dynamic WHP exit-loop path | Official solution | Run with Hyper-V/WHP available, break around `WHvRunVirtualProcessor`, inspect `WHV_RUN_VP_EXIT_CONTEXT`, read vCPU registers, and dump code at `IN`/`OUT` exit boundaries. |
| Static resource-decryption path | Joost Rijneveld | Export the resource, pattern-match `mov r8, key; mov r9d, len; in/out` markers, RC4-decrypt fragments, and NOP the markers to recover analyzable guest code without needing WHP to run. |
| CPU-mode reconstruction path | Official solution | Treat the blob as boot-like code: 16-bit startup, GDT setup, CR0 protected mode, far jumps, 32-bit setup, then 64-bit code. This teaches why disassembler mode selection matters. |
| Emulation/math path | Joost Rijneveld | Use emulation to validate small guest routines or crypto behavior, then invert the Salsa20/Feistel-like check in normal scripting instead of repeatedly driving the full VM. |

The creative lesson is that a hypervisor-backed challenge can be attacked at several layers: the Windows host API, the VM-exit protocol, the guest code image, the CPU mode transitions, or the final algorithm. The Windows-internals value is strongest when you can name which layer your shortcut bypasses.

Key mechanisms to carry into the Windows docs:

| Mechanism | What the challenge teaches |
|---|---|
| WHP/WHPX-style API | A normal user-mode process can be a virtualization stack when Windows Hypervisor Platform is available. |
| Guest physical memory | Host virtual memory backs guest physical address ranges. Analysts must track host VA, GPA, and guest VA separately. |
| Virtual CPU state | Registers, control registers, segment state, and CPU mode are part of the program state, not side details. |
| VM exits | VM exits are a boundary protocol. In `HVM`, port I/O exits play the same analytical role that syscalls or IOCTLs often play elsewhere: they reveal the contract between layers. |
| Transient code | Code may be decrypted only between two exit points. Dumping at process end can miss the useful state. |
| VBS/HVCI caveat | WHP knowledge helps understand Hyper-V-backed security, but this challenge does not prove a VBS or HVCI bypass technique. Keep the layers separate. |

Freshness caveat: Windows Hypervisor Platform is current enough to matter, but `HVM` is a challenge-sized VM, not the full Hyper-V/VBS security architecture. Use Microsoft's WHP documentation for the API contract and separate docs for VBS/HVCI.

## Flare-On 7 `crackinstaller`: BYOVD To Registry Callback

This is the most important missing ring-escalation case. The official solution explicitly combines COM, pre-`main` execution, kernel exploitation, registry filtering, a signed driver SMEP bypass, reflective loading of an unsigned driver, registry callbacks, and direct system-call style thinking. Treat it as a compact model of how many Windows layers can be chained:

1. Do not start at `main` only. The interesting driver path begins from a CRT/global initializer before normal application logic.
2. The user-mode installer drops a COM server and a signed Capcom-style driver, then opens the driver's device and sends an IOCTL with `DeviceIoControl`.
3. The signed driver disables SMEP and executes a user-supplied buffer at CPL0. The important boundary is the device handle plus IOCTL contract, not a normal imported kernel function.
4. Kernel bootstrap code resolves kernel exports, finds `ntoskrnl.exe`, creates a system thread, and reflectively maps an embedded unsigned driver.
5. The unsigned driver calls `IoCreateDriver`, creates device/extension state, assigns unload state, and registers a registry callback with `CmRegisterCallbackEx`.
6. The registry callback handles pre-create notifications for the COM server's registry path and stores a hidden password in the registry key class string.
7. The COM server later reads registry state and decrypts the flag. Solving can therefore happen from either the kernel path or the COM/registry path.

Alternative solving approaches worth preserving:

| Approach | Seen in | What it teaches |
|---|---|---|
| Official full-chain path | Official solution | Model the whole chain: global initializer, COM registration, Capcom driver, SMEP toggle, reflective unsigned driver, registry callback, class-string storage. |
| Kernel-breakpoint path | explained.re | Identify the Capcom IOCTL, break in the driver dispatch path, observe `PsCreateSystemThread`, then follow the unsigned driver's registry callback registration. |
| Static driver extraction path | xEHLE, Starfleet Cadet | Decrypt/decompress embedded drivers, recover Capcom and `driver.sys`, and analyze registry callback logic without relying on the entire installer running cleanly. |
| COM-first path | Official solution, explained.re | Recover the dropped COM server, understand `DllRegisterServer`/`DllGetClassObject`, and decide what registry values/class strings the COM object expects. |

Key mechanisms to carry into the Windows docs:

| Mechanism | What the challenge teaches |
|---|---|
| BYOVD | A legitimately signed but vulnerable driver can become the kernel execution primitive. Modern analysis must include blocklists, WDAC/HVCI state, load events, and the exact driver version. |
| SMEP | SMEP is a CPU/kernel mitigation boundary. A driver that toggles CR4 and executes user pages is a serious trust failure, not just "calling kernel shellcode." |
| IOCTL dispatch | The attack crosses a normal Windows device boundary: open a device, send an IOCTL, trust or reject buffers. IOCTL validation is security-critical. |
| Reflective kernel loading | A driver can be mapped without the normal SCM-backed driver lifetime and registry path. This changes unload, telemetry, and object discovery assumptions. |
| Registry callbacks | `CmRegisterCallbackEx` is a legitimate kernel extension point. It can observe, block, or modify registry operations before the Configuration Manager completes them. |
| Registry class strings | Rare fields can hold meaningful state. Regedit-style views may hide data that `RegQueryInfoKey`-style APIs can expose. |
| COM | COM activation is registry-backed and interface/vtable-driven. Kernel registry filtering can change what the COM layer sees. |

Freshness caveat: the Capcom driver technique is old and widely known. On current Windows, driver-signing policy, Microsoft vulnerable-driver blocklists, WDAC, HVCI, EDR kernel telemetry, and vendor-specific protections can prevent or expose the exact flow. Keep the invariant, not the old exploit recipe: signed kernel code plus weak IOCTL plus bad privilege boundary.

## Flare-On 5 `golf`: Ring -1 Hypervisor Driver

`golf` is the high-value ring -1 case. It is not a Windows security feature exercise like VBS, and it is not Windows Hypervisor Platform like `HVM`. It is a Windows executable that extracts and loads a driver, then relies on Intel VT-x behavior and `vmcall` as the guest-to-hypervisor boundary.

What matters:

- The host executable creates driver service state and calls `ZwLoadDriver`/service-style driver loading paths. Driver load failures are part of the analysis because VMX may be unavailable inside an ordinary VM.
- A copied RWX stub contains `vmcall`, which is an immediate hint that execution depends on a VMM/hypervisor component.
- The driver checks VMX capability through CPUID state. Nested virtualization settings can decide whether the challenge even reaches the interesting code.
- Once the hypervisor is active, `vmcall` becomes a boundary protocol like a syscall or IOCTL: the caller supplies state, the VMM handles a VM exit, and execution resumes with modified state.
- The useful lesson is how a thin hypervisor can sit below the OS and mediate execution without looking like a normal kernel hook.

Alternative solving approaches worth preserving:

| Approach | Seen in | What it teaches |
|---|---|---|
| Driver-load and VMX-capability path | Official solution | Use driver load status, kernel debugging, CPUID/VMX checks, and nested virtualization settings to get the environment into the right state. |
| `vmcall` triage path | Official solution, HackMD | Treat `vmcall` as a boundary marker. The instruction tells you that user-visible control flow is incomplete without the driver/VMM side. |
| Operational lab path | Attify | Test-signing, driver setup, and virtualization environment details are part of reverse engineering kernel/hypervisor samples, not just setup noise. |

Key mechanisms to carry into the Windows docs:

| Mechanism | What the challenge teaches |
|---|---|
| Driver loading | Kernel code still enters through concrete service/driver-load mechanisms unless it is already resident or reflectively mapped. |
| VMX root/non-root | Ring -1 analysis needs CPU state and VMCS/VM-exit thinking, not only Windows kernel structures. |
| VM exits | A hypervisor rootkit can make selected instructions into callbacks into the VMM. |
| Lab realism | Hypervisor analysis depends heavily on nested virtualization support, test-signing policy, and debugger placement. |
| VBS caveat | Knowing VT-x helps with VBS/HVCI concepts, but `golf` is a custom challenge hypervisor, not evidence about current VBS implementation or bypasses. |

Freshness caveat: `golf` is from 2018 and uses challenge-specific code. Use it to learn VMX and hypervisor-rootkit mental models. Use current Intel/AMD manuals and current Microsoft VBS/HVCI docs for modern platform behavior.

## Bootkit And Firmware Cases: `doogie.bin`, `Suspicious Floppy Disk`, `Mbransom`, `CATBERT`

These cases belong together because they force you below the normal Windows kernel model. They are still relevant to Windows and Linux understanding because boot trust, disk layout, firmware execution, and pre-OS persistence are shared platform problems.

| Challenge | What to extract | Mechanism lesson |
|---|---|---|
| `doogie.bin` | Boot sector plus supporting sectors, loaded as 16-bit code. The official path uses BIOS `INT 13h` extended-read semantics and a Disk Address Packet to read seven sectors to `0x8000`, then rebases analysis there. | First learn how to load and rebase boot code correctly. Mis-set disassembler mode or base address makes every later conclusion shaky. |
| `Suspicious Floppy Disk` | A crafted boot sector loads the original boot sector, hooks the interrupt vector table entry for `INT 13h`, preserves the original handler elsewhere, and intercepts sector reads/writes that DOS programs appear to perform normally. | A bootkit can lie below the filesystem. If `infohelp.exe` looks harmless outside the image, the behavior may live in BIOS interrupt hooks or hidden sectors. |
| `Mbransom` | The MBR is rewritten, relocates itself from `0x7C00` to `0x0600`, checks partition state, loads the rest of Track 0 into `0x1000`, RC4-deobfuscates the decryption program, and uses real-mode code to drive the ransomware flow. | MBR malware abuses unallocated Track 0 space, partition-table state, and BIOS disk services. The disk image is the program. |
| `CATBERT Ransomware` | A provided `bios.bin` is an OVMF UEFI firmware image and `disk.img` is FAT12. The modified EFI shell exposes `decrypt_file`; shell extraction with UEFITool reveals a UEFI PE that parses C4TB files and interprets VM bytecode for password checks. | UEFI analysis is PE analysis before the OS: firmware volumes, EFI modules, `EFI_SYSTEM_TABLE`, boot services, runtime services, and shell commands are the operating environment. |

Alternative solving approaches worth preserving:

| Approach | Seen in | What it teaches |
|---|---|---|
| 16-bit boot-sector rebase | Official `doogie.bin`, official `Mbransom` | Use the correct CPU mode and load address, then rebase once the boot code copies itself or loads the next stage. |
| Bochs/QEMU/gdb path | Official `Suspicious Floppy Disk`, Mustafa, 0xdf | Boot code and UEFI code are often easier to understand when you can single-step the emulator at the real execution boundary. |
| Interrupt-hook differential path | HackMD `Suspicious Floppy Disk` | Compare behavior inside the boot image to extracted DOS files. If the extracted program loses behavior, suspect a lower layer such as `INT 13h`. |
| Unicorn/scripted emulation path | Mustafa, VNPT, community scripts | Emulate only the key-check or disk-decryption routine when full-system boot debugging is too slow. |
| Firmware extraction path | Official `CATBERT`, Tien D. Phan, 0xdf | Use firmware-volume tools to extract PE32 modules, then use ordinary PE reversing plus EFI-specific structure knowledge. |
| Bytecode/VM decompiler path | Official `CATBERT`, Tien D. Phan, 0xdf | Once firmware code delegates validation to bytecode, build an emulator/disassembler for that VM instead of repeatedly driving the firmware UI. |

Key mechanisms to carry into the Windows docs:

| Mechanism | What the challenges teach |
|---|---|
| `0x7C00` and relocation | BIOS loads the first sector to a conventional address, but real boot code often copies itself elsewhere before loading later stages. |
| BIOS `INT 13h` | Disk I/O before protected OS drivers is interrupt-driven. Hooking the interrupt vector table can hide or rewrite sector behavior. |
| Sector/track layout | CHS/LBA, Track 0, partition entries, VBR handoff, and FAT12 layout become security-relevant when the disk itself carries code. |
| Real mode | Segment:offset addressing, 16-bit disassembly, BIOS services, and tiny memory layouts are not optional details for MBR analysis. |
| UEFI firmware volumes | UEFI boot components are structured firmware files and PE modules, not raw BIOS-era sectors. |
| EFI services | `EFI_SYSTEM_TABLE`, boot services, runtime services, file protocols, and shell command registration replace Win32/kernel APIs in firmware space. |
| Boot trust | Secure Boot, measured boot, TPM sealing, ELAM, and driver signing should be understood as responses to this class of pre-OS tampering. |

Freshness caveat: BIOS MBR bootkits are legacy-style examples. They are still excellent for learning disk/boot mechanics, but current Windows machines usually boot through UEFI with Secure Boot, TPM-backed measured boot, BitLocker sealing, ELAM, and modern recovery flows. `CATBERT` is newer and UEFI-shaped, but it is a challenge firmware image, not a current real-world UEFI malware family.

## Cross-Case Heuristics

| If you see... | Ask this Windows-internals question |
|---|---|
| A crash dump plus PCAP | Which kernel object, driver, or callback explains the network transform? |
| A missing module in friendly lists | What do memory scans, VADs, driver objects, section objects, and stack frames show? |
| A signed old driver plus a suspicious IOCTL | Is this a BYOVD path, and what does the device dispatch routine do with user buffers and CPU/kernel mitigations? |
| A pre-`main` initializer | What code ran before the debugger's comfortable entry point, and did it create services, drivers, COM state, callbacks, or hidden registry data? |
| Sparse imports | Is the program using loader APIs, PEB walking, export parsing, API hashing, or direct syscalls? |
| Many deliberate exceptions | Is exception dispatch the actual control-flow graph? Which VEH/SEH/unwind path applies? |
| A `vmcall` instruction plus a driver | Is a custom hypervisor mediating execution, and which VM exits form the protocol? |
| A user-mode process importing `WinHvPlatform.dll` | Is it hosting guest code, and where are GPA mappings, vCPU registers, and exit handlers? |
| A boot sector, MBR, or floppy image | What is the CPU mode, load address, sector layout, `INT 13h` behavior, and next-stage handoff? |
| A UEFI firmware image | Which firmware volume contains the modified PE module, and which EFI services/protocols replace normal OS APIs? |
| Network traffic that decrypts only after memory work | Which runtime table, callback list, or driver-owned state carries the keys or transform? |

## Connections To The Rest Of The Docs

- [Source-enriched Windows mechanisms](<06-source-enriched-windows-mechanisms.md>): use `help` for I/O Manager, drivers, WFP, and memory forensics; use `crackinstaller` for BYOVD, registry callbacks, and COM; use `evil` for exception dispatch and API resolution; use `golf` and `HVM` for hypervisor/runtime boundary thinking; use the bootkit/firmware cases for boot trust.
- [Windows deep-understanding question bank](<../02-question-banks/02-windows-deep-understanding-qa.md>): these challenges provide concrete cases for exceptions, memory forensics, minifilters/WFP, kernel mitigations, code integrity, boot trust, and Hyper-V/VBS questions.
- [Digital Whisper issues 134-185 internals map](<../05-topic-notes/digital-whisper-134-185-internals-map.md>): use the Hebrew Flare-On 2021/2024 articles as extra walkthrough practice, but prefer official solution PDFs for exact challenge mechanics.

## Primary Reference Links

- Official 2018 Flare-On solutions index: https://cloud.google.com/blog/topics/threat-intelligence/2018-flare-on-challenge-solutions/
- Official 2019 Flare-On solutions index: https://cloud.google.com/blog/topics/threat-intelligence/2019-flare-on-challenge-solutions/
- Official 2020 Flare-On 7 solutions index: https://cloud.google.com/blog/topics/threat-intelligence/flare-7-challenge-solutions
- Official 2021 Flare-On 8 solutions index: https://cloud.google.com/blog/topics/threat-intelligence/flare-on-8-challenge-solutions/
- Official 2023 Flare-On 10 solutions index: https://cloud.google.com/blog/topics/threat-intelligence/flareon10-challenge-solutions/
- Official 2024 Flare-On 11 solutions index: https://cloud.google.com/blog/topics/threat-intelligence/flareon-11-challenge-solutions
- Microsoft Windows Hypervisor Platform API: https://learn.microsoft.com/en-us/virtualization/api/hypervisor-platform/hypervisor-platform
- Microsoft `AddVectoredExceptionHandler`: https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-addvectoredexceptionhandler
- Microsoft `CmRegisterCallbackEx`: https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-cmregistercallbackex
- Microsoft `FwpsCalloutRegister0`: https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/fwpsk/nf-fwpsk-fwpscalloutregister0
- Microsoft `FwpmFilterAdd0`: https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/fwpmk/nf-fwpmk-fwpmfilteradd0
