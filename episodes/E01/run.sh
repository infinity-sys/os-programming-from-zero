#!/usr/bin/env bash
# ISOS E01: assemble the boot sector and boot it in QEMU (works on macOS, Linux, WSL2)
set -e
nasm -f bin boot.asm -o boot.bin
wc -c boot.bin
xxd -s 496 boot.bin
qemu-system-x86_64 -drive format=raw,file=boot.bin -display none -serial stdio
