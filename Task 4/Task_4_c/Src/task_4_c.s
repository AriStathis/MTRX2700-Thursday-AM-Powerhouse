.syntax unified
.thumb

.global assembly_function

// Clock registers
.equ RCC, 0x40021000	// Base clock register. Reset, Clock Control
.equ AHBENR, 0x14       // Enable GPIO clocks
.equ APB1ENR, 0x1C      // enable peripherals on bus 1
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
.equ TIM_EGR, 0x14       // Event generation register

.equ DELAYTIME, 2000



.data

.text

assembly_function:


	BL enableTimer
	BL enableGPIOClocks
	BL enableLEDs

	// Load base address for timer 2
	LDR R0, =TIM2

	// Enable the counter bit 0 and bit 7 and bit 2 of CR1
	MOV R1, #0b010000101
	STR R1, [R0, TIM_CR1]

	//Output for LEDs
	LDR R6, =GPIOE

	//Set Prescaler
	MOV R1, #0x7D					@ prescaler of 125
	LDR R2, =TIM_PSC                @ Load offset address for prescaler
	STR R1, [R0, R2]                @ Store prescaler value in timer address





	//Set ARR
	make_delay:

	LDR R0, =TIM2					@ Base address for timer 2

	LDR R4, =0x7A1200 				@ Clock speed of 8MHz

	LDR R2, =0x3E8					@ 1000

	LDR R3, =0x7D			        @ PSC VALUE

	LDR R1, =DELAYTIME				@ load delay time

	@ ARR = delay time x Clock Speed / PRESCALAR x 1000

	UDIV R1, R1, R2					@ delay time / 1000

	UDIV R4, R4, R3					@ clock speed / PSC VALUE

	MUL R1, R1, R4					@ delay time x Clock Speed / PSC VALUE


	//Timer  overflow
	LDR R2, =TIM_ARR
	STR R1, [R0, R2]



	//Setting TIM_EGR bit 0 to 1
	LDR R1, [R0, TIM_EGR]
	ORR R1, 0b0001 << 0
	STR R1, [R0, TIM_EGR]



onTime:

	# Set UIF flag to zero again because it's raised when we enable it****

	//MOV R1, #0b0

	LDR R1, [R0, TIM_SR]
	LDR R2, =#0xfffe

	AND R1, R2
	STR R1, [R0, TIM_SR]


	# Turn on LEDs
	LDR R7, =0b11111111
	STRB R7, [R6, #ODR + 1]

	# Check status register for UIF flag  BIT 0
	LDR R1, [R0, TIM_SR]
	LDR R2, =0b00000001
	TST R2, R1 @if ANDS is 1, UIF flag is raised (delay time is over).
	            @if ANDS is 0, UIF flag is raised (still keep looping in onTime)

	# Branch to appropriate subroutine
	BEQ onTime


/*
clear:

	// Reset clock
	LDR R7, =0x00
	STR R7, [R0, TIM_CNT]

*/

offTime:


	# Set UIF flag to zero again because it's raised when we enable it****

	//MOV R1, #0b0

	LDR R1, [R0, TIM_SR]
	LDR R2, =#0xfffe

	AND R1, R2
	STR R1, [R0, TIM_SR]


	# Turn off LEDs
	LDR R7, =0b00000000
	STRB R7, [R6, #ODR + 1]

	# Check status register for UIF flag  BIT 0
	LDR R1, [R0, TIM_SR]
	LDR R2, =0b00000001
	TST R2, R1 @if ANDS is 1, UIF flag is raised (delay time is over).
	            @if ANDS is 0, UIF flag is raised (still keep looping in onTime)


	# Branch to appropriate subroutine
	BEQ offTime



clear2:
	//Reset the clock
	LDR R7, =0x00
	STR R7, [R0, TIM_CNT]

	/*

	//Reset the flag
	LDR R7, =0b00000000
	STRB R7, [R0, TIM_SR]
	*/

	//B onTime

// Enable Timer 2 by setting relevant bit in APB1ENR
enableTimer:

	// Enable Timer 2 clock
	LDR R0, =RCC
	LDR R1, [R0, APB1ENR]
	ORR R1, 1 << TIM2EN
	STR R1, [R0, APB1ENR]

	//OUTPUT compare stuff I commented out
	/*

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
*/

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
