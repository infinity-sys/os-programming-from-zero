bits 16
org 0x7C00

; E06: is the A20 line on? 0xFFFF:0x0510 = 0x100500, which wraps to 0x000500 if A20 is off
start:
    xor ax, ax
    mov ds, ax              ; DS = 0x0000
    mov ax, 0xFFFF
    mov es, ax              ; ES = 0xFFFF
    call test_a20
    in al, 0x92             ; "fast A20" port
    and al, 0xFD            ; clear bit 1: switch A20 off
    out 0x92, al
    call test_a20
    in al, 0x92
    or al, 2                ; set bit 1: A20 back on
    out 0x92, al
    call test_a20
.done:
    hlt
    jmp .done

test_a20:                   ; write 0x00 at 0x000500, 0xFF at FFFF:0510
    mov byte [0x0500], 0x00
    mov byte [es:0x0510], 0xFF
    mov si, on
    cmp byte [0x0500], 0xFF ; did the write land on 0x000500?
    jne print
    mov si, off
print:
    lodsb
    test al, al
    jz .ret
    mov dx, 0x3F8           ; COM1
    out dx, al
    mov ah, 0x0E            ; and the screen
    int 0x10
    jmp print
.ret:
    ret

on:  db "A20 on:  FFFF:0510 = 0x100500", 13, 10, 0
off: db "A20 off: FFFF:0510 wraps to 0x000500", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
