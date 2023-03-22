.syntax unified
.thumb

.global lab_5_a

// Clock Registers
.equ RCC, 0x40021000
.equ AHBENR,  0x14
.equ APB2ENR, 0x18

// Addresses and offsets for USART1
.equ USART1,0x40013800
.equ USART_CR1, 0x00
.equ USART_BRR, 0x0C
.equ USART_ISR, 0x1C
.equ USART_TDR, 0x28

// GPIO
//.equ GPIOA, 0x48000000
.equ GPIOC, 0x48000800 //TX PC4  RX PC5
.equ GPIO_MODER,   0x00 //
.equ GPIO_OSPEEDR, 0x08
.equ GPIO_AFRL,    0x20
//.equ GPIOA_ENABLE, 17
.equ GPIOC_ENABLE, 19

// UART
.equ USART1_ENABLE, 14
.equ UART_TXE, 7
.equ UART_TE, 3
.equ UART_RE, 2
.equ UART_UE, 0

.data
// 定义终止字符
.equ TERMINATING_CHAR, 0x0A
.align

txString: .asciz "1234\r\n" // The r is a carraige return. The n is a new line
txLength: .byte 6

.text

// Entry point
lab_5_a:

	BL enableGPIOClocks
	BL enableUSART

	B prepareTransmit

enableGPIOClocks:
	LDR R0, =RCC
	LDR R1, [R0, #AHBENR]
	ORR R1, 1 << GPIOC_ENABLE
	STR R1, [R0, #AHBENR]
	BX LR

enableUSART:
	// Step 1: Choose pin mode
	LDR R0, =GPIOC
	LDR R1, =0xA00 //1010 0000 0000 (moder4 & moder5 for pc4 & pc5)
	STR R1, [R0, #GPIO_MODER]

	// Step 2: Set specific alternate function
	MOV R1, 0x77   // STM32F303-specific-datasheet P49
	STRB R1, [R0, #GPIO_AFRL + 2]

	// Step 3: High clock speed and enable USART1 clock
	LDR R1, =0xF00
	STR R1, [R0, #GPIO_OSPEEDR]

	LDR R0, =RCC
	LDR R1, [R0, #APB2ENR]
	ORR R1, 1 << USART1_ENABLE
	STR R1, [R0, #APB2ENR]

	// Step 4: Baud rate and enable USART1 (both transmit and receive)
	MOV R1, #0x46
	LDR R0, =USART1
	STRH R1, [R0, #USART_BRR]

	LDR R0, =USART1
	LDR R1, [R0, #USART_CR1]
	ORR R1, 1 << UART_TE | 1 << UART_RE | 1 << UART_UE
	STR R1, [R0, #USART_CR1]

	BX LR

prepareTransmit:
	LDR R3, =txString
	LDR R4, =txLength
	LDR R4, [R4] //LDR value inside txLength

transmit:
	LDR R0, =USART1
	LDR R1, [R0, #USART_ISR]
	ANDS R1, 1 << UART_TXE // is index 7 of
	BEQ transmit

	LDRB R5, [R3], #1


	STRB R5, [R0, #USART_TDR]//store the bit to TDR
	SUBS R4, #1
	BGT transmit

	BL delayLoop
	B prepareTransmit

delayLoop:
	LDR R9, =0xfffff1

delayInner:

	SUBS R9, #1
	BGT delayInner
	BX LR
