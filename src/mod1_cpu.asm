; =============================================================================
; src/mod1_cpu.asm - Módulo 1: Identificación del CPU
; =============================================================================

section .data
    encabezado_m1       db "=== [MODULO 1: IDENTIFICACION DEL CPU] ===", 10, 0
    etiqueta_fabricante db "Fabricante: ", 0
    etiqueta_procesador db "Procesador: ", 0
    etiqueta_arquitectura db "Arquitectura: x86_64", 10, 0
    etiqueta_familia    db "Familia: ", 0
    etiqueta_modelo     db "Modelo: ", 0
    etiqueta_revision   db "Stepping: ", 0
    etiqueta_extensiones db "Extensiones: ", 0

    texto_sse         db "SSE ", 0
    texto_sse2        db "SSE2 ", 0
    texto_sse42       db "SSE4.2 ", 0
    texto_avx         db "AVX ", 0
    texto_avx2        db "AVX2 ", 0
    texto_avx512      db "AVX-512 ", 0

section .bss
    buffer_fabricante resb 13         ; 12 bytes + NULL
    buffer_procesador resb 49         ; 48 bytes + NULL
    caracteristicas_edx  resd 1
    caracteristicas_ecx  resd 1
    caracteristicas_ebx7 resd 1

section .text

run_mod1_cpu:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, encabezado_m1
    call print_str

    ; -------------------------------------------------------------------------
    ; 1. Nombre Comercial del Procesador (Hojas 0x80000002 - 0x80000004)
    ; -------------------------------------------------------------------------
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000004
    jb .skip_brand

    lea rdi, [buffer_procesador]
    mov eax, 0x80000002
    cpuid
    mov [rdi], eax
    mov [rdi + 4], ebx
    mov [rdi + 8], ecx
    mov [rdi + 12], edx

    mov eax, 0x80000003
    cpuid
    mov [rdi + 16], eax
    mov [rdi + 20], ebx
    mov [rdi + 24], ecx
    mov [rdi + 28], edx

    mov eax, 0x80000004
    cpuid
    mov [rdi + 32], eax
    mov [rdi + 36], ebx
    mov [rdi + 40], ecx
    mov [rdi + 44], edx
    mov byte [rdi + 48], 0

    mov rdi, etiqueta_procesador
    call print_str

    ; Omitir espacios iniciales si existen en el brand string
    lea rdi, [buffer_procesador]
.trim_spaces:
    cmp byte [rdi], ' '
    jne .print_brand_now
    inc rdi
    jmp .trim_spaces
.print_brand_now:
    call print_str
    call print_newline

.skip_brand:
    ; -------------------------------------------------------------------------
    ; 2. Fabricante (Vendor ID - Hoja 0)
    ; -------------------------------------------------------------------------
    xor eax, eax
    cpuid
    mov [buffer_fabricante], ebx
    mov [buffer_fabricante + 4], edx
    mov [buffer_fabricante + 8], ecx
    mov byte [buffer_fabricante + 12], 0

    mov rdi, etiqueta_fabricante
    call print_str
    mov rdi, buffer_fabricante
    call print_str
    call print_newline

    ; Imprimir Arquitectura fija x86_64
    mov rdi, etiqueta_arquitectura
    call print_str

    ; -------------------------------------------------------------------------
    ; 3. Familia, Modelo, Stepping y Flags Base (Hoja 1)
    ; -------------------------------------------------------------------------
    mov eax, 1
    cpuid
    mov [caracteristicas_ecx], ecx
    mov [caracteristicas_edx], edx

    mov r8d, eax                    ; Guardar EAX completo para Familia/Modelo

    ; Stepping = EAX[3:0]
    mov r9d, r8d
    and r9d, 0x0F

    ; Base Model = EAX[7:4], Extended Model = EAX[19:16]
    mov r10d, r8d
    shr r10d, 4
    and r10d, 0x0F                  ; Base Model

    ; Base Family = EAX[11:8], Extended Family = EAX[27:20]
    mov r11d, r8d
    shr r11d, 8
    and r11d, 0x0F                  ; Base Family

    cmp r11d, 6
    je .calc_ext_model
    cmp r11d, 15
    jne .print_fam_mod

    ; Si Family == 15, sumar Extended Family
    mov eax, r8d
    shr eax, 20
    and eax, 0xFF
    add r11d, eax

.calc_ext_model:
    mov eax, r8d
    shr eax, 12
    and eax, 0xF0
    or r10d, eax

.print_fam_mod:
    ; Imprimir Familia
    mov rdi, etiqueta_familia
    call print_str
    mov edi, r11d
    call print_uint64
    call print_newline

    ; Imprimir Modelo
    mov rdi, etiqueta_modelo
    call print_str
    mov edi, r10d
    call print_uint64
    call print_newline

    ; Imprimir Stepping
    mov rdi, etiqueta_revision
    call print_str
    mov edi, r9d
    call print_uint64
    call print_newline

    ; -------------------------------------------------------------------------
    ; 4. Extensiones (SSE, SSE2, SSE4.2, AVX, AVX2, AVX-512)
    ; -------------------------------------------------------------------------
    mov eax, 7
    xor ecx, ecx
    cpuid
    mov [caracteristicas_ebx7], ebx

    mov rdi, etiqueta_extensiones
    call print_str

    ; SSE: EDX bit 25
    mov eax, [caracteristicas_edx]
    bt eax, 25
    jnc .chk_sse2
    mov rdi, texto_sse
    call print_str

.chk_sse2:
    ; SSE2: EDX bit 26
    mov eax, [caracteristicas_edx]
    bt eax, 26
    jnc .chk_sse42
    mov rdi, texto_sse2
    call print_str

.chk_sse42:
    ; SSE4.2: ECX bit 20
    mov eax, [caracteristicas_ecx]
    bt eax, 20
    jnc .chk_avx
    mov rdi, texto_sse42
    call print_str

.chk_avx:
    ; AVX: ECX bit 28
    mov eax, [caracteristicas_ecx]
    bt eax, 28
    jnc .chk_avx2
    mov rdi, texto_avx
    call print_str

.chk_avx2:
    ; AVX2: Hoja 7 EBX bit 5
    mov eax, [caracteristicas_ebx7]
    bt eax, 5
    jnc .chk_avx512
    mov rdi, texto_avx2
    call print_str

.chk_avx512:
    ; AVX-512F: Hoja 7 EBX bit 16
    mov eax, [caracteristicas_ebx7]
    bt eax, 16
    jnc .ext_done
    mov rdi, texto_avx512
    call print_str

.ext_done:
    call print_newline

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
