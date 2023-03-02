.syntax unified
.thumb

.global assembly_function
@define function

.equ all_upper_value, 0x00
.equ all_lower_value, 0x01

.data
@define variables
first_string: .asciz "Hello World\0"


.text
@define code

assembly_function:
	MOV R3, #0x0					@start of index string
	MOV R4, #0x1					@use to iterate through next string
	MOV R6, #0x61					@This determines if lowercase or upper case
	MOV R7, #0x20					@this is ascii for space which needs to be skipped over


	LDR R1, =first_string		 	@pointer first letter of string

	MOV R2, all_lower_value			@compare this to dummy


	CMP R2, R3
	BEQ all_upper
	BNE all_lower


all_lower:

	LDRB R5, [R1, R3]				@dereference this character

	CMP R5, R6						@condition if the ascii value is less than the lowest asii lowercase value
									@if flag is raised then means it is uppercase
									@if R5 < R6

	BLT lower_operation
	B iterate_lower
	B all_lower

all_upper:

	LDRB R5, [R1, R3]				@dereference this character


	CMP R5, R6						@condition if the ascii value is less than the lowest asii lowercase value
									@if flag is raised then means it is uppercase

	BGE upper_operation				@if R5 > R6
	B iterate_upper
	B all_upper

lower_operation:

	CMP R7, R5
	BEQ iterate_lower

	ADD R5, R5, 0x20
	STRB R5, [R1, R3]
	ADD R3, R3, R4					@R3 = R3 + R4 increment for next
	B all_lower

iterate_lower:
	ADD R3, R3, R4					@R3 = R3 + R4 increment for next
	B all_lower

upper_operation:

	SUB R5, R5, 0x20
	STRB R5, [R1, R3]
	ADD R3, R3, R4					@R3 = R3 + R4 increment for next
	B all_upper

iterate_upper:
	ADD R3, R3, R4					@R3 = R3 + R4 increment for next
	B all_upper







