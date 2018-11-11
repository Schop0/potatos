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
    MOV eax, 23                          ; Load size of gdt
    MOV [gdtr], ax                       ; set it in lower 2 bytes of gdtr
	MOV eax, gdt                         ; Load address of gdt
    MOV [gdtr + 2], eax                  ; set it in upper 4 bits of gdtr
    LGDT [gdtr]                          ; Start using our new GDT

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
; Global Descriptor Table
;========================================;
gdt:
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
; Partition table
;========================================;
	times 446-($-$$) db 0            ; Pad boot code with 0s up until the partition table

	; Partition 1
	times 16 db 0 ; Empty partition table entry

;	db 0x80                          ; Set bootable flag (bit 7)
	; 24-bit CHS address of first sector
;	db  ; bits 0-7: Head
;	dw  ; bits 8-13: Sector & bits 14-23: cylinder
;	db 0x0B ; identifier for fat32 partition type
	; 24-bit CHS address of last sector
;	db  ; bits 0-7: Head
;	dw  ; bits 8-13: Sector & bits 14-23: cylinder
;	dq 1 ; 32-bit logical block address of first sector
;	dq  ; 32-bit number of sectors in partition

	; Partiton 2
	times 16 db 0 ; Empty partition table entry

	; Partiton 3
	times 16 db 0 ; Empty partition table entry

	; Partiton 4
	times 16 db 0 ; Empty partition table entry

;========================================;
;	Boot sector padding and signature
;========================================;
    times 510-($-$$) db 0                ; Pad remainder of boot sector with 0s
    dw 0xAA55                            ; The standard PC boot signature

;========================================;
; PotatOS stub
;========================================;
BITS 32
PotatOS:
