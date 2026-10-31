# E04: A 512-Byte Boot Sector in Real Mode

Video: VIDEO_LINK_PLACEHOLDER

## E03 solution
1. `dw 0xAA55` is stored little-endian: byte 510 is `0x55`, byte 511 is `0xAA`.
2. 0x7C00 = 7 x 4096 + 12 x 256 = 28672 + 3072 = **31744** (`echo $((0x7C00))`).
3. `dw 0x1234` is stored as `34 12`: the low byte comes first.

Check: `nasm -f bin t.asm -o t.bin && xxd t.bin` prints `55aa 3412`.

## This episode (from the repository root)
```
make listing    # NASM listing: offset, machine code, source line
make disasm     # ndisasm -o 0x7c00 build/boot.bin: the bytes back as instructions
make size       # exactly 512 bytes, last two bytes 55 aa
make hello      # boot it in QEMU: "Hello from ISOS!" on the serial line
make screen     # the QEMU screen saved to build/hello.ppm
make noorg      # the same code without org 0x7C00: mov si,0x19 prints the wrong bytes
```
`SECS=n` changes how long QEMU runs (default 3). `ndisasm` comes with NASM.

## Your turn (solution in E05)
Print "Hello from ISOS!" three times.
1. Put 3 in CX before the print loop.
2. Reload SI with `mov si, msg` each time round.
3. At the end of the message, `loop` back.
4. `make size` must still say 512 and 55 aa; `make hello` shows three lines.
