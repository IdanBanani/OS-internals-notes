# Windows IPC Named Pipes, RPC, ALPC, And Security

Value Score: 88/100
Role: Windows IPC owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-18

Scope: security-relevant Windows IPC lessons from the Csandker Offensive Windows IPC series, focused on named pipes, RPC, ALPC, impersonation, endpoint naming, endpoint discovery, and message/resource lifetime. This is an internals note, not an exploitation playbook.

Primary source anchors:

- Csandker originals and AQWU mirrors/translations: [Named Pipes original](https://csandker.io/2021/01/10/Offensive-Windows-IPC-1-NamedPipes.html) / [AQWU mirror](https://www.aqwu.net/wp/?p=177), [RPC original](https://csandker.io/2021/02/21/Offensive-Windows-IPC-2-RPC.html) / [AQWU mirror](https://www.aqwu.net/wp/?p=179), and [ALPC original](https://csandker.io/2022/05/24/Offensive-Windows-IPC-3-ALPC.html) / [AQWU mirror](https://www.aqwu.net/wp/?p=175).
- Microsoft Learn: [Pipes](https://learn.microsoft.com/en-us/windows/win32/ipc/pipes), [`CreateNamedPipe`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createnamedpipew), [`ImpersonateNamedPipeClient`](https://learn.microsoft.com/en-us/windows/win32/api/namedpipeapi/nf-namedpipeapi-impersonatenamedpipeclient), [client impersonation](https://learn.microsoft.com/en-us/windows/win32/secauthz/client-impersonation), [RPC overview](https://learn.microsoft.com/en-us/windows/win32/rpc/rpc-start-page), [`RpcServerRegisterIf2`](https://learn.microsoft.com/en-us/windows/win32/api/rpcdce/nf-rpcdce-rpcserverregisterif2), [`RpcBindingSetAuthInfoEx`](https://learn.microsoft.com/en-us/windows/win32/api/rpcdce/nf-rpcdce-rpcbindingsetauthinfoexw), [`RpcImpersonateClient`](https://learn.microsoft.com/en-us/windows/win32/api/rpcdce/nf-rpcdce-rpcimpersonateclient), [protocol sequence constants](https://learn.microsoft.com/en-us/windows/win32/rpc/protocol-sequence-constants), and [ETW ALPC events](https://learn.microsoft.com/en-us/windows/win32/etw/alpc).
- Local companions: [Windows deep-understanding Q&A](<../02-question-banks/02-windows-deep-understanding-qa.md>), [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>), [Remote-attacker low-level mechanisms](<remote-attacker-low-level-mechanisms.md>), and [Windows object handles, references, and tokens](<windows-object-handles-references-and-tokens.md>).

## Offensive Priority Index

| Score | Section | Why it matters |
|---:|---|---|
| 100 | Core IPC lesson; named pipes; named-pipe name races | Pipe endpoints are file-like authority boundaries; DACLs, SQOS, and name ownership decide many service bugs. |
| 100 | RPC; RPC impersonation failure | RPC binding/auth/QoS and failed impersonation are high-value confused-deputy patterns for service boundaries. |
| 99 | ALPC; ALPC resource-lifetime bugs | ALPC can transfer handles, views, security context, and message attributes; lifetime bugs affect broker boundaries. |
| 97 | RPC discovery and reverse engineering; IPC triage checklist | Useful for auditing and reversing reachable services after the core authority model is clear. |
| 95 | Windows 11 relevance; active recall | Use to avoid stale conclusions and to test whether the invariant survived build-specific changes. |

## Windows 11 Relevance

Short answer: yes, the lessons are still useful for Windows 11, but only at the mechanism/invariant level. Do not treat every structure field, private flag, default ACL, target list, or exploitability claim from a 2021-2022 post as current without checking the exact Windows 11 build.

Still relevant on Windows 11:

- Named pipes are still a core Windows IPC mechanism reached through file-style APIs and protected by endpoint security descriptors.
- RPC still uses protocol sequences, bindings, IDL/NDR marshalling, endpoint mapper behavior, interface registration flags, authentication settings, and optional server callbacks.
- `RpcServerRegisterAuthInfo` is still not enough by itself to prove that unauthenticated clients cannot reach an interface; current Microsoft documentation for `RpcServerRegisterIf2` still says security is optional by default and points to callbacks or `RPC_IF_ALLOW_SECURE_ONLY`.
- `RpcImpersonateClient` still has the same security invariant: if impersonation fails and a privileged server continues, the request runs in the server process security context. Microsoft still documents that as a security warning.
- ALPC still exists as the local IPC substrate for many Windows components, and Microsoft still exposes ALPC ETW event classes for send/receive/wait-style events.
- The design questions remain stable: who owns the endpoint, who can connect, what identity is in effect, what impersonation level was allowed, what resources were transferred, and who cleans them up?

Must be revalidated on Windows 11:

- Private ALPC structures, message-attribute details, object layouts, handle-table layouts, and debugger extension output.
- Built-in service endpoint names, pipe/ALPC/RPC DACLs, endpoint mapper visibility, and default security descriptors.
- Whether a specific pipe-name race, unanswered connection, impersonation chain, or ALPC resource leak is reachable in a modern service.
- Effects of Windows 11 hardening such as service isolation, AppContainer/broker design, PPL, firewall policy, NTLM restrictions, SMB signing/channel policy, Credential Guard/VBS, and endpoint-product callbacks.
- Tool output from WinObj, Process Explorer, WinDbg, Procmon, ETW, NtApiDotNet, RPCDump, or PortQry. Use tools as evidence, not as proof that the old blog screenshot still matches.

So the markdowns should preserve these posts as mechanism lessons, not as version-frozen exploitation recipes. The correct Windows 11 use is: learn the invariant from the post, then verify the concrete endpoint, token, QoS, DACL, ETW event, handle, and cleanup behavior on the target build.

## Core IPC Lesson

Do not classify Windows IPC by API name only. Classify it by:

1. the endpoint object or name;
2. the transport below the friendly API;
3. the security descriptor or registration policy on the endpoint;
4. the client token, impersonation level, and QoS;
5. the parser or marshalling layer;
6. the resources transferred with the message, such as handles or mapped views;
7. the evidence source: handles, object namespace, ETW, endpoint mapper, network capture, or process imports.

The repeated pattern across named pipes, RPC, and ALPC is that the IPC endpoint is both a communication channel and an authority boundary. Bugs usually come from name confusion, overly permissive endpoint access, accidental remote exposure, impersonation defaults, unchecked impersonation failure, parser/marshalling bugs, or resource lifetime mistakes.

## Named Pipes

Named pipes are file-like IPC objects managed by NPFS. User mode reaches them through familiar file APIs such as `CreateFile`, `ReadFile`, and `WriteFile`, but the target is a pipe `FILE_OBJECT`, not an on-disk file.

Security-relevant mechanics:

| Mechanism | Lesson |
|---|---|
| Path form | `\\.\pipe\name` is local. `\\host\pipe\name` uses SMB transport. `\\127.0.0.1\pipe\name` can force a remote-style path to the same host. |
| Security descriptor | `lpSecurityAttributes` on `CreateNamedPipe` is the main endpoint access control. A default descriptor may be much broader than intended, especially for read access. |
| Message vs byte mode | Message mode preserves message boundaries and can return `ERROR_MORE_DATA` when the read buffer is too small. Byte mode is stream-like and needs explicit framing by the protocol. |
| Overlapped and blocking mode | Blocking behavior and async completion shape deadlocks, cancellation, threadpool behavior, and denial-of-service risk. |
| Pipe buffers | Named-pipe buffers consume nonpaged memory while data is queued. User-controlled buffer sizes or traffic patterns can become resource-pressure issues. |
| `PeekNamedPipe` | Read-like inspection can observe queued data without consuming it if the DACL allows the caller to connect/read. |

Pipe impersonation is the major authority-transfer concept. When a pipe server impersonates a client, the server thread acts under the client's token until it reverts. That is legitimate for access-on-behalf-of-client designs, but it is dangerous when either side did not intend that identity relationship.

Client-side hardening rule:

```text
If a client opens a pipe path controlled by someone else, explicitly set SQOS.
```

For remote-style pipe paths, do not rely on vague defaults. Use `SECURITY_SQOS_PRESENT` with `SECURITY_IDENTIFICATION` or `SECURITY_ANONYMOUS` when the server should not impersonate the client. Remember that connecting to `\\127.0.0.1\pipe\...` is still a remote-style path from the pipe semantics perspective.

Server-side hardening rules:

- Set a deliberate DACL on every sensitive pipe.
- Use `FILE_FLAG_FIRST_PIPE_INSTANCE` when the service must own the first pipe instance and should fail if another instance already exists.
- Keep `nMaxInstances` and buffer sizes intentional.
- Treat every client message as untrusted input, even when the client is local.
- Close unnecessary pipe handles so EOF, disconnect, and completion behavior are not hidden by extra references.

## Named Pipe Name Races

Named pipe names support multiple instances. Without the right flags, another process can create the same pipe name first or create another instance and wait for clients. This turns endpoint naming into a race surface.

The durable lesson is:

> A named endpoint is not only a communication address; it is a resource that can be squatted, raced, or confused unless creation semantics and DACLs make ownership explicit.

Defensive evidence:

- service startup order and pipe creation timing;
- pipe path and instance count;
- whether `FILE_FLAG_FIRST_PIPE_INSTANCE` was used;
- endpoint DACL;
- clients that repeatedly try missing pipe names;
- unexpected clients/server processes holding pipe handles.

## RPC

RPC adds a structured contract layer over transports. The visible RPC method call is backed by IDL, generated stubs, NDR marshalling/unmarshalling, binding handles, authentication settings, and protocol sequences.

Important protocol sequences:

| Protocol sequence | Transport meaning | Security implication |
|---|---|---|
| `ncalrpc` | Local RPC, implemented through ALPC on modern Windows. | Local service/broker boundary; still has impersonation and endpoint ACL concerns. |
| `ncacn_np` | Named-pipe transport over SMB. | Named pipe DACLs and SMB authentication behavior matter. |
| `ncacn_ip_tcp` | TCP transport. | Remote network exposure, endpoint mapper, firewall, authentication and relay/downgrade questions. |
| `ncacn_http` | RPC over HTTP proxy path. | Enterprise remote-management surface; policy and authentication details matter. |

RPC security is not one switch. The useful checklist is:

- Interface registration flags: for example local-only or secure-only behavior.
- Security callback: custom allow/deny logic for callers.
- Server authentication info: SPN/authentication service.
- Client binding authentication and QoS: authentication level, authentication service, impersonation level, and identity.
- Endpoint mapper visibility: dynamic endpoints must register; well-known endpoints may not appear there.

Two traps matter.

First, server-side `RpcServerRegisterAuthInfo` by itself does not force every client call to be authenticated. The server must register the interface with the right security flags and/or reject unauthenticated callers in a callback or method logic.

Second, RPC client impersonation is an opt-out-prone model if the client creates an authenticated binding without lowering the impersonation level. A client that does not want the server to impersonate it should set QoS explicitly rather than relying on defaults.

## RPC Impersonation Failure

The most important implementation lesson is not "RPC can impersonate clients"; it is "failed impersonation must be treated as an authorization failure."

If a privileged RPC server calls `RpcImpersonateClient` and does not check the return status, the following operation may run under the server's own token instead of the client's token. That creates a confused-deputy pattern:

```text
server intended: validate/action as client
buggy result: action continues as service/SYSTEM/server identity
```

Server-side rule:

- Check `RpcImpersonateClient` or pipe impersonation return values.
- If impersonation fails, fail the request.
- Always revert on all paths after successful impersonation.
- Do not cache "we are impersonating" in a boolean unless it is tied to actual API success and cleanup.

Client-side rule:

- Use binding/pipe QoS to set the maximum impersonation level the server can receive.
- Prefer identification or anonymous level when the server only needs to know who you are, not act as you.

## RPC Discovery And Reverse Engineering

Useful evidence sources:

| Evidence | What it tells you |
|---|---|
| Imports from `rpcrt4.dll` | Possible RPC server/client behavior, such as `RpcServerListen` or `RpcStringBindingCompose`. |
| Endpoint mapper | Registered dynamic RPC interfaces and endpoints. Absence does not mean absence of a well-known endpoint. |
| Network capture | DCE/RPC bind requests expose interface UUIDs and protocol behavior. |
| IDL/type library or generated stubs | Method numbers, parameter marshalling, and contract shape. COM/DCOM may expose type-library clues. |
| Runtime traces | Whether calls were anonymous/authenticated, local/remote, over named pipe/TCP/ALPC, and which service hosted the endpoint. |

The reverse-engineering lesson is to start from a known sample or recovered IDL-like structure, then map UUID/version/opnum/parameter shape to server routines. RPC vulnerabilities are often parser or authorization mistakes hiding behind generated marshalling code.

## ALPC

ALPC is the low-level local IPC facility behind many Windows services and local RPC paths. It is fast and widely used, but it is internal/undocumented enough that production designs should normally use documented layers such as RPC/COM/named pipes rather than direct ALPC.

Key model:

- Server creates a connection port.
- Client connects to that named port.
- The kernel creates communication ports for the established channel.
- Messages are sent through `NtAlpcSendWaitReceivePort`.
- The kernel mediates queues, message delivery, attributes, handle transfer, and section/view transfer.

ALPC messages are not just byte payloads. Message attributes can carry security context, handles, context information, and section-backed data views. That makes ALPC a high-value local boundary because a message can transfer authority and memory resources, not only text.

Important ALPC security lessons:

| Area | Lesson |
|---|---|
| Undocumented contract | Treat direct ALPC structure/layout knowledge as build-sensitive. Prefer documented wrappers unless you are reversing/debugging. |
| Port DACL and namespace | Named connection ports should be treated like sensitive named objects. Who can connect is the first boundary. |
| Impersonation | ALPC impersonation depends on QoS/flags and message security attributes; both sides can be potential impersonation targets in different flows. |
| Handle attributes | ALPC can transfer handles; receiving code must know what handle type/access it accepted and close/restrict what it does not need. |
| Data views | `ALPC_DATA_VIEW_ATTR` style transfers map section views into the receiver. The receiver must release/unmap views correctly. |
| Context attributes | Per-message/client context fields create lifetime and confusion risks if reused across clients or trusted without validation. |

## ALPC Resource-Lifetime Bugs

The biggest ALPC-specific lesson from the series is resource cleanup. If a receiver accepts ALPC message attributes that map views or transfer handles but fails to release them, a sender can create memory pressure, handle leaks, address-space clutter, or more controlled layout effects.

The defensive invariant:

> Every message attribute that creates a receiver-side resource needs an explicit receiver-side ownership rule and cleanup path.

Review questions:

- Which attributes can the peer send?
- Does the receiver request/accept those attributes intentionally?
- Are unexpected attributes rejected or ignored safely?
- Are mapped views released even on parse errors?
- Are transferred handles closed or moved into an owned object?
- Is the cleanup tied to message lifetime, client lifetime, or server lifetime?
- Can one client force another client's context or resource state to be reused?

## IPC Triage Checklist

For any Windows IPC endpoint, answer these before making a security claim:

1. What is the endpoint: pipe name, RPC UUID/protocol sequence/endpoint, ALPC port, COM CLSID/AppID, or inherited/duplicated handle?
2. Is it local-only, remote-capable, or local code accidentally using a remote-style path?
3. Who can connect, and where is that enforced: DACL, RPC interface flag, security callback, broker policy, firewall, service ACL, or application logic?
4. What identity does the server run as?
5. Can the server impersonate the client; if yes, at what level and from which API path?
6. Can the client limit impersonation using SQOS or RPC QoS?
7. Does the server check impersonation success before performing privileged actions?
8. What parser or marshalling layer consumes the request?
9. Can the message carry handles, mapped views, or other resources?
10. What evidence can prove behavior: ETW, Procmon, handle tables, endpoint mapper, network capture, WinObj, WinDbg, imports, or service logs?

## Active Recall

1. Why is a named pipe a `FILE_OBJECT` but still not an ordinary disk file?
2. Why does `\\127.0.0.1\pipe\name` matter for pipe impersonation reasoning?
3. Why should a pipe client set `SECURITY_SQOS_PRESENT` deliberately?
4. Why does `FILE_FLAG_FIRST_PIPE_INSTANCE` matter for privileged pipe servers?
5. Why does `RpcServerRegisterAuthInfo` alone not prove only authenticated clients can call the interface?
6. Why is RPC QoS a client-side security control?
7. Why must a privileged RPC/pipe server fail closed when impersonation fails?
8. Why can the RPC endpoint mapper miss well-known endpoints?
9. Why is ALPC powerful even though it is local-only?
10. Why do ALPC message attributes turn parsing bugs into handle, section, or resource-lifetime bugs?
