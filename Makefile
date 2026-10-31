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

clean:
	rm -rf build

.PHONY: run run-nographic tools toolcheck docker-build docker-shell clean
