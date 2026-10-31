; boot.asm - ISOS E01: a 512-byte boot sector that says hello
bits 16
org 0x7C00              ; the BIOS loads us at address 0x7C00

start:
    xor ax, ax
    mov ds, ax          ; data segment = 0
    mov si, msg
.next:
    lodsb               ; AL = next byte of msg
    test al, al
    jz .done            ; 0 marks the end
    mov ah, 0x0E        ; BIOS teletype: print AL on screen
    int 0x10
    mov dx, 0x3F8       ; COM1 serial port
    out dx, al          ; same byte to the serial line
    jmp .next
.done:
    hlt
    jmp .done

msg: db "Hello from ISOS!", 13, 10, 0

times 510-($-$$) db 0   ; pad to byte 510
dw 0xAA55               ; signature: bytes 55 AA
