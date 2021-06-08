copyWord MACRO string
    LOCAL copy
    mov di, offset string
    
    copy:
    movsb
    
    cmp [si], 0Dh           ;Признак конца командной строки
    je cmdEnd
    
    cmp [si], ' '
    jne copy
       
ENDM   

skipSpaces MACRO str  
    LOCAL skip
    sub str, 1
    skip:
    inc str
    cmp [str], ' ' 
    je skip
ENDM  

closeFile MACRO file  
    mov bx, handler 
    mov ah, 3Eh
    int 21h      
ENDM 

outputString MACRO string
    push ax
    mov dx, offset string
    mov ah, 09h
    int 21h      
    pop ax
ENDM 

.model small
.stack 100h

.data 
empty                       equ 0720h
screen_size                 equ 2000 
screen_width                equ 80
screen_heigth               equ 25
white_color_black_bg        equ 0Fh 
action_next                 equ 0
action_previous             equ 1
action_copy                 equ 2
exit                        equ 3
counter                     db 0
buffer_string               db 2000 dup(?) ; buffer of first 200o butes RAM  
hex_string                  db 2000 dup(?) ; buffer to hex string
hex_num                     db '?','?'
screen                      dw screen_size dup(?)
desired_action_none         equ 4
desired_action              db ?  

fileName                    db 126 dup(0)  
handler                     dw 0

fopenError db 09h,"An error occurred while opening file: ",'$'     
cmdError db 09h,"Could't get file name from cmd arguments",'$'
pathNotFound db "path not found.",'$'   
2ManyFiles db "too many files opened.",'$'  
accessDenied db "access denied.",'$' 
invalidAccessMode db "invalid access mode.",'$' 
fileNotFound db "file not found.",'$'
.code
    jmp start

set_video_mode proc
    push ax
    
    mov ah, 0
    mov al, 03h
    int 10h
    
set_video_mode_end:
    pop ax
    ret
endp  


    

choose_desired_action proc
    cmp ah, 01h ;ESC key
    je choose_desired_action_exit ; не забыть корректно завершить программу
    cmp ah, 11h ;W key
    je choose_desired_action_next
    cmp ah, 1Fh ; S key
    je choose_desired_action_previous
    cmp ah, 2eh ; C key
    je choose_desired_action_copy   
    jmp choose_desired_action_end
     
    choose_desired_action_exit:
    mov desired_action, exit
    jmp choose_desired_action_end
    choose_desired_action_next:
    mov desired_action, action_next
    jmp choose_desired_action_end
    choose_desired_action_previous:
    mov desired_action, action_previous
    jmp choose_desired_action_end
    choose_desired_action_copy:
    mov desired_action, action_copy
    jmp choose_desired_action_end 
     
    choose_desired_action_end:
    ret
endp
    

get_desired_action proc  
    push ax
    
    mov desired_action, desired_action_none
    
    get_desired_action_loop:
        mov ah, 01h
        int 16h
        jz get_desired_action_end
        mov ah, 00h
        int 16h
        call choose_desired_action
     jmp get_desired_action_loop
     
     get_desired_action_end:
     pop ax
     ret
endp  

update_screen proc
    push ax
    push es 
    push ds
    push si
    push di
    push cx
    
    mov ax, @data
    mov ds, ax
    mov ax, 0B800h
    mov es, ax
    mov di, 0
    mov cx, screen_size
    mov ax, white_color_black_bg
    mov si, offset hex_string
    screen_loop:
        movsb                              ; movsb ds:si to es:di
        stosb
    loop screen_loop
    

    update_screen_end:
    pop cx
    pop di
    pop si
    pop ds
    pop es
    pop ax
    ret
endp

get_hex_num proc    ;convert hex in al into str  
    push ax
    push dx
    mov dl,16       
    div dl
    push ax
    cmp al,10       
    jb pb1
    add al,7
    pb1:   
        add al,48
        mov hex_num[0],al
        pop ax
        mov al,ah
        cmp al,10
        jb pb2
        add al,7
    pb2:    
        add al,48
        mov hex_num[1],al
        pop  dx
        pop  ax
    ret 
get_hex_num endp 

hex_str proc     
    pusha  
    push ds 

    mov ax, @data
    mov ds, ax
    lea si, hex_string
    xor ax, ax   
    mov cx, 1000
    print_loop_next: 
    xor ax, ax
    mov al, es:[di]
    call get_hex_num  
    mov ax, word ptr hex_num 

    mov es:[si], al
    mov es:[si+1], ah
        
    add si, 2
    inc di   
    loop print_loop_next
    
    pop ds
    popa
    ret
hex_str endp
    
        
 
next_page_screen proc  
    push ax

    mov ax,  ds 
    cmp ax , 0b798h
    je next_page_video_mode 
    cmp ax, 0ffaah
    ja next_page_screen_again
    cmp ax, 0eee8h
    je next_page_PZU   
    cmp bx, 1
    je counterON
    mov si , 0
    lea di, buffer_string
    mov cx, 2000
    rep movsb  
    lea di, buffer_string
    call hex_str
    stosw 
    call update_screen  
    ;add [counter], 1 
    inc bx
    jmp next_page_screen_end
    next_page_video_mode:
        mov ax, 0c855h  
        mov ds, ax
        jmp next_page_screen_end                                              ; вывести строку с ошибкой в консоль
    next_page_PZU:
        mov ax, 0f000h
        mov ds, ax
        jmp next_page_screen_end  
        
    next_page_screen_again: 
        mov ax, 00000h
        mov ds, ax
        jmp next_page_screen_end
    
    counterON:
        lea di, buffer_string
        add di, 1000 
        call hex_str
        call update_screen 
        dec bx 
        add ax , 125
        mov ds, ax        
    
    next_page_screen_end:


    pop ax 
    ret
