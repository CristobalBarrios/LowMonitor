; =============================================================================
; src/main.asm - Punto de entrada principal y Parser CLI (LowMonitor - Carga 5)
; =============================================================================

%include "src/utils.asm"
%include "src/mod1_cpu.asm"
%include "src/mod2_ports.asm"
%include "src/mod3_mem.asm"
%include "src/mod4_perf.asm"
%include "src/mod5_hierarchy.asm"

section .data
    mensaje_banner:
        db "╔═════════════════════════════════════════════════════════════╗", 10
        db "║ _    _ __  __  _____                                        ║", 10
        db "║| |  | |  \/  |/ ____|                                       ║", 10
        db "║| |  | | \  / | |  __                                        ║", 10
        db "║| |  | | |\/| | | |_ |                                       ║", 10
        db "║| |__| | |  | | |__| |    _ _            _                   ║", 10
        db "║ \__/\/|_|  |_|\_____|   (_) |          | |                  ║", 10
        db "║   /  \   _ __ __ _ _   _ _| |_ ___  ___| |_ _   _ _ __ __ _ ║", 10
        db "║  / /\ \ | '__/ _` | | | | | __/ _ \/ __| __| | | | '__/ _` |║", 10
        db "║ / ____ \| | | (_| | |_| | | ||  __/ (__| |_| |_| | | | (_| |║", 10
        db "║/_/    \_\_|  \__, |\__,_|_|\__\___|\___|\__|\__,_|_|  \__,_|║", 10
        db "║                 | |                                         ║", 10
        db "║                 |_|                                         ║", 10
        db "╚═════════════════════════════════════════════════════════════╝", 10
        db "LowMonitor v1.0 - Diagnostico de Hardware x86-64 [Carga 5: CPU + Puertos + Memoria + Rendimiento + Jerarquia]", 10, 0
    mensaje_ayuda db "Uso: ./bin/lowmonitor [OPCION]", 10
                db "Opciones:", 10
                db "  --cpu       Ejecutar Modulo 1: Identificacion del CPU", 10
                db "  --ports     Ejecutar Modulo 2: Monitor de puertos E/S", 10
                db "  --memory    Ejecutar Modulo 3: Diagnostico de memoria", 10
                db "  --perf      Ejecutar Modulo 4: Monitor de rendimiento CPU", 10
                db "  --hierarchy Ejecutar Modulo 5: Jerarquia de memoria", 10
                db "  --all       Ejecutar todos los modulos implementados", 10, 0

    opcion_cpu         db "--cpu", 0
    opcion_puertos     db "--ports", 0
    opcion_memoria     db "--memory", 0
    opcion_rendimiento db "--perf", 0
    opcion_jerarquia   db "--hierarchy", 0
    opcion_todos       db "--all", 0

section .bss
    ; Espacio reservado general

section .text
    global _start

_start:
    mov rcx, [rsp]
    cmp rcx, 2
    jl .show_help

    mov rbx, [rsp + 16]             ; argv[1]

    mov rdi, rbx
    mov rsi, opcion_cpu
    call strcmp
    test rax, rax
    jz .exec_cpu

    mov rdi, rbx
    mov rsi, opcion_puertos
    call strcmp
    test rax, rax
    jz .exec_ports

    mov rdi, rbx
    mov rsi, opcion_memoria
    call strcmp
    test rax, rax
    jz .exec_memory

    mov rdi, rbx
    mov rsi, opcion_rendimiento
    call strcmp
    test rax, rax
    jz .exec_perf

    mov rdi, rbx
    mov rsi, opcion_jerarquia
    call strcmp
    test rax, rax
    jz .exec_hierarchy

    mov rdi, rbx
    mov rsi, opcion_todos
    call strcmp
    test rax, rax
    jz .exec_all

    jmp .show_help

.exec_cpu:
    call run_mod1_cpu
    jmp .exit_ok

.exec_ports:
    call run_mod2_ports
    jmp .exit_ok

.exec_memory:
    call run_mod3_mem
    jmp .exit_ok

.exec_perf:
    call run_mod4_perf
    jmp .exit_ok

.exec_hierarchy:
    call run_mod5_hierarchy
    jmp .exit_ok

.exec_all:
    mov rdi, mensaje_banner
    call print_str
    call print_newline
    call run_mod1_cpu
    call print_newline
    call run_mod2_ports
    call print_newline
    call run_mod3_mem
    call print_newline
    call run_mod4_perf
    call print_newline
    call run_mod5_hierarchy
    jmp .exit_ok

.show_help:
    mov rdi, mensaje_banner
    call print_str
    mov rdi, mensaje_ayuda
    call print_str

.exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall
