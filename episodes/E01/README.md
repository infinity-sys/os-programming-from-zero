# E01: Let's Build an Operating System (Course Roadmap)

Video: https://youtu.be/RasSyFEOA8s

- `boot.asm`: a 512-byte boot sector that prints "Hello from ISOS!" on screen (BIOS int 0x10) and on COM1 (0x3F8).
- `run.sh`: build and boot it.

```
nasm -f bin boot.asm -o boot.bin
wc -c boot.bin           # 512
xxd -s 496 boot.bin      # ... 55aa
qemu-system-x86_64 -drive format=raw,file=boot.bin -display none -serial stdio
```

Byte map: code 0-24 (25 bytes), message 25-43 (19 bytes), padding 44-509 (466 zeros), signature 510-511 (55 AA).

## Your turn
Put your own name in the message. Count the padding by hand first: padding = 510 − 25 − (characters + 3). Build: still 512 bytes, still ends 55 AA. Boot it. The solution opens episode 2.
