BITS 16

    call +0                              ; Relative call to the next instruction,
                                         ; effectively pushing the address of the
                                         ; next instruction to the call stack.
    jmp main                             ; Skip over data


    text_string db 'PotatOS 1.2', 0
    prompt db `\r`, `\n`, '> ', 0        ; "> " on the start of a new line


main:
    pop ax                               ; Retrieve last-called instruction's address
                                         ; Let's assume that was the 2nd instruction
    sub ax, 2                            ; Calculate the address just before our code
    mov sp, ax                           ; Start the stack there
    mov bx, cs                           ; Load the code segment we're in
    mov ss, bx                           ; Make sure stack uses the same segment
    mov ds, bx                           ; Use the same segment for data as well

    inc ax                               ; Calculate our code's base address
    push ax                              ; Save it for a rainy day

    mov ah, 0                            ; Set video mode function for int 10h
    mov al, 12h                          ; Video graphics mode 640x480 16-color
    int 10h

    mov si, text_string                  ; Put string position into SI
    call print_string                    ; Call our string-printing routine

.next_line:
    mov si, prompt
    call print_string
.infinite:
    mov ah, 0                            ; Character input service for kbd int.
    int 16h                              ; Keyboard interrupt puts key in al

    cmp al, `\r`                         ; Check for carriage return (enter key)
    je .next_line

    mov ah, 0Eh
    add bl, 01h                          ; change color
    int 0x10

    jmp .infinite                        ; Jump here - infinite loop!


print_string:                            ; Routine: output string in SI to screen
    mov bl, 01h                          ; first color in the palette

.repeat
    lodsb                                ; Get character from string (source segment)
    cmp al, 0
    je .done                             ; If char is zero, end of string

    mov ah, 0Eh                          ; int 10h 'print char' function TTY mode
    add bl, 01h                          ; change color
    int 10h                              ; Otherwise, print it

    jmp .repeat

.done:
    ret


    times 510-($-$$) db 0                ; Pad remainder of boot sector with 0s
    dw 0xAA55                            ; The standard PC boot signature
