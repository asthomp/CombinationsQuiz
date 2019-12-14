TITLE Combinations Quiz

; Author: Aaron Thompson
; Last Modified: 12/14/19
; Description: This program presents the user with
; a combinations problem, allows them to guess an
; answer, and displays the correct answer. After
; they have completed as many problems as they'd
; like, they can quit and receive their overall
; score.
; Requirements: Irvine Library


INCLUDE Irvine32.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode:DWORD


; ***************************************************************
; MACRO to print a string to the console using PrintString.
; receives: (by reference): mStringAddress 
; returns: none
; preconditions: none
; registers changed: none
; ***************************************************************

Print	MACRO	mStringAddress

	push		mStringAddress
	call		PrintString
	
ENDM 

; ***************************************************************
; MACRO to print an integer to the console using PrintNumber.
; receives: (by reference): mNumAddress
; returns: none
; preconditions: none
; registers changed: none
; ***************************************************************

PrintNum MACRO	mNumber

	push		mNumber
	call		PrintNumber
	
ENDM 


; ***************************************************************
; MACRO to print a CrLf to the console using Win32 API functions.
; receives: none
; returns: none
; preconditions: none
; registers changed: eax
; ***************************************************************

HitEnter MACRO

	LOCAL		mString

	.data

	mString		BYTE 0dh, 0ah, 0

	.code

	push		eax
	lea			eax, mString
	push		eax
	call		PrintString
	
	pop			eax

ENDM 


; ***************************************************************
; MACRO to print an error message to the console. 
; receives: none
; returns: none
; preconditions: none
; registers changed: none
; ***************************************************************

PrintErrorMessage	MACRO

	LOCAL			inputError

	.data

	inputError		BYTE	" <Invalid. Try again.> ", 0

	.code

	push			OFFSET inputError
	call			PrintString

ENDM 

.data

	; Sets up assorted prompts to be displayed for the user. 

	endl			EQU		<0dh, 0ah>		
	student			BYTE	" Programmed by Aaron Thompson",0	
	gameTitle		BYTE	" The Combinations Quiz!", 0				

	gameIntro		BYTE	" A combination is the number of subsets of size r (or r-combinations)", endl
					BYTE	" that can be chosen from a set of n elements. The formula for solving", endl
					BYTE	" a combinations problem is:  n!/r!(n-r)!. For these problems, the", endl
					BYTE	" order of the elements doesn't matter and repetition is not allowed. ", endl, endl
					BYTE	" I'll generate a random combinations problem for you to solve.", endl
					BYTE	" If you enter your answer, I'll let you know if it's correct!        ", 0

	exercise1		BYTE	" Problem #",0
	exercise2		BYTE	" Number of elements in the set: ",0
	exercise3		BYTE	" Number of elements to choose from the set: ",0
	prompt			BYTE	" How many ways can you choose? [1-1000]: ",0

	ans1			BYTE	" There are ",0
	ans2			BYTE	" combinations of ",0
	ans3			BYTE	" items from a set of ",0

	right			BYTE	" You are correct! ", 0
	wrong			BYTE	" You need more practice. ", 0
	again			BYTE	" Another problem? (y/n) ", 0

	played1			BYTE	" You played ",0
	played2			BYTE	" round(s).",0
	score1			BYTE	" You scored ",0
	score2			BYTE	" point(s).",0
	wrong1			BYTE	" You got ",0
	wrong2			BYTE	" problem(s) wrong.",0
	byePrompt		BYTE	" Thanks for trying my program! Goodbye! ",0

	colon			BYTE	": ", 0
	period			BYTE	". ", 0
	seperator		BYTE	"=-----------------------------------------------------------------=",0

	; Sets up the storage variables used throughout the program.

	userInput		DWORD	?
	answer			DWORD	?
	result			DWORD	? 
	n				DWORD	?
	r				DWORD	?
	round			DWORD	1
	wins			DWORD	0
	bool			DWORD	0

.code

main PROC 
 
	call		Randomize

	push		OFFSET seperator
	push		OFFSET gameIntro
	push		OFFSET gameTitle
	call		Introduction

