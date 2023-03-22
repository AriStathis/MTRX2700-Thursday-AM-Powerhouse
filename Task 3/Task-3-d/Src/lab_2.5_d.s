
.syntax unified
.thumb

.global assembly_function_d

// Clock Registers
.equ RCC, 0x40021000   // Reset clock control. Base clock regiser  复位和时钟控制
.equ AHBENR,  0x14     // Enable GPIO clocks   高速总线 外围时钟允许寄存器
.equ APB2ENR, 0x18     // Enable USART1  低速总线 外围时钟允许寄存器 P52
.equ APB1ENR, 0x1C	   //Enable UART4

// Addresses and offsets for USART1
.equ USART1,0x40013800 // Base address for USART1  PC4 PC5
.equ UART4, 0x40004C00  // Base address for UART4  PC10 PC11
.equ USART_CR1, 0x00   // Control regis            zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzter 1  控制寄存器
.equ USART_BRR, 0x0C   // Baud rate register  波特率寄存器
.equ USART_ISR, 0x1C   // Status Register     中断和状态寄存器
.equ USART_RDR, 0x24   // Receive data register  接收数据寄存器
.equ USART_TDR, 0x28   // Transmit data register  发送数据寄存器

// GPIO

.equ GPIOC, 0x48000800  // GPIO Port C base address  PC4 PC5
.equ GPIO_MODER,   0x00 // Mode selection
.equ GPIO_OSPEEDR, 0x08 // Speed selection  GPIO端口输出速度寄存器
.equ GPIO_AFRL,	   0x20 // Alternate function specification  GPIO复用功能低16寄存器
.equ GPIO_AFRH,    0x24
.equ GPIOC_ENABLE, 19   // Bit to enable clock for Port C (For UART1)

// UART
.equ USART1_ENABLE, 14  // Bit to enable USART1 clock
.equ UART4_ENABLE,  19  // Bit to enable UART4 clock
.equ UART_TXE,  7       // Transmit data register empty bit   发送数据寄存器为空
.equ UART_RXNE, 5       // 读取数据寄存器不为空  当RDR移位寄存器的内容传输至USART_RDR寄存器时，
						//该位置1。读取USART_RDR寄存器可将其清0。向USART_RQR寄存器中的RXFRQ写入1，也可以清除RXNE标志。
.equ UART_TE, 3         // Bit to enable transmission  发送使能
.equ UART_RE, 2         // Bit to enable receive   接收使能
.equ UART_UE, 0         // Bit to enable USART1 submodule  USART使能

.data

//定义终止字符
.equ TERMINATING_CHAR, 0x0A

.align

UART4_Rxbuffer: .space 16  //连续分配 64B 的存储单元,并将其值初始化为 0
UART4_Rxcounter: .byte 16

USART1_Txstring: .asciz "123456\r\n" // Define a string
USART1_Txlength: .byte 8

.text


assembly_function_d:

	BL enableGPIOClocks
	BL enableUSART		//接收

	B waitReceive_transmit

	B prepareTransmit


