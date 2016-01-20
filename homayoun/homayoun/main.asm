;
; homayoun.asm
;
; Created: 1/16/2016 2:34:59 PM
; Author : Parham Alvani
;

; Managing buffer for USART send:
; [ ][ ][ ][ ][ ][ ][ ] ... [ ][ ]
;  |           | 
;  buffer      Y

.dseg
buffer:
	.byte 512

.cseg
.org $000
reset_label:
	jmp reset_isr

reset_isr:
	cli
	ldi r16 , LOW(RAMEND) 
	out SPL , r16 
	ldi r16 , HIGH(RAMEND)
	out SPH , r16

	; Set USART buffer pointers
	ldi YL, LOW(buffer)
	ldi YH, HIGH(buffer)

	; PA0 - PA3 --> input + pullup
	; PA4 - PA7 --> output
	ldi r16, $F0
	out DDRA, r16
	in r16, SFIOR
	andi r16, $FB
	out SFIOR, r16
	ldi r16, $0F
	out PORTA, r16
	
	; PB0 - PB6 --> output
	; PB7 --> Input
	ldi r16, $7F
	out DDRB, r16

	; PD6 - PD7 --> Output
	ldi r16, (1 << PD6) | (1 << PD7)
	out DDRD, r16
	ldi r16, (1 << PD6)
	out PORTD, r16

	; Set USART baud rate to 2400kbps with 16Mhz clock
	ldi r16, HIGH(416)
	out UBRRH, r16
	ldi r16, LOW(416)
	out UBRRL,r16

	; Set USART startup settings
	; Stop bit = 2
	; Parity = ODD
	; Data bit = 8
	ldi r24, (0 << UMSEL) | (1 << UCSZ1) | (1 << URSEL) | (1 << UPM1) | (1 << UPM0) | (0 << UCPOL) | (1 << UCSZ0) | (1 << USBS)
	out UCSRC, r24
	ldi r24, (0 << UCSZ2) | (1 << TXEN) | (0 << RXEN)
	out UCSRB, r24
	ldi r24, (0 << U2X) | (0 << MPCM)
	out UCSRA, r24

	; PC0 - PC3 --> Output
	ldi r16, $0F
	out DDRC, r16
	
	call lcd_init
	sei
	jmp start

; Keypad interrupt rutine, providing delay
; to keep key bauncing away :)
key_poll:
	wdr
	call delay
	in r16, PINA
	ori r16, $F0
	cpi r16, $FF
	breq key_poll
	
	wdr
	call key_find

	; Show in seven segment
	;ldi r16, $0E
	;out PORTC, r16
	;call seven_seg
	;out PORTB, r22

	; Show in LCD
	call lcd_write

	ldi r16, $0F
	out PORTA, r16
	
	st Y+, r0

	mov r21, r0
	cpi r21, '\n'
	brne key_poll_ret
	call usart_send
	call lcd_clear

key_poll_ret:
	ret

start:
	wdr
    call key_poll
    jmp start

; Get value in r0 and
; put serven seg value in r22
seven_seg:
	mov r21, r0
	cpi r21, $31
	breq seven_seg_1
	cpi r21, $32
	breq seven_seg_2
	cpi r21, $33
	breq seven_seg_3
	cpi r21, $34
	breq seven_seg_4
	cpi r21, $35
	breq seven_seg_5
	cpi r21, $36
	breq seven_seg_6
	cpi r21, $37
	breq seven_seg_7
	cpi r21, $38
	breq seven_seg_8
	cpi r21, $39
	breq seven_seg_9
seven_seg_1:
	ldi r22, $06
	ret
seven_seg_2:
	ldi r22, $5B
	ret
seven_seg_3:
	ldi r22, $4F
	ret
seven_seg_4:
	ldi r22, $66
	ret
seven_seg_5:
	ldi r22, $6D
	ret
seven_seg_6:
	ldi r22, $7D
	ret
seven_seg_7:
	ldi r22, $07
	ret
seven_seg_8:
	ldi r22, $7F
	ret
seven_seg_9:
	ldi r22, $6F
	ret

; Find key pressed on row keypad
; and put in r0;
key_find:
	ldi r17, $00
	ldi r18, $00
	ldi r19, $7F
key_find_loop1:
	mov r16, r19
	out PORTA, r16
	nop
	in r16, PINA
	ldi r20, $04
key_find_loop2:
	ror r16
	brcc key_find_ret
	dec r20
	cpi r20, $00
	brne key_find_loop2
	inc r18
	inc r18
	inc r18
	inc r18
	sec
	ror r19
	inc r17
	cpi r17, $04
	brne key_find_loop1
key_find_ret:
	mov r0, r20
	add r0, r18
	dec r0
	mov r16, r0
	cpi r16, $00
	breq key_find_0
	cpi r16, $01
	breq key_find_1
	cpi r16, $02
	breq key_find_2
	cpi r16, $03
	breq key_find_3
	cpi r16, $04
	breq key_find_4
	cpi r16, $05
	breq key_find_5
	cpi r16, $06
	breq key_find_6	
	cpi r16, $07
	breq key_find_7
	cpi r16, $08
	breq key_find_8
	cpi r16, $09
	breq key_find_9
	cpi r16, $0A
	breq key_find_10
	cpi r16, $0B
	breq key_find_11
	cpi r16, $0C
	breq key_find_12
	cpi r16, $0D
	breq key_find_13
	cpi r16, $0E
	breq key_find_14
	cpi r16, $0F
	breq key_find_15
