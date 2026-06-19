# Practical Snippet Pack

Value Score: 93/100
Role: Runnable proof snippets
Proof Level: Lab-backed snippets

Date: 2026-06-18

Purpose: give the notes more direct code evidence. These snippets are intentionally small, local, and non-operational. They exist to prove OS-internals statements such as "a VMA is not residency," "a pathname is not an open object," "a handle's granted access matters," and "`volatile` is not atomic."

Run them only in a disposable VM or local lab. Record the command, expected observation, actual observation, and caveat beside the relevant note.

## Linux: VMA, Residency, And COW

Claim: a valid virtual range, resident physical pages, and copy-on-write state are different layers.

`vma_cow.c`:

```c
#define _GNU_SOURCE
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <unistd.h>

int main(void) {
    const size_t page = (size_t)sysconf(_SC_PAGESIZE);
    const size_t pages = 4096;
    const size_t len = page * pages;

    unsigned char *p = mmap(NULL, len, PROT_READ | PROT_WRITE,
                            MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED) {
        fprintf(stderr, "mmap failed: %s\n", strerror(errno));
        return 1;
    }

    printf("pid=%ld mapping=%p len=%zu\n", (long)getpid(), (void *)p, len);
    printf("Inspect /proc/%ld/maps and /proc/%ld/smaps now, then press Enter.\n",
           (long)getpid(), (long)getpid());
    getchar();

    for (size_t i = 0; i < pages; i++) {
        p[i * page] = 0x41;
    }

    printf("Touched one byte per page. Inspect RSS/Private_Dirty, then press Enter.\n");
    getchar();

    pid_t child = fork();
    if (child == 0) {
        for (size_t i = 0; i < pages / 2; i++) {
            p[i * page] = 0x42;
        }
        printf("child pid=%ld wrote half the pages. Inspect parent and child smaps.\n",
               (long)getpid());
        sleep(60);
        return 0;
    }

    waitpid(child, NULL, 0);
    munmap(p, len);
    return 0;
}
```

Build and run:

```bash
gcc -O2 -Wall -Wextra -o vma_cow vma_cow.c
./vma_cow
```

Observe:

```bash
grep -A20 -B2 "$(printf '%x' 0xADDRESS_PREFIX)" /proc/<pid>/smaps
cat /proc/<pid>/maps
/usr/bin/time -v ./vma_cow
```

What this proves: `/proc/<pid>/maps` shows range policy; `smaps` and fault counts show residency/private/shared transitions; child writes turn shared COW pages into private dirty pages.

What it does not prove: exact kernel internal fields. For that, read the target kernel source around `mm/mmap.c`, `mm/memory.c`, `mm/rmap.c`, and `fs/proc/task_mmu.c`.

## Linux: fd, Pathname, And Open Object Lifetime

Claim: an fd is not the pathname. An unlinked file can still exist through an open file description.

`fd_unlink.c`:

```c
#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    const char *path = "/tmp/os-internals-fd-lab.txt";
    int fd = open(path, O_CREAT | O_RDWR | O_TRUNC, 0600);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    write(fd, "before unlink\n", 14);
    printf("pid=%ld fd=%d path=%s\n", (long)getpid(), fd, path);
    printf("Run: ls -l /proc/%ld/fd/%d ; stat %s\n", (long)getpid(), fd, path);
    getchar();

    unlink(path);
    write(fd, "after unlink\n", 13);
    printf("path unlinked, fd still open. Run: ls -l /proc/%ld/fd/%d\n",
           (long)getpid(), fd);
    getchar();

    lseek(fd, 0, SEEK_SET);
    char buf[128];
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    if (n > 0) {
        buf[n] = '\0';
        printf("%s", buf);
    }

    close(fd);
    return 0;
}
```

Build and run:

```bash
gcc -O2 -Wall -Wextra -o fd_unlink fd_unlink.c
strace -e openat,unlink,write,read,close ./fd_unlink
```

What this proves: path lookup, directory entry lifetime, inode/file object lifetime, and fd lifetime are different.

## Linux: User Pointer Validation

Claim: syscall arguments are untrusted until the kernel validates and copies user memory.

`bad_user_ptr.c`:

```c
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    const char ok[] = "valid buffer\n";
    ssize_t good = write(STDOUT_FILENO, ok, sizeof(ok) - 1);
    printf("good write returned %zd errno=%d\n", good, errno);

    errno = 0;
    const void *bad = (const void *)(uintptr_t)0x1;
    ssize_t fail = write(STDOUT_FILENO, bad, 16);
    printf("bad write returned %zd errno=%d (%s)\n", fail, errno, strerror(errno));
    return 0;
}
```

Build and run:

```bash
gcc -O2 -Wall -Wextra -o bad_user_ptr bad_user_ptr.c
strace -e write ./bad_user_ptr
```

What this proves: the syscall boundary is not a normal trusted function call. The kernel rejects an invalid userspace pointer instead of dereferencing it blindly.

## C++: Race, Volatile, Atomic, And Assembly

Claim: `volatile` is not atomic; `std::atomic` changes language semantics and usually the generated instructions.

`counter_race.cpp`:

```cpp
#include <atomic>
#include <iostream>
#include <thread>
#include <vector>

static unsigned plain_counter = 0;
static volatile unsigned volatile_counter = 0;
static std::atomic<unsigned> atomic_counter{0};

int main() {
    constexpr int threads = 8;
    constexpr int iterations = 200000;

    auto run = [](auto fn) {
        std::vector<std::thread> workers;
        for (int i = 0; i < threads; i++) {
            workers.emplace_back(fn);
        }
        for (auto &t : workers) {
            t.join();
        }
    };

    run([] {
        for (int i = 0; i < iterations; i++) {
            plain_counter++;
        }
    });

    run([] {
        for (int i = 0; i < iterations; i++) {
            volatile_counter++;
        }
    });

    run([] {
        for (int i = 0; i < iterations; i++) {
            atomic_counter.fetch_add(1, std::memory_order_relaxed);
        }
    });

    std::cout << "expected=" << threads * iterations << "\n";
    std::cout << "plain=" << plain_counter << "\n";
    std::cout << "volatile=" << volatile_counter << "\n";
    std::cout << "atomic=" << atomic_counter.load() << "\n";
}
```

Build and run:

```bash
g++ -O2 -std=c++20 -pthread -Wall -Wextra -o counter_race counter_race.cpp
./counter_race
g++ -O2 -std=c++20 -S -masm=intel counter_race.cpp
```

What this proves: the plain and volatile counters can lose updates; the atomic counter preserves atomic increment semantics. The assembly shows why: ordinary load/add/store differs from atomic read-modify-write.

## Windows: Handle Granted Access

Claim: a Windows handle carries granted access. Later APIs test that granted mask; the handle value alone is not enough.

`handle_rights.c`:

```c
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>

int wmain(int argc, wchar_t **argv) {
    if (argc != 2) {
        wprintf(L"usage: %ls <pid>\n", argv[0]);
        return 2;
    }

    DWORD pid = wcstoul(argv[1], NULL, 10);
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!h) {
        wprintf(L"OpenProcess failed: %lu\n", GetLastError());
        return 1;
    }

    WCHAR image[MAX_PATH];
    DWORD size = MAX_PATH;
    if (QueryFullProcessImageNameW(h, 0, image, &size)) {
        wprintf(L"query ok: %ls\n", image);
    } else {
        wprintf(L"query failed: %lu\n", GetLastError());
    }

    BYTE byte = 0;
    SIZE_T got = 0;
    if (!ReadProcessMemory(h, (LPCVOID)0x10000, &byte, sizeof(byte), &got)) {
        wprintf(L"ReadProcessMemory failed as expected with query-only handle: %lu\n",
                GetLastError());
    } else {
        wprintf(L"unexpected read success: got=%zu\n", got);
    }

    CloseHandle(h);
    return 0;
}
```

Build and run from a Developer Command Prompt:

```cmd
cl /W4 /EHsc handle_rights.c
handle_rights.exe <pid-of-a-test-process>
```

Observe with Process Explorer or WinDbg `!handle` if available.

What this proves: `OpenProcess` success does not imply every process operation is authorized. The granted access mask constrains later APIs.

## Windows: Private Memory Versus Mapped Section

Claim: `VirtualAlloc`, mapped sections, and image mappings produce different memory-manager evidence.

`win_memory_shapes.c`:

```c
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>

int wmain(void) {
    void *private_mem = VirtualAlloc(NULL, 4096, MEM_RESERVE | MEM_COMMIT,
                                     PAGE_READWRITE);
    if (!private_mem) {
        wprintf(L"VirtualAlloc failed: %lu\n", GetLastError());
        return 1;
    }

    HANDLE section = CreateFileMappingW(INVALID_HANDLE_VALUE, NULL,
                                        PAGE_READWRITE, 0, 4096, NULL);
    if (!section) {
        wprintf(L"CreateFileMapping failed: %lu\n", GetLastError());
        return 1;
    }

    void *mapped = MapViewOfFile(section, FILE_MAP_READ | FILE_MAP_WRITE,
                                 0, 0, 4096);
    if (!mapped) {
        wprintf(L"MapViewOfFile failed: %lu\n", GetLastError());
        return 1;
    }

    ((char *)private_mem)[0] = 'P';
    ((char *)mapped)[0] = 'M';

    wprintf(L"pid=%lu private=%p mapped=%p\n", GetCurrentProcessId(),
            private_mem, mapped);
    wprintf(L"Open VMMap now and compare Private Data vs Mapped File/Shareable regions.\n");
    Sleep(60000);

    UnmapViewOfFile(mapped);
    CloseHandle(section);
    VirtualFree(private_mem, 0, MEM_RELEASE);
    return 0;
}
```

Build and run:

```cmd
cl /W4 /EHsc win_memory_shapes.c
win_memory_shapes.exe
```

What this proves: Windows memory evidence is not just "address is readable." Backing object, VAD category, protection, and sharing differ.

## Recording Template

For each snippet, add a short lab note:

```text
Snippet:
Claim:
Build/run command:
Expected:
Actual:
Observed with:
What this proves:
What this does not prove:
Next mutation:
```
