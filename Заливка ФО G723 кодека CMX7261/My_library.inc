PIN_SCLK		EQU		P0.0	;SCK
PIN_RDATA		EQU		P0.1	;MISO
PIN_CDATA		EQU		P0.2	;MOSI
PIN_CSN			EQU		P0.4	
PIN_RESETN		EQU		P2.1
	
	
;Задержки для SPI.
Wait_short:
	MOV		R0,			#100
	Wait_sh:
		DJNZ	R0,			Wait_sh
RET

Wait_long:
	MOV		R0,		#0
	MOV		R1,		#0
	
	Wait_ln:
		DJNZ	R0,		Wait_ln
		DJNZ	R1,		Wait_ln
RET


;Непосредственно сам SPI. Возможно, требует доработок.
SPI0:
	MOV		SPI0DAT,	A

poll_SPIF:
	JNB		SPIF,		poll_SPIF	;Ждем, пока  SPI сообщит о том, что все данные переданы.
	CLR		SPIF

	MOV		A,			SPI0DAT
	ACALL	Wait_short
RET

SPI01:
	MOV		SPI0DAT,	A

poll_SPIF1:
	JNB		SPIF,		poll_SPIF	;Ждем, пока  SPI сообщит о том, что все данные переданы.
	CLR		SPIF
RET
	
Writing_constants_to_RAM_1:
	MOV		0x21,	#0xFF
	MOV		0x22,	#0xFF
	MOV		0x23,	#0xCE
	MOV		0x24,	#0x46
	MOV		0x25,	#0x40
	MOV		0x26,	#0x00
	MOV		0x27,	#0xA2
	MOV		0x28,	#0x70
RET

Writing_constants_to_RAM_2:
	MOV		0x21,	#0x00
	MOV		0x22,	#0x10
	MOV		0x23,	#0x22
	MOV		0x24,	#0xF6
	MOV		0x25,	#0x20
	MOV		0x26,	#0x00
	MOV		0x27,	#0x18
	MOV		0x28,	#0x10
RET
	
Writing_constants_to_RAM_3:
	MOV		0x25,	#0x40		;Для регистров $25 и далее.
	MOV		0x26,	#0x10
	MOV		0x27,	#0x00
	MOV		0x28,	#0x00
RET
	
Wait_for_chip_ID:
	ACALL		Wait_short
			
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x4F	
	ACALL	SPI0			
	ACALL	SPI0

	SETB		PIN_CSN
	ACALL		Wait_short
	
	JZ 		Wait_for_chip_ID		;Вот эта штука должна быть строго после поъема выбора кристалла!
RET