GameBegins:

	; Resets or "clears" the bool that tracks whether-or-not the user
	; would like to play again.

	mov			bool, 0

	push		OFFSET	colon
	push		OFFSET exercise3
	push		OFFSET exercise2
	push		OFFSET exercise1
	push		round
	push		OFFSET n
	push		OFFSET r
	call		ShowProblem

	push		OFFSET prompt
	push		OFFSET answer
	call		GetData
	
	push		OFFSET result
	push		r
	push		n
	call		Combinations

	push		OFFSET	period
	push		OFFSET	wrong
	push		OFFSET	right
	push		OFFSET	ans3
	push		OFFSET	ans2
	push		OFFSET	ans1
	push		OFFSET wins
	push		answer
	push		result
	push		r
	push		n
	call		ShowResults
	
	push		OFFSET seperator
	push		OFFSET again
	push		OFFSET round
	push		OFFSET bool
	call		PlayAgain

	; If the user chose to play another round, the bool variable will
	; have been changed to true. Otherwise, end the game. 

	cmp			bool, 1
	je			GameBegins


	push		OFFSET seperator
	push		OFFSET byePrompt
	push		OFFSET wrong2
	push		OFFSET wrong1
	push		OFFSET score2
	push		OFFSET score1
	push		OFFSET played2
	push		OFFSET played1
	push		round
	push		wins
	call		GoodBye

	invoke		ExitProcess, 0

main ENDP

	
; ***************************************************************
; Procedure to introduce the program to the user. 
; receives: (by reference): student, ec, gameTitle, gameIntro, seperator
; returns: none
; preconditions: none
; registers changed: ebp
; ***************************************************************

Introduction	PROC

	; This code preserves the registers and sets up the stack.

	push		ebp
	mov			ebp, esp

	; Prints game title.

	Print		[ebp+8]
	HitEnter
	HitEnter

	; Prints an introduction for the user. 

	Print		[ebp+12]
	HitEnter

	; Prints a seperator bar to improve the user interface. 

	HitEnter
	Print		[ebp+16]
	HitEnter

	; The code cleans up after itself and restores the registers as appropriate. 

	pop		ebp
	ret		12

Introduction	ENDP


; ***************************************************************
; Procedure to generate a random combinations problem and display
; it to the user. 
; receives: (by reference): r, n, exercise1, exercise2, exercise3, colon
; (by value) round
; returns: none
; preconditions: none
; registers changed: ebp, eax, ebx, edx
; ***************************************************************

ShowProblem		PROC

	; This code preserves the registers and sets up the stack.

	push		ebp
	mov			ebp, esp
	pushad

	; Code adapted from Mr. Paulson's Lecture #20. 
	; Since the range is 3-12, we must adjust the range to reflect the appropriate formula. 

	mov			eax, 12
	sub			eax, 3		
	inc			eax

    call		RandomRange  ; Puts a random number from [0-9] in EAX.

	; To ensure the range is correct, 3 must be added to our random number. 
	; This makes the range 3-12.

	add			eax, 3 

	; This code stores our randomly generated number in n.

	mov			edx, [ebp+12]
	mov			[edx], eax

	; Since n is already stored and that's the high point of r's range, we can generate a random number
	; for r (which ranges from 1 to n).

	sub			eax, 1
	inc			eax

	call		RandomRange

	; As before, the number must be shifted to accomodate the low end of the range. 
	add			eax, 1  

	; This code stores our randomly generated number in r.
	mov			edx, [ebp+8]
	mov			[edx], eax

	; This code prints the problem #. 

	HitEnter
	Print		[ebp+20]
	PrintNum	[ebp+16]
	Print		[ebp+32]
	HitEnter

	; This code prints the number of elements in the set. 

	HitEnter
	Print		[ebp+24]
	mov			eax, [ebp+12]
	PrintNum	[eax]
	HitEnter

	; This code prints the number of items to choose from the set.

	Print		[ebp+28]
	mov			eax, [ebp+8]
	PrintNum	[eax]
	HitEnter

	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	pop			ebp
	ret			24

ShowProblem		ENDP


; ***************************************************************
; Procedure to get data from the user. 
; receives: (by reference): prompt, answer
; returns: answer
; preconditions: none
; registers changed: ebp, eax, ebx, edx
; ***************************************************************

GetData			PROC

	; This code preserves the registers and sets up the stack.

	push		ebp                 
	mov			ebp,esp					
	pushad

