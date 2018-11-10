BITS 16
ORG 7C00h

    jmp main                             ; Skip over data

;========================================;
;	Data
;========================================;
    welcome_msg db 'Booting...', 0
	gdtr dq 0                            ; Reserve at least 48 bits for gdtr

;========================================;
;	main
;========================================;
main:
    ; Do some initial setup in protected mode
    pop ax                               ; Address of instruction right after last call
    sub ax, 2                            ; Calculate the address just before our code
    mov sp, ax                           ; Start the stack there
    mov bx, cs                           ; Load the code segment we're in
    mov ss, bx                           ; Make sure stack uses the same segment
    mov ds, bx                           ; Use the same segment for data as well
    mov es, bx                           ; And the same for the extra segment

	; Print a welcome message
    mov si, welcome_msg                  ; Address to load to
    call puts                            ; Call our string-printing routine

	; Load more disk sectors
    mov cx, 2                            ; Sector 2
    call load_sector                     ; Load sector cx

	; Set video mode
	mov ax, 3                            ; Video mode 3: 80x25 character text
	int 10h                              ; Set video mode

	; Enble >1MB addressable memory
    mov ax,2401h
    int 15h                              ; Activate A20

	; Protect ourselves from interrupts during transition to protected mode
	cli                                  ; Disable interrupts

	; Set up Global Descriptor Table
    MOV   EAX, 23                        ; Size of gdt
    MOV   [gdtr], AX                     ; set size in lower 2 bytes of gdtr
    XOR   EAX, EAX                       ; Clear eax
    MOV   AX, DS                         ; start at our data segment
    SHL   EAX, 4                         ; calculate address from page number
    ADD   EAX, 7E00h                     ; add offset where we loaded our gdt
    MOV   [gdtr + 2], eax                ; set gdt pointer in upper 4 bits of gdtr
    LGDT  [gdtr]                         ; Start using our new GDT

	; Enable protected mode bit
	mov eax, cr0
	or al, 1
	mov cr0, eax

	; Long jump into protected mode code
	jmp 08h:PotatOS


reboot:
    jmp 0xFFFF:0x0000                    ; Jump back to BIOS ROM address

;========================================;
;	puts
;========================================;
puts:                                    ; Routine: output string in SI to screen
    lodsb                                ; Get character from string (source segment)
    cmp al, 0
    je .done                             ; If char is zero, end of string

    mov ah, 0Eh                          ; int 10h 'print char' function TTY mode
    int 10h                              ; Otherwise, print it

    jmp puts

.done:
    ret

;========================================;
;	load_sector
;========================================;
load_sector:
    mov al, 1                            ; Number of sectors to load
    mov bx, 7E00h                        ; Destination in extra segment (es:bx)
    mov dh, 0                            ; Head number 0 (CHS addressing)

    mov ah, 0x02                         ; Set read sectors function for int13
    int 0x13

    jc reboot                            ; Error. Good luck. Bye.

    ret
;========================================;
;	Boot sector padding and signature
;========================================;
    times 510-($-$$) db 0                ; Pad remainder of boot sector with 0s
    dw 0xAA55                            ; The standard PC boot signature

;========================================;
; Global Descriptor Table
;========================================;
GDT:
; offset 0x00
.null:
	dq 0

; offset 0x08
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

;========================================;
; Protected mode code directive
;========================================;
BITS 32

;========================================;
; PotatOS
;========================================;
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
	hlt
	jmp halt


	pmode_msg db 'This is 32-bit protected mode code! Feel free to replace this (sector 2) with your own application of at most 512 bytes. It will be loaded and executed at address virtual address 00h.', 0
