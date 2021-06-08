readFile MACRO file  
    mov bx, file 
    mov cx, readLEN
    mov dx, di 
    mov ah, 3Fh
    int 21h    
ENDM             
 
;�������� �����
closeFile MACRO file  
    mov bx, file 
    mov ah, 3Eh
    int 21h      
ENDM

;����� ������ �� �����
outputString MACRO string
    push ax
    mov dx, offset string
    mov ah, 09h
    int 21h      
    pop ax
ENDM 

;������� �������� � ������ str
skipSpaces MACRO str  
    LOCAL skip
    sub str, 1
    skip:
    inc str
    cmp [str], ' ' 
    je skip
ENDM

;����������� �� si � string �� ������� ��� ����� ��������� ������
copyWord MACRO string
    LOCAL copy
    mov di, offset string
    
    copy:
    movsb
    
    cmp [si], 0Dh           ;������� ����� ��������� ������
    je cmdEnd
    
    cmp [si], ' '
    jne copy
       
ENDM 

.model small

.data 

eof db 0

MAX_PATH equ 261
progPath db MAX_PATH dup(0)
  
fopenError db 09h,"An error occurred while opening file: ",'$' 
freadError db 09h,"An error occurred while reading file: ",'$' 
execErr db 09h,"An error occurred while starting another programm: ",'$'
cmdError db 09h,"Could't get file name from cmd arguments",'$'
fileNotFound db "file not found.",'$'
pathNotFound db "path not found.",'$'
2ManyFiles db "too many files opened.",'$'
accessDenied db "access denied.",'$'
invalidAccessMode db "invalid access mode.",'$' 
wrongHandle db "wrong handle.",'$'  
notEnoughMem db "not enough memory.",'$'  
wrongSur db "wrong surrounding.",'$' 
wrongFormat db "wrong format.",'$' 

fileName db 126 dup(0) 

readLEN dw 1                   
file dw 0  

command_line db 0, 0 

epb dw 0
	dw offset command_line,0
	dw 005Ch,0,006Ch,0  
	
DataSize=$-eof	

.stack 100h

.code

main:      
    ;��������� ������� ������
    mov ah, 4Ah
	mov bx, ((CodeSize/16)+1)+((DataSize/16)+1)+32
	int 21h
    
    mov ax, @data 
    mov es, ax 
    
    ;��������� ����� ����� �� cmd
    call getFileName
    
    mov ds, ax
      
    ;�������� ��������� ����� �����
    call checkName      
    
    ;������� ����
    mov dx, offset fileName
    call openFileR
    mov file, ax 
    
    nextProgramm: 
    call clearPath              ;�������� ����
    call getProgPath            ;�������� ���� �� �����

    ;��������� � ��������� ���������
    mov ax, 4B00h
    mov dx, offset progPath 
    mov bx, offset epb
    int 21h
    jc execError
    
    cmp eof, 0
    je nextProgramm
    
    jmp closeFile

;������ ��� �������� �����
openFail:
    
    outputString fopenError         
    
    ;���� �� ������
    cmp ax, 02h   
    jne not2
    outputString fileNotFound
    jmp closeFile     
    
not2: 
    ;���� �� ������ 
    cmp ax, 03h 
    jne not3  
    outputString pathNotFound
    jmp closeFile      
    
not3:  
    ;������� ������� ����� ������
    cmp ax, 04h
    jne not4   
    outputString 2ManyFiles
    jmp closeFile
    
not4:
    ;�������� � �������
    cmp ax, 05h
    jne not5 
    outputString accessDenied
    jmp closeFile      
    
not5: 
    ;������������ ����� �������
    outputString invalidAccessMode
           
;�������� �����           
closeFile:    
    closeFile file                 

exit:
    ;���������� ������
    mov ah, 4Ch
    int 21h 

;������ ��� ������    
failedReading: 

    outputString freadError
    cmp ax, 05h
    jne skip 
    
    ;�������� � ������� 
    outputString accessDenied
    jmp closeFile
     
    skip: 
    ;������������ �������������
    outputString wrongHandle
    jmp closeFile
    
namesNotFound:  
    ;������ ��������� ������
    outputString cmdError
    jmp exit   
    
execError:

    outputString execErr
        
    ;���� �� ������
    cmp ax, 02h   
    jne not2e
    outputString fileNotFound
    jmp closeFile     
    
not2e: 
    ;�������� ������
    cmp ax, 05h 
    jne not5e 
    outputString accessDenied
    jmp closeFile      
    
not5e:  
    ;����c������� ������
    cmp ax, 08h
    jne not8e   
    outputString notEnoughMem
    jmp closeFile
    
not8e:
    ;������������ ���������
    cmp ax, 0Ah
    jne notAe 
    outputString wrongSur
    jmp closeFile      
    
notAe: 
    ;������������ ������
    outputString wrongFormat
    jmp closeFile 


;��������� ����� �� ��������� ������
getFileName proc
    pusha
		
	mov si, 82h             ;������ ��������� ������
	
    skipSpaces si           ;������� ��������
	
	copyWord fileName       ;���������� �����
	
	cmdEnd:	    
    popa
    ret
endp
 
;������� ���� � ������ ������ ������ 
openFileR proc 
    xor cx, cx 
    xor al, al
    mov ah, 3dh
    mov al, 00h 
    int 21h 
    jc openFail   
    ret    
endp  

;�������� ���������� ����� ����� �� ��������� ������
checkName proc    
    cmp [filename], 0
    je namesNotFound
    ret
endp

;������ ����� ������ �� �����
getProgPath proc
    pusha
    
    mov di, offset progPath
    dec di
    
    reading:
    inc di
    readFile file
    jc failedReading
    ;��������� 0 �������� - ����� �����
    cmp ax, 0
    je eoff
    
    cmp [di], 0Dh
    je lineEnd
    
    jmp reading
    
    lineEnd:
    mov [di], 0
    
    ;������� 1 ������� � ����� 
    mov dx, 1
    xor cx, cx 
    mov bx, file
    mov al, 01h
    mov ah, 42h
    int 21h
         
    popa
    ret
    
    eoff:
    inc eof
    popa
    ret
endp 

;��������� ���� ����������� ���������
clearPath proc
    mov di, offset progPath
    mov al, 0
    mov cx, MAX_PATH
    
    rep stosb
    ret        
endp 

CodeSize = $ - main

end main