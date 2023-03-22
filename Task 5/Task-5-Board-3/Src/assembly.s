.syntax unified
.thumb

.global assembly_function

.equ ODR, 0x14
.equ IDR, 0x10
.equ MODER, 0x00


@ base register for resetting and clock settings
.equ RCC, 0x40021000
.equ AHBENR, 0x14	@ register for enabling clocks
.equ APB1ENR, 0x1C
.equ APB2ENR, 0x18
.equ AFRH, 0x24
.equ AFRL, 0x20
.equ RCC_CR, 0x00 @ control clock register
.equ RCC_CFGR, 0x04 @ configure clock register

@ register addresses and offsets for UART4
.equ UART4, 0x40004C00 @ from peripheral register memory boundary in the big manual
.equ UART5, 0x40005000
.equ USART_CR1, 0x00
.equ USART_BRR, 0x0C
.equ USART_ISR, 0x1C @ UART status register offset
.equ USART_ICR, 0x20 @ UART clear flags for errors
.equ UART4EN, 19  @ specific bit to enable UART4
.equ UART5EN, 20
.equ UART_TE, 3	@ transmit enable bit
.equ UART_RE, 2	@ receive enable bit
.equ UART_UE, 0	@ enable bit for the whole UART
.equ UART_ORE, 3 @ Overrun flag
.equ UART_FE, 1 @ Frame error

.equ UART_ORECF, 3 @ Overrun clear flag
.equ UART_FECF, 3 @ Frame error clear flag


@ uart4 is on GPIOC
.equ GPIOA, 0x48000000	@ base register for GPIOA (pa0 is the button)
.equ GPIOD, 0x48000C00
.equ GPIOC, 0x48000800	@ base register for GPIOA (pa0 is the button)
.equ GPIOE, 0x48001000	@ base register for GPIOE (pe8-15 are the LEDs)

.equ GPIO_MODER, 0x00	@ set the mode for the GPIO
.equ GPIO_OSPEEDR, 0x08	@ set the speed for the GPIO

@ transmitting data
.equ UART_TXE, 7	@ a new byte is ready to read
.equ USART_TDR, 0x28	@ a new byte is ready to read

.equ UART_RXNE, 5	@ a new byte is ready to read
.equ USART_RDR, 0x24	@ a new byte is ready to read
.equ USART_RQR, 0x18
.equ UART_RXFRQ, 3	@ a new byte is ready to read

@ UART5


.data
@ define variables

.align
incoming_buffer: .space 62
incoming_counter: .byte 62

tx_length: .byte 8


.text
@ define text


@ this is the entry function called from the c file
assembly_function:

@ run the functions to perform the config of the ports
	BL initialise_power
	BL enable_peripheral_clocks
	BL enable_uarts
	BL initialise_discovery_board

@ initialise the buffer and counter
	LDR R6, =incoming_buffer
	LDR R7, =incoming_counter
	LDRB R7, [R7]
	MOV R8, #0x00


