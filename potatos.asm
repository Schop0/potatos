BITS 16
ORG 7C00h

    call main                            ; Skip over data


    prompt db `\r`, `\n`, '> ', 0        ; "> " on the start of a new line
    goodbye_string db `\r`, `\n`, 'Press any key to reboot...', 0


main:
    pop ax                               ; Address of instruction right after last call
    sub ax, 2                            ; Calculate the address just before our code
    mov sp, ax                           ; Start the stack there
    mov bx, cs                           ; Load the code segment we're in
    mov ss, bx                           ; Make sure stack uses the same segment
    mov ds, bx                           ; Use the same segment for data as well
    mov es, bx                           ; And the same for the extra segment

    inc ax                               ; Calculate our code's base address
    push ax                              ; Save it for a rainy day

    mov cx, 2                            ; Sector 2
    call load_sector                     ; Load sector cx
    mov si, 0x1000                       ; Address of string after loading
    call print_string                    ; Call our string-printing routine

    call next_line                      ; Call our line-echoing routine

    ret                                  ; This is only happens on rainy days

reboot:
    jmp 0xFFFF:0x0000                    ; Jump back to BIOS ROM address


print_string:                            ; Routine: output string in SI to screen
    lodsb                                ; Get character from string (source segment)
    cmp al, 0
    je .done                             ; If char is zero, end of string

    mov ah, 0Eh                          ; int 10h 'print char' function TTY mode
    int 10h                              ; Otherwise, print it

    jmp print_string

.done:
    ret


next_line:
    mov si, prompt
    call print_string
.infinite:
    mov ah, 0                            ; Character input service for kbd int.
    int 16h                              ; Keyboard interrupt puts key in al

    cmp al, `\r`                         ; Check for carriage return (enter key)
    je next_line

    cmp ah,0x01                          ; Check for escape key
    je .escape

    mov ah, 0Eh
    add bl, 01h                          ; change color
    int 0x10

    jmp .infinite                        ; Jump here - infinite loop!

.escape:
    mov si, goodbye_string
	call print_string

    mov ah, 0                            ; Character input service for kbd int.
    int 16h                              ; Keyboard interrupt puts key in al

    jmp reboot


load_sector:
    mov al, 1                            ; Number of sectors to load
    mov bx, 0x1000                       ; Destination in extra segment (es:bx)
    mov dh, 0                            ; Head number 0 (CHS addressing)

    mov ah, 0x02                         ; Set read sectors function for int13
    int 0x13
    jc reboot                            ; Error. Good luck. Bye.

    ret


    times 510-($-$$) db 0                ; Pad remainder of boot sector with 0s
    dw 0xAA55                            ; The standard PC boot signature
    ; From here on we are no longer in the boot sector but in sector 2


    text_string db 'PotatOS 1.4 says Hello from sector 2!', 0
