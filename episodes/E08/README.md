# E08: The GDT in Depth: Segment Descriptors Byte by Byte

Video: VIDEO_LINK_PLACEHOLDER

## E07 solution
With 16 heads per cylinder and 63 sectors per track (HPC x SPT = 1008):
1. LBA 2000: C = 2000 / 1008 = 1, H = (2000 / 63) mod 16 = 31 mod 16 = 15, S = (2000 mod 63) + 1 = 47 + 1 = 48. So C 1, H 15, S 48.
2. C 0, H 1, S 1: LBA = (0 x 16 + 1) x 63 + 0 = 63.
3. `10 00 10 00 00 00 00 10 09 00 00 00 00 00 00 00`: size 0x10, 0, count 16 (0x0010), offset 0x0000, segment 0x1000, LBA 9 (qword).

## By hand
- A descriptor is 8 bytes. Read the 64-bit value from the right:
  - bits 0-15 limit 0-15, bits 16-39 base 0-23, bits 40-47 access byte, bits 48-51 limit 16-19, bits 52-55 flags, bits 56-63 base 24-31.
- Access byte: P (bit 7), DPL (bits 5-6), S (bit 4, 1 = code or data), type (bits 0-3). 0x9A = code, readable; 0x92 = data, writable.
- Flags: G (bit 3, limit in 4 KiB pages), D/B (bit 2, 32-bit), L (bit 1, 64-bit code), AVL (bit 0).
- 0x00CF9A000000FFFF: base 0, limit 0xFFFFF, G = 1, so (0xFFFFF + 1) x 4096 = 4,294,967,296 bytes (4 GiB).
- Selector: index (bits 3-15), TI (bit 2, 0 = GDT, 1 = LDT), RPL (bits 0-1). 0x08 = entry 1, 0x10 = entry 2.
- GDTR (lgdt, sgdt): a 16-bit limit (table size - 1) and a 32-bit base. Three entries: limit 3 x 8 - 1 = 23 = 0x17.

## This episode (from the repository root)
```
make gdt                         # boot: stage 2 loads a 3-entry GDT, sgdt prints limit 0x0017, base 0x00007E98
make gdt-bytes                   # the 24 bytes of the table (xxd), at file offset 0x98 = 0x7E98
make desc D=0x00CF9A000000FFFF   # decode one descriptor: base, limit, access, flags, size
make selector SEL=0x10           # split a selector: index, TI, RPL
make gdb-gdt                     # needs gdb: stops at the hlt after lgdt, shows the table and GDT=00007e98 00000017
```
Files: `boot/stage2_gdt.asm` (stage 2, 8 sectors, 4096 bytes), stage 1 from E07.
Tested on Ubuntu 24.04.5 with NASM 2.16.01, QEMU 8.2.2 and GDB 15.1. The CPU is still in real mode at the end (CR0 = 0x10): the switch is E09.

## Your turn (solution in E09)
1. Decode the descriptor `0x004092100000FFFF` by hand. What are its base, limit, size and type?
2. Split the selector 0x2B into index, TI and RPL.
3. How big is a segment with limit 0x3FF and G = 1?

Check all three with `make desc` and `make selector`.
