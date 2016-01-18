;
; homayoun.asm
;
; Created: 1/16/2016 2:34:59 PM
; Author : Parham Alvani
;

; Managing buffer for USART send:
; [ ][ ][ ][ ][ ][ ][ ] ... [ ][ ]
;  |           | 
;  Y           Z

.dseg
buffer:
	.byte 512

.cseg
.org $000
reset_label:
	jmp reset_isr

.org $002
int0_label:
	jmp int0_isr

.org $018
udre_label:
	jmp udre_isr

reset_isr:
	cli
	ldi r16 , LOW(RAMEND) 
	out SPL , r16 
	ldi r16 , HIGH(RAMEND)
	out SPH , r16

	; Set USART buffer pointers
	ldi YL, LOW(buffer)
	ldi YH, HIGH(buffer)
	ldi ZL, LOW(buffer)
	ldi ZH, HIGH(buffer)

	; PC0 - PC3 --> input + pullup
	; PC4 - PC7 --> output
	ldi r16, $F0
	out DDRC, r16
	in r16, SFIOR
	andi r16, $FB
	out SFIOR, r16
	ldi r16, $0F
	out PORTC, r16
	
	; Set PORTA as output
	ldi r16, $FF
	out DDRA, r16

	; Enable INT0 with low level trigger
	in r16, GICR
	ori r16, (1<<INT0)
	out GICR, r16
	in r16, MCUCR
	andi r16, $FC
	out MCUCR, r16
	
	; Set USART baud rate to 19.2kbps with 1Mhz clock
	ldi r16, $00
	out UBRRH, r16
	ldi r16, $02
	out UBRRL,r16

	; Set USART startup settings
	; Stop bit = 1
	; Parity = None
	; Data bit = 8
	ldi r24,(0<<UMSEL)|(1<<UCSZ1)|(1<<URSEL)|(0<<UPM1)|(0<<UPM0)|(0<<UCPOL)|(1<<UCSZ0)|(0<<USBS)|(0<<UCPOL)
	out UCSRC,r24
	ldi r24,(0<<UCSZ2)|(1<<TXEN)|(0<<RXEN)|(1<<UDRIE)
	out UCSRB,r24
	ldi r24,(0<<U2X)|(0<<MPCM)
	out UCSRA,r24


	sei
	jmp start

int0_isr:
	cli
	
	call key_find
	mov XL, r0
	adiw X, $30
	mov r0, XL

	ldi r16, $0F
	out PORTC, r16
	
	st Y+, r0
	
	out PORTA, r0

	; Setup LCD write mode in 
	

	sei
	reti

udre_isr:
	cli
	cp ZL, YL
	ld r16, Z+
	out UDR, r16
	sei
	reti

start:
    jmp start

key_find:
	ldi r17, $00
	ldi r18, $00
	ldi r19, $7F
key_find_loop1:
	mov r16, r19
	out PORTC, r16
	nop
	in r16, PINC
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
	ret