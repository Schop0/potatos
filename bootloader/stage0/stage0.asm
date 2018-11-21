BITS 16
ORG 7C00h

;========================================;
; stage0
;========================================;
main:
	mov ax, 3                        ; Video mode 3: 80x25 character text
	int 10h                          ; Set video mode, clearing creen

	mov cx, 2                        ; Sector 2
	call load_sector                 ; Load stage1

	jmp stage1                       ; transfer control to stage1


load_sector:
	mov al, 1                        ; Number of sectors to load
	mov bx, 7E00h                    ; Destination in extra segment (es:bx)
	mov dh, 0                        ; Head number 0 (CHS addressing)

	mov ah, 0x02                     ; Set read sectors function for int13
	int 0x13

	ret

;========================================;
; Data
;========================================;
	times 446-($-$$) db 0            ; Pad boot code with 0s up until the partition table

	; Primary partitions x4
	times 16 db 0                    ; Empty partition table entry
	times 16 db 0                    ; Empty partition table entry
	times 16 db 0                    ; Empty partition table entry
	times 16 db 0                    ; Empty partition table entry

	times 510-($-$$) db 0            ; Pad remainder of boot sector with 0s
	dw 0xAA55                        ; The standard PC boot signature

;========================================;
; stage1 stub
;========================================;
stage1:
