; =============================================================================
; src/mod3_mem.asm - Módulo 3: Diagnóstico de Memoria RAM
; =============================================================================

TAMANO_PRUEBA_MEM equ 16777216          ; 16 MB

section .data
    encabezado_m3       db "=== [MODULO 3: DIAGNOSTICO DE MEMORIA] ===", 10, 0
    etiqueta_patron_aa  db "Patron 0xAA:        ", 0
    etiqueta_patron_55  db "Patron 0x55:        ", 0
    etiqueta_patron_inc db "Patron Incremental: ", 0
    texto_pasada_prefijo db "PASADA (", 0
    texto_error_sufijo  db " errores)", 10, 0
    etiqueta_ram_total   db "Memoria total:      ", 0
    texto_gb_sufijo     db " GB detectada (", 0
    texto_mb_sufijo     db " MB)", 10, 0
    texto_error_mmap    db "Error al reservar memoria con sys_mmap", 10, 0

section .bss
    align 16
    buffer_info_sistema resb 128

section .text

run_mod3_mem:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r12
    push r13
    push r14

    mov rdi, encabezado_m3
    call print_str

    mov rax, 9                      ; sys_mmap
    xor rdi, rdi
    mov rsi, TAMANO_PRUEBA_MEM
    mov rdx, 3                      ; PROT_READ | PROT_WRITE
    mov r10, 0x22                   ; MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9
    syscall

    cmp rax, -4095
    jae .mmap_failed
    mov r12, rax

    ; 1. Patrón 0xAA
    mov rdi, r12
    mov rcx, TAMANO_PRUEBA_MEM / 8
    mov rax, 0xAAAAAAAAAAAAAAAA
    cld
    rep stosq

    xor r13, r13
    mov rsi, r12
    mov rcx, TAMANO_PRUEBA_MEM / 8
    mov rbx, 0xAAAAAAAAAAAAAAAA
.loop_aa:
    mov rax, [rsi]
    xor rax, rbx
    popcnt rax, rax
    add r13, rax
    add rsi, 8
    dec rcx
    jnz .loop_aa

    mov rdi, etiqueta_patron_aa
    call print_str
    mov rdi, texto_pasada_prefijo
    call print_str
    mov rdi, r13
    call print_uint64
    mov rdi, texto_error_sufijo
    call print_str

    ; 2. Patrón 0x55
    mov rdi, r12
    mov rcx, TAMANO_PRUEBA_MEM / 8
    mov rax, 0x5555555555555555
    cld
    rep stosq

    xor r13, r13
    mov rsi, r12
    mov rcx, TAMANO_PRUEBA_MEM / 8
    mov rbx, 0x5555555555555555
.loop_55:
    mov rax, [rsi]
    xor rax, rbx
    popcnt rax, rax
    add r13, rax
    add rsi, 8
    dec rcx
    jnz .loop_55

    mov rdi, etiqueta_patron_55
    call print_str
    mov rdi, texto_pasada_prefijo
    call print_str
    mov rdi, r13
    call print_uint64
    mov rdi, texto_error_sufijo
    call print_str

    ; 3. Secuencia Incremental
    mov rdi, r12
    mov rcx, TAMANO_PRUEBA_MEM / 8
    xor rax, rax
.write_inc:
    mov [rdi], rax
    inc rax
    add rdi, 8
    dec rcx
    jnz .write_inc

    xor r13, r13
    mov rsi, r12
    mov rcx, TAMANO_PRUEBA_MEM / 8
    xor rbx, rbx
.verify_inc:
    mov rax, [rsi]
    xor rax, rbx
    popcnt rax, rax
    add r13, rax
    inc rbx
    add rsi, 8
    dec rcx
    jnz .verify_inc

    mov rdi, etiqueta_patron_inc
    call print_str
    mov rdi, texto_pasada_prefijo
    call print_str
    mov rdi, r13
    call print_uint64
    mov rdi, texto_error_sufijo
    call print_str

    ; Liberar memoria
    mov rax, 11                     ; sys_munmap
    mov rdi, r12
    mov rsi, TAMANO_PRUEBA_MEM
    syscall

    ; 4. Memoria Total vía sys_sysinfo (rax = 99)
    mov rax, 99
    lea rdi, [rel buffer_info_sistema]
    syscall

    mov rax, [rel buffer_info_sistema + 32] ; totalram (uint64)
    mov ebx, [rel buffer_info_sistema + 104]; mem_unit (uint32, zero-extended a rbx)
    xor rdx, rdx
    mul rbx                         ; rdx:rax = Total RAM en bytes

    ; Convertir bytes a MB -> dividir entre 1,048,576 (2^20)
    shrd rax, rdx, 20
    mov r14, rax                    ; r14 = Total MB

    ; Convertir MB a GB redondeando al entero más cercano: (MB + 512) / 1024
    mov rax, r14
    add rax, 512
    shr rax, 10                     ; rax = Total GB

    mov rdi, etiqueta_ram_total
    call print_str
    mov rdi, rax
    call print_uint64
    mov rdi, texto_gb_sufijo
    call print_str
    mov rdi, r14
    call print_uint64
    mov rdi, texto_mb_sufijo
    call print_str
    jmp .done_m3

.mmap_failed:
    mov rdi, texto_error_mmap
    call print_str

.done_m3:
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
