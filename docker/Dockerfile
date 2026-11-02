# ISOS E02: the whole course toolchain in one container (same for everybody)
# E07: gdb and xxd added (make gdb-stage2, make sectors)
FROM ubuntu:24.04
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      qemu-system-x86 nasm clang lld make gdb xxd \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /isos
CMD ["bash"]
