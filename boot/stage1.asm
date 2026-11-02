bits 16
org 0x7C00

; E07 stage 1: the boot sector loads stage 2 from the disk, then jumps to it.
; Build with -DUSE_CHS to read with the old CHS call (int 0x13, AH=0x02).
STAGE2_LOAD    equ 0x7E00   ; right after this sector, in free low memory
%ifndef STAGE2_SECTORS
%define STAGE2_SECTORS 8 ; 8 x 512 = 4 KiB, LBA 1 to 8
%endif

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00          ; the stack grows down, below our sector
    sti
    mov [boot_drive], dl    ; the BIOS tells us which drive we booted from

    mov si, msg_s1
    call print
    mov al, dl
    call print_hex          ; "drive 0x80"
    mov si, crlf
    call print

    mov di, 3               ; up to 3 tries: real drives can fail once
.try:
%ifdef USE_CHS
    mov ah, 0x02            ; read sectors, CHS
    mov al, STAGE2_SECTORS  ; how many
    mov ch, 0               ; cylinder 0
    mov cl, 2               ; sector 2 (sectors count from 1)
    mov dh, 0               ; head 0
    mov dl, [boot_drive]
    mov bx, STAGE2_LOAD     ; ES:BX = 0x0000:0x7E00
%else
    mov ah, 0x42            ; extended read, LBA, with a disk address packet
    mov dl, [boot_drive]
    mov si, dap             ; DS:SI = the packet
%endif
    int 0x13
    jnc .ok                 ; carry clear: success
    mov [err], ah           ; carry set: AH = error code
    xor ah, ah              ; AH=0x00: reset the drive, then try again
    mov dl, [boot_drive]
    int 0x13
    dec di
    jnz .try

    mov si, msg_err         ; three failures: give up
    call print
    mov al, [err]
    call print_hex
    mov si, crlf
    call print
.halt:
    hlt
    jmp .halt

.ok:
    mov si, msg_ok
    call print
    mov dl, [boot_drive]    ; pass the drive number on
    jmp 0x0000:STAGE2_LOAD  ; far jump: CS = 0, IP = 0x7E00

; print the zero-terminated string at DS:SI (screen and COM1)
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
    mov dx, 0x3F8           ; COM1
    out dx, al
    mov ah, 0x0E            ; BIOS teletype
    xor bh, bh              ; on screen page 0
    int 0x10
    pop bx
    pop dx
    ret

; print AL as 0xNN
print_hex:
    push ax
    mov si, hex0x
    call print
    pop ax
    push ax
    shr al, 4
    call .nib
    pop ax
    and al, 0x0F
.nib:
    add al, '0'
    cmp al, '9'
    jbe .out
    add al, 7               ; 'A' to 'F'
.out:
    jmp putc

; the disk address packet (DAP) for AH=0x42: 16 bytes
dap:
    db 0x10                 ; size of the packet
    db 0                    ; reserved, always 0
    dw STAGE2_SECTORS       ; sectors to read
    dw STAGE2_LOAD          ; offset  } where to put them
    dw 0x0000               ; segment }
    dq 1                    ; first LBA (LBA 0 is this sector)

boot_drive: db 0
err:        db 0
msg_s1:  db "Stage 1: booted from drive ", 0
msg_ok:  db "Stage 1: stage 2 loaded, jumping", 13, 10, 0
msg_err: db "Stage 1: disk error, AH = ", 0
hex0x:   db "0x", 0
crlf:    db 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
