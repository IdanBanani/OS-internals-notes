# Journey PDF Source Map

Value Score: 70/100
Role: Journey PDF source route
Proof Level: Source-map

Date: 2026-05-16

Purpose: map the companion Journey PDFs into the existing study path. Treat these files as curated concept bridges, review tracks, and workbook-style drill material. They should not replace current kernel documentation, target source trees, Microsoft Learn, symbols, or build-specific debugger validation.

## How To Use These References

- Use the concept journeys before a topic feels fragmented across many notes.
- Use the security journeys after you understand the base OS object model.
- Use the workbooks for active recall after reading the scored question banks.
- Use the forensic journey when a topic needs observable artifacts rather than only mechanism theory.
- Keep freshness in mind: Linux kernel, Android, and Windows details can change by version, configuration, build, and vendor policy.

## Source Inventory

| Code | Reference | Best use | Existing docs to read beside it |
|---|---|---|---|
| J-AND-CONCEPT | TheAndroidConceptJourney_v1_May2025 (1).pdf | Android system model: Zygote, Binder, ART, app sandbox, SELinux, native/runtime boundary, mobile memory pressure. | [Android internals](<../03-linux/04-android-internals.md>), [Linux deep-understanding Q&A](<../02-question-banks/01-linux-deep-understanding-qa.md>) |
| J-LIN-CONCEPT | TheLinuxConceptJourney_v5_April2025.pdf | Broad Linux concept review across processes, syscalls, memory, files, networking, and kernel boundaries. | [Linux project README](<../03-linux/README.md>), [Linux source map](<../03-linux/source-map.md>) |
| DSJ | TheLinuxKernelDataStructuresJourney_v2.0_April2024.pdf | Structure-reading support for `task_struct`, lists, trees, maps, object relationships, and kernel container idioms. | [Linux source map](<../03-linux/source-map.md>), [Linux vs Windows internals](<../01-comparisons-and-maps/01-linux-vs-windows-internals.md>) |
| MACROJ | TheLinuxKernelMacroJourney_v1_Aug2024.pdf | Macro and container idioms that make kernel source readable: `container_of`, lists, generated helpers, compile-time annotations. | [Linux source map](<../03-linux/source-map.md>), [Veteran interview FAQ](<../03-linux/06-veteran-interview-faq.md>) |
| J-LIN-SEC | TheLinuxSecurityJourney_v3_April2025.pdf | Linux security model review: credentials, capabilities, namespaces, seccomp, LSMs, eBPF/security hooks, and hardening vocabulary. | [Linux deep-understanding Q&A](<../02-question-banks/01-linux-deep-understanding-qa.md>), [low-level security component map](<../01-comparisons-and-maps/02-low-level-security-component-map.md>) |
| J-LIN-SEC-WB | TheLinuxSecurityJourneyWorkbook_v1_June2025.pdf | Active recall after Linux security reading. Use to turn passive reading into answer practice. | [Linux deep-understanding Q&A](<../02-question-banks/01-linux-deep-understanding-qa.md>) |
| J-NET | TheNetworkingJourney_v2_May2025.pdf | Networking concept bridge for packet flow, sockets, routing, filtering, DNS/TLS, and observability vocabulary. | [Memory, filesystems, and network Q&A](<../02-question-banks/03-memory-filesystems-network-qa.md>) |
| J-WIN-CONCEPT | TheWindowsConceptJourney_v6_March2025.pdf | Broad Windows concept review: architecture, objects, handles, processes, threads, memory, I/O, registry, and services. | [Windows long-term mastery roadmap](<../04-windows/01-windows-long-term-mastery-roadmap.md>), [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>) |
| J-WIN-FORENSICS | TheWindowsForensicJourney_v2_April2025.pdf | Evidence-oriented Windows review: artifacts, Event Log/ETW style thinking, process/file/network/registry triage, and memory-forensics vocabulary. | [Windows deep-understanding Q&A](<../02-question-banks/02-windows-deep-understanding-qa.md>), [Attacker-relevant structures](<attacker-relevant-structures-and-components.md>) |
| J-WIN-SEC | TheWindowsSecurityJourney_v6_Jan2025.pdf | Windows security review: tokens, SIDs, privileges, access checks, authentication, credential boundaries, hardening, and defensive surfaces. | [Windows deep-understanding Q&A](<../02-question-banks/02-windows-deep-understanding-qa.md>), [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>) |
| J-WIN-SEC-WB | TheWindowsSecurityJourneyWorkbook_v1_June2025.pdf | Active recall after Windows security reading. Use beside the Windows question bank. | [Windows deep-understanding Q&A](<../02-question-banks/02-windows-deep-understanding-qa.md>) |

## Reading Placement

| Study moment | Journey files to use | What to extract |
|---|---|---|
| Before Linux Phase 1 | J-LIN-CONCEPT | One clean process/syscall/file/memory vocabulary pass before deeper source-map work. |
| Before Linux Phase 2 | DSJ, MACROJ | Kernel source-reading vocabulary for embedded lists, container structures, macros, and object relationships. |
| After Linux security notes | J-LIN-SEC, J-LIN-SEC-WB | Security-boundary answers: `cred`, capabilities, namespaces, cgroups, seccomp, LSM, BPF, lockdown, module signing. |
| Android review | J-AND-CONCEPT | Android-specific layers above Linux: Zygote, Binder, ART, SELinux, app UID sandboxing, low-memory policy. |
| Network weak spot | J-NET | Vocabulary and packet-flow review before answering network receive path, socket state, and filtering questions. |
| Before Windows Module 1 | J-WIN-CONCEPT | Windows object/handle/process/thread/memory/I/O vocabulary before Native API and debugger-heavy notes. |
| After Windows security notes | J-WIN-SEC, J-WIN-SEC-WB | Token/access-check/authentication/credential-boundary recall drills. |
| Before Windows telemetry/forensics questions | J-WIN-FORENSICS | Evidence vocabulary: event, artifact, handle, file, registry, network, memory, and timeline correlation. |

## Freshness Rules

| Topic | Treat Journey PDFs as | Verify against |
|---|---|---|
| Linux kernel mechanisms | Concept bridge and source-reading support | Target kernel source, docs.kernel.org, target config, and symbols/debug data |
| Linux security and eBPF | Security vocabulary and review material | Current kernel docs, distro config, LSM/capability/seccomp settings, and BPF privilege policy |
| Android internals | Android architecture review | AOSP version, device vendor kernel, SELinux policy, API level, and monthly security bulletin context |
| Windows mechanisms | Concept bridge and study support | Windows build, public symbols, Microsoft Learn, WinDbg, Sysinternals, and observed ETW/Event Log data |
| Windows security and forensics | Security/forensic vocabulary and drill material | Current Defender/VBS/HVCI/Credential Guard/PPL policy, event providers, and endpoint configuration |
| Networking | Cross-platform concept bridge | OS-specific stack documentation, firewall/filtering policy, packet captures, and driver/offload configuration |
