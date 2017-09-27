TITLE MASM main
INCLUDE Irvine32.inc
LOCATE_DECIMAL_POINT PROTO NEAR C, decimalbuffer:ptr byte, BLength:ptr word, DPposition:ptr word
	.data

number1Array BYTE 100 DUP(0)
n1bytecount dw ?

number2Array BYTE 100 DUP(0)
n2bytecount dw ?

decimalPosition1 dw ?
decimalPosition2 dw ?
finalDecimal dw ?
finalLength dw ?

startMSG BYTE "Addition Calculator (BCD) Decimal Supported",0
number1prompt BYTE "Enter First Number > ",0
number2prompt BYTE "Enter Second Number > ",0
resultMSG BYTE	"Addition Result: ",0

errorMSG BYTE "Invalid input",0

	.code

MAIN PROC
START:
	mov		edx,OFFSET startMSG
	call	writestring
	call	crlf
	
	mov		edx,OFFSET number1prompt
	call	writestring
	
	mov		ebx,OFFSET number1Array
	xor		cx,cx
	xor		esi,esi
	xor		dx,dx
	call	getNumbers
	
	cmp		dx,0FFFFh
	je		START
	
	mov		n1bytecount,cx
	call	crlf

	mov		edx,OFFSET number2prompt
	call	writestring
	
	mov		ebx,OFFSET number2ARRAY
	xor		cx,cx
	xor		esi,esi
	xor		dx,dx
	call	getNumbers
	
	cmp		dx,0FFFFh
	je		START

	mov		n2bytecount,cx
	call	crlf
	
FLIPARRAYS:
	mov		ebx,OFFSET number1Array
	mov		cx,n1bytecount
	call	flipArray
	
	mov		ebx,OFFSET number2Array
	mov		cx,n2bytecount
	call	flipArray
	
	INVOKE	LOCATE_DECIMAL_POINT,OFFSET number1Array,OFFSET n1bytecount,OFFSET decimalPosition1
	INVOKE	LOCATE_DECIMAL_POINT,OFFSET number2Array,OFFSET n2bytecount,OFFSET decimalPosition2
	
DECIMALCHECK:
	mov		ax,decimalPosition1
	mov		bx,decimalPosition2
	cmp		ax,bx
	jl		DECIMAL1LESS
	jg		DECIMAL2LESS
	mov		finalDecimal,ax
	jmp		CHECKLENGTH
DECIMAL1LESS:  ;flips arrays with additional zeroes for decimal
	mov		finalDecimal,ax
	mov		ebx,OFFSET number1Array
	mov		cx,n1bytecount
	call	flipArray
	mov		ax,finalDecimal
	mov		bx,decimalPosition1
	sub		ax,bx
	add		cx,ax
	mov		ebx,OFFSET number1Array
	call	flipArray
	jmp		CHECKLENGTH
DECIMAL2LESS:	;flips arrays with additional zeroes for decimal
	mov		finalDecimal,ax
	mov		ebx,OFFSET number2Array
	mov		cx,n2bytecount
	call	flipArray
	mov		ax,finalDecimal
	mov		bx,decimalPosition2
	sub		ax,bx
	add		cx,ax
	mov		ebx,OFFSET number2Array
	call	flipArray
	jmp		CHECKLENGTH
CHECKLENGTH:	;makes sure the longest array count is used in addition and printing
	mov		ax,n1bytecount
	mov		bx,n2bytecount
	cmp		ax,bx
	jl		LENGTH1LESS
	jg		LENGTH2LESS
	mov		finalLength,ax
	jmp		ADDARRAY
LENGTH1LESS:
	mov		finalLength,bx
	jmp		ADDARRAY
LENGTH2LESS:
	mov		finalLength,ax
	
ADDARRAY:
	mov		ax,finalLength
	mov		bx,finalDecimal
	sub		ax,bx
	mov		finalDecimal,ax
	mov		cx,finalLength
	mov 	ebx,OFFSET number1Array
	mov 	edi,OFFSET number2Array
	call	addArrays
	mov		ebx,OFFSET number1Array
	mov		cx,finalLength
	call	flipArray
	mov		ebx,OFFSET number1Array
	mov		cx,finalLength
	call	printArray
	jmp		START

exit
MAIN	ENDP

;************************SUBROUTINES**********************************************
;************************Get Numbers**********************************************
;GRABS and Converts User input to decimal
;Checks for decimal allows one decimal input
;Error is called if more than one decimal entered, or if not ascii 1-9
getNumbers	PROC
	xor		dx,dx
	xor		di,di
	
STARTGETNUMBER:
	call	readchar
	call	writechar
	
	cmp 	al,0Dh
	je		ISNULL
	
	cmp		al,02Eh
	je		ISDECIMAL
	
	cmp		al,0dh
	je		EXITGETNUMBER

	sub		al,30h
	
	cmp		al,0
	jl		ERRORMESSAGE
	cmp		al,9
	jg 		ERRORMESSAGE
	
	mov		[ebx + esi],al
	
	jmp		CONTINUENUM
ISNULL:
	cmp		cx,0
	jne		EXITGETNUMBER
	mov		BYTE PTR [ebx + esi],0
	inc		cx
	jmp		EXITGETNUMBER

ISDECIMAL:
	cmp		di,0
	jne		ERRORMESSAGE
	mov		di,02Eh
	mov		[ebx+esi],al
	jmp		CONTINUENUM

MULTDEC:
	inc		esi
	jmp		STARTGETNUMBER

CONTINUENUM:
	inc		cx
	inc		esi
	jmp		STARTGETNUMBER