InputValidationLoop:

	;This code prints the user prompt asking for a number within the range.

	Print		[ebp+12]   

	; This section of code gets an integer from the user.
		
	push		[ebp+12]
	push		[ebp+8]  
	call		GetNumber

	; This code checks to see if the integer supplied by the user is within range.
	; If not, an error prints and the user is prompted again. 

	mov			ebx, [ebp+8]
	mov			edx, [ebx]
	cmp			edx, 1000
	jg			PrintError		 ; Their number was too high. 

	cmp			edx, 1
	jl			PrintError		; Their number was too low. 

	jmp			ExitLoop		; Otherwise, their number is in bounds.

PrintError:

	;This code prints an error message when the user provides a number
	;outside the range.

	PrintErrorMessage
	HitEnter
	HitEnter

	jmp			InputValidationLoop

ExitLoop:

	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	pop			ebp
	ret			12

GetData			ENDP 


; ***************************************************************
; Procedure to calculate the combinations formula.
; receives: (by reference): result (by value): n, r
; returns: request
; preconditions: integer values for n and r
; registers changed: ebp, eax, ebx, edx
; formula: n!/r!(n-r)!
; ***************************************************************

Combinations	PROC

	; This code preserves the registers and sets up the stack.

	push		ebp            
	mov			ebp,esp			
	pushad					
	 
	; This section of code calculates (n-r) and then
	; finds (n-r)!, storing the calculation in result.

	mov			eax, [ebp+8]
	sub			eax, [ebp+12]

	push		eax
	call		Factorial
	mov			ebx, [ebp+16]		; Stores the calculation in result.
	mov			[ebx], eax				

	; This section of code calculates r! and
	; stores it in eax. 

	push		[ebp+12]
	call		Factorial

	; This code multiplies r! by (n-r)! and stores
	; result in result.

	mov			edx, [ebp+16]
	mov			ebx, [edx]
	mul			ebx					; Multiplies r! by (n-r)!
	mov			ebx, [ebp+16]		; Stores the calculation in result.
	mov			[ebx], eax
	   	
	; This segment of code calculates n! and stores
	; it in eax. 

	push		[ebp+8]
	call		Factorial

	; Gets r!(n-r)! from result and stores it in ebx.

	mov			edx, [ebp+16]
	mov			ebx, [edx]

	; Divides n! by r!(n-r)! and stores the result in eax.

	mov			edx, 0
	div			ebx

	; Stores the final calculation in result. This calculation
	; is the solution to the combinations formula, given n and r.
	
	mov			ebx, [ebp+16]	
	mov			[ebx], eax
	
	; The code cleans up after itself and restores the registers as appropriate. 

	popad	
	pop			ebp
	ret			12

Combinations	ENDP


; ***************************************************************
; Procedure to recursively calculate a factorial.
; receives: (by value) an integer
; preconditions: parameter must have already been checked for validity
; registers changed: ebp, eax, ebx
; recursive formula: if (x>0) { return x * factorial(x-1); } else { return 1;}\
; returns: factorial in EAX
; ***************************************************************

Factorial		PROC

; Sets up the stack frame and preserves some registers.
; The remaining registers are preserved in Factorial's calling
; function, Combinations. 

	push		ebp                 ; Sets up the stack frame.
	mov			ebp,esp				; The base pointer points to the top of the stack.


	; This procedure examines x and compares it to 1, our base case. 
	; If x is equal to or less than one, the code jumps to the base 
	; case statements. If x is greater than one, it proceeds with the 
	; recursive statements.

	mov			ebx, [ebp+8]		; Stores the "pushed" variable (x) in ebx.
	cmp			ebx, 1				; Compares x to 1. 

	jle			BaseCase			; If x <= 1, proceed with the base case statements.

	; This section of code contains the recursive case. The rescursive 
	; case executes its statements (including calling itself),
	; proceeds to the multiply section, and then returns. 

Recurse:	
	
	; The x value, now stored in ebx, is decremented and pushed onto the stack as a parameter. 
	; Then, Factorial is called recursively on itself.

	dec			ebx                   
	push		ebx
	call		Factorial

	; Factorial will call itself recursively until it hits the base case. From there, 
	; it will proceed back upward through each call, returning to the section 
	; labelled "multiply."

	jmp			Multiply
	
	; This section of code contains the base case. The base case
	; executes its statements and then proceeds to the multiply 
	; section before returning. 

