.syntax unified
.thumb

.global assembly_function
@define function



.data
@define variables
first_string: .asciz "Hello World\0"	@defining string



.text
@define code



assembly_function:

	MOV R2, #0x0					@start of iteration of string i.e. used as an offset
	MOV R4, #0x61					@this determines if lowercase or upper case


	LDR R1, =first_string			@load address for string into R1

grab_letter:

	LDRB R3, [R1, R2]				@load byte (letter in ascii)

	B check_upper

check_upper:

	CMP R3, R4						@condition if the ascii value is less than the lowest asii lowercase value

	BLT check_consonant				@uppercase

	BGE check_vowel					@lowercase

check_consonant:

	CMP R3, 0x41					@A
	BEQ make_lower					@make vowel lowercase

	CMP R3, 0x45					@E
	BEQ make_lower

	CMP R3, 0x49					@I
	BEQ make_lower

	CMP R3, 0x4F					@O
	BEQ make_lower

	CMP R3, 0x55					@U
	BEQ make_lower

	BNE iterate

make_lower:

	ADD R3, R3, 0x20				@making the letter lowercase
	STRB R3, [R1, R2]				@storing it back into the string after manipulation
	B iterate

iterate:

	ADD R2, R2, 0x1					@R2 = R2 + 1
	B grab_letter					@branch to beginning of logic for next letter

check_vowel:

	CMP R3, 0x61					@a
	BEQ	iterate

	CMP R3, 0x65					@e
	BEQ	iterate

	CMP R3, 0x69					@i
	BEQ	iterate

	CMP R3, 0x6F					@o
	BEQ	iterate

	CMP R3, 0x75					@u
	BEQ	iterate

	BNE make_upper

make_upper:

	SUB R3, R3, 0x20				@making the letter lowercase
	STRB R3, [R1, R2]				@storing it back into the string after manipulation

	B iterate









