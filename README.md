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

## The boot process (E03)

```
make poweron    # registers at power on (the reset vector)
make firmware   # the BIOS (SeaBIOS) log
make memdump    # RAM at 0x7C00 next to build/boot.bin
make nosig      # a sector without 55 AA is refused
make uefi       # boot with OVMF (UEFI), screenshot in build/uefi.ppm
```

For `make uefi` you need OVMF: included with Homebrew QEMU; `sudo apt install ovmf` on Debian / Ubuntu / WSL2; `edk2-ovmf` on Fedora / Arch; or pass `OVMF=/path/to/OVMF_CODE.fd`.

## A 512-byte boot sector (E04)

```
make listing    # offsets and machine code of boot/boot.asm
make disasm     # disassemble build/boot.bin at 0x7C00
make size       # 512 bytes, ending 55 aa
make hello      # boot it: Hello from ISOS!
make screen     # QEMU screenshot in build/hello.ppm
make noorg      # what breaks without org 0x7C00
```

## Segments and BIOS interrupts (E05)

```
make addr       # SEG:OFF to a physical address (SEG=... OFF=...)
make segs       # org 0 and a far jump to 0x07C0
make ivt        # int 0x10 and int 0x16 vectors from memory
make keys       # read the keyboard with int 0x16
```

## Protected and long mode (E06)

```
make a20     # the A20 line: on, off (port 0x92), on
make pm      # 32-bit protected mode: GDT, CR0.PE, far jump
make lm      # 64-bit long mode from one boot sector
make modes   # CR0, CR3, CR4, EFER of each sector (QEMU monitor)
make room    # bytes used of the 510 in each boot sector
```

## Loading more than 512 bytes (E07)

```
make disk        # build/disk.img: stage 1 at LBA 0, stage 2 at LBA 1 to 8 (dd)
make sectors     # xxd of LBA 0, 1, 8 and 9
make stage2      # boot it: stage 1 reads stage 2 with int 0x13 AH=0x42 (LBA)
make chs         # the same with the old CHS read, AH=0x02
make short       # stage 1 reads only 4 of the 8 sectors
make diskerr     # a disk with no sector 1: carry set, AH = error code
make lba2chs LBA=63   # the LBA to CHS formula (HPC=16, SPT=63)
make gdb-stage2  # GDB stops at 0x7E00, the first byte of stage 2
```
New tools: `sudo apt install gdb xxd` (tested on Ubuntu 24.04 with NASM 2.16.01, QEMU 8.2.2, GDB 15.1).

## Run

```
make run            # QEMU window + serial output in your terminal
make run-nographic  # serial only (Ctrl-A then X to quit)
```

You should see `Hello from ISOS!`.

## License
MIT, see LICENSE.
