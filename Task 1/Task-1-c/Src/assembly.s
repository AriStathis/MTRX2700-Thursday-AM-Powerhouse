.syntax unified
.thumb


.global assembly_function
@define function



.data
@define variables
first_string: .asciz "....Haaaello. aa1 MaaaAA1` Aay.ari. ```Aa1aa. 1234a\0"



.text
@define code

assembly_function:

	MOV R2, #0x0												@start of iteration of string i.e. used as an offset

	MOV R4, #0x61												@this determines if lowercase or upper case

	LDR R1, =first_string										@load address for string into R1

get_first_letter:

	LDRB R3, [R1, R2]											@load byte (letter in ascii)

	CMP R3, 0x61												@first lowercase ascii value

	BGE check_valid_ascii_first_letter_lower_case 				@potentially lowercase

	CMP R3, 0x5b												@last uppercase ascii value

	BLT check_valid_ascii_first_letter_upper_case				@potentially uppercase

	ADD R2, R2, 0x1												@iterate offest

	B get_first_letter											@get first letter

check_valid_ascii_first_letter_upper_case:

	CMP R3, 0x41												@potentially uppercase

	ADD R2, R2, 0x1												@iterate to next if it isnt uppercase

	BGE grab_letter												@first valid ascii letter is uppercase --> start program

	BLT get_first_letter 										@letter is not ASCII --> start first letter check again


check_valid_ascii_first_letter_lower_case:

	CMP R3, 0x7B												@checking if valid ASCII

	BLT to_upper												@valid ASCII

	ADD R2, R2, 0x1												@iterate offset for next letter

	B get_first_letter											@invalid ASCII

to_upper:

	SUB R3, R3, 0x20											@making the first letter uppercase

	STRB R3, [R1, R2]											@storing it back into the string after manipulation

	ADD R2, R2, #0x1											@increment address offset of string

	B grab_letter												@start program

grab_letter:

	LDRB R3, [R1, R2]											@load byte (letter in ascii)

	B check_full_stop											@check for full stop

check_full_stop:

	CMP R3, 0x2E												@check for full stop

	BEQ iterate_after_full_stop									@if there is a full stop find next value

	BNE check_valid_upper_case_ascii							@all other characters should be lowercase

iterate_after_full_stop:

	ADD R2, R2, 0x1												@next letter

	LDRB R3, [R1, R2]											@load byte (letter in ascii)

	B check_valid_upper_case_ascii_after_full_stop				@check if uppercase

check_valid_upper_case_ascii_after_full_stop:

	CMP R3, 0x41												@potentially uppercase

	BGE confirm_valid_upper_case_ascii_after_full_stop			@confirm if uppercase

	BLT check_valid_lower_case_ascii_after_full_stop			@if not check if lower

confirm_valid_upper_case_ascii_after_full_stop:

	CMP R3, 0x5B												@less than highest uppercase ascii value

	BLT iterate													@iterate to next letter

	BGE check_valid_lower_case_ascii_after_full_stop			@make it lower

check_valid_lower_case_ascii_after_full_stop:

	CMP R3, 0x61												@checking for bounds

	BGE confirm_valid_lower_case_ascii_after_full_stop			@if greater than it may be a lowercase ascii character

	BLT lower_case_iteration_after_full_stop									@iterate to next value and start again

confirm_valid_lower_case_ascii_after_full_stop:

	CMP R3, 0x7B												@confirming if it is strictly a lowercase character
																@ascii letter between 0x60 and 0x7a
	BLT to_upper												@make uppercase

	BGE lower_case_iteration_after_full_stop									@iterate again check lowercase after fullstop

check_ascii_bounds:

	CMP R3, 0x7B												@confirming if it is strictly a lowercase character
																@ascii letter between 0x60 and 0x7a
	BLT to_upper

	BGE lower_case_iteration_after_full_stop					@lower case iteration after full stop

lower_case_iteration_after_full_stop:

	ADD R2, R2, 0x1												@next letter

	LDRB R3, [R1, R2]											@load byte (letter in ascii)

	B check_valid_upper_case_ascii_after_full_stop				@check if uppercase after full stop


check_valid_upper_case_ascii:

	CMP R3, 0x5B												@checking if uppercase

	BLT check_upper												@check if uppercase

	ADD R2, R2, 0x1												@iterate to next offset in string

	B grab_letter												@start functions again

check_upper:

	CMP R3, 0x41												@confirming it is uppercase not a symbol

	BGE make_lower												@make it lowercase

	ADD R2, R2, 0x1												@iterate to next offset in string

	BLT grab_letter												@start program again

make_lower:

	ADD R3, R3, 0x20											@making the letter lowercase

	STRB R3, [R1, R2]											@storing it back into the string after manipulation

	B grab_letter												@start program again


iterate:

	ADD R2, R2, 0x1												@iterate to next offset in string

	B grab_letter												@start program again




























