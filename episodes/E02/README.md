# E02: Your OS Workbench (QEMU, clang, NASM and make on Mac, Windows (WSL2) and Linux)

Video: VIDEO_LINK_PLACEHOLDER

## E01 solution (`ex1_solution/boot.asm`)
padding = 510 - 25 - (length + 3). "Hi, I am Sara!" = 14 characters, 17 bytes, so the padding is 468 bytes (0x1D4).

```
cd episodes/E02/ex1_solution
nasm -f bin boot.asm -o boot.bin -l boot.lst
wc -c boot.bin           # 512
xxd -s 496 boot.bin      # ends with 55aa
qemu-system-x86_64 -drive format=raw,file=boot.bin -display none -serial stdio   # Hi, I am Sara!  (Ctrl-A, X to quit)
```

## This episode (from the repository root)
```
make tools        # versions of qemu, nasm, clang, lld, make
make toolcheck    # C -> 64-bit x86 ELF; first bytes 7f 45 4c 46 02 01 01
make run          # Hello from ISOS!
make docker-build && make docker-shell   # optional: the same toolchain in Docker
```

## Your turn (solution in E03)
1. `make tools > versions.txt`
2. `make toolcheck`, and check the first four bytes of build/hello.elf by hand: 7F 45 4C 46.
3. `make run`. Which platform are you on, and are your versions new enough (QEMU 8+, NASM 2.15+, LLVM 17+)?