endp      

;previous_page_screen proc 
;    push ax 
;    mov ax, ds
;    cmp ax, 0007dh
;    jb previous_page_screen_end 
;    previous:  
;    cmp bx, 1
;    je  counterONPre
;    sub ax, 125
;    mov ds, ax
;    mov si , 0
;    lea di, buffer_string
;    mov cx, 2000
;    rep movsb  
;    lea di, buffer_string 
;    add di, 1000
;    call hex_str
;    call update_screen  
;    add ax, 125
;    mov ds, ax  
;    inc bx
;    
;    counterONPre:
;        lea di, buffer_string
;        call hex_str
;        call update_screen
;        dec bx
;    
;    previous_page_screen_end:  
;    pop ax
;    ret
;endp   



main_loop proc
    main_loop_loop:
    
    call get_desired_action 
    cmp desired_action , exit
    je main_loop_end
    
    cmp desired_action, desired_action_none
    je main_loop_loop
    
    
    cmp desired_action, action_next 
    je next_page_screen_met

    
;    cmp desired_action, action_previous
;    je previous_page_screen_met

    
    cmp desired_action, action_copy  
    call save_in_file
    jmp main_loop_loop
    
    next_page_screen_met:
    call next_page_screen 
    jmp main_loop_loop
    
;    previous_page_screen_met:
;    call previous_page_screen
;    jmp main_loop_loop
   
    main_loop_end:
    ret
endp

init proc  
;    push dx
;    push ax
;    
;    mov dx, offset f_name 
;    xor ax, ax
;    mov ah, 5bh 
;    
;    int 21h
;    jc  init_error
;    mov bx, ax
;    
;    pop ax
;    pop dx
;    init_error: 
;    mov si, 0
;    stosw
;    call update_screen
;    
    ret
endp

write_to_file proc 

    
    mov dx, offset buffer_string
    xor ax, ax
    mov ah, 40h
    int 21h
    
    jc start_end
    
    ret
endp
           
clear_screen proc  
        push  ax
        push cx 
        push es
       
        mov ax, 0b800h 
        mov di, 0
        mov es, ax
        mov ax, empty
        mov cx, 2000
        rep stosw  
       
        pop ax
        pop cx
        pop es
        ret
endp

getFileName proc
    pusha
		
	mov si, 82h             ;Начало командной строки
	
    skipSpaces si           ;Пропуск пробелов
	
	copyWord fileName       ;Считывание слова
	
	cmdEnd:	    
    popa
    ret
endp 

checkName proc    
    cmp [filename], 0
    je namesNotFound
    ret
endp 

namesNotFound:  
    ;Пустая командная строка
    outputString cmdError
    jmp start_end   
    
not2: 
    ;Путь не найден 
    cmp ax, 03h 
    jne not3  
    outputString pathNotFound
    jmp start_end    
    
not3:  
    ;Открыто слишком много файлов
    cmp ax, 04h
    jne not4   
    outputString 2ManyFiles
    jmp start_end
    
not4:
    ;Отказано в доступе
    cmp ax, 05h
    jne not5 
    outputString accessDenied
    jmp start_end      
    
not5: 
    ;Некорректный режим доступа
    outputString invalidAccessMode  
    jmp start_end
    
openFail:
    
    outputString fopenError         
    
    ;Файл не найден
    cmp ax, 02h   
    jne not2
    outputString fileNotFound
jmp start_end   
    
createFileW proc 
    mov ah,3Ch
    mov cx,0 
    lea dx, filename
    int 21h 
    jc openFail   

    
    mov ax, 03d02h
    mov dx, offset fileName 
    mov cx, 1
    int 21h 
    jc openfail
    ret     
endp 

save_in_file proc 
    pusha                     
    push ds
    push si    
    push di 
    mov ax, @data
    mov ds , ax
    xor ax,ax
    xor bx,bx 
    xor di,di 
    xor cx, cx
    
    mov bx, [handler]
       
    xor ax, ax
    
    mov ah, 40h
;    mov bx, handler  
    mov cx, 2001
    mov dx, offset hex_string
    int 21h  
    jc not2
    
    pop di
    pop si 
    pop ds
    popa
    ret   
save_in_file endp  
        
start:
         
    mov ax, @data 
    mov es, ax 
    
    ;Получение имени файла из cmd
    call getFileName
    
    mov ds, ax
      
    ;Проверка получения имени файла
    call checkName      
    
    ;Открыть файл
    mov dx, offset fileName
    call createFileW
    mov handler, ax   
         
;    mov ax, @data
;    mov es, ax  
    mov ax, 00000h
    mov ds, ax            ;start adress od RAM
    
;    call set_video_mode       ; movsb ds:si to es:di
    
;    call init            ;реализуем тут меню начальное пока будет пусто
    XOR BX, BX
    call main_loop  
    
                      
    
    
    
start_end:   
    closeFile handler
    call clear_screen 
    mov ax, 4c00h
    int 21h
end start
