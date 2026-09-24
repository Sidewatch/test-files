; x86-64 NASM, System V ABI: write "hello" and exit.
; nasm -felf64 sample.asm && ld -o sample sample.o

section .data
    msg     db  "hello, world", 10      ; message plus newline
    msglen  equ $ - msg
    counter dq  0

section .text
    global _start

_start:
    mov     rax, 1               ; sys_write
    mov     rdi, 1               ; stdout
    lea     rsi, [rel msg]
    mov     rdx, msglen
    syscall

    inc     qword [rel counter]
    cmp     qword [rel counter], 3
    jl      _start               ; print three times

    mov     rax, 60              ; sys_exit
    xor     rdi, rdi
    syscall
