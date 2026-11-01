# E06: Into Protected and Long Mode: Why We Need a Real Bootloader

Video: https://youtu.be/veYVexuV4NI

## E05 solution
Physical address = segment x 16 + offset:
1. 0x07C0:0x0000 = 0x07C00 + 0x0000 = 0x07C00
2. 0x0000:0x7C00 = 0x00000 + 0x7C00 = 0x07C00 (the same byte, where the BIOS loads the boot sector)
3. 0xFFFF:0x0010 = 0xFFFF0 + 0x0010 = 0x100000 = 1 MiB. That needs 21 bits, one past what 20 address lines (A0 to A19) can name, so with the A20 line off it wraps to 0x000000.

## By hand
- A20: `make a20` writes 0 at 0x0500 and 0xFF at FFFF:0510 (= 0x100500). With A20 off (port 0x92, bit 1 = 0) the second write lands on 0x0500.
- GDT entries are 8 bytes. A selector is entry number x 8: 0x08 = code, 0x10 = data.
- `0x00CF9A000000FFFF`: base 0, limit 0xFFFFF x 4 KiB = 4 GiB, access 0x9A = present, ring 0, code, readable. `0x00CF92000000FFFF` is the same with access 0x92 = data, writable.
- Protected mode: `cli`, `lgdt`, set CR0 bit 0 (PE), far jump to `0x08:pm32`. No BIOS after that: VGA text memory at 0xB8000, two bytes per character (letter, colour).
- Long mode: page tables (PML4 at 0x1000, PDPT at 0x2000, PD at 0x3000 with one 2 MiB page), CR4.PAE, CR3 = 0x1000, EFER.LME (MSR 0xC0000080, bit 8), CR0.PG + PE, far jump to a code descriptor with the L bit (`0x00209A0000000000`).
- `make modes`: CR0 = 0x10 (real), 0x11 (protected, CS32), 0x80000011 (long, CS64, EFER = 0x500 = LME + LMA).

## This episode (from the repository root)
```
make a20     # FFFF:0510 with A20 on, off (port 0x92) and on again
make pm      # boot/pm.asm: 32-bit protected mode, writes to 0xB8000 and COM1
make lm      # boot/lm.asm: real mode to 64-bit long mode in one sector
make modes   # CS, CR0, CR3, CR4 and EFER of each sector, from the QEMU monitor
make room    # bytes of code in each boot sector, out of 510
```
Nothing new to install: NASM and QEMU, as in E02.

## Your turn (solution in E07)
1. If we add a 4th entry to our GDT, what is its selector?
2. Write our page directory entry 0x83 in binary. What do bits 0, 1 and 7 mean?
3. One page directory has 512 entries of 2 MiB each. How much memory does it map?

Solution (E07): 1. 0x18 (entry 3 x 8). 2. 1000 0011: bit 0 present, bit 1 writable, bit 7 a 2 MiB page. 3. 512 x 2 MiB = 1 GiB.
