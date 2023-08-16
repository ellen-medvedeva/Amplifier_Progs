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


