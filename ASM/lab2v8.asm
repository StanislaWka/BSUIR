.model tiny     

org 100h
.data
maxStringSize equ 200

stringPointer db maxStringSize
stringSize db 0
string db maxStringSize dup (?)

searchPointer db maxStringSize
searchStringSize db 0
searchString db maxStringSize dup (?)
            ;jg ja
Message1 db "Enter the main string:$"
Message2 db "Enter the search string:$"  
Message3 db "Your String:$"

.code  

macro writeStringTo pointer
    lea dx, pointer
    
    mov bx, dx
    mov ax, 0a00h
    int 21h
    
    mov al, [bx+1]
    mov ah, 0
    
    add bx, ax
    mov [bx + 2], '$'
endm

macro readStringFrom pointer
    mov ax, 0900h  
    lea dx, pointer 

    int 21h
endm  


                     
macro return 
    mov ah, 02h
     
    mov dl, 0Ah  
    int 21h  
    
    mov dl, 0Dh
    int 21h  
endm

start:
    mov ax, @data
    mov ds, ax
    mov es, ax
    
    readStringFrom Message1
    return
    writeStringTo stringPointer
    return
    
secondStringEnter:
    readStringFrom Message2
    return
    writeStringTo searchPointer
    return
    
    mov al, searchStringSize 
    cmp al, 0
    je printString
    cmp al, stringSize
    ja secondStringEnter
    
secondStringSpaceCheck:        ; проверка на пробелы во втрой строки
    lea di, searchString
    
    mov ch, 0
    mov cl, searchStringSize
    inc cx
    
    mov ah, 0
    mov al, ' '
    
    cld
    repnz scasb                ; потворятб пока не ноль сравнивание с аккумултором al,ax c ES:DI
    cmp cx, 0
    jne secondStringEnter
    
    lea si, string    
    
compareWords:                      ; нахождение слова
    cmp [si], '$'
    je printString 
    
    lea di, searchString
    mov ch,0
    mov cl, searchStringSize
    
    cld
    repe cmpsb                   ; повтрять команду сравнивание DS:SI ES:DI
    
    jne notThisWord
    
    jmp foundWord
    
notThisWord:                        ; если не то то умниьшаем си
    dec si
    jmp wordSearch

wordSearch:                          ; ищем новое слово до пробела
    cmp [si], '$'
    je printString
    
    mov al, [si]
    inc si
    cmp al, ' '
    
    je compareWords 
    jmp WordSearch

foundWord:                            ; проверки

    cmp [si], '$'
    je deleteWord
    cmp [si], ' '
    jne wordSearch

deleteWord:                          ; устнаваливаем di and si в конец удаляемого слова
    mov al,searchStringSize
    mov ah, 0
    sub si, ax
    mov ax, si
    mov bx, 105h
    cmp ax, bx
    je wordSearch 
    dec si
    mov di, si    
                
spacesCheck:
    cmp [si], ' '
    je foundSpace
    
    mov ax, si
    mov bx, 104h
    cmp ax, bx 
    mov cx, 0
    je countWordSize
    
    mov cx, 0
    jmp countWordSize                
               
foundSpace: 
    dec si
    jmp spacesCheck

countWordSize:
    cmp [si], ' '
    je replaceWord
    mov ax, si
    mov bx, 104h
    cmp ax, bx
    je replaceWord

    jmp wordEndNotFound

wordEndNotFound:
    dec si
    inc cx
    jmp countWordSize

replaceWord:
    inc si
    add di, cx
    mov dx, di           ; помещаем в dx конец найденного
    mov di, si           ; перемещаем в di начало удалямого слова
    add si, cx
    inc si
;mov dx, di   ; ???????
            
moveWord:
    movsb                ; перермещение симовлов из DS:SI in ES:DI
    cmp [si], '$'
    jne moveWord
    jmp endFound

endFound:
    mov [di], '$'
    mov al, searchStringSize
    mov ah, 0
    sub dx, ax
    mov si, dx
    jmp wordSearch

endFoundInWordSizeSearch:
    sub si, cx
    mov [si], '$'

printString:    
    readStringFrom Message3
    return
    readStringFrom string
    
    mov ax, 4c00h
    int 21h
    
end start        