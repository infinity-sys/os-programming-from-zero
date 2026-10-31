# E03: What Happens When You Press Power? Firmware, BIOS, UEFI and Bootloaders

Video: VIDEO_LINK_PLACEHOLDER

## E02 solution
`make tools > versions.txt`, then `cat versions.txt`. Real results (31 Oct 2026):

| System | QEMU | NASM | LLVM clang + lld | make |
|---|---|---|---|---|
| macOS (Homebrew, Apple silicon) | 11.1.3 | 3.02 | 23.1.4 | GNU Make 3.81 |
| Debian 13 | 10.0.13 | 2.16.03 | 19.1.7 | GNU Make 4.4.1 |
| Docker (Ubuntu 24.04) | 8.2.2 | 2.16.01 | 18.1.3 | GNU Make 4.3 |

Minimum: QEMU 8, NASM 2.15, LLVM 17. All three pass. If a tool is missing, `make tools` says which one (try `PATH=/usr/bin:/bin make tools` on a Mac to see it).

## This episode (from the repository root)
```
make poweron    # CPU frozen before its first instruction: EIP=0000fff0, CS base ffff0000 -> 0xFFFFFFF0
make firmware   # the SeaBIOS log (I/O port 0x402): ... Booting from 0000:7c00
make memdump    # 16 bytes of RAM at 0x7C00, then the first 16 bytes of build/boot.bin: identical
make nosig      # the same sector without 55 AA: "Boot failed: not a bootable disk"
make uefi       # boot with OVMF (UEFI); screenshot in build/uefi.ppm (UEFI shell)
```
`SECS=n` changes how long QEMU runs (default 3). UEFI firmware: included with Homebrew QEMU; Debian / Ubuntu / WSL2: `sudo apt install ovmf`; Fedora / Arch: `edk2-ovmf`; or `make uefi OVMF=/path/to/OVMF_CODE.fd`.

## Your turn (solution in E04)
1. The source says `dw 0xAA55`. Which byte is at offset 510, and which at 511?
2. Convert 0x7C00 to decimal.
3. `dw 0x1234`: which byte comes first in the file?

Do it by hand first, then check 1 and 3 with `nasm -f bin` and `xxd` (or `od -A x -t x1`).
