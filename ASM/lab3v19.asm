.model small
.stack 130h
  
 
.data 
maximalNumberOfElements equ 30
numberOfEnteredNumbers db 0

 
stringPointer db 7		;7 = 1 – sign, 5 – digits, 1 – '$' 
stringSize db 0
string db 7 dup (?)

negativeFlag db ?		;check for '-' in string 

tempDoubleWord dd 0
tempAverage dd 0 
average dd 0 

enterString db "Enter number in range [-32768, 32767], enter 'S' to stop.", 0Dh, 0Ah, '$'
enterNumberString db "Enter number: ", '$' 
outOfRangeString db "Out of range!", 0Dh, 0Ah, '$'
notDigitString db "Incorrect symbol detected!", 0Dh, 0Ah, '$'
resultString db "Incorrect symbol detected!", 0Dh, 0Ah, '$'	 
 
 
macro writeStringTo pointer 
    lea dx, pointer 
    
    mov bx, dx                                                                                                
    
    mov ax, 0A00h                  
    int 21h                                        
    
    mov al, [bx + 1]   
    mov ah, 0
    
    add bx, ax 
    mov [bx + 2], '$' 
endm     
                                              
macro readStringFrom pointer
    mov ax, 0900h  
    lea dx, pointer 

    int 21h
endm

macro carriageReturn 
    mov ah, 02h
     
    mov dl, 0Ah  
    int 21h  
    
    mov dl, 0Dh
    int 21h  
endm



 
macro addNumber
	mov ax, word ptr average            ;mov tempAverage, average
	mov word ptr tempAverage, ax   
	mov ax, word ptr [average + 2]
	mov word ptr [tempAverage + 2], ax 

	lea bx, tempDoubleWord     			;average = tempAverage + tempDoubleWord 
	mov ax, [bx]                	
	add ax, [bx + 4]
	mov [bx + 8], ax
	mov ax, [bx + 2]
	adc ax, [bx + 6]
	mov [bx + 10], ax
endm     
 

.code                          
start:
mov ax, @data
mov ds, ax  

readStringFrom enterString
 
enterNumber:
	mov cx, 0
	
 	cmp numberOfEnteredNumbers, maximalNumberOfElements		;if maximal number of elements reached 
    je suming
    
	readStringFrom enterNumberString
	writeStringTo stringPointer
	carriageReturn
	
	cmp string, 'S'			;stop enter 
    je suming           	
    
    cmp string, '-'
    je  negativeNumber 
    
	positiveNumber:
		cmp stringSize, 6 	;if positive number if bigger then 5 symbols
		je outOfRange
		
		lea si, string
		mov negativeFlag, 0
   	 jmp checkDigits
    
	negativeNumber: 
		lea si, string + 1
		mov negativeFlag, 1
		jmp checkDigits



	checkDigits:
		cmp [si], '$'		;if end of number
		je stoi
	
		cmp [si], '0'
		jl notDigit
	
		cmp [si], '9'
		ja notDigit
	
		inc cx
		inc si
	jmp checkDigits


	
stoi:
	sub si, cx
	mov ax, 0
	mov bh, 0
	
	stoiLoop: 
		mov dx, 10
		mul dx
		jc outOfRange 
		sub [si], '0' 
		mov bl, [si]
		add ax, bx
		jc outOfRange
		inc si	
	loop stoiLoop



check:
	cmp negativeFlag, 1
	je checkNegative	

	checkPositive: 	
		cmp ax, 32767
		ja outOfRange
		jmp addToStack
	
	checkNegative: 	
		cmp ax, 32768
		ja outOfRange
		neg ax
	
	addToStack:
		inc numberOfEnteredNumbers 
		push ax 
		jmp enterNumber
	


errors:
	notDigit:
		readStringFrom notDigitString
		jmp enterNumber

	outOfRange:
		readStringFrom outOfRangeString
		jmp enterNumber
 
 


suming:
	mov ch, 0
	mov cl, numberOfEnteredNumbers

sumingLoop:
	pop word ptr tempDoubleWord		
	cmp word ptr tempDoubleWord, 0
	jns positive
	
	negative:
	mov word ptr [tempDoubleWord + 2], 1111111111111111b	;make second word negative 0, FFFFh does't works, IDKN why...
	addNumber
	jmp next
	
	positive: 
	mov word ptr [tempDoubleWord + 2], 0000h
	addNumber

	next:	
loop sumingLoop



dividing:
	mov ax, average  	
	mov dx, [average + 2]
	mov ch, 0
	mov cl, numberOfEnteredNumbers
	idiv cx				;integer in ax, fractional in dx 
    
    mov word ptr average, dx
 
 
printInteger:
	mov cx, 5			;maximal number of digits in number 
	lea si, string
	
	cmp ax, 0
	js addMinus

	addPlus:
	mov [si], '+'
	jmp printIntegerNumber 
	
	addMinus:  
	mov [si], '-' 
	neg ax                  
 
	 
printIntegerNumber:	                  
	add si, 6			
	mov [si], '$'
	dec si				;to lowest digit
	mov bx, 10          ;divide by 10
	mov dx, 0           
	                   
	integerNumberToStringLoop: 	
		div bx				
		mov [si], dl
		mov dx, 0
		add [si], '0'
		dec si
		
	loop integerNumberToStringLoop
	
	readStringFrom string
	 

;									MAYBE BABY	 
;	cmp word ptr average, 0
;	je end
;	
;	printFractional: 
;		mov cx, 5			;maximal number of digits in number 
;		lea si, string
;		mov [si], ','
;		inc si
;		mov ax, word ptr average
;		mov word ptr average, 0
;		
;		printFractionalNumber:	                  
;			mov bx, 10          ;divide by 10
;			mov dx, 0           
;	                   
;		fractionalNumberToStringLoop: 	
;			div bx				
;			mov [si], dl
;			mov dx, 0
;			add [si], '0'
;			inc si
;		
;	loop fractionalNumberToStringLoop
;	
;	readStringFrom string
				
end:   
   	mov ax, 4C00h
  	int 21h                      
                        
end start      