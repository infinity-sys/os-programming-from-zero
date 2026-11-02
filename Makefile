# ISOS: Operating Systems Programming, From Zero to Hero (Infinity Systems)
NASM ?= nasm
QEMU ?= qemu-system-x86_64

# We need LLVM's clang (it can target a bare x86-64 machine).
# On macOS, prefer Homebrew's LLVM over Apple's clang.
LLVM_CLANG := $(firstword $(wildcard /opt/homebrew/opt/llvm/bin/clang /usr/local/opt/llvm/bin/clang))
ifeq ($(origin LD),default)
  LD := ld.lld
endif
ifeq ($(origin CC),default)
  CC := $(if $(LLVM_CLANG),$(LLVM_CLANG),clang)
endif
export CC LD NASM QEMU

build/boot.bin: boot/boot.asm
	mkdir -p build
	$(NASM) -f bin $< -o $@

run: build/boot.bin
	$(QEMU) -drive format=raw,file=build/boot.bin -serial stdio

run-nographic: build/boot.bin
	$(QEMU) -drive format=raw,file=build/boot.bin -display none -serial stdio

# E02: print every tool's version (save it with: make tools > versions.txt)
tools:
	@sh scripts/check_tools.sh

# E02: prove the cross-compiler works: C -> a 64-bit x86 ELF for a bare machine
toolcheck: build/hello.elf
	@od -A x -t x1 -N 20 build/hello.elf
	@echo "toolcheck: OK, built build/hello.elf"

build/hello.elf: tests/hello.c
	mkdir -p build
	$(CC) --target=x86_64-unknown-elf -ffreestanding -nostdlib -O2 -c $< -o build/hello.o
	$(LD) -e kmain -o $@ build/hello.o

# E02: the same toolchain in a container (Docker Desktop or Docker Engine)
docker-build:
	docker build -t isos-dev docker

docker-shell:
	docker run --rm -it -v "$(CURDIR)":/isos isos-dev

# E03: what happens when you press power?
# OVMF = UEFI firmware for QEMU (Homebrew ships it with qemu; on Linux: the ovmf package)
OVMF ?= $(firstword $(wildcard /opt/homebrew/share/qemu/edk2-x86_64-code.fd /usr/local/share/qemu/edk2-x86_64-code.fd /usr/share/qemu/edk2-x86_64-code.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd))
SECS ?= 3

# The CPU's very first instruction address, before the firmware runs (QEMU starts paused: -S)
poweron: build/boot.bin
	@printf 'info registers\nquit\n' | $(QEMU) -S -display none -monitor stdio -drive format=raw,file=build/boot.bin 2>/dev/null | grep -E '^(EIP|CS )' | tr -d '\r' | awk '!seen[$$0]++'

# The firmware's own log (SeaBIOS writes it to I/O port 0x402)
firmware: build/boot.bin
	@$(QEMU) -display none -drive format=raw,file=build/boot.bin -chardev file,id=fw,path=build/firmware.log -device isa-debugcon,iobase=0x402,chardev=fw 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@grep -E 'SeaBIOS \(version|Booting from|Boot failed|bootable|drive 0x' build/firmware.log | tr -d '\r' | awk '!seen[$$0]++'

# Where did the BIOS put our sector? Read 16 bytes of RAM at 0x7C00
memdump: build/boot.bin
	@(sleep 2; printf 'xp /16xb 0x7c00\n'; sleep 1; printf 'quit\n') | $(QEMU) -display none -monitor stdio -drive format=raw,file=build/boot.bin 2>/dev/null | grep -ao '0*7c0[0-9a-f]: [0-9a-fx ]*' | tr -d '\r' | awk '!seen[$$0]++'
	@od -A x -t x1 -N 16 build/boot.bin | head -n 1

# The same sector without the 55 AA signature: the BIOS refuses it
build/nosig.bin: build/boot.bin
	head -c 510 build/boot.bin > $@
	printf '\000\000' >> $@

nosig: build/nosig.bin
	@$(QEMU) -display none -drive format=raw,file=build/nosig.bin -chardev file,id=fw,path=build/nosig.log -device isa-debugcon,iobase=0x402,chardev=fw 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@grep -E 'Booting from|Boot failed|No bootable' build/nosig.log | tr -d '\r' | awk '!seen[$$0]++'

# UEFI firmware (OVMF) instead of the BIOS: it ignores our BIOS boot sector
uefi: build/boot.bin
	@test -n "$(OVMF)" || { echo "OVMF not found: install the ovmf package or set OVMF=/path/to/OVMF_CODE.fd"; exit 1; }
	@(sleep $(SECS); printf 'screendump build/uefi.ppm\nquit\n') | $(QEMU) -display none -monitor stdio -drive if=pflash,format=raw,readonly=on,file=$(OVMF) -drive format=raw,file=build/boot.bin -net none 2>/dev/null >/dev/null
	@echo "firmware: $(OVMF)"; echo "screen saved: build/uefi.ppm"

