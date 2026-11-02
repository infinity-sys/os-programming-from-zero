# E09: Protected Mode Properly: CR0, the Far Jump and 32-bit Code

Video: VIDEO_LINK_PLACEHOLDER

## E08 solution
1. `make desc D=0x004092100000FFFF`: base 0x00100000 (1 MiB), limit 0xFFFF, access 0x92 (data, writable), flags 0x4 (G = 0, 32-bit), so the limit counts bytes: 0xFFFF + 1 = 65,536 bytes (64 KiB).
2. `make selector SEL=0x2B`: 0x2B = 00101 0 11, index 5, TI 0 (GDT), RPL 3. Check: 5 x 8 + 3 = 43 = 0x2B.
3. Limit 0x3FF with G = 1: (0x3FF + 1) x 4096 = 1024 pages = 4,194,304 bytes (4 MiB).

## By hand
- The switch: check A20, enable it (port 0x92: set bit 1, never bit 0), `cli`, `lgdt`, set CR0 bit 0 (PE), then a far jump `jmp 0x08:pm32` to load CS with a 32-bit code selector.
- After the jump: load DS, ES, SS (and FS, GS) with the data selector 0x10 and set ESP (here 0x90000).
- No BIOS in protected mode: print by writing to VGA text memory at 0xB8000. Each cell is 2 bytes (character, attribute); cell address = 0xB8000 + (row x 80 + column) x 2. Attribute: background in the high 4 bits, foreground in the low 4 bits (0x1F = white on blue).
- CR0 = 0x11 after the switch: bit 0 PE and bit 4 ET.
- No IDT yet, so any fault ends in a triple fault: #GP (0x0D), then the double fault (0x08) also fails, and the CPU resets.

## This episode (from the repository root)
```
make pm2          # boot: A20 check and enable, lgdt, CR0.PE=1, far jump, then CR0, ESP, CS printed from 32-bit code
make pm2-screen   # the VGA text screen after the switch, saved as build/pm2.ppm
make triple       # a selector past the end of the GDT: check_exception 0xd, 0x8, Triple fault (-no-reboot)
make gdb-pm       # needs gdb: stops right after the far jump: CS=0008 CS32, CR0=00000011
```
Files: `boot/stage2_pm.asm` (stage 2, 8 sectors, 4096 bytes; build with -DTRIPLE for the fault), stage 1 from E07.
Tested on Ubuntu 24.04.5 with NASM 2.16.01, QEMU 8.2.2 and GDB 15.1.

## Your turn (solution in E10)
1. What is the address of the last cell on the screen, row 24, column 79?
2. What colors does the attribute 0x4E give?
3. CR0 reads 0x11. Which bits are set, and what do they mean?

Work it out by hand, check it in the shell, and try changing the attribute in `vga_print`.
