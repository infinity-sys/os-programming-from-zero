# Operating Systems Programming: From Zero to Hero

The code for the Infinity Systems YouTube course **Operating Systems Programming**. In this course we build our own operating system, called **ISOS** (Infinity Systems Operating System), from a 512-byte boot sector to a 64-bit kernel with paging, processes, system calls, a file system and a shell.

Every episode has a folder in `episodes/` and a git tag (`e01`, `e02`, …), so you can jump to exactly the code you saw in the video.

## Setup (pick your platform)

| Platform | Install |
|---|---|
| macOS | `brew install qemu nasm llvm lld make` |
| Windows | `wsl --install -d Ubuntu`, then follow the Linux (Ubuntu) line inside WSL2 |
| Linux: Ubuntu / Debian | `sudo apt install qemu-system-x86 nasm clang lld make` |
| Linux: Fedora | `sudo dnf install qemu-system-x86 nasm clang lld make` |
| Linux: Arch | `sudo pacman -S qemu-full nasm clang lld make` |
| Docker | a ready toolchain image arrives in episode 2 |

## Run

```
make run            # QEMU window + serial output in your terminal
make run-nographic  # serial only (Ctrl-A then X to quit)
```

You should see `Hello from ISOS!`.

## License
MIT, see LICENSE.
