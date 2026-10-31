; =============================================================================
; src/mod5_hierarchy.asm - Módulo 5: Gestión Jerárquica de Memoria
; Medición de latencia real derrotando al Hardware Stride Prefetcher
; =============================================================================

TAMANO_BUFFER_JERARQUIA equ 33554432        ; 32 MB para cubrir L1, L2, L3 y RAM

section .data
    encabezado_m5       db "=== [MODULO 5: GESTION JERARQUICA DE MEMORIA] ===", 10, 0
    etiqueta_registros  db "Registros: ", 0
    texto_unidad_registros db " ciclo", 10, 0
    etiqueta_l1         db "L1 cache:  ", 0
    texto_unidad_l1     db " ciclos (32KB)", 10, 0
    etiqueta_l2         db "L2 cache:  ", 0
    texto_unidad_l2     db " ciclos (512KB)", 10, 0
    etiqueta_l3         db "L3 cache:  ", 0
    texto_unidad_l3     db " ciclos (16MB)", 10, 0
    etiqueta_ram        db "RAM:       ", 0
    texto_unidad_ram    db " ciclos (Acceso directo con CLFLUSH)", 10, 0

section .text

; -----------------------------------------------------------------------------
; measure_pointer_chase: Crea un anillo de punteros pseudoaleatorio usando un
; paso primo (167 líneas de caché) sobre una máscara potencia de 2 (size/64 - 1)
; para evitar que el prefetcher L1/L2 adivine el siguiente acceso.
; Entrada: rdi = base_ptr, rsi = tamaño_bloque_bytes (potencia de 2)
; Salida:  rax = ciclos por acceso
; -----------------------------------------------------------------------------
measure_pointer_chase:
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11

    mov r8, rdi                     ; r8 = base_ptr
    mov r9, rsi
    shr r9, 6                       ; r9 = N líneas de 64 bytes (potencia de 2)
    mov r10, r9
    dec r10                         ; r10 = máscara (N - 1)

    xor rcx, rcx                    ; rcx = nodo actual (0)
    mov r11, r9                     ; contador de nodos a enlazar

.build_random_ring:
    mov rax, rcx
    add rax, 167                    ; Salto primo (impar -> recorre todos los nodos de 2^k)
    and rax, r10                    ; rax = siguiente nodo = (actual + 167) & (N - 1)

    ; Dirección del nodo actual: r8 + (rcx * 64)
    mov rdx, rcx
    shl rdx, 6
    ; Dirección del nodo siguiente: r8 + (rax * 64)
    mov rbx, rax
    shl rbx, 6
    lea rbx, [r8 + rbx]

    mov [r8 + rdx], rbx             ; Guardar puntero al siguiente nodo
    mov rcx, rax                    ; Avanzar al siguiente nodo
    dec r11
    jnz .build_random_ring

    ; Warm-up de la caché
    mov rax, r8
    mov rcx, r9
.warmup:
    mov rax, [rax]
    dec rcx
    jnz .warmup

    ; Medición con RDTSC sobre 1,000,000 de saltos dependientes
    mov rbx, r8
    mov rcx, 1000000

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r9, rax

.chase_loop:
    mov rbx, [rbx]
    mov rbx, [rbx]
    mov rbx, [rbx]
    mov rbx, [rbx]
    sub rcx, 4
    jnz .chase_loop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r9

    xor rdx, rdx
    mov rcx, 1000000
    div rcx

    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

run_mod5_hierarchy:
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push r12
    push r13

    mov rdi, encabezado_m5
    call print_str

    mov rax, 9                      ; sys_mmap
    xor rdi, rdi
    mov rsi, TAMANO_BUFFER_JERARQUIA
    mov rdx, 3
    mov r10, 0x22
    mov r8, -1
    xor r9, r9
    syscall

    cmp rax, -4095
    jae .done_m5
    mov r12, rax

    ; 1. Registros
    mov rcx, 250000
    mov rbx, 1
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r13, rax

.reg_loop:
    mov rax, rbx
    mov rbx, rax
    mov rax, rbx
    mov rbx, rax
    dec rcx
    jnz .reg_loop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r13
    xor rdx, rdx
    mov rcx, 1000000
    div rcx
    test rax, rax
    jnz .print_reg
    mov rax, 1
.print_reg:
    mov rdi, etiqueta_registros
    call print_str
    mov rdi, rax
    call print_uint64
    mov rdi, texto_unidad_registros
    call print_str

    ; 2. L1 Caché (16 KB)
    mov rdi, r12
    mov rsi, 16384
    call measure_pointer_chase
    mov rdi, etiqueta_l1
    call print_str
    mov rdi, rax
    call print_uint64
    mov rdi, texto_unidad_l1
    call print_str

    ; 3. L2 Caché (256 KB)
    mov rdi, r12
    mov rsi, 262144
    call measure_pointer_chase
    mov rdi, etiqueta_l2
    call print_str
    mov rdi, rax
    call print_uint64
    mov rdi, texto_unidad_l2
    call print_str

    ; 4. L3 Caché (16 MB)
    mov rdi, r12
    mov rsi, 16777216
    call measure_pointer_chase
    mov rdi, etiqueta_l3
    call print_str
    mov rdi, rax
    call print_uint64
    mov rdi, texto_unidad_l3
    call print_str

    ; 5. RAM Principal (CLFLUSH)
    mov rcx, 10000
    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r13, rax

.ram_loop:
    clflush [r12]
    mfence
    mov rax, [r12]
    lfence
    dec rcx
    jnz .ram_loop

    lfence
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, r13
    xor rdx, rdx
    mov rcx, 10000
    div rcx

    mov rdi, etiqueta_ram
    call print_str
    mov rdi, rax
    call print_uint64
    mov rdi, texto_unidad_ram
    call print_str

    mov rax, 11
    mov rdi, r12
    mov rsi, TAMANO_BUFFER_JERARQUIA
    syscall

.done_m5:
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
