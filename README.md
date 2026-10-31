# Operating Systems Programming: From Zero to Hero

The code for the Infinity Systems YouTube course **Operating Systems Programming**. In this course we build our own operating system, called **ISOS** (Infinity Systems Operating System), from a 512-byte boot sector to a 64-bit kernel with paging, processes, system calls, a file system and a shell.

Every episode has a folder in `episodes/` and a git tag (`e01`, `e02`, …), so you can jump to exactly the code you saw in the video.

## Setup (pick your platform)

| Platform | Install |
|---|---|
| macOS | `brew install qemu nasm llvm lld` (make is already there) |
| Windows | PowerShell (admin): `wsl --install -d Ubuntu`, restart, open Ubuntu, then the Debian / Ubuntu line inside it. Clone into your Linux home (`~`), not `C:` |
| Linux: Ubuntu / Debian | `sudo apt install qemu-system-x86 nasm clang lld make` |
| Linux: Fedora | `sudo dnf install qemu-system-x86 nasm clang lld make` |
| Linux: Arch | `sudo pacman -S qemu-full nasm clang lld make` |
| Docker | `make docker-build`, then `make docker-shell` (Ubuntu 24.04 image, `docker/Dockerfile`) |

## Check your workbench (E02)

```
make tools       # prints every tool's version (save it: make tools > versions.txt)
make toolcheck   # cross-compiles tests/hello.c to a 64-bit x86 ELF
```

Any QEMU 8+, NASM 2.15+ and LLVM clang/lld 17+ works. On macOS the Makefile uses Homebrew's LLVM clang automatically (Apple's clang has no lld); override with `make CC=/path/to/clang`.

## Run

```
make run            # QEMU window + serial output in your terminal
make run-nographic  # serial only (Ctrl-A then X to quit)
```

You should see `Hello from ISOS!`.

## License
MIT, see LICENSE.