BaseCase: 

	mov			eax, 1
	jmp			FactorialEnd

	; After the recursive procedures have been called, the code proceeds back 
	; upward through each call. Regardless of the case, the final step for each 
	; call is to proceed through the "multiply" section. For each recursion, 
	; the x parameter ([ebp+8]) is multiplied by the product of all the previous
	; x parameters. This means that, for a given call, x is multiplied by the 
	; product of all the previous values from (x-1)... to 1. The algorithm
	; ultimately returns this calculation, the factorial, in eax. 


Multiply:

	mov			ebx, [ebp+8] 
	mul			ebx

FactorialEnd:

	; The code cleans up after itself and restores the registers as appropriate. 

	pop			ebp
	ret			4

Factorial		ENDP


; ***************************************************************
; Procedure to show the user the results of a round.
; receives: (by reference) ans1, ans2, ans3, right, wrong, period
;			(by value) n, r, result, answer
; preconditions: none
; registers changed: eax, ebx
; returns: none
; ***************************************************************

ShowResults		PROC

	LOCAL		mString:DWORD

	; This code preserves the registers. Local sets up the stack.

	pushad

	; Prints the answer.

	HitEnter
	Print		[ebp+28]
	PrintNum	[ebp+16]
	Print		[ebp+32]
	PrintNum	[ebp+12]
	Print		[ebp+36]
	PrintNum	[ebp+8]
	Print		[ebp+48]
	HitEnter

; Compare user's answer (+20) to computer's answer (+16)

	mov			eax, [ebp+20]
	mov			ebx, [ebp+16]
	cmp			eax, ebx
	je			Correct

	; Prints that the user's answer is incorrect. Skips incrementing the "win" counter.

	Print		[ebp+44]
	jmp			EndShowResults

Correct:

	; Prints that the user had the correct answer and increments the "win" counter.

	Print		[ebp+40]
	mov			ebx, [ebp+24]
	mov			eax, [ebx]
	inc			eax
	mov			[ebx], eax

EndShowResults:

	HitEnter

	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	ret			44

ShowResults		ENDP


; ***************************************************************
; Procedure to determine whether or not the user would like another
; combinations problem. 
; receives: (by reference) bool, round, again, seperator
; preconditions: none
; registers changed: ebp, eax, ebx
; returns: bool
; ***************************************************************

PlayAgain		PROC

LOCAL aHandle:HANDLE, abytesRead:DWORD, aBuffSize:DWORD, aBuffer[82]:BYTE


	; This code preserves the registers. Local sets up the stack.

	pushad

PlayAgainTop:

	; Prompts the user, asking if they'd like to continue playing. 

	HitEnter
	Print		[ebp+16]

	; Cleans the buffer and populates it with 0s. 

	lea			eax, aBuffer
	push		eax
	call		CleanBuffer

	; Preserves the registers around the ReadConsole Win32 API function.

	pushad

	INVOKE		GetStdHandle, STD_INPUT_HANDLE
	mov			aHandle, eax
	INVOKE		ReadConsole, aHandle, ADDR aBuffer, 82, ADDR aBytesRead, 0

	; Restores the registers once we've read from the keyboard.

	popad

	; If the character is Y or y, the user wants to play again. 

	cmp			aBuffer, 121
	je			PlayAgainTrue
	cmp			aBuffer, 89
	je			PlayAgainTrue

	; If the character is set to N or n, the user does not want to play again.

	cmp			aBuffer, 110
	je			PlayAgainReturn

	cmp			aBuffer, 78
	je			PlayAgainReturn

	; Otherwise, the character typed invalid input and we need to print an error message.

	jmp			PlayAgainError

PlayAgainTrue:

	; If the user would like to play again, we need to increment the
	; round counter and set bool to true so that the loop in main
	; will replay the game. 

	mov			eax, [ebp+12]
	mov			ebx, [eax]
	inc			ebx
	mov			[eax], ebx

	mov			eax, [ebp+8]
	mov			ebx, 1
	mov			[eax], ebx
	jmp			PlayAgainReturn

; Prints the error message and then loops again, prompting the user again.

PlayAgainError:

	PrintErrorMessage
	HitEnter
	jmp			PlayAgainTop

; Returns with bool set to false; the game will not play again.

PlayAgainReturn:

	HitEnter
	Print		[ebp+20]
	HitEnter

	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	ret			16
PlayAgain		ENDP

