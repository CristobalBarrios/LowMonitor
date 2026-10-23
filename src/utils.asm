; =============================================================================
; src/utils.asm - Rutinas auxiliares x86-64 (Impresión, Conversiones, Strings)
; =============================================================================

section .data
    caracter_salto db 10, 0
    caracter_punto db ".", 0
    caracter_cero  db "0", 0

section .bss
    buffer_numero resb 64           ; Buffer temporal para conversiones ASCII

section .text

; -----------------------------------------------------------------------------
; strlen: Calcula la longitud de un string terminado en NULL (0)
; Entrada: rdi = puntero al string | Salida: rax = longitud
; -----------------------------------------------------------------------------
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; -----------------------------------------------------------------------------
; print_str: Imprime un string terminado en NULL por stdout (Preserva RAX)
; Entrada: rdi = puntero al string
; -----------------------------------------------------------------------------
print_str:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    push r11

    call strlen
    mov rdx, rax                    ; rdx = longitud
    mov rsi, rdi                    ; rsi = puntero al buffer
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    syscall

    pop r11
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

; -----------------------------------------------------------------------------
; print_newline: Imprime un salto de línea (0x0A)
; -----------------------------------------------------------------------------
print_newline:
    push rdi
    lea rdi, [rel caracter_salto]
    call print_str
    pop rdi
    ret

; -----------------------------------------------------------------------------
; print_uint64: Convierte e imprime un entero de 64 bits sin signo en decimal
; Entrada: rdi = valor de 64 bits
; -----------------------------------------------------------------------------
print_uint64:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi
    mov rcx, 10
    lea rsi, [rel buffer_numero + 63]
    mov byte [rsi], 0

    test rax, rax
    jnz .convert
    dec rsi
    mov byte [rsi], '0'
    jmp .print

.convert:
    xor rdx, rdx
    div rcx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .convert

.print:
    mov rdi, rsi
    call print_str

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; -----------------------------------------------------------------------------
; print_fixed2: Imprime un entero escalado x100 con 2 decimales (ej. 370 -> 3.70)
; Entrada: rdi = valor escalado por 100
; -----------------------------------------------------------------------------
print_fixed2:
    push rax
    push rcx
    push rdx
    push rdi
    push r12

    mov rax, rdi
    xor rdx, rdx
    mov rcx, 100
    div rcx                         ; rax = entero, rdx = centésimas
    mov r12, rdx                    ; guardar centésimas en r12

    mov rdi, rax
    call print_uint64

    lea rdi, [rel caracter_punto]
    call print_str

    cmp r12, 10
    jae .no_zero
    lea rdi, [rel caracter_cero]
    call print_str

.no_zero:
    mov rdi, r12
    call print_uint64

    pop r12
    pop rdi
    pop rdx
    pop rcx
    pop rax
    ret

; -----------------------------------------------------------------------------
; print_hex64: Imprime un registro de 64 bits en formato Hexadecimal (0x...)
; Entrada: rdi = valor de 64 bits
; -----------------------------------------------------------------------------
print_hex64:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi
    lea rsi, [rel buffer_numero + 63]
    mov byte [rsi], 0
    mov rcx, 16

.hex_loop:
    mov rdx, rax
    and rdx, 0x0F
    cmp dl, 9
    jbe .is_digit
    add dl, ('A' - 10)
    jmp .store
.is_digit:
    add dl, '0'
.store:
    dec rsi
    mov [rsi], dl
    shr rax, 4
    dec rcx
    jnz .hex_loop

    dec rsi
    mov byte [rsi], 'x'
    dec rsi
    mov byte [rsi], '0'

    mov rdi, rsi
    call print_str

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; -----------------------------------------------------------------------------
; strcmp: Compara dos strings terminados en NULL
; Entrada: rdi = str1, rsi = str2 | Salida: rax = 0 si iguales, 1 si distintos
; -----------------------------------------------------------------------------
strcmp:
    push rcx
    push rdx
    xor rcx, rcx
.loop:
    mov al, [rdi + rcx]
    mov dl, [rsi + rcx]
    cmp al, dl
    jne .not_equal
    test al, al
    jz .equal
    inc rcx
    jmp .loop
.equal:
    xor rax, rax
    pop rdx
    pop rcx
    ret
.not_equal:
    mov rax, 1
    pop rdx
    pop rcx
    ret