key_find_0:
	; ENTER
	ldi r16, '\n'
	mov r0, r16
	ret
key_find_1:
	; SET
	ldi r16, 'S'
	mov r0, r16
	ret
key_find_2:
	ldi r16, '0'
	mov r0, r16
	ret
key_find_3:
	; MENU
	ldi r16, 'M'
	mov r0, r16
	ret
key_find_4:
	; MODE
	ldi r16, 'm'
	mov r0, r16
	ret
key_find_5:
	ldi r16, '9'
	mov r0, r16
	ret
key_find_6:
	ldi r16, '8'
	mov r0, r16
	ret
key_find_7:
	ldi r16, '7'
	mov r0, r16
	ret
key_find_8:
	; DOWN
	ldi r16, 'D'
	mov r0, r16
	ret
key_find_9:
	ldi r16, '6'
	mov r0, r16
	ret
key_find_10:
	ldi r16, '5'
	mov r0, r16
	ret
key_find_11:
	ldi r16, '4'
	mov r0, r16
	ret
key_find_12:
	; UP
	ldi r16, 'U' 
	mov r0, r16
	ret
key_find_13:
	ldi r16, '3'
	mov r0, r16
	ret
key_find_14:
	ldi r16, '2'
	mov r0, r16
	ret
key_find_15:
	ldi r16, '1'
	mov r0, r16
	ret
	

; Create delay with repeating nop
delay:
	ldi r18, $0A
delay_loop_3:
	ldi r17, $FF
delay_loop_2:
	ldi r16, $FF
delay_loop_1:
	wdr
	dec r16
	cpi r16, $00
	brne delay_loop_1
	dec r17
	cpi r17, $00
	brne delay_loop_2
	dec r18
	cpi r18, $00
	brne delay_loop_3
	ret

; Sned bytes stored in the buffer from
; begin to Y
usart_send:
	ldi ZL, LOW(buffer)
	ldi ZH, HIGH(buffer)
usart_send_try:
	wdr
    sbis UCSRA, UDRE
	rjmp usart_send_try
	wdr
	ld r16, Z
	out UDR, r16
	ldi r16, $FF
	st Z+, r16
	cp ZH, YH
	brne usart_send_try
	cp ZL, YL
	brne usart_send_try
	ldi YL, LOW(buffer)
	ldi YH, HIGH(buffer)
	ret

; Set dispaly, cursor on .. let's rock :)
lcd_init:
lcd_init_busy:
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	nop
	; RS = PC3 = 0
	; RW = PD7 = 1
	; E = PD6 = 0
	ldi r16, (0 << PC3)
	out PORTC, r16
	ldi r16, (1 << PD7) | (0 << PD6)
	out PORTD, r16
	; Check busy flag
	in r16, PINB
	ori r16, $7F
	cpi r16, $FF
	breq lcd_init_busy
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	; PB0 - PB7 --> Output
	ldi r16, $FF
	out DDRB, r16
	; Out 0x0F
	ldi r16, $0F
	out PORTB, r16
	; RS = PC3 = 0
	; RW = PD7 = 0
	; E = PD6 = 0
	ldi r16, (0 << PC3)
	out PORTC, r16
	ldi r16, (0 << PD7) | (0 << PD6)
	out PORTD, r16
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	; PB0 - PB6 --> output
	; PB7 --> Input
	ldi r16, $7F
	out DDRB, r16
	ret

; Clear display
lcd_clear:
lcd_clear_busy:
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	nop
	; RS = PC3 = 0
	; RW = PD7 = 1
	; E = PD6 = 0
	ldi r16, (0 << PC3)
	out PORTC, r16
	ldi r16, (1 << PD7) | (0 << PD6)
	out PORTD, r16
	; Check busy flag
	in r16, PINB
	ori r16, $7F
	cpi r16, $FF
	breq lcd_clear_busy
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	; PB0 - PB7 --> Output
	ldi r16, $FF
	out DDRB, r16
	; Out 0x01
	ldi r16, $01
	out PORTB, r16
	; RS = PC3 = 0
	; RW = PD7 = 0
	; E = PD6 = 0
	ldi r16, (0 << PC3)
	out PORTC, r16
	ldi r16, (0 << PD7) | (0 << PD6)
	out PORTD, r16
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	; PB0 - PB6 --> output
	; PB7 --> Input
	ldi r16, $7F
	out DDRB, r16
	ret

; Send one byte stored in r0 into LCD
lcd_write:
lcd_write_busy:
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	nop
	; RS = PC3 = 0
	; RW = PD7 = 1
	; E = PD6 = 0
	ldi r16, (0 << PC3)
	out PORTC, r16
	ldi r16, (1 << PD7) | (0 << PD6)
	out PORTD, r16
	; Check busy flag
	in r16, PINB
	ori r16, $7F
	cpi r16, $FF
	breq lcd_write_busy
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	; PB0 - PB7 --> Output
	ldi r16, $FF
	out DDRB, r16
	; Out r0
	mov r16, r0
	out PORTB, r16
	; RS = PC3 = 1
	; RW = PD7 = 0
	; E = PD6 = 0
	ldi r16, (1 << PC3)
	out PORTC, r16
	ldi r16, (0 << PD7) | (0 << PD6)
	out PORTD, r16
	; E = PD6 = 1
	ldi r16, (1 << PD6)
	out PORTD, r16
	; PB0 - PB6 --> output
	; PB7 --> Input
	ldi r16, $7F
	out DDRB, r16
	ret