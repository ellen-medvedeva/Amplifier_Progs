PIN_SCLK		EQU		P0.0	;SCK
PIN_RDATA		EQU		P0.1	;MISO
PIN_CDATA		EQU		P0.2	;MOSI
PIN_CSN			EQU		P0.4	;Вот тут вопрос. Эту лапку будем менять программно.
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


;Выбор кристалла.
;Down_the_crystal_selection:
;	CLR		PIN_CSN
;	ACALL	Wait_short		;Согласно документации, тут должна быть задержка не менее 100 нс.
	
;Up_the_crystal_selection:
;	SETB	PIN_CSN
	;может быть, сюда нужно будет добавить задержку.


Save_block_data_to_XRAM:
;Для первого банка.
	MOV		DPTR,	#0x0000		;Начало отсчета адресов XRAM.
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
	
;Для второго банка.
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
	
;Для третьего банка.
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
	
	
Writing_constants_to_RAM:
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		R2,		#0x49
	MOV		A,		R2
	;INC		R2
	;ACALL	SPI0
	MOV		SPI0DAT,	A
	;poll_SPIF1:
	;	JNB		SPIF,		poll_SPIF1	;
	;	CLR		SPIF
	;ACALL	Wait_short
	
	MOV		DPTR,	#0x0004
	MOVX	A,		@DPTR
	;INC		DPTR
	;ACALL	SPI0	
	MOV		SPI0DAT,	A
	poll_SPIF2:
		JNB		SPIF,		poll_SPIF2	;
		CLR		SPIF
	;ACALL	Wait_short	
	
	SETB	PIN_CSN
	ACALL	Wait_short
	
	;CJNE	R2,		#0x29,		Writing_constants_to_RAM
RET
	
	
	
	
	