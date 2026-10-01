; ======================================================================
; Warehouse stock counter in x86-64 NASM, System V ABI (Linux).
; Build: nasm -felf64 sample.asm && ld -o sample sample.o
; TODO: replace the linear scan with a hash lookup.
; FIXME: print_number does not handle zero.
; ======================================================================

; ── Preprocessor ────────────────────────────────────────────────────
%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_EXIT    60
%define STDOUT      1
%assign MAX_ITEMS   16
%strlen GREETING_LEN "Warehouse"
%include "constants.inc"
%ifdef DEBUG
    %define TRACE 1
%elifndef QUIET
    %define TRACE 0
%else
    %define TRACE 0
%endif
%if MAX_ITEMS > 8 && TRACE == 0
    %define BIG_TABLE
%endif

%macro PRINT 2                   ; PRINT buffer, length
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    mov     rsi, %1
    mov     rdx, %2
    syscall
%endmacro

%macro ENTER_FN 0-1 0            ; optional local-space argument
    push    rbp
    mov     rbp, rsp
    sub     rsp, %1
%endmacro

%macro CHECK 1+
    %rep 2
        nop
    %endrep
    %%local:
        cmp     %1
        jne     %%local
%endmacro

; ── Constants ───────────────────────────────────────────────────────
BUFFER_SIZE equ 64
ITEM_SIZE   equ 16
NEWLINE     equ 10

; ── Initialised data ────────────────────────────────────────────────
section .data align=16
    msg         db  "Stock report", NEWLINE, 0
    msglen      equ $ - msg
    escaped     db  "tab\there", 9, 'single quoted', `backtick\n`, 0
    wide        dw  0x1234, 0b1010_0101, 777o, 1234h, 0a5h
    dwords      dd  1, 2, 3, -4, 1.5, 0x7FFFFFFF
    qwords      dq  0xDEADBEEFCAFEBABE, 3.14159, 1.0e10
    table       times 4 dd 0
    padding     times 16-($-$$) db 0
    counter     dq  0
    threshold   dd  25
    float32     dd  0.25
    float64     dq  -2.5e-3
    sku_list    db  "A-100", 0, "B-200", 0, "C-300", 0
    sku_end     db  0

; ── Uninitialised data ──────────────────────────────────────────────
section .bss
    buffer      resb BUFFER_SIZE
    items       resq MAX_ITEMS
    total       resd 1
    flags       resw 1
    scratch     resy 1
    alignb 8
    big_block   resb 4096

; ── Read-only data ──────────────────────────────────────────────────
section .rodata
    banner      db "Acme Central", NEWLINE
    banner_len  equ $-banner
    lookup      dd 10, 20, 30

; ── Code ────────────────────────────────────────────────────────────
section .text
    default rel
    bits 64
    global _start
    global count_items:function
    extern printf
    extern exit

_start:
    ENTER_FN 32
    PRINT   msg, msglen
    lea     rsi, [rel msg]
    mov     rdi, items
    mov     rcx, MAX_ITEMS
    xor     eax, eax
    call    count_items
    mov     [total], eax
    cmp     dword [total], 0
    je      .empty
    jmp     .done

.empty:
    PRINT   banner, banner_len
.done:
    inc     qword [rel counter]
    cmp     qword [rel counter], 3
    jl      _start
    mov     rax, SYS_EXIT
    xor     rdi, rdi
    syscall

; ── Function: count items below the threshold ───────────────────────
; rdi = array, rcx = count, returns eax = number below threshold
count_items:
    push    rbx
    push    r12
    xor     eax, eax                 ; result
    xor     ebx, ebx                 ; index
.loop:
    cmp     rbx, rcx
    jae     .return
    mov     edx, [rdi + rbx*8]       ; scaled index addressing
    mov     r12d, dword [threshold]
    cmp     edx, r12d
    jge     .skip
    inc     eax
.skip:
    add     rbx, 1
    jmp     .loop
.return:
    pop     r12
    pop     rbx
    ret

