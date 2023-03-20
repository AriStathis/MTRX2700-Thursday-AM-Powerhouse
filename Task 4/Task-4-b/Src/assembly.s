.syntax unified
.thumb

.global assembly_function

// Clock registers
.equ RCC, 0x40021000	// Base clock register. Reset, Clock Control
.equ AHBENR, 0x14       // Enable GPIO clocks
.equ APB1ENR, 0x1C @ enable peripherals on bus 1
.equ APB2ENR, 0x18      // Enable Timers

// Base addresses for GPIO ports
.equ GPIOE, 0x48001000

// Offsets for GPIO ports
.equ MODER, 0x00
.equ ODR, 0x14

// Bits for enabling GPIO ports
.equ GPIOA_ENABLE, 17
.equ GPIOC_ENABLE, 19
.equ GPIOE_ENABLE, 21

@ enable the clocks for timer 2
.equ TIM2EN, 0

.equ GPIOx_AFRH, 0x24 @ offset for setting the alternate pin function

// Timer registers
.equ TIM2, 0x40000000	 // Base address for Timer 2
.equ TIM_CR1, 0x00	     // Enable counter and choose whether to count up or down
.equ TIM_CCMR1, 0x18  @ compare capture settings register
.equ TIM_CNT, 0x24       // Counter
.equ TIM_ARR, 0x2C       // Value for counter to count up to or to count down from
.equ TIM_PSC, 0x28       // Prescaler
.equ TIM_CCER, 0x20      // Enable output compare
.equ TIM_CCR1, 0x34      // Value for TCNT to be compared to in output compare
.equ TIM_SR, 0x10        // Status register
.equ TIM_DIER, 0x0C @ enable interrupts

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



.text

assembly_function:


	BL enableTimer
	BL enableGPIOClocks
	BL enableLEDs
	BL initialise_discovery_board

	LDR R0, =TIM2					@ Load base address for timer 2


	MOV R1, #0b1					@ Enable the counter

	STR R1, [R0, TIM_CR1]

	LDR R6, =GPIOE					@ Output for LEDs


	MOV R1, #0x7D					@ Prescaler of 125 --> 1s
	//MOV R1, #0xFA					@ Prescaler of 250 --> 2s
	//MOV R1, #0x1F4				@ Presclaer of 500 --> 4s

	LDR R2, =TIM_PSC
	STR R1, [R0, R2]

	MOV R1, #0x10000				@ Count up to 2^16

	LDR R2, =TIM_ARR
	STR R1, [R0, R2]


on_time:

	LDR R7, =0b11111111				@ Turn on LEDs

	STRB R7, [R6, #ODR + 1]

	BL check_flag_and_clear


off_time:

	LDR R7, =0b00000000				@ Clear all LEDs

	STRB R7, [R6, #ODR + 1]			@ Store clear in appropriate status register

	BL check_flag_and_clear

	B on_time						@ Recheck output compare address



check_flag_and_clear:

	LDR R1, [R0, TIM_SR]			@ Check status register to check for output compare

	LDR R2, =0b00000010				@ Value to check against

	TST R2, R1						@ Test if status register is toggled

	BGT clear						@ Branch to on time clear

	B check_flag_and_clear

clear:

	LDR R7, =0x0					@ Clear clock

	STR R7, [R0, TIM_CNT]			@ Store in appropriate address

	LDR R7, =0b00000000				@ Clear flag

	STRB R7, [R0, TIM_SR]			@ Store in appropriate flag

	BX LR






// Enable Timer 2 by setting relevant bit in APB1ENR
enableTimer:

	// Enable Timer 2 clock
	LDR R0, =RCC
	LDR R1, [R0, APB1ENR]
	ORR R1, 1 << TIM2EN
	STR R1, [R0, APB1ENR]

	// Set timer 2 channel 1 to output compare
	LDR R0, =TIM2
	LDR R1, [R0, TIM_CCER]
	ORR R1, 1 << 0x0
	STRB R1, [R0, TIM_CCER]

	// Set timer 2 channel 1 to toggle on successful output compare
	LDR R1, =0x30
	STRB R1, [R0, TIM_CCMR1]

	// Set value to be compared against
	LDR R1, =0x10000				@2^16
	STR R1, [R0, TIM_CCR1]

	BX LR

// Enable clocks for GPIO ports through AHBENR register
enableGPIOClocks:
	LDR R0, =RCC
	LDR R1, [R0, #AHBENR]
	ORR R1, 1 << GPIOA_ENABLE | 1 << GPIOC_ENABLE | 1 << GPIOE_ENABLE
	STR R1, [R0, #AHBENR]
	BX LR

// Enable LEDs by setting relevant PORT E pins to output through MODER register
enableLEDs:
	LDR R0, =GPIOE
	LDR R1, =0x5555
	STRH R1, [R0, #MODER + 2]
	BX LR

@ initialise the discovery board I/O (just outputs: inputs are selected by default)
initialise_discovery_board:
	LDR R10, =GPIOE 					@ load the address of the GPIOE register into R0
	LDR R11, =0x5555  					@ load the binary value of 01 (OUTPUT) for each port in the upper two bytes

	STRH R11, [R10, #MODER + 2]   		@ store the new register values in the top half word representing
										@ the MODER settings for pe8-15
	BX LR 								@ return from function call
