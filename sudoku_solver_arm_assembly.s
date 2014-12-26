@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@	9x9 sudoku solver
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.equ SWI_PrChr,0x00  			; write an ASCII char to Stdout
.equ SWI_PrStr,0x69  			; write a null-ending string
.equ SWI_RdInt,0x6c  ; read integer
.equ SWI_PrInt,0x6b  ; write integer
.equ SWI_RdStr,0x6a	 ; read string from the file
.equ SWI_Open,0x66   ; open file
.equ SWI_Close,0x68  ; close file
.equ SWI_Exit,0x11   ; exit program
.equ Stdout,1 		 ; Set output target to be stdout
.global _start
_start:
.text

@ =========== opening the file
ldr r0, =FileName 				; set name for file
mov r1, #0 		  				; mode is output
swi SWI_Open	  				; open file for output	
bcs showOpeningFileErrorMessage ; if error show error message
ldr r1,=FileHandle 				; load file handle
str r0,[r1]						; save file handle
ldr r1, =STK_SZ
@ =========== Load board into memory
readTheValueOfTheCurrentIndexfromTheMemory:
	ldr r1,=CharArray			;
	mov r2,#1000
	swi SWI_RdStr
	@bcs endOfFileReached		; show end of file message is end of the file
	mov r9,r1					; keep the last memory location
	ldr r8, =STK_TOP	 		; Initialise stack pointer and put the location in r8
	ldr r7,=0					; r7 will keep track of current row
	ldr r6,=0					; r6 will keep track of current column
	ldr r5,=0					; r5 will keep track of stacks current location
	ldr r4,=0x31				; r4 will oscillate between 1 - 9 (#0x31 - #0x39) to keep track of assigned values to the cell for comparison
	ldr r3,=0					; r3 will keep track of current location of the board
	mov r0,r9					; at the begining put the address of r9 into r0 to be used in isCellUnassigned

@ =========== Loop until the table is solved	
loopUntilEndOfLine:				; inner loop for reading the entire line

isCellUnassigned:
	ldrb r0, [r0]				; load register byte value of the address stored in r0 into r0(keep r0 unchanged until the end of all checks)
	cmp r0,#0x30				; check if the value in the memory is unassigned (character 0)
	beq chooseInteger			; branch to solveFunction if the value is 0 (48 -> #0x30)
	bne moveToNextCell			; goto next cell if not 0
chooseInteger:
	sub r0,r8,r5				; adjust the stack pointer. means subtract the current value of the stack from the initial value and put its location into r0
	str r4,[r0]					; push the value of r4 into memory location pointed by r0
	cmp r4,#0x3A				; See If we have checked all 9 values
	add r4,r4,#1				; add one to the value of r4
	beq goOneLevelBack			; If equal everything must go back one step. 
	bal checkRow
returnFromCheckRow:
	cmp r1,#1
	beq checkColumn				; if r1 is 1 means checkRow has returned true therefore checkColumn
	bne chooseInteger			; choose next Integer
returnFromCheckColumn:
	cmp r1,#1					
	beq checkBox				; if r1 is 1 means checkColumn has returned true therefore checkBox
	bne chooseInteger			; do some choose next Integer
returnFromCheckBox:
	cmp r1,#1					
	beq assignTheProposedValue	; if r1 is 1 means checkBox has returned true therefore assign The Proposed Value by moving the stack pointer one up
	bne chooseInteger			; do some choose next Integer

numberFoundSoIncreaseR4:

assignTheProposedValue:
	sub r0, r8,r5				; get the address of current location of the stack
	ldr r0,[r0]					; load the value that is proposed from the stack into r0
	add r1,r9,r3				; get the address of current location of the board
	strb r0,[r1]				; change the value of the board to the proposed value. store the value in r0 into the address that r1 is pointing to
	sub r0, r8,r5				; get the address of current location of the stack
	str r1,[r0]					; store the value of the r1 which is the address of the current zero into the stack 
	add r5,r5,#4				; move the stack pointer to the next location
	ldr r4, =0x31				; make r4 one again
	bal moveToNextCell

goOneLevelBack:
	bal findPreviousZero		; find the previous zero

findPreviousZero:
	sub r5,r5,#4				; go one step back in the stack
	sub r0,r8,r5				; get the address of current location of the stack
	ldr r0,[r0]					; load the address of previous zero into r0
	sub r1,r8,#4				; find the location of -1 stack
	cmp r0, r1					; if equal means we have passed the board
	beq boardCanNotBeSolved		; Board can not be solved
    bal adjustColumnAndRow		; adjust the row keeper
backFromAdjustColumnAndRow:
	add r0,r9,r3				; goto the location of the previous zero
	ldrb r0,[r0]				; get the value of previous zero
	add r0,r0,#1				; add one to it
	mov r4,r0					; put the value of r0 into r4
	sub r1,r8,r5				; get the address of current location of the stack
	str r4,[r1]					; push that value of r4 into the stack
	add r1,r9,r3				; goto location of the zero
	ldr r2,=0x30				; put zero in r2
	strb r2,[r1]				; make that location of the board zero
	cmp r0,#0x3A				; check if it is more than 9
	beq findPreviousZero		; do find one 
	bal chooseInteger			; choose another integer

adjustColumnAndRow:
	mov r2,r3					; put current value of r3 board keeper in r2
	sub r3,r0,r9				; adjust the board location keeper
	ldr r1,=1
	sub r1,r3,r1
adjustColumnAndRowLoop:
	sub r2,r2,#1
	cmp r2,r1
	beq backFromAdjustColumnAndRow
	sub r6,r6,#1
	cmp r6,#-1
	bne endif4
	sub r7,r7,#1
	cmp r7,#-1
	beq boardCanNotBeSolved
	ldr r6, =8
endif4:
bal adjustColumnAndRowLoop
moveToNextCell:
	add r3, r3, #1				; add one to the board location keeper
	add r0, r9, r3				; move to next byte
	add r6,r6,#1				; keep track of current column
	cmp r6,#9					; compare r6 with #9. if it is equal to 9 means we are on the next row
	bne endif1					; if equal make r6 =0 and add 1 to r7 to be on the next row
	add r7,r7,#1
	cmp r7,#9
	beq printBoard				; Board is solved
	ldr r6,=0
endif1:
	bal loopUntilEndOfLine 		; keep reading till end of the line
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkRow:
	ldr r2, =9					; this is tmp and r2 can be changed on the next request
	mul r2,r7,r2				; mul 9 by the row number to find the memory location of the first column of the row
	add r2,r9,r2				; goto the value of the first column in the current row
	stmia sp!, {r2}				; keep r2 value in the stack for incremant in case of not having the same value in comparison
	ldr r1, =0					; keep track of how many cloumns we have checked
	stmia sp!,{r1}				; push the value of looping into the stack
whileCheckRow:
	ldrb r1, [r2]				; load register byte of r2 into r1 (now we have the value of the first column of the current row in r1)
	ldr r2,[r0]					; load the value of the stack into r2. The address of stack is in r0
	cmp r1,r2					; compate r1 (column of the current row) with r2 (value of the stack)
	ldmdb sp!, {r1}				; pop out the value of the loop /this have been placed here since sp needs to be pop in case we move to somewhere else
	ldmdb sp!, {r2}				; pop out the value of the current cell of the bord from the stack /this have been placed here since sp needs to be pop in case we move to somewhere else
	beq chooseInteger			; if equal go back to chooseInteger
								; location of the ldmdb sp!, {r1}	
	add r1,r1,#1				; add one to the value of the loop
	cmp r1, #9					; compare the value of loop with 9
	beq breakCheckRowWhile		; if the value is 9
								; location of the ldmb sp! {r2}
	add r2,r2,#1				; add #1 to the value of the current cell of the board
	stmia sp!, {r2}				; keep r2 which is the location of the current column value in the stack for incremant in case of not having the same value in comparison
	stmia sp!,{r1}				; push the value of looping into the stack
bal whileCheckRow
breakCheckRowWhile:
	ldr r1,=1					; make r1=1 to show the checkRow was successfull
bal returnFromCheckRow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkColumn:
	add r2, r9, r6				; add the value of current column to the first location of the board to find first row of the current column location
	stmia sp!, {r2}				; keep r2 value in the stack for incremant in case of not having the same value in comparison
	ldr r1, =0					; keep track of how many rows we have checked
	stmia sp!,{r1}				; push the value of looping into the stack
whileCheckColumn:
	ldrb r1, [r2]				; load register byte of r2 into r1. it will be the value of the first row of the current column
	ldr r2,[r0]					; load the value of the stack into r2. The address of stack is in r0
	cmp r1,r2					; compate r1 (column of the current row) with r2 (value of the stack)
	ldmdb sp!, {r1}				; pop out the value of the loop /this have been placed here since sp needs to be pop in case we move to somewhere else
	ldmdb sp!, {r2}				; pop out the value of the current cell of the bord from the stack /this have been placed here since sp needs to be pop in case we move to somewhere else
	beq chooseInteger			; if equal go back to chooseInteger
								; location of the ldmdb sp!, {r1}	
	add r1,r1,#1				; add one to the value of the loop
	cmp r1, #9					; compare the value of loop with 9
	beq breakCheckColumnWhile	; if the value is 9
								; location of the ldmb sp! {r2}
	add r2,r2,#9				; add #9 to the value of the current cell of the board. This will bring us to the next row with in the same column
	stmia sp!, {r2}				; keep r2 which is the location of the current column value in the stack for incremant in case of not having the same value in comparison
	stmia sp!,{r1}				; push the value of looping into the stack
bal whileCheckColumn
breakCheckColumnWhile:
	ldr r1,=1					; make r1=1 to show the checkColumn was successfull
bal returnFromCheckColumn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
checkBox:
	ldr r1, =2
	cmp r6, r1
	bls ifCompareRow			; if column tracker is equal or smaller it could be box 0,3,6
	ldr r1, =5
	cmp r6, #5
	bls ifCompareRow			; if column tracker is equal or smaller it could be box 1,4,7
	ldr r1, =8
	cmp r6, #8
	bls ifCompareRow			; if column tracker is equal or smaller it could be box 2,5,8
ifCompareRow:
	ldr r2, =2
	cmp r7, r2
	bhi ifCheckRow5				; if greater than 2 branch to ifCheckRow5
	cmp r1, #2
	beq checkBox0				; if row tracker is equal or smaller and have 2 in r1 it will be box 0
	cmp r1, #5
	beq checkBox1				; if row tracker is equal or smaller and have 5 in r1 it will be box 1
	cmp r1, #8
	beq checkBox2				; if row tracker is equal or smaller and have 8 in r1 it will be box 2
ifCheckRow5:
	ldr r2, =5
	cmp r7, r2
	bhi ifCheckRow8				; if greater than 2 branch to ifCheckRow8
	cmp r1, #2
	beq checkBox3				; if row tracker is equal or smaller and have 2 in r1 it will be box 3
	cmp r1, #5
	beq checkBox4				; if row tracker is equal or smaller and have 5 in r1 it will be box 4
	cmp r1, #8
	beq checkBox5				; if row tracker is equal or smaller and have 8 in r1 it will be box 5
ifCheckRow8:
	ldr r2, =8
	cmp r7, r2
								; no need for branching since this is the last option
	cmp r1, #2
	beq checkBox6				; if row tracker is equal or smaller and have 2 in r1 it will be box 6
	cmp r1, #5
	beq checkBox7				; if row tracker is equal or smaller and have 5 in r1 it will be box 7
	cmp r1, #8
	beq checkBox8				; if row tracker is equal or smaller and have 8 in r1 it will be box 8

checkBox0:						;check cell 0,1,2, 9,10,11,18,19,20
	ldr r1,=0
	bal checkRequestedBox
checkBox1:						;check cell 3,4,5,12,13,14,21,22,23
	ldr r1,=3
	bal checkRequestedBox
checkBox2:						;check cell 6,7,8,15,16,17,24,25,26
	ldr r1,=6
	bal checkRequestedBox
checkBox3:						;check cell 27,28,29,36,37,38,45,46,47
	ldr r1,=27
	bal checkRequestedBox
checkBox4:						;check cell 30,31,32,39,40,41,48,49,50
	ldr r1,=30
	bal checkRequestedBox
checkBox5:						;check cell 33,34,35,42,43,44,51,52,53
	ldr r1,=33
	bal checkRequestedBox
checkBox6:						;check cell 54,55,56,63,64,65,72,73,74
	ldr r1,=54
	bal checkRequestedBox
checkBox7:						;check cell 57,58,59,66,67,68,75,76,77
	ldr r1,=57
	bal checkRequestedBox
checkBox8:						;check cell 60,61,62,69,70,71,78,79,80
	ldr r1,=60
	bal checkRequestedBox

checkRequestedBox:
								; r1 is the location of the first cell in the box
	stmia sp!,{r1}				; push r1 into the stack
	ldr r2, =0					; keep track of how many cells in the box have been checked
	stmia sp!,{r2} 				; push the box cell tracker into the stack
loopInTheBox:
	add r1,r9,r1				; goto cell of the box
	ldrb r1,[r1]				; put the value of the cell in r1
	ldr r2,[r0]					; put the value of the stack which is the proposed value into r2
	cmp r1,r2					; compare value of the cell with the proposed value
	beq chooseInteger			; if equal go back to chooseInteger
	ldmdb sp!,{r2}				; pop out box cell tracker from the sp and put it into r1
	ldmdb sp!,{r1}				; pop the location keeper of the cell in the box
	add r2,r2,#1				; add one to r2 
	cmp r2, #3					; if the value of r1 is less than 3 
	bhs ifEndOfRow1OfTheBox
	add r1,r1,#1				; move to next column of the first row of the box
	stmia sp!,{r1}				; push value of the location of the box into stack
	stmia sp!,{r2} 				; push the box cell tracker into the stack
	bal loopInTheBox
ifEndOfRow1OfTheBox:
	cmp r2, #6					; compare cell tracker with #6
	bhs ifEndOfRow2OfTheBox		; if it is greater than or equal to #6 goto next section
	cmp r2, #3					; compare cell tracker with #3
	bne endif2					; if equal 
	sub r1,r1,#2				; subtract 2 from the r1 to find out the first cell of the box value
	add r1,r1,#8				; add 8 to find the value of the one cell before second row of the box
endif2:	
	add r1,r1, #1				; add one to get to the second row of the box
	stmia sp!,{r1}				; push value of the location of the box into stack
	stmia sp!,{r2} 				; push the box cell tracker into the stack
	bal loopInTheBox
ifEndOfRow2OfTheBox:
	cmp r2, #9
	bhs breakCheckBoxWhile		; if it is greater than or equal to #9 
	cmp r2, #6					; compare cell tracker with #6
	bne endif3					; if equal 
	sub r1,r1,#11				; subtract 11 from the r1 to find out the first cell of the box value
	add r1,r1,#17				; add 17 to find the value of the one cell before third row of the box
endif3:
	add r1,r1, #1				; add one to get to the second row of the box
	stmia sp!,{r1}				; push value of the location of the box into stack
	stmia sp!,{r2} 				; push the box cell tracker into the stack
	bal loopInTheBox

breakCheckBoxWhile:
	ldr r1,=1					; make r1=1 to show the checkColumn was successfull
bal returnFromCheckBox

giveTheStatus:

break:
	mov r0, #Stdout
	ldr r1, =Count
	swi SWI_PrStr
	sub r1,r8,#1
	swi SWI_PrInt
	mov r0,#'\n
	swi SWI_PrChr				
@bal loopUntilEndOfTheFile		; keep reading till end of the file
bcs endOfFileReached		; show end of file message is end of the file
@ =========== print board
printBoard:
	mov r0, #Stdout
	ldr r1, =BoardSolved
	swi SWI_PrStr
	mov r2,r9
	ldr r3,=0
loop1:
	ldrb r1, [r2]				
	sub r1,r1,#0x30
	swi SWI_PrInt
	add r2,r2,#1
	add r3,r3,#1
	cmp r3,#81
	beq endOfFileReached2
	bal loop1
boardCanNotBeSolved:
	mov R0, #Stdout
	ldr r1, =BoardCanNotBeSolved
	bal endOfFileReached2
@ =========== end of file reached
endOfFileReached:				; printing out the result
	bal printBoard;
endOfFileReached2:	

@ =========== closing the file 
closingTheFile:
	ldr r0, =FileHandle
	ldr r0,[r0]
	swi SWI_Close
@ =========== exit the program
Exit:
	swi SWI_Exit @ Stop executing
@ =========== show opening file error message
showOpeningFileErrorMessage:
	mov R0, #Stdout
	ldr R1, =OpeningFileError
	swi SWI_PrStr
	ldr R1,=FileName
	swi SWI_PrStr
	mov R0, #'\n
	swi SWI_PrChr
	bal Exit
@ =========== directives
.data
.align
FileName: .asciz "board.txt"
.align
OpeningFileError: .asciz "Unable to open the file "
.align
EndOfFileMessage: .asciz "End of file "
.align
Count: .asciz "Characters: "
.align
BoardSolved: .asciz "Board Successfully solved!\n"
.align
BoardCanNotBeSolved: .asciz "Board can not be solved!\n"
.align
FileHandle: .word 0
.align
CharArray: .skip 82
.align
STK_SZ: .space 0x100 		;  stack
STK_TOP: .word 1
.end
