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

clean:
	rm -rf build

.PHONY: run run-nographic tools toolcheck docker-build docker-shell poweron firmware memdump nosig uefi clean
