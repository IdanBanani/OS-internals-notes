# Windows Object Handles, References, And Tokens

Value Score: 91/100
Role: Windows authority/lifetime owner
Proof Level: Conceptual, lab-routed

Date: 2026-05-18

Scope: Object Manager handle entries, object pointer references, reference counts versus handle counts, object identity by kernel address, handle-table security fields, token API relationships, and why kernel object residency is not the same as "everything is nonpaged pool."

Primary source anchors:

- Microsoft Learn: [Windows kernel-mode Object Manager](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/windows-kernel-mode-object-manager), [life cycle of an object](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/life-cycle-of-an-object), [`ObReferenceObject`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-obreferenceobject), [`ObReferenceObjectByHandle`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-obreferenceobjectbyhandle), [failure to validate object handles](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/failure-to-validate-object-handles), [kernel objects](https://learn.microsoft.com/en-us/windows/win32/sysinfo/kernel-objects), [kernel object namespaces](https://learn.microsoft.com/en-us/windows/win32/termserv/kernel-object-namespaces), [audit access of global system objects](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/audit-audit-the-access-of-global-system-objects), [handle inheritance](https://learn.microsoft.com/en-us/windows/win32/sysinfo/handle-inheritance), [pipe handle inheritance](https://learn.microsoft.com/en-us/windows/win32/ipc/pipe-handle-inheritance), [`STARTUPINFO`](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-startupinfoa), [`UpdateProcThreadAttribute`](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute), [`SetHandleInformation`](https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-sethandleinformation), [`DuplicateHandle`](https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-duplicatehandle), [access tokens](https://learn.microsoft.com/en-us/windows/win32/secauthz/access-tokens), [access rights for token objects](https://learn.microsoft.com/en-us/windows/win32/secauthz/access-rights-for-access-token-objects), [`OpenProcessToken`](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocesstoken), [`DuplicateTokenEx`](https://learn.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-duplicatetokenex), [`LogonUserW`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-logonuserw), [memory pools](https://learn.microsoft.com/en-us/windows/win32/memory/memory-pools), and [NX nonpaged pool](https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/no-execute-nonpaged-pool).
- Local companions: [Source-enriched Windows mechanisms](<../04-windows/06-source-enriched-windows-mechanisms.md>), [Windows deep-understanding Q&A](<../02-question-banks/02-windows-deep-understanding-qa.md>), and [Windows kernel memory, sections, privileges, and ASLR](<windows-kernel-memory-sections-privileges-and-aslr.md>).

## Offensive Priority Index

| Score | Section | Why it matters |
|---:|---|---|
| 100 | Handles versus object pointers; handle count versus pointer reference count | Authority and lifetime are not the same thing; this is core to handle bugs, UAF reasoning, and kernel object identity. |
| 100 | Token handles and token APIs | Tokens encode Windows identity, privileges, impersonation, logon state, and many PE/agent-runtime boundaries. |
| 99 | Handle tables, attributes, inherited values, handoff channels | Handle inheritance and duplication can move authority across process boundaries without another open check. |
| 99 | Global and local named objects | Cross-session Object Manager names are useful service rendezvous points, but weak DACLs and predictable names create squatting, DoS, and shared-memory abuse. |
| 98 | Same object by address; handle-entry layout | Useful for debugging, reversing, and avoiding false conclusions from handle values or private layouts. |
| 96 | Kernel objects, pool residency, NX nonpaged pool | Important for kernel exploitation constraints and driver memory-safety reasoning, but after authority/lifetime basics. |

## Handles Versus Object Pointers

A Windows handle and a kernel object pointer are different ways to keep an Object Manager object reachable.

| Mechanism | What it is | What it carries | Lifetime effect |
|---|---|---|---|
| Handle | Per-process handle-table entry. | Object reference plus granted access mask and handle attributes. | Keeps the object alive while the handle exists. Closing the handle drops that handle reference. |
| Kernel object pointer with a reference | Pointer to the object body after `ObReferenceObject`, `ObReferenceObjectByHandle`, `ObReferenceObjectByPointer`, creation ownership, or another documented reference-taking path. | Usually no new granted access mask; the caller already passed any needed check. | Keeps the object alive until `ObDereferenceObject`. |
| Raw pointer with no reference | A plain address copied from somewhere. | No authority and no lifetime guarantee by itself. | Does not keep the object alive. It can become stale if the object is dereferenced/freed. |

The safe driver pattern is:

1. Receive or find a handle/object.
2. Validate type and access while still protected by the relevant handle table, lookup lock, or API contract.
3. Take a real object reference if the pointer will outlive that protected lookup.
4. Drop the reference on every exit path with `ObDereferenceObject`.

`ObReferenceObjectByHandle` is the classic bridge: it validates a handle and returns a referenced pointer to the object body. The caller must later dereference the object. Driver Verifier can catch the dangerous pattern where a driver treats a user-supplied handle as `KernelMode` and skips the user-mode access/type model.

## Handle Count Versus Pointer Reference Count

Do not collapse all lifetime state into one intuitive number.

| Counter idea | Meaning |
|---|---|
| Handle count | Number of open handles to the object. This is visible in many debugger/object views. |
| Pointer/reference count | Object Manager references that keep the object body from being deleted. Handles contribute, but so do kernel references and temporary lookup references. |
| Type-specific counts | Extra counts owned by the object type or subsystem, such as process/thread lifetime, file object relationships, section/control-area state, rundown protection, or cache manager state. |
| Handle-table-entry usage/ref fields | Internal packed fields used to protect or manage a handle-table entry. They are not the object header pointer count. |

The practical approximation is:

```text
object pointer/reference count >= object handle count
```

But do not write:

```text
object refcount = number of user handles + kernel handles + all kernel pointers
```

That statement is too simple for three reasons:

- A pointer only counts if the code took an Object Manager reference. A local variable holding a copied pointer is not counted.
- Temporary references during lookup, duplication, auditing, callbacks, rundown, or type-specific cleanup can appear and disappear.
- Some objects have subsystem lifetime state beyond the generic Object Manager header.

The interview-safe wording is:

> Handles are rights-bearing references. Kernel code can also hold pointer references. Object deletion waits until the relevant references are gone, but the debugger-visible counts are implementation details and may include temporary or type-specific state.

## Same Object By Address

For a live Object Manager object, the object body kernel virtual address is the strongest identity clue:

- Same decoded object body address at the same instant means the same Object Manager object.
- Different object body addresses mean different Object Manager object bodies.

The caveats matter:

- Compare the same kind of pointer. An object header pointer and an object body pointer differ by an offset.
- Handle table entries often store encoded or compressed pointer bits; decode them before comparing.
- Address reuse can happen after an object is freed. A stale address from an old dump/event is not proof of same lifetime.
- Different Object Manager objects can represent the same underlying resource. Two `FILE_OBJECT`s can refer to the same file; two token objects can represent similar security contexts; two section objects can point at the same file or related control state.
- A pseudo-handle such as current process/current thread is not an ordinary handle-table entry until an API converts or duplicates it.

So the user's proposed statement is almost right but should be scoped:

> In a live kernel-debugging view, if two real handles decode to the same object body address, they refer to the same Object Manager object. If they decode to different object body addresses, they are different Object Manager objects, though they may still wrap the same underlying file, identity, or backing resource.

## Handle Tables And `EPROCESS.ObjectTable`

Each process has a handle table, classically reachable from the process object through an `ObjectTable`-style field in symbol/debugger views. The field name and layout are private implementation details, but the concept is stable: a handle value indexes a per-process table managed by the Object Manager.

A handle table entry is not just an object pointer. It stores or encodes:

- object pointer bits or an object/header pointer representation;
- granted access mask or access bits;
- handle attributes such as inheritance and protect-from-close;
- audit-on-close or audit-related state where required;
- entry lock/usage/reference metadata;
- extra bookkeeping for table expansion, free lists, quota, and debugger/accounting views.

Security meaning:

- The granted access mask is the authority later APIs test. If a process has a process handle with `PROCESS_VM_READ`, the later read path checks that handle's granted rights rather than re-opening by name.
- The mask is kernel handle-table state. User mode cannot directly write it. Normal user-mode choices are to open a new handle with requested access, duplicate a handle with allowed options, inherit an inheritable handle, or close a handle.
- `SetHandleInformation` can change documented per-handle flags such as `HANDLE_FLAG_INHERIT` and `HANDLE_FLAG_PROTECT_FROM_CLOSE`; it does not grant new object access rights.
- A kernel write primitive or vulnerable driver that can modify handle table entries can turn this into an access-control bypass. That is kernel tampering, not normal API behavior.

## Handle Attributes And Security

| Attribute / field | Meaning | Security concern |
|---|---|---|
| Granted access mask | Rights granted when the handle was opened or duplicated. | Main authority artifact. Overbroad handles are capability leaks. |
| Inherit flag | Child process can inherit the handle when process creation allows inheritable handles. | Accidental privileged handle leaks into child processes. Prefer explicit handle lists for sensitive launches. |
| Protect from close | `CloseHandle` does not close the handle while the flag is set. | Useful for debuggers/frameworks; can also confuse cleanup and leak detection. |
| Audit on close | Object/audit policy may require close-time auditing. | Evidence and compliance state; not an authorization grant. |
| Entry usage/ref metadata | Internal table-entry protection/accounting. | Not the object lifetime reference count; poor exploit/debugger target unless you know the exact build. |

Inheritance and duplication are authority transfer. A child or target process may receive a handle that it could not have opened on its own. That is normal when intentional and dangerous when accidental. Defenders should inspect source process, target object type, granted access, inheritability, duplication events where available, and whether the target process should ever have that capability.

## `Global\`, `Local\`, And `BaseNamedObjects`

Named kernel objects can be found by name instead of by inherited or duplicated handle. Win32 exposes `Global\Name` and `Local\Name` prefixes for many named objects such as events, semaphores, mutexes, waitable timers, file-mapping objects, job objects, and symbolic link objects.

The useful mental model:

| Prefix or location | Meaning |
|---|---|
| `Global\Name` | Resolve the name through the global named-object alias/link to the machine-wide root `\BaseNamedObjects` namespace. Service applications use this global namespace by default; services normally run in session 0, but the namespace rule is "service app -> global," not "session 0 path -> local BNO." |
| `Local\Name` | Resolve the name in the caller's session namespace. This is the default for ordinary interactive processes. |
| Per-session `BaseNamedObjects` | Separate session namespace so multiple logged-on users or RDS sessions can run applications without colliding on ordinary named events/mutexes/sections. |
| Object Manager symbolic link | In Object Manager views, `Global` is commonly visible as a symbolic-link object from a session namespace to the global `\BaseNamedObjects` directory. The link is namespace plumbing; it is not the shared object itself. |
| Object security descriptor | The real authorization boundary. Namespace choice decides where the name is looked up; the DACL decides who can open or modify the object. |

Do not phrase this as "`Global\` gives access through session 0." The better phrasing is: `Global` redirects name lookup to the root/global `\BaseNamedObjects`, and service applications use that global namespace by default. Do not confuse that with a per-session path such as `\Sessions\0\BaseNamedObjects` if a build/tool view shows one. `Global\` is not an authentication mechanism and it is not a grant of session-0 authority. Creating a global file-mapping object or symbolic-link object from a non-session-0 process requires `SeCreateGlobalPrivilege`; opening an existing global object is governed by the object's DACL and requested access.

Also separate two different objects:

- the `Global` symbolic-link object, which normally exists as namespace infrastructure and should not be writable or replaceable by an ordinary attacker;
- the named event, mutex, section, or other object created under the link target, which may be attacker-reachable if its name and security descriptor allow it.

If an attacker could replace the namespace link itself, that would be a severe namespace-control problem. The usual bug class is less exotic: an attacker cannot change the `Global` link, but can create, open, or influence a poorly secured object below the global namespace.

Why `Global\` is useful:

- A service can rendezvous with clients in multiple interactive sessions.
- A system-wide mutex/event can represent "one instance on the whole machine" instead of "one instance per session."
- A service can publish a named event, semaphore, or file mapping without first handing every client an inherited handle.
- A named file mapping can be a small shared-memory channel when the DACL and protocol are deliberate.

Security pitfalls:

| Pitfall | Abuse shape |
|---|---|
| Predictable name plus no ownership check | Attacker creates `Global\VendorThing` first. The service later opens it, trusts it, fails oddly, or loses the intended name. |
| Weak DACL | Low-privileged code opens a global event/mutex/section and signals, resets, waits, writes, or reads when it should not. |
| Shared memory treated as trusted | Service reads attacker-controlled bytes from a writable global file mapping and uses them as commands, paths, sizes, or handles. |
| Type collision | Attacker pre-creates a different object type at the expected name, causing create/open failures or fallback logic. |
| Cross-session leakage | Object intended for one user session is created globally, exposing state or control to other logged-on users. |
| Name as identity | Service assumes "opened my named object" means "trusted client." The name is rendezvous state, not caller authentication. |

Safer rules:

- Use per-session `Local\` names unless cross-session communication is required.
- Pass explicit `SECURITY_ATTRIBUTES` with a tight DACL for sensitive named objects.
- If the creator must own the name, check create/open status such as `ERROR_ALREADY_EXISTS` and fail closed on unexpected pre-existence.
- Treat every byte in shared memory as untrusted input unless the writer identity and protocol are separately authenticated.
- Prefer inherited or duplicated handles when the relationship is parent/child or broker/client and the authority should not be rediscoverable by name.
- Consider private namespaces and boundary descriptors when cooperating processes need a name-based channel that unrelated processes cannot squat by string alone.
- For auditing, global object access can be logged through object-access policy, but broad global-object auditing is noisy and should be used deliberately.

## Inherited Handle Values And Handoff Channels

For normal handle inheritance through `CreateProcess`, the inherited handle has the same handle value and access mask in the child process. That is why simple examples can pass an inherited pipe handle as a decimal or hex value: the integer the parent knows is also valid in the child.

The phrase "same index" is close but too implementation-shaped. A `HANDLE` is an opaque per-process value, commonly derived from handle-table indexing, but code should not reason about the private index format. The contract to remember is:

```text
inherited handle -> same Object Manager object, same handle value, same granted access
```

That does not mean the child automatically knows which inherited handle is which. The parent and child still need a protocol.

Common handoff channels:

| Channel | How it works | When it fits |
|---|---|---|
| Command line | Parent passes `--control-handle=0x...`; child parses it as `uintptr_t`/`ULONG_PTR` and casts to `HANDLE`. | Simple parent-owned child tools. Do not treat argv as secret. |
| Environment block | Parent puts `CONTROL_HANDLE=0x...` in the child's environment. | Less command-line exposure, still visible to the child and often inspectable by debugging/admin tools. |
| `STARTUPINFO` standard handles | Parent sets `hStdInput`, `hStdOutput`, and/or `hStdError` with `STARTF_USESTDHANDLES`; child calls `GetStdHandle`. | Classic redirected stdin/stdout/stderr pipes. No custom argv parsing needed for those three roles. |
| IPC control message | Parent starts child, then sends the handle value over an already-known channel such as standard input, a named pipe, socket, ALPC/RPC, or shared memory. | Multi-handle protocols, late binding, or when a control channel is already part of the design. |
| Shared config/state | Parent writes the value into an inherited file mapping, config file, registry value, or other agreed location. | Works, but needs lifetime, ACL, and race discipline. |
| Named object instead of inherited handle | Parent gives a name; child calls `OpenEvent`, `OpenFileMapping`, `CreateFile` on a named pipe, etc. | Avoids inherited handle-value handoff, but creates a new handle after a DACL/name lookup rather than reusing the inherited handle. |

`PROC_THREAD_ATTRIBUTE_HANDLE_LIST` is a filter, not a naming channel. It lets the parent say exactly which handles should be inherited by that child, which is much safer than `bInheritHandles=TRUE` in a multithreaded process with many inheritable handles. But the child still needs a convention or communication channel to know that handle value `0xNNN` means "control pipe" versus "log file" versus "job object."

`DuplicateHandle` is the dynamic version of the same problem. The caller can duplicate a handle into another process and receive the handle value that is valid in the target process. If the caller is not the target process, it must still send that target handle value to the target process through IPC. Numeric handle passing only works because the handle entry already exists in the receiving process; a random integer does not create authority.

Security rules:

- Prefer noninheritable handles by default; deliberately mark only the handles that must cross the process boundary.
- Prefer `STARTUPINFOEX` plus `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` when launching a child from a process that may have unrelated inheritable handles.
- Treat command-line and environment handle values as coordination data, not secrets. The handle's authority is the real security object.
- Close unneeded pipe ends in both parent and child. Extra inherited pipe handles commonly prevent EOF or completion from being observed.
- Use object-specific duplication where required. For example, Winsock sockets have their own duplication API rather than ordinary `DuplicateHandle` semantics.

## Why A Handle Entry Can Be 16 Bytes

On modern x64 Windows builds, a private `_HANDLE_TABLE_ENTRY` is commonly 16 bytes: two 64-bit words. Do not treat that as an ABI.

The design pressure is straightforward:

- A handle table needs to be compact because a process can have many handles.
- The entry must represent object identity, granted access, and per-handle flags.
- Kernel pointers are aligned, so low address bits are often predictable.
- x64 canonical addresses and kernel VA layout mean not every theoretical 64-bit pointer bit has to be stored naively in every build.
- Windows can pack pointer bits, attributes, lock/usage bits, and access bits into two machine words.

This is why reverse-engineering notes talk about `ObjectPointerBits`, `GrantedAccessBits`, `NoRightsUpgrade`, `Attributes`, `RefCnt`, or similar fields. Those names and bit widths are build-specific. The right takeaway is not "the handle entry is always exactly this struct"; it is:

> The entry is compact because Windows stores a decoded object reference plus access/attribute metadata, and x64 alignment/canonical-address properties let the kernel pack that state efficiently.

## Token Handles And Token APIs

Tokens are Object Manager objects too. A token handle has granted token rights such as `TOKEN_QUERY`, `TOKEN_DUPLICATE`, `TOKEN_ASSIGN_PRIMARY`, `TOKEN_IMPERSONATE`, and `TOKEN_ADJUST_PRIVILEGES`.

| API | What it returns/does | Security point |
|---|---|---|
| `OpenProcessToken(process, desiredAccess, &token)` | Opens a handle to the target process's primary token. | Requires suitable access to the process and requested token rights. The returned handle's mask controls what can be done next. |
| `OpenThreadToken(thread, ...)` | Opens an impersonation token from a thread that is impersonating. | If the thread is not impersonating, there may be no thread token. |
| `LogonUserW` | Authenticates credentials locally and returns a token handle for that logon type. | Usually returns a primary token, but network logon can return an impersonation token. Password handling and logon type matter. |
| `DuplicateTokenEx` | Creates a new token object from an existing token handle. Can create primary or impersonation tokens. | Existing token handle needs `TOKEN_DUPLICATE`. Requested rights are checked against token security. Primary-token use with process creation has additional privilege/right requirements. |
| `AdjustTokenPrivileges` | Enables/disables privileges already present in a token. | Does not add absent privileges. Check `ERROR_NOT_ALL_ASSIGNED`. |

Typical server pattern:

```text
client connects
  -> server impersonates client
  -> OpenThreadToken gets the client impersonation token
  -> DuplicateTokenEx can create a primary token if process creation is needed
  -> CreateProcessAsUser or access checks use that effective identity
```

Security pitfalls:

- Confusing primary token and impersonation token.
- Duplicating or inheriting a powerful token handle into a less trusted process.
- Enabling a privilege and assuming it creates authority that was not present.
- Using the server's process token for an operation that should have used the impersonated client.
- Asking for `TOKEN_ALL_ACCESS` when only `TOKEN_QUERY` or `TOKEN_DUPLICATE` is needed.

## Kernel Objects And Pool Residency

Not every piece of kernel state is "nonpaged pool forever."

Object Manager objects have headers and bodies, and each object type decides its allocation and lifetime rules. Many core dispatcher/process/thread/device objects must be nonpaged or effectively resident because they can be touched by scheduling, waits, DPC/APC paths, or other fault-intolerant code. But object-related state can also live elsewhere:

- handle tables can use paged pool;
- object names/security descriptors/type metadata may have separate allocation rules;
- file objects point into cache manager, filesystem, section, and storage state;
- section objects point into control-area/prototype-PTE/backing-file/pagefile state;
- process objects point to VADs, handle tables, tokens, jobs, sessions, and user-mode PEB/process parameters with different residency rules;
- driver-created auxiliary buffers can be paged or nonpaged depending on access context.

The correct rule is:

> Residency is a property of the specific allocation and access path, not of the word "object."

If code can touch the memory at high IRQL, under spin lock, from a DPC/interrupt-adjacent path, or during fault-critical memory-manager work, the memory must be resident/nonpaged. If the state is only used at passive-level code paths that can fault or wait, pageable/paged allocations may be valid.

## NX Nonpaged Pool

Nonpaged means resident; it does not have to mean executable.

Modern Windows provides NX nonpaged pool because most nonpaged pool allocations are data. If an attacker turns a pool overflow or UAF into a write of shellcode bytes, executable nonpaged pool would make control-flow hijack easier. NX pool marks those data pages non-executable, so an exploit needs a different control-flow strategy such as ROP/JOP, data-only attack, or an explicitly executable allocation.

Important caveats:

- Windows 8 and later introduced NX nonpaged pool support for drivers.
- Older Windows versions and legacy-driver compatibility paths historically used executable nonpaged pool.
- Drivers that truly need executable nonpaged memory must request executable pool explicitly, and that should be rare.
- NX pool does not stop data corruption. It removes one easy path: executing instructions from ordinary nonpaged data.

Security answer:

> Nonpaged pool is resident because high-IRQL/kernel paths may need it without faulting. NX nonpaged pool is non-executable because residency is not a reason to allow instruction fetch from data.

## Active Recall

1. Why does a handle keep an object alive even though the handle value is not a pointer?
2. Why is a raw kernel pointer unsafe unless code owns a counted reference or another lifetime guarantee?
3. Why is pointer/reference count not simply "all handles plus every pointer variable"?
4. When does same object address prove same Object Manager object, and when can that still hide same underlying file/resource?
5. Why is the granted access mask more important than the path used to obtain the handle?
6. Which handle flags can normal user mode modify with `SetHandleInformation`, and which cannot be used to grant more access?
7. Why is `Global\` useful for services, and why is it not authentication?
8. How can predictable global named objects lead to squatting, DoS, shared-memory corruption, or cross-session leakage?
9. Why can inherited handles have the same numeric value in the child while still needing a handoff protocol?
10. Why is `PROC_THREAD_ATTRIBUTE_HANDLE_LIST` safer than inheriting every inheritable handle, and why does it not label handles for the child?
11. Why is a 16-byte handle-table entry plausible on x64 but not an ABI promise?
12. How do `OpenProcessToken`, `LogonUser`, and `DuplicateTokenEx` differ?
13. Why does `AdjustTokenPrivileges` not add missing privileges?
14. Why are not all object-related allocations nonpaged?
15. Why is NX nonpaged pool a mitigation against code execution but not against data-only corruption?
