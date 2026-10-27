; =============================================================================
; src/mod2_ports.asm - Módulo 2: Monitor de Puertos E/S (60h, 61h, 3F8h)
; =============================================================================

section .data
    encabezado_m2       db "=== [MODULO 2: MONITOR DE PUERTOS E/S] ===", 10, 0
    etiqueta_espacio    db "Espacio E/S soportado: 0 - 65535 (16-bit DX)", 10, 0
    etiqueta_anchos     db "Anchos probados: 8-bit (AL), 16-bit (AX), 32-bit (EAX)", 10, 0
    etiqueta_p60         db "Puerto 60h (teclado): ", 0
    etiqueta_p61         db "Puerto 61h (panel):   ", 0
    etiqueta_p3f8        db "Puerto 3F8h (COM1):   ", 0
    texto_ok_hw         db "[OK] (Lectura directa I/O - Valor: ", 0
    texto_ok_trampa     db "[OK] (Proteccion Ring-3 verificada | RFLAGS: ", 0
    texto_cierre_parentesis db ")", 10, 0

section .bss
    align 16
    accion_senal        resb 152
    senal_anterior      resb 152
    bandera_fallo_es    resb 1
    rflags_guardado     resq 1

section .text

sig_restorer:
    mov rax, 15                     ; sys_rt_sigreturn
    syscall

io_sigsegv_handler:
    mov byte [rel bandera_fallo_es], 1
    mov rax, [rdx + 176]            ; RFLAGS en ucontext_t
    mov [rel rflags_guardado], rax
    lea rax, [rel io_resume_point]
    mov [rdx + 168], rax            ; Avanzar RIP a io_resume_point
    ret

test_io_port:
    push rbx
    push rcx
    push rdx
    push rdi

    mov byte [rel bandera_fallo_es], 0
    xor rax, rax

    in al, dx                       ; Lectura 8 bits
    in ax, dx                       ; Lectura 16 bits
    in eax, dx                      ; Lectura 32 bits

    cmp dx, 0x60
    je .save_flags_ok
    out dx, al                      ; Escritura 8 bits

.save_flags_ok:
    pushfq
    pop qword [rel rflags_guardado]

io_resume_point:
    cmp byte [rel bandera_fallo_es], 0
    jne .handled_ring3

    push rax
    mov rdi, texto_ok_hw
    call print_str
    pop rax
    movzx rdi, al
    call print_hex64
    mov rdi, texto_cierre_parentesis
    call print_str
    jmp .done_port

.handled_ring3:
    mov rdi, texto_ok_trampa
    call print_str
    mov rdi, [rel rflags_guardado]
    call print_hex64
    mov rdi, texto_cierre_parentesis
    call print_str

.done_port:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

run_mod2_ports:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    mov rdi, encabezado_m2
    call print_str
    mov rdi, etiqueta_espacio
    call print_str
    mov rdi, etiqueta_anchos
    call print_str

    ; Instalar handler SIGSEGV y guardar el anterior en senal_anterior
    lea rdi, [rel accion_senal]
    lea rax, [rel io_sigsegv_handler]
    mov [rdi], rax
    mov qword [rdi + 8], 0x04000004 ; SA_RESTORER | SA_SIGINFO
    lea rax, [rel sig_restorer]
    mov [rdi + 16], rax
    mov qword [rdi + 24], 0

    mov rax, 13                     ; sys_rt_sigaction
    mov rdi, 11                     ; SIGSEGV
    lea rsi, [rel accion_senal]
    lea rdx, [rel senal_anterior]
    mov r10, 8
    syscall

    ; Intentar sys_ioperm
    mov rax, 173
    mov rdi, 0x60
    mov rsi, 0x3A0
    mov rdx, 1
    syscall

    ; Probar Puertos 60h, 61h, 3F8h
    mov rdi, etiqueta_p60
    call print_str
    mov dx, 0x0060
    call test_io_port

    mov rdi, etiqueta_p61
    call print_str
    mov dx, 0x0061
    call test_io_port

    mov rdi, etiqueta_p3f8
    call print_str
    mov dx, 0x03F8
    call test_io_port

    ; Restaurar el signal handler original del sistema (senal_anterior)
    mov rax, 13
    mov rdi, 11
    lea rsi, [rel senal_anterior]
    xor rdx, rdx
    mov r10, 8
    syscall

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
