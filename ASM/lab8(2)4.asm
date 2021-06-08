.model tiny
.code
org 100h

begin:
	jmp start 

count dw 9
temp dw 0
screen dw 2000 dup (?)
screen_sz equ 2000
oldInt09h dd 0

second_resident db 123


newInt09h proc
	pushf
	call dword ptr cs:oldInt09h
	
	pusha
	push cs
	pop ds

	call copy_screen

	call check_right_brackets
	call check_left_brackets

	call push_screen
	
stop_08h:	

	popa
	iret
	
endp 

copy_screen proc
	pusha
	
	push 0b800h
	pop es
	xor di, di
	mov cx, screen_sz
	copy_screen_loop:
		mov ax, es:[di]
		mov [screen+di], ax
		mov byte ptr [screen+di+1], byte ptr 7
		add di,2
		loop copy_screen_loop

	xor di, di

	popa
	ret
endp 


push_screen proc
	pusha
	
	push 0b800h
	pop es
	xor di, di
	mov cx, screen_sz
	lea si, screen
	rep movsw	
	popa
	ret
push_screen endp

check_right_brackets proc 
	pusha

	xor di, di
	mov temp, 0
	mov cx, screen_sz
	find_right_brackets:
		cmp byte ptr [screen+di], byte ptr "("
		jne crc_not_left
		add temp, 1
		crc_not_left:
		cmp byte ptr [screen+di], byte ptr ")"
		jne crc_inc
		cmp temp, 0
		jne crc_dec_temp
		mov byte ptr [screen+di+1], byte ptr 08ch
		jmp crc_inc

		crc_dec_temp:
		dec temp
		crc_inc:
		add di, 2
		loop find_right_brackets

	popa
	ret 
endp

check_left_brackets proc 
	pusha

	mov di, screen_sz
	add di, screen_sz
	sub di, 2   

	mov temp, 0
	mov cx, screen_sz
	find_left_brackets:
		cmp byte ptr [screen+di], byte ptr ")"
		jne clc_not_right
		add temp, 1
		clc_not_right:
		cmp byte ptr [screen+di], byte ptr "("
		jne clc_dec
		cmp temp, 0
		jne clc_dec_temp
		mov byte ptr [screen+di+1], byte ptr 08ch
		jmp clc_dec

		clc_dec_temp:
		dec temp
		clc_dec:
		sub di, 2
		loop find_left_brackets

	popa
	ret 
endp

start:

	mov al, 09h
	mov ah, 35h
	int 21h
	
	mov word ptr oldInt09h, bx
	mov word ptr oldInt09h +2, es

	call check_resident

	cli
	
	mov ah,25h
	mov al, 09h
	mov dx, offset newInt09h
	int 21h
	
	sti 

	mov dx, offset start
	int 27h

exit:
	mov ah, 4ch
	int 21h



check_resident proc 
	mov di, offset second_resident
	mov al, byte ptr second_resident
	cmp al, byte ptr es:[di]
	jne cr_continue
	mov ah, 09h
	mov dx, offset reload_resident_str
	int 21h 
	jmp exit
	cr_continue:
	ret
endp



reload_resident_str db "Resident is already in memory", 10, 13, "$"

	end begin