; ***************************************************************
; Procedure that says goodbye to the user and prints the final score.
; receives: (by reference) played1, played2, score1, score2, wrong1,
;			wrong2, byePrompt, seperator
;			(by value) wins, round
; preconditions: none
; registers changed: ebp, eax, ebx
; returns: bool
; ***************************************************************

Goodbye			PROC

	; This code preserves the registers and sets up the stack.

	push		ebp
	mov			ebp, esp
	pushad

	; Prints how many rounds were played.

	HitEnter
	Print		[ebp+16]
	PrintNum	[ebp+12]
	Print		[ebp+20]
	HitEnter

	; Prints how many games were won.

	Print		[ebp+24]
	PrintNum	[ebp+8]
	Print		[ebp+28]
	HitEnter

	; Prints how many games were lost. 
	Print		[ebp+32]
	mov			eax,[ebp+12]
	mov			ebx,[ebp+8]
	sub			eax, ebx
	PrintNum	eax
	Print		[ebp+36]
	HitEnter
	
	; Prints a seperator bar to improve the user interface.

	HitEnter
	Print		[ebp+44]
	HitEnter
	HitEnter

	;Prints a goodbye to the user. 

	Print		[ebp+40]
	HitEnter
	HitEnter

	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	pop			ebp
	ret			40

Goodbye			ENDP


; ***************************************************************
; This procedure prints a string. 
; receives: (by reference) a string variable
; preconditions: Strings must be null-terminated. 
; registers changed: eax, bl, edx, esi ebp 
; This procedure replaces Irvine Library's WriteString.
; ***************************************************************

PrintString		PROC

LOCAL pHandle:HANDLE, pBytesRead:DWORD, pWritten:DWORD, pSize:DWORD

	; This code preserves the registers. Local sets up the stack.

	pushad

	mov			edx, [ebp+8]		; A pointer to where the string parameter @ is stored.
	mov			eax, 0				; This register is being used to count the number of elements in the string. 
	mov			esi, 0				; This register is being used to traverse the string array. 
	
; This loop counts the number of characters in the string,
; which is required to print the string to the console. 
; For each iteration of the loop, it either finds a character,
; which increments the counter, or the sentinel value (0), which 
; indicates that it's found the end of the string.

CountLoop:

	mov			bl, [edx+esi]  
	movzx		ebx, bl
	cmp			ebx, 0

	je			Sentinel

	inc			eax
	inc			esi

	jmp			CountLoop

Sentinel:
 
	mov			pSize, eax


	; Now that we've counted the number of elements in the string, 
	; we can print the string to the console using that data.

	invoke		GetStdHandle, STD_OUTPUT_HANDLE
	mov			pHandle, eax
	invoke		WriteConsole, pHandle, [ebp+8], pSize, addr pWritten, 0 

	; The code cleans up after itself and restores the registers as appropriate. 
	popad
	ret			4 

PrintString		ENDP


; ***************************************************************
; This procedure prints a number using the Win32 API. 
; receives: (by reference) a number.
; preconditions: none
; registers changed: eax, bl, edx, esi ebp
; This procedure replaces Irvine Library's WriteDec.
; ***************************************************************

PrintNumber		PROC

LOCAL aHandle:HANDLE, aBytesWritten:DWORD, aPower:DWORD, aPowerResult:DWORD, aDigits:DWORD, aTempNum:DWORD, aPrintMe:DWORD

	; This section preserves the registers. Local sets up the stack. 

	pushad

	; The number to print is stored in a local variable for manipulation.

	mov			eax, [ebp+8]
	mov			aTempNum, eax

	; CountDigits is provided two variables (by reference) and called. 
	; It returns the total number of digits in the number to be printed. 
	; The printing loop will execute once for each digit in the number. 

	lea			eax, aDigits
	push		eax
	push		[ebp+8]
	call		CountDigits
	mov			ecx, aDigits

	; This code calculates the highest power of 10 that the number is divisible by. 
	; If a number has n digits, that value is 10^n-1. The Power10 procedure is called
	; and calculates 10^n-1, storing that data in a pushed variable.

	mov			eax, aDigits
	dec			eax
	mov			aPower, eax

	lea			ebx, aPowerResult
	push		ebx
	push		aPower
	call		Power10

	; This loop divides the number (ex: 567), which has n digits, by 10^n-1. The result
	; is the actual digit in that decimal column (ex: 500/100 = 5). The actual digit is
	; converted to ASCII code and printed to the console. The remainder of the number 
	; (ex: 67) is stored and the loop iterates again, this time performing the same  
	; operations on a number that has n-1 digits. 

