.syntax unified
.thumb

.global lab_5_b

/******************************
.text    表示代码段
.data    初始化的数据段
.bss     未初始化的数据段
.rodata  只读数据段
.global  表示全局变量
 声明汇编程序为全局的函数，意即可被外部函数调用，同时C程序中要使用extern声明要调用的汇编语言程序。
.extern XXXX 说明xxxx为外部函数，调用的时候可以遍访所有文件找到该函数并且使用它。
*******************************/

// Clock Registers
.equ RCC, 0x40021000   // Reset clock control. Base clock regiser  复位和时钟控制
.equ AHBENR,  0x14      // Enable GPIO clocks   高速总线 外围时钟允许寄存器
.equ APB2ENR, 0x18     // Enable USART1   低速总线 外围时钟允许寄存器
.equ APB1ENR, 0x1C

// Addresses and offsets for USART1
.equ USART1,0x40013800 // Base address for USART1
.equ UART4, 0x40004C00  @ from peripheral register memory boundary in the big manual
.equ USART_CR1, 0x00   // Control register 1  控制寄存器
.equ USART_BRR, 0x0C   // Baud rate register  波特率寄存器
.equ USART_ISR, 0x1C   // Status Register     中断和状态寄存器
.equ USART_RDR, 0x24   // Receive data register  接收数据寄存器
.equ USART_TDR, 0x28   // Transmit data register  发送数据寄存器

// GPIO
.equ GPIOC, 0x48000800  // GPIO Port C base address
.equ GPIO_MODER,   0x00   // Mode selection
.equ GPIO_OSPEEDR, 0x08 // Speed selection  GPIO端口输出速度寄存器
.equ GPIO_AFRL,    0x20    // Alternate function specification  GPIO复用功能低16寄存器
.equ GPIO_AFRH,    0x24
.equ GPIOC_ENABLE, 19   // Bit to enable clock for Port C (For UART4)

// UART
.equ USART1_ENABLE, 14  // Bit to enable USART1 clock
.equ UART4_ENABLE,  19  @ specific bit to enable UART4
.equ UART_TXE,  7        // Transmit data register empty bit   发送数据寄存器为空
.equ UART_RXNE, 5       // 读取数据寄存器不为空  当RDR移位寄存器的内容传输至USART_RDR寄存器时，该位置1。
						// 读取USART_RDR寄存器可将其清0。向USART_RQR寄存器中的RXFRQ写入1，也可以清除RXNE标志。
.equ UART_TE, 3         // Bit to enable transmission  发送使能
.equ UART_RE, 2         // Bit to enable receive   接收使能
.equ UART_UE, 0         // Bit to enable USART1 submodule  USART使能


.data

//// 定义终止字符
.equ TERMINATING_CHAR, 0x0A

.align

rx_buffer: .space 64   //连续分配 100B 的存储单元,并将其值初始化为 0
rx_counter: .byte 64

.text

lab_5_b:

	BL enableGPIOClocks
	BL enableUSART

	B waitReceive





enableGPIOClocks:
	LDR R0, =RCC              // Load register with clock base adderss
	LDR R1, [R0, #AHBENR]     // Load R1 with peripheral clock register's values
	ORR R1, 1 << GPIOC_ENABLE // Set relevant bits to enable clock for Port C
	STR R1, [R0, #AHBENR]     // Store value back in register to enable clock
	BX LR

enableUSART:
/********************************
LDR:数据从内存中某处读取到寄存器,MOV不可以
MOV:只能在寄存器之间移动数据，或者把立即数移动到寄存器中

LDR R0, 0x12345678  :就是把0x12345678这个地址中的值存放到R0中
LDR R0, =0x12345678 :把0x12345678这个地址写到R0中
****************************/

	// Step 1: Choose pin mode
	LDR R0, =GPIOC
	LDR R1, =0x00A00000 @ Mask for pins PC10 and PC11 to use the alternate function
	STR R1, [R0, GPIO_MODER]

	// Step 2: Set specific alternate function
	MOV R1, 0x55	@ set the alternate function for the UART4 pins (PC10 and PC11)
	STRB R1, [R0, GPIO_AFRH + 1]

	// Step 3: High clock speed and enable USART1 clock
	LDR R1, =0x00F00000 @ Set the speed for PC10 and PC11 to use high speed
	STR R1, [R0, GPIO_OSPEEDR]

	LDR R0, =RCC @ the base address for the register to turn clocks on/off
	LDR R1, [R0, #APB1ENR] @ load the original value from the enable register
	ORR R1, 1 << UART4_ENABLE  @ apply the bit mask to the previous values of the enable UART4
	STR R1, [R0, #APB1ENR] @ store the modified enable register values back to RCC


	// Step 4: Baud rate and enable USART1 (both transmit and receive)
	MOV R1, #0x46 @ from our earlier calculations (for 8MHz), store this in register R1. (around 115200)
	LDR R0, =UART4 @ the base address for the register to turn clocks on/off
	STRH R1, [R0, #USART_BRR] @ store this value directly in the first half word (16 bits) of


	LDR R0, =UART4 @ the base address for the register to set up UART4
	LDR R1, [R0, #USART_CR1] @ load the original value from the enable register
	ORR R1, 1 << UART_TE | 1 << UART_RE | 1 << UART_UE @ make a bit mask with a '1' for the bits to enable,
	STR R1, [R0, #USART_CR1] @ store the modified enable register values back to RCC

	BX LR @ return


waitReceive:
	LDR R3, =rx_buffer         // Load string
	LDR R4, =rx_counter        // Load pointer to number of characters in string
	LDR R4, [R4]               // Dereference pointer
	MOV R5, #0x00			   // 接收字符长度
/***************************************
1、数据从RX引脚通向接收移位寄存器，在接收控制的控制下，一位一位的读取RX的电平，把第一位放在最高位，
  然后右移，移位八次之后就可以接收一个字节了。
2、当一个字节数据移位完成之后，这一个字节的数据就会整体的移到接收数据寄存器RDR里来。
3、在转移时会置RXNE接收标志位，即RDR寄存器非空，下方为该位的描述。当被置1后，就说明数据可以被读出。
*************************************/

  // 读取USART1接收缓冲区中的数据
receive:



 	LDR R0, =UART4


	LDR R1, [R0, #USART_ISR]
	TST R1, 1 << UART_RXNE    //读取RXNE位，检查接收缓冲区是否有新数据 检查RXNE位是否为1

	BEQ receive   //RXNE=0 -->receive  如果没有新数据，则跳转

	LDR R1, [R0, #USART_RDR]  // 读取接收缓冲区中的数据

	STRB R1, [R3, R5]		// R3+R5 <-- R1(USART_RDR)
	ADD R5, #1  //接收1字符，地址加1


	// part CB
	CMP R1, #TERMINATING_CHAR
	BEQ stop
    //BEQ waitReceive   //接收到，重新接收

	CMP R4, R5

	BGT receive              //R4 > R5 --> 可以继续接收

	BL delayLoop              // Delay between sending strings

	B waitReceive         // Start all over again



delayLoop:
	LDR R9, =0xfffff

delayInner:

	SUBS R9, #1
	BGT delayInner
	BX LR

stop:
	LDR R7, [R0, #USART_CR1] @ load the original value from the enable register
	AND R7, 0 << UART_RE
	STR R7, [R0, #USART_CR1] @ store the modified enable register values back to RCC
	MOV R6, #1

	BX LR




