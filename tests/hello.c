/* ISOS E02: the smallest possible "kernel" C file, to test the cross-compiler.
   No operating system, no C library: just a function the linker can use as entry. */
void kmain(void) {
    for (;;) { }   /* a kernel never returns */
}
