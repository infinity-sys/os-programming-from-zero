# E07: Loading More Than 512 Bytes: INT 13h, CHS and LBA

Video: VIDEO_LINK_PLACEHOLDER

## E06 solution
1. Selector = entry number x 8, so entry 3 is 3 x 8 = 24 = 0x18.
2. 0x83 = 1000 0011: bit 0 present, bit 1 writable, bits 2 to 6 zero (bit 2 = 0: kernel only), bit 7 page size (one 2 MiB page).
3. 512 entries x 2 MiB = 1024 MiB = 1 GiB.

## By hand
- CHS: cylinder and head count from 0, sector counts from 1. The boot sector is C 0, H 0, S 1.
- CHS ceiling of the BIOS call: 1024 cylinders x 255 heads x 63 sectors x 512 bytes = 8,422,686,720 bytes (about 7.8 GiB).
- LBA numbers sectors from 0. With HPC heads per cylinder and SPT sectors per track:
  - LBA = (C x HPC + H) x SPT + (S - 1)
  - C = LBA / (HPC x SPT), H = (LBA / SPT) mod HPC, S = (LBA mod SPT) + 1 (integer division)
- QEMU's BIOS reports HPC = 16, SPT = 63 for our 1 MiB disk (int 0x13 AH=0x08, `make stage2`).
- Low memory: 0x0500 to 0x7BFF free (our stack), 0x7C00 to 0x7DFF stage 1, 0x7E00 up to the EBDA (usually just below 0x9FC00) free: stage 2 goes at 0x7E00.
- int 0x13: AH=0x00 reset, AH=0x02 read CHS (AL count, CH cylinder, CL sector bits 0-5 + cylinder bits 8-9, DH head, DL drive, ES:BX buffer), AH=0x08 drive parameters, AH=0x41 check extensions, AH=0x42 extended read (DL drive, DS:SI packet). Carry clear = OK; carry set = AH holds an error code (0x01 invalid function or parameter, 0x04 sector not found, 0x80 timeout).
- Disk address packet (16 bytes): size 0x10, 0, sector count (word), buffer offset (word), buffer segment (word), first LBA (qword).

## This episode (from the repository root)
```
make disk        # build/disk.img (1 MiB): stage 1 at LBA 0, stage 2 at LBA 1 to 8
make sectors     # xxd: 55 AA at the end of LBA 0, stage 2 at LBA 1, END! at the end of LBA 8
make stage2      # boot: stage 1 loads 4 KiB to 0x7E00 with AH=0x42, stage 2 checks END! and prints the geometry
make chs         # the same with the old CHS read (AH=0x02, C 0, H 0, S 2)
make short       # stage 1 built with STAGE2_SECTORS=4: "last sector MISSING"
make diskerr     # a 512-byte disk: "disk error, AH = 0x01"
make lba2chs LBA=63
make gdb-stage2  # needs gdb: breaks at 0x7E00, shows CS, EIP, EDX, ESP and the END! marker at 0x8DFC
```
Files: `boot/stage1.asm` (boot sector, 269 of 510 bytes used), `boot/stage2.asm` (exactly 8 sectors, 4096 bytes).
New tools: `sudo apt install gdb xxd`. Tested on Ubuntu 24.04.5 with NASM 2.16.01, QEMU 8.2.2 and GDB 15.1.

## Your turn (solution in E08)
With 16 heads per cylinder and 63 sectors per track:
1. Convert LBA 2000 to CHS.
2. Convert C 0, H 1, S 1 to LBA.
3. Write the 16 bytes of a disk address packet that reads 16 sectors, starting at LBA 9, to 0x1000:0x0000.