PrintNumberLoop:
	
	;Calculates division results.

	mov			edx, 0
	mov			eax, aTempNum
	mov			ebx, aPowerResult
	div			ebx

	; Converts to ASCII.

	add			eax, 48
	mov			aPrintMe, eax
	mov			aTempNum, edx

	; Preserves the registers around the WriteConsole Win32 API function.

	pushad

	invoke		GetStdHandle, STD_OUTPUT_HANDLE
	mov			aHandle, eax
	invoke		WriteConsole, aHandle, addr aPrintMe, 1, addr aBytesWritten, 0 

	;After the number is printed, the registers are restored.

	popad

	; The original power-of-ten, 10^n-1 must be adjusted because we've already
	; printed the number in the largest column. After division, our new value
	; will be 10^(n-1-1). Then, we're good to loop again.

	mov			edx, 0
	mov			eax, aPowerResult
	mov			ebx, 10
	div			ebx
	mov			aPowerResult, eax

	loop		PrintNumberLoop

	popad
	ret			4 

PrintNumber		ENDP


; ***************************************************************
; This procedure gets keyboard input from the user (via Win32 API
; functions), confirms it received an integer, and returns it.
; receives: keyboard input, (by reference) storage variable
; preconditions: none
; registers changed: eax, ebx, ecx, edx, esi 
; This procedure replaces Irvine Library's ReadInt.
; ***************************************************************

GetNumber		PROC

LOCAL gHandle:HANDLE, gbytesRead:DWORD, gBuffSize:DWORD, gBuffer[82]:BYTE

	; This preserves the registers. Local sets up the stack. 

	pushad

GetNumberLoop:

	; The code, first, creates a buffer, calling CleanBuffer to 
	; populate is with 0's. It then sets limits to the buffer's size, 
	; restricting it to 2-bytes less than its total.

	lea			eax, gBuffer
	push		eax
	call		CleanBuffer

	mov			gBuffSize, 80

	; The registers are preserved to prevent issues with ReadConsole from
	; affecting functionality.

	pushad

	INVOKE		GetStdHandle, STD_INPUT_HANDLE
	mov			gHandle, eax

	INVOKE		ReadConsole, gHandle, ADDR gBuffer, gBuffSize, ADDR gBytesRead, 0

	; Restores the registers after the input is collected from the keyboard. 

	popad

	mov			eax, 0  ; Set up the accumulator.
	mov			esi, 0  ; Set up the buffer's index.

	; If the user just hits enter, the procedure prints an error.

	 cmp		[gBuffer], 0Dh
	 je			Error

	 ; Otherwise, the code loops through the buffer checking each
	 ; character to confirm that it received an appropriate input. It
	 ; checks whether-or-not the sentinel character has been found (0Dh)
	 ; and then checks if each character is an ASCII number.

Loop1:

	cmp			[gBuffer+esi], 0Dh
	je			StoreResult

	cmp			[gBuffer+esi], 48
	jl			Error

	cmp			[gBuffer+esi], 57
	ja			Error
		
	; Since it's possible that we previously read a number into our storage variable,
	; we need to "move it over" to make room for the number we just read. So, we multiply
	; our accumulating variable by 10 to shift it to the left. If it holds a digit, the
	; number will shift. If it doesn't (0), nothing happens (10*0=0). 

	mov			ebx, 10
	mul			ebx

	; Next, this code stores the target number into a register and extends it.
	; 48 bytes are subtracted from the number to convert it from ASCII to an
	; actual digit and, then, the number is added to the accumulator.

	movzx		ecx, [gBuffer+esi]
	sub			ecx, 48
	add			eax, ecx

	; Lastly, we increment the variable that is traversing the buffer
	; and loop again. 

	inc			esi

	jmp			Loop1

	; In the event of an error, a message prints and the code loops through
	; the process again, reissuing the prompts to the user.

Error:

	PrintErrorMessage 
	HitEnter
	HitEnter
	Print		[ebp+12]  

	jmp			GetNumberLoop

	; Once the number has been completely collected and converted,
	; the result is stored in the storage variable and function returns. 

