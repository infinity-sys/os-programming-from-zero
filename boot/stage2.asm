bits 16
org 0x7E00

; E07 stage 2: loaded by stage 1 from LBA 1 to 8 (4 KiB), no 512-byte limit any more.
SECTORS equ 8

stage2:
    mov [drive], dl
    mov si, msg_hi
    call print
    ; is the last byte of our 4 KiB really here? stage 1 must have read all 8 sectors
    cmp dword [the_end], 0x21444E45   ; "END!"
    jne .short
    mov si, msg_all
    call print
    jmp .geometry
.short:
    mov si, msg_short
    call print

.geometry:                  ; ask the BIOS for the drive's CHS geometry: int 0x13, AH=0x08
    mov ah, 0x08
    mov dl, [drive]
    xor di, di
    mov es, di              ; ES:DI = 0 (a BIOS bug workaround)
    int 0x13
    jc .done
    mov al, cl
    and al, 0x3F            ; CL bits 0-5: sectors per track
    mov [spt], al
    inc dh                  ; DH = last head number, so heads = DH + 1
    mov [heads], dh
    mov si, msg_geo1
    call print
    xor ah, ah
    mov al, [heads]
    call print_dec
    mov si, msg_geo2
    call print
    xor ah, ah
    mov al, [spt]
    call print_dec
    mov si, crlf
    call print
.done:
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

; print AX in decimal
print_dec:
    mov bx, 10
    xor cx, cx
.div:
    xor dx, dx
    div bx                  ; AX = AX / 10, DX = remainder
    push dx
    inc cx
    test ax, ax
    jnz .div
.put:
    pop ax
    add al, '0'
    call putc
    loop .put
    ret

drive: db 0
heads: db 0
spt:   db 0
msg_hi:    db "Stage 2: running at 0x7E00, 4096 bytes, 8 sectors", 13, 10, 0
msg_all:   db "Stage 2: last sector present (END!)", 13, 10, 0
msg_short: db "Stage 2: last sector MISSING", 13, 10, 0
msg_geo1:  db "Stage 2: BIOS geometry: heads = ", 0
msg_geo2:  db ", sectors per track = ", 0
msg_bye:   db "Stage 2: done, halting", 13, 10, 0
crlf:      db 13, 10, 0

times SECTORS*512-4-($-$$) db 0
the_end: db "END!"           ; the very last 4 bytes of sector 8
