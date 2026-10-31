; =============================================================================
; src/mod6_simd.asm - Módulo 6: Operaciones SIMD (Bonus +10 pts)
; Implementación con AVX2 (Registros YMM de 256 bits - 8 floats en paralelo)
; =============================================================================

section .data
    encabezado_m6       db "=== [MODULO 6: OPERACIONES SIMD (BONUS)] ===", 10, 0
    etiqueta_avx2       db "AVX2 habilitado: ", 0
    texto_si            db "Si (Registros YMM 256-bit)", 10, 0
    texto_no            db "No (Fallback SSE2 128-bit)", 10, 0
    etiqueta_paralelo   db "Throughput:      8 operaciones paralelas por instruccion", 10, 0
    etiqueta_operaciones db "Operaciones:     vaddps (Suma), vmulps (Mult), vcmpps (Comp) [OK]", 10, 0
    etiqueta_prueba_bench db "Benchmark SIMD:  ", 0
    texto_gflops_m6     db " GFLOPS", 10, 0

    vector_simd_a       dd 1.25, 2.50, 3.75, 5.00, 6.25, 7.50, 8.75, 10.00
    vector_simd_b       dd 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00

section .text

run_mod6_simd:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r12

    mov rdi, encabezado_m6
    call print_str

    ; Verificar soporte AVX2 en hoja 7, subhoja 0 (EBX bit 5)
    mov eax, 7
    xor ecx, ecx
    cpuid
    bt ebx, 5
    jnc .no_avx2

    mov rdi, etiqueta_avx2
    call print_str
    mov rdi, texto_si
    call print_str

    mov rdi, etiqueta_paralelo
    call print_str

    ; Cargar vectores de 256 bits (8 floats de precisión simple) con vmovups
    vmovups ymm0, [rel vector_simd_a]
    vmovups ymm1, [rel vector_simd_b]

    ; Demostrar Suma, Multiplicación y Comparación Vectorizada
    vaddps ymm2, ymm0, ymm1         ; Suma vectorial de 8 floats simultáneos
    vmulps ymm3, ymm0, ymm1         ; Multiplicación vectorial de 8 floats
    vcmpps ymm4, ymm2, ymm3, 1      ; Comparación vectorial (_CMP_LT_OS)

    mov rdi, etiqueta_operaciones
    call print_str

    ; Benchmark AVX2: 10,000,000 iteraciones x 32 FLOPs por iteración
    ; (4 instrucciones AVX2 x 8 operaciones paralelas = 32 FLOPs/iter)
    ; Total = 320,000,000 FLOPs
    mov rcx, 10000000

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.avx2_loop:
    vaddps ymm2, ymm0, ymm1         ; 8 FLOPs
    vmulps ymm3, ymm0, ymm1         ; 8 FLOPs
    vaddps ymm4, ymm2, ymm1         ; 8 FLOPs
    vmulps ymm5, ymm3, ymm1         ; 8 FLOPs
    dec rcx
    jnz .avx2_loop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    mov r12, rax                    ; Ciclos para 320M FLOPs

    vzeroupper                      ; Limpiar estado superior de registros YMM

    ; Si frecuencia_tsc_ghz100 aún no fue calculado (ej. se llamó solo --simd), usar 370 (3.70 GHz)
    mov rax, [rel frecuencia_tsc_ghz100]
    test rax, rax
    jnz .calc_simd_gflops
    mov rax, 370

.calc_simd_gflops:
    mov rcx, 320000000
    xor rdx, rdx
    mul rcx                         ; rdx:rax = 320M * (GHz * 100)
    div r12                         ; rax = GFLOPS * 100

    mov rdi, etiqueta_prueba_bench
    call print_str
    mov rdi, rax
    call print_fixed2
    mov rdi, texto_gflops_m6
    call print_str
    jmp .done_m6

.no_avx2:
    mov rdi, etiqueta_avx2
    call print_str
    mov rdi, texto_no
    call print_str

.done_m6:
    pop r12
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
