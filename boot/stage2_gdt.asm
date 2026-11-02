bits 16
org 0x7E00

; E08 stage 2: a hand-written GDT, loaded with lgdt and read back with sgdt.
; Same stage 1 as E07 (8 sectors from LBA 1 to 0x7E00). Still real mode: E09 switches.
SECTORS equ 8

stage2:
    mov si, msg_hi
    call print

    cli                     ; no interrupts while we touch descriptor tables
    lgdt [gdtr]             ; GDTR <- 6 bytes: limit (16 bits), base (32 bits)
    sti

    sgdt [check]            ; read the GDTR back into memory
    mov si, msg_limit
    call print
    mov ax, [check]         ; limit
    call print_hex16
    mov si, msg_base
    call print
    mov ax, [check+4]       ; base, high word
    call print_hex16
    mov ax, [check+2]       ; base, low word
    call print_hex16
    mov si, crlf
    call print

    mov si, msg_sel
    call print
    mov ax, CODE_SEL
    call print_hex16
    mov si, msg_sel2
    call print
    mov ax, DATA_SEL
    call print_hex16
    mov si, crlf
    call print

    mov si, msg_bye
    call print
.halt:
    hlt
    jmp .halt

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

; print AX as 4 hex digits
print_hex16:
    mov cx, 4
.digit:
    rol ax, 4               ; top nibble to the bottom
    push ax
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe .out
    add al, 7               ; 'A' to 'F'
.out:
    call putc
    pop ax
    loop .digit
    ret

; ---- the GDT: three 8-byte descriptors, 8-byte aligned ----
align 8
gdt:
gdt_null:  dq 0                     ; 0x00: the CPU requires a null descriptor first
gdt_code:                           ; 0x08: code, base 0, limit 0xFFFFF x 4 KiB = 4 GiB
    dw 0xFFFF                       ; limit 0-15
    dw 0x0000                       ; base 0-15
    db 0x00                         ; base 16-23
    db 10011010b                    ; access: P=1 DPL=00 S=1 type=1010 (code, exec/read)
    db 11001111b                    ; flags G=1 D=1 L=0 AVL=0, limit 16-19 = 1111
    db 0x00                         ; base 24-31
gdt_data:                           ; 0x10: data, same base and limit
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                    ; access: P=1 DPL=00 S=1 type=0010 (data, read/write)
    db 11001111b
    db 0x00
gdt_end:

gdtr:
    dw gdt_end - gdt - 1            ; limit: size in bytes minus 1 = 23
    dd gdt                          ; linear base address of the table

CODE_SEL equ gdt_code - gdt         ; selector = index x 8 (TI=0, RPL=0)
DATA_SEL equ gdt_data - gdt

check:     dw 0
           dd 0
msg_hi:    db "Stage 2 (E08): loading a GDT with 3 descriptors", 13, 10, 0
msg_limit: db "GDTR (sgdt): limit = 0x", 0
msg_base:  db ", base = 0x", 0
msg_sel:   db "Selectors: code = 0x", 0
msg_sel2:  db ", data = 0x", 0
msg_bye:   db "Stage 2: GDT loaded, still in real mode, halting", 13, 10, 0
crlf:      db 13, 10, 0

times SECTORS*512-4-($-$$) db 0
the_end: db "END!"           ; the very last 4 bytes of sector 8
