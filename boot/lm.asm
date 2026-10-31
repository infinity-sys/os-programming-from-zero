bits 16
org 0x7C00

; E06: real mode -> 64-bit long mode, all inside 512 bytes
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov edi, 0x1000         ; page tables at 0x1000, 0x2000, 0x3000
    mov ecx, 0x3000 / 4
    xor eax, eax
    rep stosd               ; clear 12 KiB
    mov dword [0x1000], 0x2003  ; PML4[0] -> PDPT (present, writable)
    mov dword [0x2000], 0x3003  ; PDPT[0] -> page directory
    mov dword [0x3000], 0x0083  ; PD[0]: one 2 MiB page at 0 (huge)
    mov eax, cr4
    or eax, 1 << 5          ; PAE
    mov cr4, eax
    mov eax, 0x1000
    mov cr3, eax            ; CR3 = the top table
    mov ecx, 0xC0000080     ; EFER
    rdmsr
    or eax, 1 << 8          ; LME: long mode enable
    wrmsr
    mov eax, cr0
    or eax, (1 << 31) | 1   ; PG + PE: paging and protection together
    mov cr0, eax
    lgdt [gdt_ptr]
    jmp 0x08:lm64           ; far jump into the 64-bit code segment

bits 64
lm64:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov rsi, msg
    mov rdi, 0xB8000
.next:
    lodsb
    test al, al
    jz .done
    mov dx, 0x3F8
    out dx, al
    mov ah, 0x2F            ; white on green
    stosw
    jmp .next
.done:
    hlt
    jmp .done

gdt:
    dq 0                    ; null
    dq 0x00209A0000000000   ; 0x08: 64-bit code (L bit set)
gdt_ptr:
    dw gdt_ptr - gdt - 1
    dd gdt

msg: db "Hello from 64-bit long mode!", 0

times 510-($-$$) db 0
dw 0xAA55
