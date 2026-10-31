; boot/segs.asm - ISOS E05: the same boot sector, addressed as 07C0:0000
bits 16
org 0                       ; offsets now count from the start of the sector

start:
    jmp 0x07C0:go           ; far jump: CS = 0x07C0, IP = go
go:
    mov ax, 0x07C0
    mov ds, ax              ; DS = 0x07C0, so DS x 16 = 0x7C00
    mov si, msg             ; a small offset inside our segment
.next:
    lodsb                   ; AL = byte at DS:SI, SI = SI + 1
    test al, al
    jz .done
    mov ah, 0x0E            ; BIOS teletype
    int 0x10
    mov dx, 0x3F8           ; COM1
    out dx, al
    jmp .next
.done:
    hlt
    jmp .done

msg: db "Hello via 07C0:0000!", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
