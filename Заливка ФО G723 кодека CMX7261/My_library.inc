PIN_SCLK		EQU		P0.0	;SCK
PIN_RDATA		EQU		P0.1	;MISO
PIN_CDATA		EQU		P0.2	;MOSI
PIN_CSN			EQU		P0.4	
PIN_RESETN		EQU		P2.1
	
	
;Задержки для SPI.
Wait_short:
	Wait_sh:
		DJNZ	R0,			Wait_sh
	MOV		R0,			#100
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
	MOV		DPTR,	#0x21		;Начало отсчета адресов XRAM.
	MOV		A,		#0xFF
	MOVX	@DPTR,	A			;Пересылка из аккумулятора в память.
	INC		DPTR
	
	MOV		A,		#0xFF	
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0xCE	
	MOVX	@DPTR,	A			
	INC		DPTR

	MOV		A,		#0x46		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x40		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x00		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0xA2		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x70
	MOVX	@DPTR,	A			
	INC		DPTR
RET

Writing_constants_to_RAM_2:
	MOV		DPTR,	#0x21
	MOV		A,		#0x00		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x10		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x22		
	MOVX	@DPTR,	A			
	INC		DPTR

	MOV		A,		#0xF6		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x20		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x00		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x18	
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x10		
	MOVX	@DPTR,	A			
	INC		DPTR	
RET

Writing_constants_to_RAM_3:
	MOV		DPTR,	#0x25
	MOV		A,		#0x40		;Для регистров $25 и далее.		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x10		
	MOVX	@DPTR,	A			
	INC		DPTR
	
	MOV		A,		#0x00	
	MOVX	@DPTR,	A			
	INC		DPTR

	MOV		A,		#0x00	
	MOVX	@DPTR,	A			

RET
	
Wait_for_chip_ID:
	ACALL		Wait_short
			
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x4F	
	ACALL	SPI0			
	ACALL	SPI0
	CJNE 	A,		#0,		Wait_for_chip_ID		
		
	SETB		PIN_CSN
RET