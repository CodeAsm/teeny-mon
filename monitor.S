.global _start

.equ UART0_BASE, 0x101f1000     @ QEMU VersatilePB UART0
.equ UART0_DR,    0x00
.equ UART0_FR,    0x18

.equ UART0_IBRD,  0x24  // For baudrate at 115200
.equ UART0_FBRD,  0x28
.equ UART0_LCRH,  0x2C
.equ UART0_CR,    0x30

/* -------------------------------------------------
   Entry point
   ------------------------------------------------- */
_start:
    bl uart_init
    ldr r0, =hello
    bl uart_puts
    bl loop

    
@ === UART Functions ===

/* -------------------------------------------------
   UART init for 115200 baud @ 24 MHz PL011 clock
   IBRD = 13, FBRD = 2  → baud ≈ 115200
   ------------------------------------------------- */
uart_init:
    ldr r1, =UART0_BASE
    mov r0, #0
    str r0, [r1, #UART0_CR]           @ disable UART

   // mov r0, #(1 << 4)                 @ Clear FIFOs (bit 4: FEN = FIFO Enable)
   // str r0, [r1, #UART0_LCRH]         @ Write to line control register

    mov r0, #4
    str r0, [r1, #UART0_IBRD]         @ integer divisor
    mov r0, #0
    str r0, [r1, #UART0_FBRD]         @ fractional divisor

    mov r0, #(3 << 5)                 @ 8-bit, no parity, 1 stop
    str r0, [r1, #UART0_LCRH]

    ldr r0, =((1 << 9) | (1 << 8) | 1) @ enable TXE, RXE, UARTEN
    str r0, [r1, #UART0_CR]
    bx lr


/* -------------------------------------------------
   Send one char in r0
   ------------------------------------------------- */
uart_send:
    push {r0, r1}            @ Save r0 (string pointer) and r1 on the stack
1:
    ldr r1, =UART0_BASE
    ldr r2, [r1, #UART0_FR]
    tst r2, #(1 << 5)             @ TXFF bit (Transmit FIFO Full)
    bne 1b
    strb r0, [r1, #UART0_DR]
    
    pop {r0, r1}             @ Restore r0 (string pointer) and r1 from the stack
    bx lr                    @ Return


/* -------------------------------------------------
   Receive one char → r0
   ------------------------------------------------- */
uart_recv:
1:
    ldr r1, =UART0_BASE
    ldr r2, [r1, #UART0_FR]
    tst r2, #(1 << 4)      @ RXFE bit (Receive FIFO Empty)
    bne 1b
    ldrb r0, [r1, #UART0_DR]
    bx lr

/* -------------------------------------------------
   Print null-terminated string (r0 = ptr)
   ------------------------------------------------- */
uart_puts:
    ldr r1, =UART0_BASE          @ Load UART base address
1:
    ldrb r2, [r0], #1            @ Load the next byte from the string (post-increment r0)
    cmp r2, #0                   @ Check for null terminator
    beq 2f                       @ Exit if null terminator
3:  ldr r3, [r1, #UART0_FR]      @ Load UART flag register
    tst r3, #(1 << 5)            @ Check TXFF (Transmit FIFO Full) flag
    bne 3b                       @ Wait until FIFO is not full
    strb r2, [r1, #UART0_DR]     @ Write character to UART data register
    b 1b                         @ Repeat for the next character
2:
    bx lr                        @ Return

/* -------------------------------------------------
   Entry point
   ------------------------------------------------- */
   
@ === Reset Handler ===
reset:
    bl _start
   
loop:
    bl uart_recv
    bl uart_send       @ echo
    b loop

hello:
    .asciz "Simple ARM Monitor\r\n"
    //.byte 0