; ── Instruction showcase ────────────────────────────────────────────
showcase:
    ; Data movement
    mov     rax, 0xFFFFFFFF
    mov     eax, 1_000_000
    mov     al, 'A'
    mov     ax, 0b1111
    mov     r8, qword [rax + rbx*4 + 16]
    mov     byte [rdi], 0
    mov     word [rdi+2], 0x1234
    movzx   eax, byte [rsi]
    movsx   rax, dword [rsi]
    movsxd  rax, dword [rsi]
    cmovne  rax, rbx
    xchg    rax, rbx
    lea     rax, [rax + rax*4]
    push    qword 42
    pop     rax

    ; Arithmetic
    add     rax, rbx
    sub     rax, 10
    imul    rax, rbx, 3
    mul     rbx
    idiv    rcx
    div     ecx
    neg     rax
    not     rax
    inc     rax
    dec     rax
    adc     rax, 0
    sbb     rax, 0

    ; Bitwise and shifts
    and     rax, 0xFF
    or      rax, 1 << 4
    xor     rax, rax
    test    rax, rax
    shl     rax, 3
    shr     rax, cl
    sar     rax, 1
    rol     eax, 8
    ror     eax, 8
    bt      rax, 5
    bsf     rax, rbx
    popcnt  rax, rbx

    ; Control flow
    cmp     rax, rbx
    ja      .above
    jb      .below
    jz      .zero
    jnz     .nonzero
    jg      .greater
    jle     .lessequal
    js      .signed
    loop    showcase
    jmp     short .above
    call    [rax + 8]
    jmp     rax
.above:
.below:
.zero:
.nonzero:
.greater:
.lessequal:
.signed:

    ; String and repeat instructions
    cld
    rep movsb
    repe cmpsb
    repne scasb
    rep stosq
    lodsb

    ; SSE / AVX
    movss   xmm0, [float32]
    movsd   xmm1, [float64]
    addsd   xmm0, xmm1
    mulps   xmm2, xmm3
    cvtsi2sd xmm0, rax
    cvttsd2si rax, xmm0
    pxor    xmm4, xmm4
    movdqa  xmm5, [rel dwords]
    vaddps  ymm0, ymm1, ymm2
    vmovdqu ymm3, [rsi]
    vzeroupper

    ; System, fences, misc
    syscall
    int     0x80
    cpuid
    rdtsc
    pause
    mfence
    lock xadd [counter], rax
    lock cmpxchg [counter], rbx
    nop
    hlt
    leave
    ret

; ── Local labels, segment override, operators in expressions ────────
expr_demo:
    mov     rax, (BUFFER_SIZE * 2 + 1) / 3 % 5
    mov     rax, BUFFER_SIZE | NEWLINE & 0x0F ^ 1
    mov     rax, ~0 >> 60
    mov     rax, -ITEM_SIZE
    mov     rax, msglen - 1
    mov     rax, $$
    mov     rax, [fs:0x28]
    mov     rax, [gs:rax]
    mov     eax, [abs 0x1000]
    mov     rax, strict qword 5
    mov     rax, [rel table + 8]
    mov     rax, seg msg
    mov     rax, msg wrt ..gotpc
    mov     rax, ..start
    ret

section .note.GNU-stack noalloc noexec nowrite progbits

; ── Further constructs ──────────────────────────────────────────────
; More preprocessor
%define MAX(a, b) ((a) > (b) ? (a) : (b))
%xdefine EARLY_BOUND MAX_ITEMS
%undef TRACE
%defstr VERSION_STR 1.4.0
%deftok TOKEN_VAL VERSION_STR
%substr FIRST_CHAR "hello" 1
%strcat GREETING_FULL "Hello, ", "warehouse"
%idefine CASE_INSENSITIVE 1
%ifidn __OUTPUT_FORMAT__, elf64
    %define PLATFORM_ELF
%elifidni __OUTPUT_FORMAT__, MACHO64
    %define PLATFORM_MACHO
%endif
%ifnum 42
    %define IS_NUM 1
%endif
%ifstr "text"
%endif
%ifctx loop
%endif
%ifenv HOME
%endif
%ifmacro PRINT 2
%endif
%iftoken rax
%endif
%ifempty
%endif
%error "Unsupported platform"
%warning "Check alignment"
%fatal "Cannot continue"
%pragma list options
%line 100+1 sample.asm
%pathsearch FOUND "constants.inc"
%depend "constants.inc"
%use smartalign
ALIGNMODE p6, 32
%push mycontext
    %assign %$counter 0
