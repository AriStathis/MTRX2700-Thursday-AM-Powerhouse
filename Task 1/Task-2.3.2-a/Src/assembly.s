.syntax unified
.thumb

.global assembly_function
@define function

.equ all_upper_value, 0x00
.equ all_lower_value, 0x01

.data
@define variables
first_string: .asciz "Hello World!\0"


.text
@define code

assembly_function:
	MOV R3, #0x0					@start of index string

	LDR R1, =first_string		 	@pointer first letter of string

	MOV R2, all_upper_value			@compare this to dummy

	CMP R2, R3						@comparing to dummy

	BEQ all_upper					@set to all uppercase

	BNE all_lower					@set to all lowercase

all_lower:

	LDRB R4, [R1, R3]				@dereference this character

	CMP R4, 0x5B       				@checking if its an uppercase letter

	BLT lower_operation				@make it lower

	ADD R3, R3, 0x1					@R3 = R3 + 0x1 increment for next

	B all_lower						@back to next letter

lower_operation:

	CMP R4, 0x41					@check valid ascii letter that is uppercase

	BGE make_lower					@make letter lowercase

	ADD R3, R3, 0x1					@R3 = R3 + 0x1 increment for next

	B all_lower						@start process again as its already lower

make_lower:

	ADD R4, R4, 0x20				@making ascii letter lowercase

	STRB R4, [R1, R3]				@storing this ascii letter back in memory

	ADD R3, R3, 0x1					@R3 = R3 + 0x1 increment for next

	B all_lower						@start process again

all_upper:

	LDRB R4, [R1, R3]				@dereference this character

	CMP R4, 0x7B					@checking if its lowercase

	BLT upper_operation				@branch to check if this is uppercase

	ADD R3, R3, 0x1					@R3 = R3 + 0x1 increment for next as its already uppercase

	B all_upper						@start process again as it is already upper

upper_operation:

	CMP R4, 0x61					@making sure its uppercase

	BGE make_upper					@branch to make it uppercase

	ADD R3, R3, 0x1					@R3 = R3 + 0x1 increment for next

	B all_upper						@start process again


make_upper:

	SUB R4, R4, 0x20				@make it uppercase

	STRB R4, [R1, R3]				@store this back in memory

	ADD R3, R3, 0x1					@R3 = R3 + 1 increment for next

	B all_upper						@restart process for next letter







