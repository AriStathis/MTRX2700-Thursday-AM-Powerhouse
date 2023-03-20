.syntax unified
.thumb


.global assembly_function
@define function

@ Clock setting register (base address and offsets)
.equ RCC, 0x40021000	@ base register for resetting and clock settings

@ registers for enabling clocks
.equ AHBENR, 0x14  @ enable peripherals
.equ APB1ENR, 0x1C
.equ APB2ENR, 0x18

@ bit positions for enabling GPIO in AHBENR
.equ GPIOA_ENABLE, 17
.equ GPIOC_ENABLE, 19
.equ GPIOE_ENABLE, 21

@ GPIO register base addresses
.equ GPIOA, 0x48000000	@ base register for GPIOA (pa0 is the button)
.equ GPIOC, 0x48000800	@ base register for GPIOC is used for UART4
.equ GPIOE, 0x48001000	@ base register for GPIOE (pe8-15 are the LEDs)

@ GPIO register offsets
.equ MODER, 0x00	@ register for setting the port mode (in/out/etc)
.equ ODR, 0x14	@ GPIO output register
.equ IDR, 0x10	@ GPIO input register
.equ NUMBEROFLEDS, 0b11100000
.equ CLOCKWISE, 0
.equ ANTICLOCKWISE, 1

.equ ERROR, 0b11111111



.data
@define variables
map_array: .asciz "abcdefghijklmnopqrstuvwxyz"

test_string: .asciz "Hello World!"

led_numbers: .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25


.text
@define code
assembly_function:

	LDR R3, =led_numbers			@load address for led numbers that are outputted through GPIO to LEDs

	LDR R4, =test_string			@load address for the string
	MOV R2, #0x0					@start of iteration of test string

	LDR R1, =map_array				@load address for map into R1
	MOV R9, #0x0					@start of iteration of map_array

	LDR R12, =ERROR

	@ Branch with link to set the clocks for the I/O and UART
	BL enable_peripheral_clocks

	@ Once the clocks are started, need to initialise the discovery board I/O
	BL initialise_discovery_board


get_letter:

	MOV R9, #0x0					@reset and initialise offset of map array

	LDRB R5, [R4, R2]				@load the letter of the test string


check_uppercase_and_lower_case:

	LDRB R6, [R1, R9]				@load letter in map array

	CMP R5, R6						@checking the test string against the letter array (lower case)

	BEQ load_map_lower_case			@it is a valid ASCII letter

	SUB R6, R6, 0x20				@making it uppercase

	CMP R5, R6						@checking the test string against the letter array (upper case)

	BEQ load_map_upper_case			@it is a valid ASCII letter

	ADD R9, R9, 0x1					@next letter in our map array

	CMP R9, 0x19						@if it reaches the end of our test array then it is not a valid ascii character

	BEQ not_valid_ascii

	B check_uppercase_and_lower_case			@keep iterating through map until we find the letter that matches the map

not_valid_ascii: @This is wher the error is

	LDR R8, =0b11111111

	ADD R2, R2, 0x1					@iterate into the next letter in the test string

	B wait_for_button				@start process again

load_map_lower_case:

	LDRB R8, [R3, R9]				@into R8 the mapped value i.e. turining it into a number

	ADD R2, R2, 0x1					@iterate into the next letter in the test string

	B wait_for_button					@start process again

load_map_upper_case:

	LDRB R8, [R3, R9]

	ADD R8, R8, 0x19				@add by 25 in hex for a uppercase value, a = 0, A = 25 etc.

	ADD R2, R2, 0x1					@iterate to next letter in the test string

	B wait_for_button					@start process again


wait_for_button:

	LDR R10, =GPIOA

	LDRB R11, [R10, #IDR]

	TST R11, #0x01

	BNE light_up_letter

	B wait_for_button

light_up_letter:

	LDR R10, =GPIOE  				@ load the address of the GPIOE register into R0

	STRB R8, [R10, #ODR + 1]   		@ store this to the second byte of the ODR (bits 8-15)

	BL delay_function

	B get_letter

@ enable the clocks for peripherals (GPIOA, C and E)
enable_peripheral_clocks:
	LDR R10, =RCC 						 	@ load the address of the RCC address boundary (for enabling the IO clock)
	LDR R11, [R10, #AHBENR]  				@ load the current value of the peripheral clock registers
	ORR R11, 1 << GPIOA_ENABLE | 1 << GPIOC_ENABLE | 1 << GPIOE_ENABLE  	@ 21st bit is enable GPIOE clock, 17 is GPIOA clock
	STR R11, [R10, #AHBENR]  			@ store the modified register back to the submodule
	BX LR 								@ return from function call

@ initialise the discovery board I/O (just outputs: inputs are selected by default)
initialise_discovery_board:
	LDR R10, =GPIOE 					@ load the address of the GPIOE register into R0
	LDR R11, =0x5555  					@ load the binary value of 01 (OUTPUT) for each port in the upper two bytes

	STRH R11, [R10, #MODER + 2]   		@ store the new register values in the top half word representing
										@ the MODER settings for pe8-15
	BX LR 								@ return from function call


delay_function:
	LDR R6, =0x900FF
	@ we continue to subtract one from R6 while the result is not zero,
	@ then return to where the delay_function was called
not_finished_yet:
	SUBS R6, 0x01
	BNE not_finished_yet

	BX LR @ return from function call










