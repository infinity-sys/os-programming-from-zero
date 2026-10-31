# ISOS: Operating Systems Programming, From Zero to Hero (Infinity Systems)
NASM ?= nasm
QEMU ?= qemu-system-x86_64

build/boot.bin: boot/boot.asm
	mkdir -p build
	$(NASM) -f bin $< -o $@

run: build/boot.bin
	$(QEMU) -drive format=raw,file=build/boot.bin -serial stdio

run-nographic: build/boot.bin
	$(QEMU) -drive format=raw,file=build/boot.bin -display none -serial stdio

clean:
	rm -rf build

.PHONY: run run-nographic clean
