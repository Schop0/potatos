BITS 16
ORG 7C00h

    call main                            ; Skip over data


    welcome_msg db 'PotatOS 1.5 says Hai!', 0
    prompt db `\r`, `\n`, '> ', 0        ; "> " on the start of a new line
    goodbye_string db `\r`, `\n`, 'Press any key to reboot...', 0
	trace_msg db '[trace]', 0
	gdtr dq 0                            ; Reserve at least 48 bits for gdtr


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

    mov si, welcome_msg                  ; Address to load to
    call puts                            ; Call our string-printing routine

    mov cx, 2                            ; Sector 2
    call load_sector                     ; Load sector cx

	mov ax, 3                            ; Video mode 3: 80x25 character text
	int 10h                              ; Set video mode

	; Activate A20
    mov ax,2401h
    int 15h

	; Disable interrupts
	cli

	; Load Global Descriptor Regiser
    XOR   EAX, EAX
    MOV   AX, DS
    SHL   EAX, 4
    ADD   EAX, 7E00h
    MOV   [gdtr + 2], eax
    MOV   EAX, 23
    MOV   [gdtr], AX
    LGDT  [gdtr]

	; Enable protected mode
	mov eax, cr0
	or al, 1
	mov cr0, eax

	; long call into protected mode PotatOS
	jmp 08h:PotatOS


    call next_line                      ; Call our line-echoing routine

    ret                                  ; This is only happens on rainy days

reboot:
    jmp 0xFFFF:0x0000                    ; Jump back to BIOS ROM address


puts:                                    ; Routine: output string in SI to screen
    lodsb                                ; Get character from string (source segment)
    cmp al, 0
    je .done                             ; If char is zero, end of string

    mov ah, 0Eh                          ; int 10h 'print char' function TTY mode
    int 10h                              ; Otherwise, print it

    jmp puts

.done:
    ret


next_line:
    mov si, prompt
    call puts
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
	call puts

    mov ah, 0                            ; Character input service for kbd int.
    int 16h                              ; Keyboard interrupt puts key in al

    jmp reboot


load_sector:
    mov al, 1                            ; Number of sectors to load
    mov bx, 7E00h                        ; Destination in extra segment (es:bx)
    mov dh, 0                            ; Head number 0 (CHS addressing)

    mov ah, 0x02                         ; Set read sectors function for int13
    int 0x13

    jc reboot                            ; Error. Good luck. Bye.

    ret


    times 510-($-$$) db 0                ; Pad remainder of boot sector with 0s
    dw 0xAA55                            ; The standard PC boot signature
    ; From here on we are no longer in the boot sector but in sector 2

; Global Descriptor Table
; offset 0x0
GDT:
.null:
	dq 0

; offset 0x8
.code:				; cs should point to this descriptor
	dw 0xffff		; segment limit first 0-15 bits
	dw 0			; base first 0-15 bits
	db 0			; base 16-23 bits
	db 0x9a			; access byte
	db 11001111b	; high 4 bits (flags) low 4 bits (limit 4 last bits)(limit is 20 bit wide)
	db 0			; base 24-31 bits

; offset 0x10
.data:				; ds, ss, es, fs, and gs should point to this descriptor
	dw 0xffff		; segment limit first 0-15 bits
	dw 0			; base first 0-15 bits
	db 0			; base 16-23 bits
	db 0x92			; access byte
	db 11001111b	; high 4 bits (flags) low 4 bits (limit 4 last bits)(limit is 20 bit wide)
	db 0			; base 24-31 bits


BITS 32
PotatOS:
    mov ah, 0x07		; Load color

	mov edi, 0xB8000	; Destination: video base address
	mov esi, pmode_msg	; Source
.loop:
	mov al, [esi]		; get current character
	cmp al, 0			; null character?
	jz halt				; end of string
	mov [edi], ax		; Print colored character
	add edi, 2			; Next destination position
	inc esi				; Next source character
	jmp .loop
	

halt:
	jmp halt


	pmode_msg db 'PotatOS v1.5: This is 32-bit protected mode code! Feel free to replace this (sector 2) with your own application of at most 512 bytes. It will be loaded and executed at address 7E00h. ', 0
