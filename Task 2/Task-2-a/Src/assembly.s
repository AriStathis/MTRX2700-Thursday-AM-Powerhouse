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

.data
@ define variables

.text
@ define text


assembly_function:


	MOV R1, ANTICLOCKWISE		@ Change for clockwise or anticlockwise



	BL enable_peripheral_clocks	@ Branch with link to set the clocks for the I/O and UART

	BL initialise_discovery_board 	@ Once the clocks are started, need to initialise the discovery board I/O

	LDR R2, =NUMBEROFLEDS 				@ Load number of leds

	CMP R1, 0							@ Compare with dummy to determine anticlockwise or clockwise

	BEQ clockwise
	BNE anticlockwise


clockwise: @NORTH --> EAST

	LDR R0, =GPIOE  					@ Load the address of the GPIOE register into R0

	STRB R2, [R0, #ODR + 1]   			@ Store this to the second byte of the ODR (bits 8-15)


	BL MSB_clockwise_check_for_overflow 	@ Check the MSB

	BL delay_function						@Delay

	B clockwise @ return to the program_loop label


MSB_clockwise_check_for_overflow:

	AND R5, R2, #0b10000000					@ Zero out every bit but MSB

	CMP R5, #0b10000000						@ Check if MSB is lit up on LED pattern

	BEQ shift_clockwise_overflow			@ If it is shift it with regards to overflow

	BNE continue_clockwise_shift			@If it isnt shift it normally

	BX LR

shift_clockwise_overflow:

	LSL R2, R2, 0b1							@ Shift bit left by 1 for clockwise

	ADD R2, R2, 0b00000001					@ Insert a bit since there is overflow

	BX LR

continue_clockwise_shift:

	LSL R2, R2, 0b1							@ Shift bit

	BX LR


anticlockwise: @EAST --> NORTH

	LDR R0, =GPIOE  						@ load the address of the GPIOE register into R0

	STRB R2, [R0, #ODR + 1]  				@ store this to the second byte of the ODR (bits 8-15)

	BL LSB_anticlockwise_check_for_overflow	@ Check LSB for overflow

	BL delay_function						@ Delay

	B anticlockwise


LSB_anticlockwise_check_for_overflow:

	AND R5, R2, #0b00000001					@ Make every other bit 0 bit LSB

	CMP R5, #0b00000001						@ Check for overflow

	BEQ shift_anticlockwise_overflow

	BNE continue_anticlockwise_shift

	BX LR

shift_anticlockwise_overflow:

	LSR R2, R2, 0b1							@ Shift right

	ADD R2, R2, 0b10000000					@ Add in another bit at the start

	BX LR

continue_anticlockwise_shift:

	LSR R2, R2, 0b1							@Shift right

	BX LR

@ think about how you could make a delay such that the LEDs blink at a certain frequency
delay_function:
	LDR R6, =0x0FF001

	@ we continue to subtract one from R6 while the result is not zero,
	@ then return to where the delay_function was called
not_finished_yet:
	SUBS R6, 0x01
	BNE not_finished_yet

	BX LR @ return from function call




@ enable the clocks for peripherals (GPIOA, C and E)
enable_peripheral_clocks:
	LDR R0, =RCC  @ load the address of the RCC address boundary (for enabling the IO clock)
	LDR R7, [R0, #AHBENR]  @ load the current value of the peripheral clock registers
	ORR R7, 1 << GPIOA_ENABLE | 1 << GPIOC_ENABLE | 1 << GPIOE_ENABLE  @ 21st bit is enable GPIOE clock, 17 is GPIOA clock
	STR R7, [R0, #AHBENR]  @ store the modified register back to the submodule
	BX LR @ return from function call





@ initialise the discovery board I/O (just outputs: inputs are selected by default)
initialise_discovery_board:
	LDR R0, =GPIOE 	@ load the address of the GPIOE register into R0
	LDR R7, =0x5555  @ load the binary value of 01 (OUTPUT) for each port in the upper two bytes
					 @ as 0x5555 = 01010101 01010101
	STRH R7, [R0, #MODER + 2]   @ store the new register values in the top half word representing
								@ the MODER settings for pe8-15
	BX LR @ return from function call