ADDDECIMAL:
	mov		BYTE PTR [ebx+esi],02Eh
	inc		cx
	inc		esi
	mov		BYTE PTR [ebx+esi],0h
	inc		cx
	mov		di,02Eh
	jmp		EXITGETNUMBER

ERRORMESSAGE:
	call		MAINERROR

EXITGETNUMBER:
	cmp		di,0h
	je		ADDDECIMAL
	ret
	
getNumbers	ENDP

;************************************FLIP ARRAY*************************************
;Uses stack push and pop to flip an array
;Is also used to extend array to match decimal places
flipArray	PROC
	xor 	esi,esi
	xor		ax,ax
PUSHARRAY:
	mov 	al,[ebx + esi]
	push	ax
	inc 	esi
	cmp 	si,cx
	jl		PUSHARRAY
	xor 	esi,esi
	xor		ax,ax
POPARRAY:
	pop 	ax
	mov		[ebx + esi],al
	inc 	esi
	cmp 	si,cx
	jl		POPARRAY
	xor 	esi,esi
	xor		ax,ax
	ret
flipArray	ENDP
;******************************* ADD ARRAY *****************************************
;Adds the arrays together carying and extending length of array as needed
addArrays	PROC
	xor 	esi,esi
	xor 	ax,ax
	
STARTADDARRAYS:
	mov		dl,[ebx+esi]
	cmp		dl,02Eh
	je		ISDECIMAL
	add 	al,dl
	push	ebx
	mov		ebx,edi
	mov		dl,[ebx+esi]
	cmp		dl,02Eh
	je		ISDECIMAL
	add 	al,dl
	pop		ebx
	cmp 	al,0ah
	jge		CARRY
	mov		[ebx + esi],al
	inc		esi
	cmp 	cx,si
	je		EXITADDARR
	xor		ax,ax
	jmp		STARTADDARRAYS
CARRY:
	mov		ah,al
	sub		ah,0Ah
	mov		[ebx+esi],ah
	xor		ax,ax
	add		al,01h
	inc		esi
	cmp		cx,si
	jne		STARTADDARRAYS
	mov		[ebx+esi],al
	inc		cx
	mov		finalLength,cx
	mov		cx,finalDecimal
	inc		cx
	mov		finalDecimal,cx
	jmp		EXITADDARR
ISDECIMAL:
	inc		esi
	jmp		STARTADDARRAYS
EXITADDARR:
	ret 
addArrays	ENDP

;***********************************Print Array**************************************
;prints array
;adds decimal position to proper spot based on finalDecimal variable
printArray	PROC
	xor		esi,esi
	mov		edx,OFFSET resultMSG
	call	writestring
PRINTCHAR:
	mov		al,[ebx + esi]
	add		al,30h
	call	writechar
	cmp		si,finalDecimal
	je		ISDECIMAL
	inc		esi
	cmp		si,cx
	je		EXITPRINTARRAY
	jmp		PRINTCHAR
ISDECIMAL:
	mov		al,02Eh
	call	writechar
	cmp		cx,si
	je		LSTZERO 
	inc		esi
	jmp		PRINTCHAR
LSTZERO:
	mov		al,030h
	call	writechar
EXITPRINTARRAY:
	call	crlf
	ret
printArray	ENDP

MAINERROR	PROC
	mov		edx,OFFSET errorMSG
	call	writestring
	call	crlf
	mov		dx,0FFFFh
	ret
MAINERROR	ENDP

;*************** SUBROUTINE LOCATE_DECIMAL_POINT ********************
;Inputs: decimalbuffer, BLength, DPposition
;Outputs: decimalbuffer, BLength
LOCATE_DECIMAL_POINT PROC NEAR C USES eax ebx ecx edx esi edi ebp, decimalbuffer:ptr byte, BLength:ptr word, DPposition:ptr word
	LOCAL	tempbuffer[100]:BYTE		;input buffer


	xor ax,ax			;clear ax
	mov ebx,1			;set initial DP position to 1 since 0 is no DP
	xor ecx,ecx
	mov esi,Blength
	mov cx,[esi]
	cmp cx,0
	jg atLeast1Digit
	mov edi, decimalbuffer	;move offset of numberXbuffer
	xor ax,ax
	mov [edi],ax		;return zero
	jmp DONE
atLeast1Digit:
	lea esi,  tempbuffer	;move offset of tempbuffer
	mov edi, decimalbuffer	;move offset of numberXbuffer

findDecimalPoint:
	mov al,[edi]
	cmp al,02Eh
	jne not_DP_Yet
	mov edx,DPposition
	mov [edx],bx	
	mov edx,BLength	
	mov ax,[edx]
	dec ax				
	mov [edx],ax	
	jmp skip_DP
not_DP_Yet:	
	mov [esi],al		;reorder in temp buffer 
	inc esi
skip_DP:				;reduce length by one since skipping DP
	inc ebx
	dec ecx
	cmp ecx,0
	je CopyTempBufToOriginal
nextDigit:
	inc edi			;point to next digit

	jmp findDecimalPoint
CopyTempBufToOriginal:
	mov esi,BLength
	mov cx,[esi]
	lea esi,  tempbuffer		;move offset of tempbuffer
	mov edi, decimalbuffer	;move offset of numberXbuffer		
	
CopyLoop:
	mov al,[esi]
	mov [edi],al
	inc edi			;point to next digit
	inc esi		
	dec ecx
	cmp ecx,0
	je DONE
	jmp CopyLoop
DONE:
	xor eax,eax		
	mov [edi],eax		;remove carriage return from readstring array
	Ret
LOCATE_DECIMAL_POINT	 ENDP


END		MAIN

	

	
	


	




