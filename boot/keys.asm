; boot/keys.asm - ISOS E05: read the keyboard with BIOS int 0x16, echo each key
bits 16
org 0x7C00

start:
    xor ax, ax
    mov ds, ax
    mov si, prompt
    call print
.key:
    mov ah, 0x00            ; BIOS keyboard: wait for a key
    int 0x16                ; AL = ASCII code, AH = scan code
    cmp al, 13              ; Enter?
    je .bye
    call putc               ; echo it
    jmp .key
.bye:
    mov si, bye
    call print
.done:
    hlt
    jmp .done

print:                      ; print the zero-terminated string at DS:SI
    lodsb
    test al, al
    jz .ret
    call putc
    jmp print
.ret:
    ret

putc:                       ; AL to the screen (int 0x10) and to COM1
    mov ah, 0x0E
    int 0x10
    mov dx, 0x3F8
    out dx, al
    ret

prompt: db "Type, then Enter: ", 0
bye:    db 13, 10, "Bye from ISOS!", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