StoreResult:

	mov			edx, [ebp+8]
	mov			[edx], eax

	
	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	ret			8

GetNumber		ENDP


; ***************************************************************
; This procedure takes a number and counts the number of digits it has.
; receives: (by reference) a number, storage variable
; preconditions: none
; registers changed: ebp, eax, ebx, ecx, edx
; ***************************************************************

CountDigits PROC

	; This code preserves the registers and sets up the stack.

	push		ebp
	mov			ebp, esp
	pushad

	; This code sets up our starting divisor counter and accumulator. 

	mov			ebx, 1  
	mov			ecx, 0  

	; This section of code checks for an edge case - zero.
	; If zero is entered, this function should STILL return
	; 1, despite the value being null, because it's still a 
	; digit occupying a place. 

	mov			eax, [ebp+8]
	cmp			eax, 0
	jz			ZeroCase

	; This loop iterates over the parameter number and counts
	; the number of digits or "places" that the number has. 

Count:

	; This code uses the divisor counter to test for a digit in a decimal column. 
	; If the number is divisible by the starting divisor (ex: 1, 10, 100), it must have 
	; a digit in the corresponding column. Each round, after the division test is performed,
	; the divisor is advanced (ex: 1, 10, 100) and the accumulator is incremented, indicating 
	; that a digit has been found.

	mov			edx, 0
	mov			eax, [ebp+8]
	div			ebx

	; If the number is NOT divisible by the divisor counter, then the 
	; accumulator already has the total number of digits in the number.
	; This means the procedure can exit the counting loop. 

	cmp			eax, 0		
	jz			EndCount

	; If the number IS divisible by the divisor counter, then the code updates
	; the divisor counter (multiplies it by 10) and increases the accumulator, 
	; indicating that an additional digit was found. Then, it loops again.

	mov			eax, ebx
	mov			ebx, 10
	mul			ebx
	mov			ebx, eax
	inc			ecx  
	jmp			Count

	; The number 0 always returns a count of "1."

ZeroCase:

	mov			ecx, 1

EndCount:

	; When every digit has been counted, the total number 
	; of digits is stored in the return variable.

	mov			edx, [ebp+12]
	mov			[edx], ecx

	; The code cleans up after itself and restores the registers as appropriate. 

	popad
	pop			ebp
	ret			8
		
CountDigits		ENDP


; ***************************************************************
; Given a number n, this procedure returns (10^n) 
; receives: (by reference) a number and a storage variable
; preconditions: none
; registers changed: ebp, eax, ebx, ecx, edx
; ***************************************************************

Power10			PROC

	; This code preserves the registers and sets up the stack.

	push		ebp
	mov			ebp, esp
	pushad

	; This loads the necessary values into registers and gets the number
	; parameter from the stack.

	mov			eax, 1
	mov			ebx, 10
	mov			ecx, [ebp+8]

	; This code checks for our edge case - zero. 
	; 10^0 should always return 1. 

	cmp			ecx, 0
	jz			EndPower10

	; Otherwise, the code loops n times, starting with 10^0 in the 
	; accumulator. Each iteration, it multiplies the accumulator by 10.

PowerLoop:

	mul			ebx

	loop		PowerLoop

EndPower10:

; This code returns the answer (10^n) and saves it to the
; provided storage variable.

	mov			edx, [ebp+12]
	mov			[edx], eax

; The code cleans up after itself and restores the registers as appropriate. 

	popad
	pop			ebp
	ret			8

Power10			ENDP


; ***************************************************************
; Procedure to populate a buffer array with 82 zeroes.
; receives: (by reference) a buffer array
; preconditions: buffer must be 82 bytes
; registers changed: ebp, eax (al), ebx, ecx, esi
; returns: A buffer array populated with 82 zeroes.
; ***************************************************************

CleanBuffer PROC

	push		ebp
	mov			ebp, esp
	pushad

	; This section of code populates the buffer with 0's. 

	mov			esi, 0
	mov			ecx, 82
	mov			esi, [ebp+8]

ZeroFill:

	mov			al, 0
	mov			[esi], al

	; Each time esi is incremented, it advances to the next
	; byte of the array. 

	inc			esi
	loop		ZeroFill

	popad
	pop			ebp
	ret			4

CleanBuffer		ENDP

END	main 