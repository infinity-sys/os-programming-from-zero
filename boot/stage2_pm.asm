bits 16
org 0x7E00

; E09 stage 2: real mode -> 32-bit protected mode, done properly.
; Build with -DTRIPLE to load a selector past the end of the GDT on purpose (triple fault).
SECTORS equ 8

stage2:
    mov si, msg_hi
    call print

    call a20_check          ; AX = 1 if A20 is on
    mov si, msg_a20_off
    test ax, ax
    jz .a20_print
    mov si, msg_a20_on
.a20_print:
    call print

    in al, 0x92             ; "fast A20": bit 1 of system control port A
    or al, 00000010b
    and al, 11111110b       ; never set bit 0: it resets the machine
    out 0x92, al
    call a20_check
    mov si, msg_a20_off
    test ax, ax
    jz .a20_print2
    mov si, msg_a20_on
.a20_print2:
    call print

    mov si, msg_go
    call print

    cli                     ; 1. no interrupts: there is no IDT for protected mode yet
    lgdt [gdtr]             ; 2. the GDT from E08
    mov eax, cr0
    or eax, 1               ; 3. CR0 bit 0 = PE, protection enable
    mov cr0, eax
    jmp CODE_SEL:pm32       ; 4. far jump: loads CS from the GDT, flushes the prefetch queue

; ---- real-mode helpers ----
; AX = 1 if A20 is enabled: does 0xFFFF:0x0510 (= 0x100500) wrap around to 0x0000:0x0500?
a20_check:
    push ds
    push es
    xor ax, ax
    mov ds, ax              ; DS:0x0500 = 0x000500
    not ax
    mov es, ax              ; ES:0x0510 = 0x100500
    mov byte [ds:0x0500], 0x00
    mov byte [es:0x0510], 0xFF
    xor ax, ax
    cmp byte [ds:0x0500], 0xFF  ; changed? then the two addresses are the same byte: A20 off
    je .done
    inc ax
.done:
    pop es
    pop ds
    ret

print:
    lodsb
    test al, al
    jz .ret
    call putc
    jmp print
.ret:
    ret

putc:
    push dx
    push bx
    push ax
    mov dx, 0x3F8           ; COM1
    out dx, al
    mov ah, 0x0E            ; BIOS teletype
    xor bh, bh              ; page 0
    int 0x10
    pop ax
    pop bx
    pop dx
    ret

; ---- 32-bit protected mode ----
bits 32
pm32:
%ifdef TRIPLE
    mov ax, 0x18            ; index 3: past the GDT limit (0x17) -> #GP, no IDT -> triple fault
    mov ds, ax
%endif
    mov ax, DATA_SEL        ; 5. every data segment register gets the flat data selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000        ; 6. a 32-bit stack, below the EBDA

    call vga_clear
    mov edi, 0xB8000        ; row 0
    mov esi, pm_msg1
    call vga_print
    call newline            ; serial only: VGA rows are addresses, not characters
    mov edi, 0xB8000 + 160  ; row 1 (80 columns x 2 bytes)
    mov esi, pm_msg2
    call vga_print
    mov eax, cr0
    call vga_hex32
    call newline            ; serial only: VGA rows are addresses, not characters
    mov edi, 0xB8000 + 320  ; row 2
    mov esi, pm_msg3
    call vga_print
    mov eax, esp
    call vga_hex32
    call newline            ; serial only: VGA rows are addresses, not characters
    mov edi, 0xB8000 + 480  ; row 3
    mov esi, pm_msg4
    call vga_print
    xor eax, eax
    mov ax, cs
    call vga_hex32
    call newline
.halt:
    hlt
    jmp .halt

; fill the 80x25 screen with blank cells, white on blue
vga_clear:
    mov edi, 0xB8000
    mov ecx, 80*25
    mov ax, 0x1F20
    rep stosw
    ret

; ESI = zero-terminated string, EDI = cell address; also copies to COM1
vga_print:
    lodsb
    test al, al
    jz .ret
    call serial
    mov ah, 0x1F
    stosw
    jmp vga_print
.ret:
    ret

; EAX as 8 hex digits at EDI (and COM1)
vga_hex32:
    mov ecx, 8
.digit:
    rol eax, 4
    push eax
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe .out
    add al, 7
.out:
    call serial
    mov ah, 0x1F
    stosw
    pop eax
    loop .digit
    ret

newline:
    mov al, 13
    call serial
    mov al, 10

serial:
    push edx
    mov dx, 0x3F8
    out dx, al
    pop edx
    ret

; ---- the GDT (same as E08) ----
align 8
gdt:
gdt_null:  dq 0
gdt_code:  dq 0x00CF9A000000FFFF    ; 0x08: code, base 0, 4 GiB, 32-bit, exec/read
gdt_data:  dq 0x00CF92000000FFFF    ; 0x10: data, base 0, 4 GiB, read/write
gdt_end:
gdtr:
    dw gdt_end - gdt - 1
    dd gdt
CODE_SEL equ gdt_code - gdt
DATA_SEL equ gdt_data - gdt

msg_hi:      db "Stage 2 (E09): real mode, CS=0, going to protected mode", 13, 10, 0
msg_a20_off: db "A20: off (0x100500 wraps to 0x000500)", 13, 10, 0
msg_a20_on:  db "A20: on (0x100500 and 0x000500 are different bytes)", 13, 10, 0
msg_go:      db "cli, lgdt, CR0.PE=1, far jump...", 13, 10, 0
pm_msg1:     db "32-bit protected mode: no BIOS from here, writing to 0xB8000", 0
pm_msg2:     db "CR0 = 0x", 0
pm_msg3:     db "ESP = 0x", 0
pm_msg4:     db "CS  = 0x", 0

times SECTORS*512-4-($-$$) db 0
the_end: db "END!"
