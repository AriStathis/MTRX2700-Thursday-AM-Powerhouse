.syntax unified
.thumb

.global assembly_function


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
.equ GPIOA, 0x48000000				@ base register for GPIOA (pa0 is the button)
.equ GPIOC, 0x48000800				@ base register for GPIOC is used for UART4
.equ GPIOE, 0x48001000				@ base register for GPIOE (pe8-15 are the LEDs)

@ GPIO register offsets
.equ MODER, 0x00					@ register for setting the port mode (in/out/etc)
.equ ODR, 0x14						@ GPIO output register
.equ IDR, 0x10						@ GPIO input register


.data
@ define variables

map_array: .asciz "abcdefghijklmnopqrstuvwxyz"

string: .asciz "Hello World"

led_numbers: .byte 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
.text
@ define text

@ this is the entry function called from the c file
assembly_function:

	LDR R1, =string						@ Load address of string into R1
	MOV R3, #0x0						@ Iterate through string

	@ Branch with link to set the clocks for the I/O and UART
	BL enable_peripheral_clocks

	@ Once the clocks are started, need to initialise the discovery board I/O
	BL initialise_discovery_board


get_letter:

	LDR R2, [R1, R3]

	LDR R0, =GPIOE 		 			@ load the address of the GPIOE register into R0

	B light_up_letter


light_up_letter:

	STRB R2, [R0, #ODR + 1]   		@ store this to the second byte of the ODR (bits 8-15)

	ADD R3, R3, 0x01				@ Iterate through the string

	BL delay_function

	B get_letter

delay_function:
	LDR R6, =0x0FF001

	@ we continue to subtract one from R6 while the result is not zero,
	@ then return to where the delay_function was called
not_finished_yet:
	SUBS R6, 0x01
	BNE not_finished_yet

	BX LR 							@ return from function call


@ enable the clocks for peripherals (GPIOA, C and E)
enable_peripheral_clocks:
	LDR R0, =RCC  					@ load the address of the RCC address boundary (for enabling the IO clock)
	LDR R7, [R0, #AHBENR] 			@ load the current value of the peripheral clock registers
	ORR R7, 1 << GPIOA_ENABLE | 1 << GPIOC_ENABLE | 1 << GPIOE_ENABLE  @ 21st bit is enable GPIOE clock, 17 is GPIOA clock
	STR R7, [R0, #AHBENR]  			@ store the modified register back to the submodule
	BX LR 							@ return from function call


@ initialise the discovery board I/O (just outputs: inputs are selected by default)
initialise_discovery_board:
	LDR R0, =GPIOE 					@ load the address of the GPIOE register into R0
	LDR R7, =0x5555  				@ load the binary value of 01 (OUTPUT) for each port in the upper two bytes
									@ as 0x5555 = 01010101 01010101
	STRH R7, [R0, #MODER + 2]   	@ store the new register values in the top half word representing
									@ the MODER settings for pe8-15
	BX LR							@ return from function call