%pop
%rotate 1
%00 equ 0
%macro WITH_DEFAULTS 1-3 5, 6
    mov rax, %1
    %if %0 > 1
        mov rbx, %2
    %endif
    %ifidn %3, 6
    %endif
    %exitmacro
%endmacro
%unmacro WITH_DEFAULTS 1-3
%imacro CASELESS 0
%endmacro
%rep 3
    db 1
%exitrep
%endrep

; Directives
cpu 686
cpu x64
float rc=near
warning +orphan-labels
warning -macro-params-legacy
absolute 0x1000
    abs_field resd 1
section .text
section .mydata write progbits align=64
section .magic exec noexecute nobits
segment .code
org 0x7C00
bits 16
bits 32
bits 64
use16
use32
use64
common shared_symbol 4:4
static local_func
global _main:function hidden
global data_sym:data 8
extern ext_func wrt ..plt
import win_api kernel32.dll
export exported_fn
prefix _
postfix _
gprefix _
lprefix L_
default abs
default bnd
sectalign off

; Data in every size and form
dw  'ab', 'abc'
dd  __?float32?__(1.5), __?utf16?__("wide"), __?utf32?__("ucs")
dq  __?float64?__(2.5), 1.e+10, 0x1.fp+3
dt  3.14159265358979323846
do  0x00112233445566778899aabbccddeeff
dy  1,2,3,4
dz  1
db  0x55, 0o77, 0b1111_0000, 10101010b, 0xAAh, $0A, 0A5h, 'single', "double", `back\x41tické`
db  "hello", 0xA, 0
times 3 db 'a'
incbin "payload.bin", 16, 32
resb 1
resw 2
resd 3
resq 4
rest 5
reso 6
resy 7
resz 8

; Operators and special symbols
equ_a equ (1 + 2) * 3 - 4 / 2 // 3 % 5 %% 3
equ_b equ 1 << 4 | 2 >> 1 & 0xF ^ 3 >>> 1
equ_c equ ~0 + -1 + +1
equ_d equ 1 = 1 && 2 <> 3 || !0
equ_e equ 1 < 2 <= 3 > 0 >= 1 == 1 != 2
equ_f equ seg label1 + label1 wrt ..got
equ_g equ $ - $$
equ_h equ (3 ? 4 : 5)
    mov rax, [rbx*2 + rcx*1 + 8 - 4]
    mov rax, [rel $ + 4]
    mov rax, [qword 0x1000]
    mov rax, [byte rbx + 1]
    mov rax, [nosplit rax*2 + 0]
    mov rax, {1to8}
    vaddps zmm0{k1}{z}, zmm1, zmm2{rn-sae}
    vmovdqa64 zmm0 {k2}, [rsi]
    vpternlogd zmm0, zmm1, zmm2, 0xFF
    kmovw k1, eax
    vgatherdps zmm0{k1}, [rax + zmm1*4]
    jmp far [rax]
    call far 0x1234:0x5678
    jmp dword 0x10:target
    mov ax, seg msg
    mov [es:di], al
    lea rax, [rip + label]
    mov rax, label wrt ..gotpcrel
    mov eax, label wrt ..tlsie
    xlatb
    cbw
    cwde
    cdqe
    cqo
    ud2
    prefetcht0 [rsi]
    sfence
    lfence
    emms
    fld dword [float32]
    fstp qword [float64]
    fadd st0, st1
    fxch st2
    fwait
    finit
    movaps xmm0, [rel table]
    pshufd xmm0, xmm1, 0x1B
    aesenc xmm0, xmm1
    sha256rnds2 xmm1, xmm2, xmm0
    crc32 eax, byte [rsi]
    xgetbv
    xsave [rax]
    endbr64
    swapgs
    sysretq
    lgdt [gdt_descriptor]
    mov cr0, rax
    mov rax, dr7
    in al, 0x60
    out dx, al
    cli
    sti
    iretq
    wrmsr
    rdmsr
    invlpg [rax]
local_labels:
.first:   jmp .second
.second:  jmp ..@global_local
..@global_local:
$label_with_dollar:
?question_label:
    ret
; TODO: use VEX encodings for the SSE section.