@ continue reading forever (NOTE: eventually it will run out of memory as we don't have a big buffer
loop_forever:

	LDR R0, =UART5 @ the base address for the register to set up UART4
	LDR R1, [R0, USART_ISR] @ load the status of the UART4

	TST R1, 1 << UART_ORE | 1 << UART_FE  @ 'AND' the current status with the bit mask that we are interested in
						   @ NOTE, the ANDS is used so that if the result is '0' the z register flag is set

	BNE clear_error

	TST R1, 1 << UART_RXNE @ 'AND' the current status with the bit mask that we are interested in
							  @ NOTE, the ANDS is used so that if the result is '0' the z register flag is set

	BEQ loop_forever @ loop back to check status again if the flag indicates there is no byte waiting

	LDRB R3, [R0, USART_RDR] @ load the lowest byte (RDR bits [0:7] for an 8 bit read)


	LDR R0, =GPIOE  					@ load the address of the GPIOE register into R0
	STRB R3, [R0, #ODR + 1]   			@ store this to the second byte of the ODR (bits 8-15)


	CMP R7, R8
	BGT no_reset
	MOV R8, #0



no_reset:

	LDR R1, [R0, USART_RQR] @ load the status of the UART4
	ORR R1, 1 << UART_RXFRQ
	STR R1, [R0, USART_RQR]
	BGT loop_forever


clear_error:

	LDR R1, [R0, USART_ICR] @ load the status of the UART4
	@ Clear the overrun/frame error flag (see page 897)
	ORR R1, 1 << UART_ORECF | 1 << UART_FECF
	STR R1, [R0, USART_ICR] @ load the status of the UART4

	B loop_forever





@ function to enable the clocks for the peripherals we are using (A, C and E)
enable_peripheral_clocks:
	LDR R0, =RCC  @ load the address of the RCC address boundary (for enabling the IO clock)
	LDR R1, [R0, #AHBENR]  @ load the current value of the peripheral clock registers
	ORR R1, 1 << 21 | 1 << 19 | 1 << 17 | 1 << 20  @ 21st bit is enable GPIOE clock, 19 is GPIOC, 17 is GPIOA clock
	STR R1, [R0, #AHBENR]  @ store the modified register back to the submodule
	BX LR @ return

@ function to enable the UART4 - this requires setting the alternate functions for the UART4 pins
@ BAUD rate needs to change depending on whether it is 8MHz (external clock) or 24MHz (our PLL setting)
enable_uarts:
	LDR R0, =GPIOC
	LDR R1, =0x00055500	@ set the alternate function for the UART4 pins (PC10 and PC11) and uart5 pin PC12
	STR R1, [R0, AFRH]

	LDR R1, =0x02A00000 @ Mask for pins PC10, PC11, PC12 to use the alternate function
	STR R1, [R0, GPIO_MODER]

	LDR R1, =0x03F00000 @ Set the speed for PC10, PC11 and PC12 to use high speed
	STR R1, [R0, GPIO_OSPEEDR]

	LDR R0, =GPIOD
	LDR R1, =0x00000500
	STR R1, [R0, AFRL]

	LDR R1, =0x00000020
	STR R1, [R0, GPIO_MODER]

	LDR R1, =0x00000030 @ Set the speed for PC10, PC11 and PC12 to use high speed
	STR R1, [R0, GPIO_OSPEEDR]

	@ UART4EN is bit number 19, we need to turn the clock on for this
	LDR R0, =RCC @ the base address for the register to turn clocks on/off
	LDR R1, [R0, #APB1ENR] @ load the original value from the enable register
	ORR R1, 1 << UART4EN | 1 << UART5EN @ apply the bit mask to the previous values of the enable UART4
	STR R1, [R0, #APB1ENR] @ store the modified enable register values back to RCC

	@ this is the baud rate
	MOV R1, #0x46 @ from our earlier calculations (for 8MHz), store this in register R1
	LDR R0, =UART4 @ the base address for the register to turn clocks on/off
	STRH R1, [R0, #USART_BRR] @ store this value directly in the first half word (16 bits) of
							  	 @ the baud rate register
	MOV R1, #0x46
	LDR R0, =UART5
	STRH R1, [R0, #USART_BRR]

	@ we want to set a few things here, lets define their bit positions to make it more readable
	LDR R0, =UART4 @ the base address for the register to set up UART4
	LDR R1, [R0, #USART_CR1] @ load the original value from the enable register
	ORR R1, 1 << UART_TE | 1 << UART_RE | 1 << UART_UE @ make a bit mask with a '1' for the bits to enable,
													   @ apply the bit mask to the previous values of the enable register
	STR R1, [R0, #USART_CR1] @ store the modified enable register values back to RCC

	LDR R0, =UART5
	LDR R1, [R0, #USART_CR1]
	ORR R1, 1 << UART_TE | 1 << UART_RE | 1 << UART_UE

	STR R1, [R0, #USART_CR1]

	BX LR @ return





@ initialise the power systems on the microcontroller
@ PWREN (enable power to the clock), SYSCFGEN system clock enable
.equ PWREN, 28
.equ SYSCFGEN, 0
initialise_power:

	@ enable clock power
	LDR R0, =RCC @ the base address for the register to turn clocks on/off
	LDR R1, [R0, #APB1ENR] @ load the original value from the enable register
	ORR R1, 1 << PWREN @ apply the bit mask for power enable
	STR R1, [R0, #APB1ENR] @ store the modified enable register values back to RCC

	@ enable clock config
	LDR R1, [R0, #APB2ENR] @ load the original value from the enable register
	ORR R1, 1 << SYSCFGEN @ apply the bit mask to allow clock configuration
	STR R1, [R0, #APB2ENR] @ store the modified enable register values back to RCC
	BX LR @ return

initialise_discovery_board:
	LDR R0, =GPIOE 	@ load the address of the GPIOE register into R0
	LDR R1, =0x5555  @ load the binary value of 01 (OUTPUT) for each port in the upper two bytes
					 @ as 0x5555 = 01010101 01010101
	STRH R1, [R0, #MODER + 2]   @ store the new register values in the top half word representing
								@ the MODER settings for pe8-15
	BX LR @ return from function call
