.model small 
;.model tiny
.stack 150h

.data  


isEmpty dw 0

data_size dw $-data             ; size of data

.code
old_int dd 0                    

new_handler proc far

    cli                       
    pushf 
    call dword ptr cs:[old_int]                     
    pusha
    push ds 
    push es

    mov ax, @data
    mov es, ax
    mov ax, 0B800h
    mov ds, ax  


	xor si, si     
mainLoop1:
    cmp si, 4000                
    je continue                  
    
    
    
    mov al, ds:[si]              
    cmp al, '('
    je colorPrev
    cmp al, ')'
    je colorPrev
    cmp al, '['
    je colorPrev
    cmp al, ']'
    je colorPrev
    cmp al, '{'
    je colorPrev
    cmp al, '}'
    je colorPrev 
    inc si
    inc si
    jmp mainLoop1
afterColorPrev:    

    inc si                     
    jmp mainLoop1
    
colorPrev:
    inc si
    mov ds:[si], 7   
    jmp afterColorPrev   
  
continue: 
 
    xor si, si                 
    
mainLoop:
    cmp si, 4000               
    je letsColorIt             

    mov al, ds:[si]           

    cmp al, '('
    je addToStack1

    cmp al, '{'
    je addToStack2

    cmp al, '['
    je addToStack3

    cmp al, ')'
    je closeBracket

    cmp al, '}'
    je closeBracket

    cmp al, ']'
    je closeBracket

afterAddToStackAndOrCloseBracket:
    
    inc si                      
    inc si
    jmp mainLoop

addToStack1:
    
    push si                      
    mov al, ')'
    push ax                      
    
    mov bx, isEmpty              
    inc bx                       
    mov isEmpty, bx              

    jmp afterAddToStackAndOrCloseBracket

addToStack2:
    
    push si                      
    mov al, '}'
    push ax                      
    
    mov bx, isEmpty              
    inc bx                       
    mov isEmpty, bx              

    jmp afterAddToStackAndOrCloseBracket   

addToStack3:
    
    push si                      
    mov al, ']'
    push ax                      
    
    mov bx, isEmpty              
    inc bx                       
    mov isEmpty, bx              

    jmp afterAddToStackAndOrCloseBracket     

closeBracket:

    mov bx, isEmpty              
    cmp bx, 0                    
    je colorCloseBracket         

    pop bx                       
    cmp bl, al                   
    jne resetStack               

    mov bx, isEmpty               
    dec bx                       
    mov isEmpty, bx               

    pop bx                       

    jmp afterAddToStackAndOrCloseBracket

resetStack:

    push bx                      

    inc si                       
    mov ds:[si], 2               
    dec si                       

    push si 					 

    cmp al, ')'					 
	jne otherBrackets			 

	sub al, 1					 
	jmp pushMe					

otherBrackets:

	sub al, 2					 

pushMe:

    push ax				         

    mov bx, isEmpty             
    inc bx                      
    mov isEmpty, bx             

    jmp afterAddToStackAndOrCloseBracket

colorCloseBracket:
	
    inc si                       
    mov ds:[si], 2              
    dec si                         

    jmp afterAddToStackAndOrCloseBracket

letsColorIt:
    
    mov bx, isEmpty

colorLoop:

    cmp bx, 0
    je end_handler

    pop si                       
    pop si

    inc si                       
    mov ds:[si], 2               

    dec bx

    jmp colorLoop
 
end_handler:      
    mov isEmpty, bx

    pop es 
    pop ds

    popa   
    sti                         
    iret                        

new_handler endp

start:

    mov ax, @data
    mov ds, ax
    
    mov ah, 35h                     ;read vector interrupt
    mov al, 09h
    int 21h                         ;on exit es:bx adress interrupts
    mov word ptr cs:[old_int], bx   ;remember our interrupts
    mov word ptr cs:[old_int+2], es 
    

    
    mov ah, 25h                     ;new 
    mov al, 09h                     ;number interrupt
    push cs                         ;
    pop ds                          ;DS CS 
    mov dx, offset new_handler      ;adrres new handler
    int 21h   
    
                   ;DS:DX - new address
    
    mov ah, 31h                     ;resident program
    mov al, 00h                     ;code of exit
    mov dx, (code_size / 16) + (data_size / 16) + 800 + 16 + 2 ;16-bit segment size of code + size of data + PSP + stack + 1 cose_size + data_size
    int 21h       

;    mov dx, offset start
;    int 27h
    
code_size dw $-code                 ;size of code
end start 