# E04: a 512-byte boot sector in real mode, line by line
NDISASM ?= ndisasm

# The listing: every line of boot.asm with its offset and machine code
listing: boot/boot.asm
	@mkdir -p build
	@$(NASM) -f bin boot/boot.asm -l build/boot.lst -o build/boot.bin
	@grep -E '^ +[0-9]+ [0-9A-F]{8} ' build/boot.lst | grep -v 'rep ' | cut -c 8-

# The same bytes read back as instructions, at the address the BIOS uses
disasm: build/boot.bin
	@$(NDISASM) -o 0x7c00 build/boot.bin | head -n 13

# Size check: exactly 512 bytes, ending with 55 AA
size: build/boot.bin
	@wc -c build/boot.bin
	@od -A d -t x1 -j 510 build/boot.bin | head -n 1

# Boot it and show exactly what arrived on the serial line
hello: build/boot.bin
	@$(QEMU) -display none -drive format=raw,file=build/boot.bin -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@echo

# The screen, saved by QEMU's monitor (build/hello.ppm)
screen: build/boot.bin
	@(sleep $(SECS); printf 'screendump build/hello.ppm\nquit\n') | $(QEMU) -display none -monitor stdio -drive format=raw,file=build/boot.bin 2>/dev/null >/dev/null
	@echo "screen saved: build/hello.ppm"

# A classic bug: the same code without "org 0x7C00"
build/noorg.bin: boot/boot.asm
	@mkdir -p build
	@sed '/^org/d' boot/boot.asm > build/noorg.asm
	@$(NASM) -f bin build/noorg.asm -o $@

noorg: build/noorg.bin
	@$(NDISASM) build/noorg.bin | sed -n 3p
	@$(QEMU) -display none -drive format=raw,file=build/noorg.bin -serial file:build/noorg.out 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@od -A n -c build/noorg.out

# ---- E05: segments and BIOS interrupts ----
SEG ?= 0x07C0
OFF ?= 0x0000
KEYS ?= h i spc i s o s ret

# physical = segment x 16 + offset
addr:
	@printf '%s:%s = %s x 16 + %s = 0x%05X\n' $(SEG) $(OFF) $(SEG) $(OFF) $$(( $(SEG) * 16 + $(OFF) ))

build/segs.bin: boot/segs.asm
	mkdir -p build
	$(NASM) -f bin $< -o $@

# the same idea with org 0 and DS = 0x07C0
segs: build/segs.bin
	@$(NDISASM) -o 0 build/segs.bin | head -n 4
	@$(QEMU) -display none -drive format=raw,file=build/segs.bin -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@echo

# the interrupt vector table: 4 bytes per vector (offset, segment) from address 0
ivt: build/boot.bin
	@(sleep 2; printf 'xp /2xh 0x40\nxp /2xh 0x58\n'; sleep 1; printf 'quit\n') | $(QEMU) -display none -monitor stdio -drive format=raw,file=build/boot.bin 2>/dev/null | grep -ao '0*\(40\|58\): [0-9a-fx ]*' | tr -d '\r' | awk '!seen[$$0]++'

build/keys.bin: boot/keys.asm
	mkdir -p build
	$(NASM) -f bin $< -o $@

# boot keys.bin and type for you through the QEMU monitor (sendkey)
keys: build/keys.bin
	@(sleep 2; for k in $(KEYS); do printf 'sendkey %s\n' $$k; sleep 0.3; done; sleep 1; printf 'quit\n') | $(QEMU) -display none -monitor stdio -drive format=raw,file=build/keys.bin -serial file:build/keys.out 2>/dev/null >/dev/null
	@cat build/keys.out


# ---- E06: into protected and long mode ----
build/%.bin: boot/%.asm
	@mkdir -p build
	@$(NASM) -f bin $< -l build/$*.lst -o $@

# the E05 puzzle, for real: FFFF:0510 with A20 on, then off (port 0x92), then on again
a20: build/a20.bin
	@$(QEMU) -display none -drive format=raw,file=build/a20.bin -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid

# 16-bit real mode -> 32-bit protected mode (GDT, CR0.PE, far jump), then VGA memory at 0xB8000
pm: build/pm.bin
	@$(QEMU) -display none -drive format=raw,file=build/pm.bin -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@echo

# real mode -> 64-bit long mode (page tables, PAE, EFER.LME, CR0.PG), in one sector
lm: build/lm.bin
	@$(QEMU) -display none -drive format=raw,file=build/lm.bin -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid
	@echo

# which mode is the CPU in? CS and the control registers, read from the QEMU monitor
modes: build/boot.bin build/pm.bin build/lm.bin
	@for b in boot pm lm; do echo "== $$b.bin"; (sleep 2; printf 'info registers\n'; sleep 0.5; printf 'quit\n') | $(QEMU) -display none -monitor stdio -drive format=raw,file=build/$$b.bin 2>/dev/null | tr -d '\r' | grep -E '^(CS |CR0|EFER)' | sed -E 's/ CR2=[0-9a-f]+//'; done

