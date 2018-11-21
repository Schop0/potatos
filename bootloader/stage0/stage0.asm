BITS 16
ORG 7C00h

	call main                        ; Skip over data

;========================================;
; Data
;========================================;
	welcome_msg db `stage0 loading stage1...\r\n\0`

;========================================;
; main
;========================================;
main:
	; Do some initial setup in protected mode
	pop ax                           ; Address of instruction right after last call
	sub ax, 2                        ; Calculate the address just before our code
	mov sp, ax                       ; Start the stack there
	mov bx, cs                       ; Load the code segment we're in
	mov ss, bx                       ; Make sure stack uses the same segment
	mov ds, bx                       ; Use the same segment for data as well
	mov es, bx                       ; And the same for the extra segment

	; Print a welcome message
	mov si, welcome_msg              ; Address to load to
	call puts                        ; Call our string-printing routine

	; Set video mode
	mov ax, 3                        ; Video mode 3: 80x25 character text
	int 10h                          ; Set video mode

	; Load stage1
	mov cx, 2                        ; Sector 2
	call load_sector                 ; Load sector cx

	; transfer control to stage1
	jmp stage1


reboot:
	jmp 0xFFFF:0x0000                ; Jump back to BIOS ROM address

;========================================;
; puts
;========================================;
puts:                                    ; Routine: output string in SI to screen
	lodsb                            ; Get character from string (source segment)
	cmp al, 0
	je .done                         ; If char is zero, end of string

	mov ah, 0Eh                      ; int 10h 'print char' function TTY mode
	int 10h                          ; Otherwise, print it

	jmp puts

.done:
	ret

;========================================;
; load_sector
;========================================;
load_sector:
	mov al, 1                        ; Number of sectors to load
	mov bx, 7E00h                    ; Destination in extra segment (es:bx)
	mov dh, 0                        ; Head number 0 (CHS addressing)

	mov ah, 0x02                     ; Set read sectors function for int13
	int 0x13

	jc reboot                        ; Error. Good luck. Bye.

	ret

;========================================;
; Partition table
;========================================;
	times 446-($-$$) db 0            ; Pad boot code with 0s up until the partition table

	; Primary partitions x4
	times 16 db 0                    ; Empty partition table entry
	times 16 db 0                    ; Empty partition table entry
	times 16 db 0                    ; Empty partition table entry
	times 16 db 0                    ; Empty partition table entry

;========================================;
; Boot sector padding and signature
;========================================;
	times 510-($-$$) db 0            ; Pad remainder of boot sector with 0s
	dw 0xAA55                        ; The standard PC boot signature

;========================================;
; stage1 stub
;========================================;
stage1:
