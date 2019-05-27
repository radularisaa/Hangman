.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern fscanf: proc
extern printf: proc
extern fopen: proc
extern fclose: proc
extern strlen: proc
extern scanf: proc

extern fgets: proc
extern puts: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
file_name db "file.txt",0
open_mode dd "r",0
number_of_tries db 6,0
length_information db "The word or group of words you have to guess has %d letters.", 13, 10, 0
current_word db "The word you have so far is: ", 0
repeating_message db "You already tried this letter.",13,10, 0
array_tried db 25 dup(0)
array_length db 0
length_display dd 0
letter_repeated dd 0
number_of_tries_message db "The number of tries you have left is %d.", 13,10,0
you_won db "You are good, congratulations! You won!", 0
you_lost db "You lost! Try again!", 0
read_letter_mode db "%c",0
letter db 0,0
letter_enter db 0
message db "Introduce a letter, then press ENTER: ",0,0,0
length_word dd 0
read_word db 0,0,0,0,0
pointer_file dd 0
formed_word db 0

.code

start:
;;;;;opening file
push offset open_mode
push offset file_name
call fopen
add esp,8
mov pointer_file, eax

;;;;;;reading the word that has to be guessed
mov ebx,20
push pointer_file
push ebx
push offset read_word
call fgets
add esp,12

;;;;;the determination of the word's length
push offset read_word
call strlen
add esp,4
mov length_word, eax

;;;;;the creation of another word 
xor eax,eax
creating:
	xor ebx,ebx
	mov bl,read_word[eax]
	cmp bl," "
	je space
	jne no_space
	space:
	mov formed_word[eax]," "
	xor ecx,ecx
	mov ecx,length_word
	dec ecx
	mov length_display,ecx
	jmp continue_creating
	no_space:
	mov formed_word[eax],'?'
	continue_creating:
	inc eax
	cmp eax,length_word
	jne creating

;;;;;message display
push length_display
push offset length_information
call printf
add esp,8

game_loop:
	;reading of the letter
	push offset message
	call printf
	add esp,4	
	push offset letter
	push offset read_letter_mode
	call scanf
	add esp,8
	push offset letter_enter
	push offset read_letter_mode
	call scanf
	add esp,8
	
	;verifying if the letter introduced belongs to the word
	xor edx,edx
	xor eax,eax
	mov al,letter
	xor ebx,ebx
	xor ecx,ecx
	verifying_letter:
		mov bl,read_word[edx]
		cmp al,bl
		jne jump_here
		inc ecx
		jump_here:
		inc edx
		cmp edx,length_word
		jne verifying_letter
	mov letter_repeated,ecx
	cmp ecx,0
	jne increment
	je jump_over_increment
	increment:
	xor eax,eax
	mov al,number_of_tries
	inc eax
	mov number_of_tries,al
	
	jump_over_increment:
	;replacing the letter in the second word
	xor edx,edx
	xor eax,eax
	mov al,letter
	xor ebx,ebx
	replacing:
		mov bl,read_word[edx]
		cmp al,bl
		jne jump
		mov formed_word[edx],al
		jump:
		inc edx
		cmp edx,length_word
		jne replacing
	
	;verifying if there are more letters to be guessed
	xor edx,edx
	xor ebx,ebx
	repeating:
		mov cl,formed_word[ebx]
		cmp cl,'?'
		jne not_?
		inc dl
		not_?:
		inc ebx
		cmp ebx,length_word
		jne repeating
		push edx
		
	;verifying if the letter was already introduced
	xor ecx,ecx
	mov cl,array_length
	cmp cl,0
	je empty_array
	xor eax,eax
	mov al,letter
	xor ebx,ebx
	mov bl,array_length
	verifying_array:
	dec bl
	cmp al,array_tried[ebx]
	je repeated_letter
	cmp bl,0
	jne verifying_array
	
	empty_array:
	;message display with the current word		
	push offset current_word
	call printf
	add esp,4
	push offset formed_word
	call puts
	add esp,4
	jmp jump_over_repeated
	
	repeated_letter:
	push offset repeating_message
	call printf
	add esp,4
	
	xor eax,eax
	mov eax,letter_repeated
	cmp eax,0
	je increase
	jne jump_over_repeated
	increase:
	xor ecx,ecx
	mov cl,number_of_tries
	inc cl
	mov number_of_tries,cl
	
	jump_over_repeated:
	;completing the second word with the last letter introduced
	xor eax,eax
	mov al,array_length
	xor ebx,ebx
	mov bl,letter
	mov array_tried[eax],bl
	inc eax
	mov array_length, al

	;verifying if there are tries left	
	mov al,number_of_tries
	dec al
	mov number_of_tries,al
	cmp al,0
	je lost
	
	xor eax,eax
	mov al,number_of_tries
	push eax
	push offset number_of_tries_message
	call printf
	add esp,8
	
	pop edx
	cmp dl,0
	jne game_loop
	je won

	;loss message	
	lost:
	push offset you_lost
	call printf
	add esp,4
	jmp out_of_game

	;win message	
	won:
	push offset you_won
	call printf
	add esp,4
	
	out_of_game:
	push offset pointer_file
	call fclose
	push 0
	call exit
end start
