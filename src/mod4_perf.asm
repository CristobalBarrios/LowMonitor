; =============================================================================
; src/mod4_perf.asm - Módulo 4: Monitor de Rendimiento del CPU
; =============================================================================

section .data
    encabezado_m4       db "=== [MODULO 4: MONITOR DE RENDIMIENTO DEL CPU] ===", 10, 0
    etiqueta_frecuencia db "Frecuencia:     ", 0
    texto_ghz           db " GHz", 10, 0
    etiqueta_ciclos     db "Ciclos totales: ", 0
    etiqueta_instrucciones db "Instrucciones:  ", 0
    etiqueta_cpi        db "CPI promedio:   ", 0
    etiqueta_ipc        db "IPC:            ", 0
    etiqueta_rendimiento db "Throughput:     ", 0
    texto_gflops        db " GFLOPS", 10, 0

    align 8
    tiempo_solicitado:
        dq 0                        ; 0 segundos
        dq 100000000                ; 100,000,000 ns (100 ms)

    vector_flotante_a   dd 1.5, 2.5, 3.5, 4.5
    vector_flotante_b   dd 1.1, 1.2, 1.3, 1.4

section .bss
    align 8
    frecuencia_tsc_ghz100 resq 1

section .text

run_mod4_perf:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r12
    push r13
    push r14

    mov rdi, encabezado_m4
    call print_str

    ; 1. Medir Frecuencia del CPU con RDTSC durante 100 ms
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax                    ; TSC inicial

    mov rax, 35                     ; sys_nanosleep
    lea rdi, [rel tiempo_solicitado]
    xor rsi, rsi
    syscall

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12                    ; Ciclos en 0.1 s

    ; Escalar a GHz * 100: (Ciclos_0.1s * 10) / 10,000,000 = Ciclos_0.1s / 1,000,000
    xor rdx, rdx
    mov rcx, 1000000
    div rcx
    test rax, rax
    jnz .save_freq
    mov rax, 370                    ; Fallback seguro si corre en emulador sin TSC
.save_freq:
    mov [rel frecuencia_tsc_ghz100], rax

    mov rdi, etiqueta_frecuencia
    call print_str
    mov rdi, [rel frecuencia_tsc_ghz100]
    call print_fixed2
    mov rdi, texto_ghz
    call print_str

    ; 2. Medir Ciclos Totales, CPI e IPC (100,000,000 instrucciones)
    mov rcx, 10000000
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.perf_loop:
    add r8, 1
    add r9, r8
    xor r10, r9
    add r11, r10
    rol r8, 3
    add r9, r11
    xor r8, r10
    add r10, 5
    dec rcx
    jnz .perf_loop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    mov r12, rax                    ; r12 = Ciclos totales
    mov r14, 100000000              ; r14 = 100M instrucciones

    mov rdi, etiqueta_ciclos
    call print_str
    mov rdi, r12
    call print_uint64
    call print_newline

    mov rdi, etiqueta_instrucciones
    call print_str
    mov rdi, r14
    call print_uint64
    call print_newline

    ; CPI * 100 = (Ciclos * 100) / Instrucciones
    mov rax, r12
    mov rcx, 100
    xor rdx, rdx
    mul rcx
    div r14
    mov rdi, etiqueta_cpi
    call print_str
    mov rdi, rax
    call print_fixed2
    call print_newline

    ; IPC * 100 = (Instrucciones * 100) / Ciclos
    mov rax, r14
    mov rcx, 100
    xor rdx, rdx
    mul rcx
    div r12
    mov rdi, etiqueta_ipc
    call print_str
    mov rdi, rax
    call print_fixed2
    call print_newline

    ; 3. Medir Throughput en GFLOPS usando SSE (movups seguro ante alineamiento)
    movups xmm0, [rel vector_flotante_a]
    movups xmm1, [rel vector_flotante_b]
    movups xmm2, xmm0
    movups xmm3, xmm1
    mov rcx, 10000000

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r12, rax

.flops_loop:
    addps xmm0, xmm1
    mulps xmm2, xmm1
    addps xmm3, xmm1
    mulps xmm0, xmm1
    dec rcx
    jnz .flops_loop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r12
    mov r12, rax                    ; r12 = ciclos para 160,000,000 FLOPs

    mov rax, 160000000
    xor rdx, rdx
    mul qword [rel frecuencia_tsc_ghz100]
    div r12                         ; rax = GFLOPS * 100

    mov rdi, etiqueta_rendimiento
    call print_str
    mov rdi, rax
    call print_fixed2
    mov rdi, texto_gflops
    call print_str

    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
