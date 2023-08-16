$include (c8051F120.inc)
	
CSEG AT 0

	CLR EA					; Запретить все прерывания
	MOV WDTCN,		#0xDE	; Отключить строковый таймер
	MOV WDTCN,		#0xAD	; Отключить сторожевой таймер
	MOV SFRPAGE,	#0x0F	; Выбрать страницу "F" 
	MOV SFRPGCN,	#0x00	; Запретить автоматическое переключение страниц ("SFRPGCN" стр. "F")
	MOV OSCICN,		#0x83	; Внутренний генератор включения, частота 24,5 MГц (OSCICN" стр. "F")

;---------------------------------------------------------------------------------------------

; Настраиваем все пины.
	MOV		SFRPAGE,	#0x00		; стр. "0"
	
	MOV		SPI0CKR,	#4 ; Эту частоту ДВ на рандом поставил. 
	MOV		SPI0CFG,	#01000000b	; включаем ведущий режим
	MOV		SPI0CN,		#00000001b	; включаем модуль SPI0
	
	MOV		SFRPAGE,	#0x0F		; стр. "F"
	MOV		P0MDOUT,	#00010101b	
	MOV		P0,			#11111111b

	MOV		P2MDOUT,	#00000010b	
	MOV		P2,			#11111111b

; Подключаем пины к матрице
	MOV		XBR0,		#00000010b
	MOV		XBR2,		#01000000b
	
	MOV		SFRPAGE,	#0x00		; стр. "0"	
	MOV		R2,			#6
	
	
;0. Запишем в XRAM константы для блоков, чтобы не писать здоровенные циклы, когда будем эти константы передавать кодеку.
	ACALL	Save_block_data_to_XRAM

;1. Реализуем сброс кодека. Для этого на пине RESETN установим 0, подождем немного, а потом установим 1.
	CLR		PIN_RESETN
	ACALL	Wait_long
	SETB	PIN_RESETN	
	ACALL	Wait_long		;Как оказалось, кодеку туть нужно время на подумать.


Loop:

;2. Прочитаем содержимое регистра $4F, для этого организуем поточную транзацию с импользованием SPI.
	Wait_for_3_control_words:
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x4F	;Передаем в подрограмму адрес регистра кодека, который хотим прочитать.
	ACALL	SPI0			

	ACALL	SPI0			;На втором байте считываем сами данные.
	
	SETB		PIN_CSN
	
	CJNE	A,		#0x03,		Wait_for_3_control_words	;Сравнение аккумулятора с константой и переход, если не равно.


;3. Считаем из регистра $4D 6 байт. По идее, мы с ними ничего делать не должны.
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x4D	
	ACALL	SPI0			
	
	Read_6_bytes:
		ACALL	SPI0			
		DJNZ 	R2,		Read_6_bytes
	MOV		R2,		#6
		
	SETB		PIN_CSN
	
	
;4. Соображаем, какой блок мы собираемся обрабатывать.
	MOV		R7,		#1			;Задаем начальное значение счетчику блоков.
	
	Start_of_N_block:
		ACALL	Wait_short
	
		CJNE	R7,		#1,		Not_1st_block
		MOV		R2,		#0x21
		MOV		DPTR,	#0x0000
		ACALL	Writing_constants_to_RAM
	
		Not_1st_block:	
			CJNE	R7,		#2,		Not_2st_block
			MOV		R2,		#0x21
			MOV		DPTR,	#0x0008
			ACALL	Writing_constants_to_RAM
	
			Not_2st_block:
				CJNE	R7,		#3,		Not_3st_block
				MOV		R2,		#0x25
				MOV		DPTR,	#0x0010
				ACALL	Writing_constants_to_RAM
				
				Not_3st_block:
	
	;MOV		DPTR,	#0x8000		;Задаем начальный адрес указателя флэш-памяти.
	
	;MOV		DPTR,	#0x0004
	;MOVX	A,		@DPTR
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x49	;Передаем в подрограмму адрес регистра кодека, который хотим прочитать.
	ACALL	SPI0			
	
	CLR		A
	ACALL	SPI0			;На втором байте считываем сами данные.
	
	SETB		PIN_CSN
	
SJMP	Loop

$include (My_library.inc)
	
END