# bytes of code in each boot sector, out of the 510 we can use
room:
	@mkdir -p build
	@for b in boot segs keys a20 pm lm; do $(NASM) -f bin boot/$$b.asm -l build/$$b.lst -o build/$$b.bin; n=$$(grep 'times 510' build/$$b.lst | awk '{print $$2}'); printf '%-5s %3d of 510 bytes used\n' $$b $$((0x$$n)); done

clean:
	rm -rf build

.PHONY: run run-nographic tools toolcheck docker-build docker-shell poweron firmware memdump nosig uefi listing disasm size hello screen noorg clean addr segs ivt keys a20 pm lm modes room

# ---- E07: loading more than 512 bytes (INT 13h, CHS and LBA) ----
# a 1 MiB disk image
DISK_SECTORS ?= 2048
LBA ?= 8
# heads per cylinder, sectors per track (QEMU's BIOS, see make stage2)
HPC ?= 16
SPT ?= 63

build/stage1.bin: boot/stage1.asm
	@mkdir -p build
	@$(NASM) -f bin $< -l build/stage1.lst -o $@

build/stage1-chs.bin: boot/stage1.asm
	@mkdir -p build
	@$(NASM) -DUSE_CHS -f bin $< -o $@

build/stage1-half.bin: boot/stage1.asm
	@mkdir -p build
	@$(NASM) -DSTAGE2_SECTORS=4 -f bin $< -o $@

# sector 0 = stage 1, sectors 1 to 8 = stage 2, the rest zeros
build/disk.img: build/stage1.bin build/stage2.bin
	dd if=/dev/zero of=$@ bs=512 count=$(DISK_SECTORS) status=none
	dd if=build/stage1.bin of=$@ conv=notrunc status=none
	dd if=build/stage2.bin of=$@ bs=512 seek=1 conv=notrunc status=none

build/disk-%.img: build/stage1-%.bin build/disk.img
	cp build/disk.img $@
	dd if=$< of=$@ conv=notrunc status=none

disk: build/disk.img
	@ls -l build/stage1.bin build/stage2.bin build/disk.img | awk '{print $$5, $$9}'

# boot the two-stage disk (LBA read, AH=0x42)
stage2: build/disk.img
	@$(QEMU) -display none -drive format=raw,file=build/disk.img -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid

# the same disk, stage 1 built with the old CHS read (AH=0x02)
chs: build/disk-chs.img
	@$(QEMU) -display none -drive format=raw,file=build/disk-chs.img -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid

# stage 1 reads only 4 of the 8 sectors
short: build/disk-half.img
	@$(QEMU) -display none -drive format=raw,file=build/disk-half.img -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid

# a "disk" that is only the boot sector: the read fails, carry set, AH = error code
diskerr: build/stage1.bin
	@$(QEMU) -display none -drive format=raw,file=build/stage1.bin -serial stdio 2>/dev/null & pid=$$!; sleep $(SECS); kill $$pid

# look at the sectors in the image
sectors: build/disk.img
	@echo "-- LBA 0, last 16 bytes (the 55 AA signature)"; xxd -s 496 -l 16 build/disk.img
	@echo "-- LBA 1, first 16 bytes (stage 2 starts)";    xxd -s 512 -l 16 build/disk.img
	@echo "-- LBA 8, last 16 bytes (END!)";               xxd -s 4592 -l 16 build/disk.img
	@echo "-- LBA 9, first 16 bytes (empty)";             xxd -s 4608 -l 16 build/disk.img

# LBA -> CHS: C = LBA / (HPC x SPT), H = (LBA / SPT) mod HPC, S = (LBA mod SPT) + 1
lba2chs:
	@echo "LBA $(LBA) -> C=$$(( $(LBA) / ($(HPC) * $(SPT)) )) H=$$(( ($(LBA) / $(SPT)) % $(HPC) )) S=$$(( $(LBA) % $(SPT) + 1 ))  (HPC=$(HPC), SPT=$(SPT))"

# stop at the first instruction of stage 2 and look around with GDB
gdb-stage2: build/disk.img
	@qemu-system-i386 -display none -drive format=raw,file=build/disk.img -s -S 2>/dev/null & pid=$$!; sleep 1; \
	gdb -q -batch -ex 'target remote localhost:1234' -ex 'set architecture i8086' -ex 'break *0x7e00' -ex 'continue' \
	  -ex 'info registers cs eip edx esp' -ex 'x/8xb 0x7e00' -ex 'x/4cb 0x8dfc' 2>&1 | grep -v -e warning -e '^$$' -e Inferior -e 'Remote debugging' -e 'determining executable' ; kill $$pid

.PHONY: disk stage2 chs short diskerr sectors lba2chs gdb-stage2