enableGPIOClocks:
	LDR R0, =RCC              // Load register with clock base adderss
	LDR R1, [R0, #AHBENR]     // Load R1 with peripheral clock register's values
	ORR R1, 1 << GPIOC_ENABLE// Set relevant bits to enable clock for Port C AND A
	STR R1, [R0, #AHBENR]     // Store value back in register to enable clock
	BX LR

enableUSART:

	// Step 1: Choose pin mode
	LDR R0, =GPIOC
	LDR R1, =0x00A00A00 // Mask for pins PC10 and PC11 to use the alternate function
	STR R1, [R0, GPIO_MODER]

	// Step 2: Set specific alternate function
	MOV R1, 0x77
	STRB R1, [R0, #GPIO_AFRL + 2]

	MOV R1, 0x55	// set the alternate function for the UART4 pins (PC10 and PC11)
	STRB R1, [R0, GPIO_AFRH + 1]

	// Step 3: High clock speed and enable USART1 clock
	LDR R1, =0x00F00F00 // Set the speed for PC4 and PC5,PC10 and PC11 to use high speed
	STR R1, [R0, GPIO_OSPEEDR]

	LDR R0, =RCC
	LDR R1, [R0, #APB2ENR]
	ORR R1, 1 << USART1_ENABLE
	STR R1, [R0, #APB2ENR]

	LDR R1, [R0, #APB1ENR] // load the original value from the enable register
	ORR R1, 1 << UART4_ENABLE  // apply the bit mask to the previous values of the enable UART4
	STR R1, [R0, #APB1ENR] // store the modified enable register values back to RCC

	// Step 4: Baud rate and enable USART1 (both transmit and receive)
	MOV R1, #0x46 // from our earlier calculations (for 8MHz), store this in register R1     //4.375  7200 0000/9600/16=468.75 = 0x1D4C  ??
	LDR R0, =USART1
	STRH R1, [R0, #USART_BRR]

	LDR R0, =UART4 // the base address for the register to turn clocks on/off
	STRH R1, [R0, #USART_BRR] // store this value directly in the first half word (16 bits) of

	LDR R0, =USART1
	LDR R1, [R0, #USART_CR1]
	ORR R1, 1 << UART_TE | 1 << UART_RE | 1 << UART_UE
	STR R1, [R0, #USART_CR1]

	LDR R0, =UART4 // the base address for the register to set up UART4
	LDR R1, [R0, #USART_CR1] // load the original value from the enable register
	ORR R1, 1 << UART_TE | 1 << UART_RE | 1 << UART_UE // make a bit mask with a '1' for the bits to enable,
	STR R1, [R0, #USART_CR1] // store the modified enable register values back to RCC

	BX LR


waitReceive_transmit:
	LDR R3, =UART4_Rxbuffer         // Load string
	LDR R4, =UART4_Rxcounter         // Load pointer to number of characters in string
	LDR R4, [R4]              // Dereference pointer
	MOV R5, #0x00

//读取USART1接收缓冲区中的数据
receive:
 	LDR R0, =UART4
	LDR R1, [R0, #USART_ISR]
	ANDS R1, 1 << UART_RXNE    //读取RXNE位，检查接收缓冲区是否有新数据 检查RXNE位是否为1

	BEQ receive   //RXNE=0 -->waitReceive  如果没有新数据，则跳转

	LDR R0, =UART4
	LDR R1, [R0, #USART_RDR]  //读取接收缓冲区中的数据
	STRB R1, [R3, R5]    //保存到UART4_Rxbuffer
	ADD R5, #1

	CMP R1,#TERMINATING_CHAR
    BEQ prepareTransmit   //接收到，发送

	CMP R4, R5
	BGT receive              // R4 >= R5,rx_buffer未满

	//B prepareTransmit

prepareTransmit:
	LDR R3, =UART4_Rxbuffer         // Load string
transmit:
	LDR R0, =USART1
	LDR R1, [R0, #USART_ISR]  // Load the status register into R1
	ANDS R1, 1 << UART_TXE    // Check if the transmission data register is empty
							  // 程序状态寄存器 CPSR 寄存器，带有 S
	BEQ transmit              // Wait (loop) until it is empty  Z=1-->运算结果为0

	LDRB R6, [R3], #1         // Load the next character in the string and point to the next entry
							  //读取 R3 地址上的一字节数据,并保存到 R5 中,R5=R3+1
	STRB R6, [R0, #USART_TDR] // Transmit the character
	SUBS R5, #1               // Indicate that one character has been sent out
	BGT transmit              // Keep looping until all characters are sent，R4>1 -->transmit ??

	CMP R6, #TERMINATING_CHAR
    BEQ waitReceive_transmit    //结束发送

//发送完字符串
	//BL delayLoop              // Delay between sending strings
	B waitReceive_transmit         // Start all over again




delayLoop:
	LDR R9, =0xfffff

delayInner:

	SUBS R9, #1
	BGT delayInner
	BX LR

