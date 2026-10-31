bits 16
org 0x7C00

; E06: from 16-bit real mode into 32-bit protected mode
start:
    cli                     ; no BIOS interrupts from here on
    xor ax, ax
    mov ds, ax
    lgdt [gdt_ptr]          ; tell the CPU where our GDT is
    mov eax, cr0
    or eax, 1               ; PE bit: protection enable
    mov cr0, eax
    jmp 0x08:pm32           ; far jump: CS = selector 0x08, 32-bit code

bits 32
pm32:
    mov ax, 0x10            ; selector 0x10: the data segment
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esi, msg
    mov edi, 0xB8000        ; VGA text memory: no more int 0x10
.next:
    lodsb
    test al, al
    jz .done
    mov dx, 0x3F8           ; COM1 still works: out is not a BIOS call
    out dx, al
    mov ah, 0x1F            ; white on blue
    stosw                   ; character + colour into video memory
    jmp .next
.done:
    hlt
    jmp .done

gdt:
    dq 0                    ; 0x00: the null descriptor
    dq 0x00CF9A000000FFFF   ; 0x08: code, base 0, limit 4 GiB, 32-bit
    dq 0x00CF92000000FFFF   ; 0x10: data, base 0, limit 4 GiB
gdt_ptr:
    dw gdt_ptr - gdt - 1    ; size - 1
    dd gdt                  ; address

msg: db "Hello from 32-bit protected mode!", 0

times 510-($-$$) db 0
dw 0xAA55
