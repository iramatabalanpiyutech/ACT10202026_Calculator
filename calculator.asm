
; NASM 32-bit Menu-Driven Calculator
; Supports numbers from 0 to 99
; Uses procedures, CALL, RET, and loops

section .data
    menu db 10, "----------------------------------", 10
         db "              MENU", 10
         db "[A]dd", 10
         db "[S]ubtract", 10
         db "[M]ultiply", 10
         db "[D]ivide", 10
         db "----------------------------------", 10
    menuLen equ $ - menu

    choiceMsg db "Enter your choice: "
    choiceLen equ $ - choiceMsg

    firstMsg db "Enter first number: "
    firstLen equ $ - firstMsg

    secondMsg db "Enter second number: "
    secondLen equ $ - secondMsg

    sumMsg db "The sum is "
    sumLen equ $ - sumMsg

    subMsg db "The difference is "
    subLen equ $ - subMsg

    mulMsg db "The product is "
    mulLen equ $ - mulMsg

    divMsg db "The quotient is "
    divLen equ $ - divMsg

    againMsg db 10, "Do you want to try again (Y/N)? "
    againLen equ $ - againMsg

    invalidMsg db "Invalid input. Try again.", 10
    invalidLen equ $ - invalidMsg

    zeroMsg db "Error: Division by zero!", 10
    zeroLen equ $ - zeroMsg

    byeMsg db 10, "Program terminated.", 10
    byeLen equ $ - byeMsg

    clearScreen db 27, "[2J", 27, "[H"
    clearLen equ $ - clearScreen

    newline db 10

section .bss
    input resb 32
    num1 resd 1
    num2 resd 1
    result resd 1
    operation resb 1
    outbuf resb 16

section .text
    global _start

%macro print 2
    mov eax, 4
    mov ebx, 1
    mov ecx, %1
    mov edx, %2
    int 0x80
%endmacro

_start:
    jmp main_menu

main_menu:
    print menu, menuLen
    print choiceMsg, choiceLen

    call read_input

    mov al, [input]
    and al, 0DFh
    mov [operation], al

    cmp al, 'A'
    je get_numbers
    cmp al, 'S'
    je get_numbers
    cmp al, 'M'
    je get_numbers
    cmp al, 'D'
    je get_numbers

    print invalidMsg, invalidLen
    jmp main_menu

get_numbers:
    print firstMsg, firstLen
    call read_number
    mov [num1], eax

    print secondMsg, secondLen
    call read_number
    mov [num2], eax

    mov al, [operation]

    cmp al, 'A'
    je do_add
    cmp al, 'S'
    je do_subtract
    cmp al, 'M'
    je do_multiply
    cmp al, 'D'
    je do_divide

do_add:
    call addition
    print sumMsg, sumLen
    jmp display_result

do_subtract:
    call subtraction
    print subMsg, subLen
    jmp display_result

do_multiply:
    call multiplication
    print mulMsg, mulLen
    jmp display_result

do_divide:
    cmp dword [num2], 0
    je division_error

    call division
    print divMsg, divLen
    jmp display_result

division_error:
    print zeroMsg, zeroLen
    jmp ask_again

display_result:
    mov eax, [result]
    call print_number
    print newline, 1

ask_again:
    print againMsg, againLen
    call read_input

    mov al, [input]
    and al, 0DFh

    cmp al, 'Y'
    je restart
    cmp al, 'N'
    je exit_program

    print invalidMsg, invalidLen
    jmp ask_again

restart:
    print clearScreen, clearLen
    jmp main_menu

exit_program:
    print byeMsg, byeLen
    mov eax, 1
    xor ebx, ebx
    int 0x80

; -----------------------------------
; Procedure: Read input
; -----------------------------------
read_input:
    mov eax, 3
    mov ebx, 0
    mov ecx, input
    mov edx, 32
    int 0x80

    cmp eax, 0
    jle exit_program

    ret

; -----------------------------------
; Procedure: Read number (0 to 99)
; -----------------------------------
read_number:
    call read_input

    xor eax, eax
    xor esi, esi
    xor edi, edi

convert_loop:
    mov bl, [input + esi]

    cmp bl, 10
    je conversion_done
    cmp bl, 13
    je conversion_done

    cmp bl, '0'
    jb invalid_number
    cmp bl, '9'
    ja invalid_number

    cmp edi, 2
    jae invalid_number

    sub bl, '0'
    movzx ebx, bl

    imul eax, eax, 10
    add eax, ebx

    inc esi
    inc edi
    jmp convert_loop

conversion_done:
    cmp edi, 0
    je invalid_number
    ret

invalid_number:
    print invalidMsg, invalidLen
    jmp read_number

; -----------------------------------
; Arithmetic procedures
; -----------------------------------
addition:
    mov eax, [num1]
    add eax, [num2]
    mov [result], eax
    ret

subtraction:
    mov eax, [num1]
    sub eax, [num2]
    mov [result], eax
    ret

multiplication:
    mov eax, [num1]
    imul eax, [num2]
    mov [result], eax
    ret

division:
    mov eax, [num1]
    xor edx, edx
    div dword [num2]
    mov [result], eax
    ret

; -----------------------------------
; Procedure: Print signed integer
; -----------------------------------
print_number:
    mov edi, outbuf + 15
    xor esi, esi

    test eax, eax
    jns convert_output

    neg eax
    mov esi, 1

convert_output:
    mov ebx, 10

number_loop:
    xor edx, edx
    div ebx

    add dl, '0'
    dec edi
    mov [edi], dl

    test eax, eax
    jnz number_loop

    cmp esi, 0
    je output_ready

    dec edi
    mov byte [edi], '-'

output_ready:
    mov edx, outbuf + 15
    sub edx, edi

    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    int 0x80
    ret
