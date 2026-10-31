#!/bin/sh
# ISOS E02: print the version of every tool in your workbench.
# Usage: make tools        (or: sh scripts/check_tools.sh > versions.txt)
CC=${CC:-clang}; LD=${LD:-ld.lld}; NASM=${NASM:-nasm}; QEMU=${QEMU:-qemu-system-x86_64}
show() { # show <name> <command...>
  name=$1; shift
  if command -v "$1" >/dev/null 2>&1; then
    printf '%-6s %s\n' "$name" "$("$@" 2>&1 | head -n 1)"
  else
    printf '%-6s MISSING: %s not found (see README, Setup)\n' "$name" "$1"; missing=1
  fi
}
missing=0
echo "ISOS workbench on $(uname -s) $(uname -m)"
show qemu "$QEMU" --version
show nasm "$NASM" -v
show clang "$CC" --version
show lld  "$LD" --version
show make make --version
[ $missing -eq 0 ] && echo "All tools found." || { echo "Some tools are missing."; exit 1; }
