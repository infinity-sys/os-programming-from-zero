# E05: Real-Mode Segments and BIOS Interrupts, by Hand

Video: VIDEO_LINK_PLACEHOLDER

## E04 solution
```nasm
    mov cx, 3           ; print the message 3 times
.again:
    mov si, msg         ; back to the first letter
.next:
    lodsb
    test al, al
    jz .end_of_msg
    mov ah, 0x0E
    int 0x10
    mov dx, 0x3F8
    out dx, al
    jmp .next
.end_of_msg:
    loop .again         ; cx = cx - 1, repeat while cx is not 0
```
Still 512 bytes ending in `55 aa`; QEMU prints "Hello from ISOS!" three times.

## By hand
- Physical address = segment x 16 + offset. Example: 0x1000:0x0234 = 0x10000 + 0x0234 = 0x10234 (and 0x1023:0x0004 is the same byte).
- `jmp 0x07C0:go` assembles to `EA 05 00 C0 07`: opcode, offset 0x0005, segment 0x07C0 (little-endian).
- The interrupt vector table sits at address 0: 256 entries of 4 bytes (offset, then segment). Vector n is at n x 4: int 0x10 at 0x40, int 0x16 at 0x58.
- `int n` pushes FLAGS, CS and IP, then jumps through vector n; `iret` pops them back.

## This episode (from the repository root)
```
make addr                       # SEG:OFF = SEG x 16 + OFF (default 0x07C0:0x0000)
make addr SEG=0x1000 OFF=0x0234 # any pair: 0x10234
make segs                       # boot/segs.asm: org 0 + far jump to 0x07C0, disassembled and booted
make ivt                        # the int 0x10 and int 0x16 vectors, read from QEMU memory
make keys                       # boot/keys.asm: int 0x16 keyboard echo; QEMU sendkey types KEYS for you
```
`KEYS="h i ret"` changes what `make keys` types. `make ivt` numbers depend on your QEMU/SeaBIOS build.

## Your turn (solution in E06)
Work out by hand, in hex, then check with `make addr`:
1. 0x07C0:0x0000
2. 0x0000:0x7C00
3. 0xFFFF:0x0010, and why does it reach past 1 MiB on a CPU with 20 address lines?
