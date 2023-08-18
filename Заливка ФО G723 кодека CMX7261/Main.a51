Start_program:
$include (c8051F120.inc)
	
CSEG AT 0

	CLR EA					; Запретить все прерывания
	MOV WDTCN,		#0xDE	; Отключить строковый таймер
	MOV WDTCN,		#0xAD	; Отключить сторожевой таймер
	MOV SFRPAGE,	#0x0F	; Выбрать страницу "F" 
	MOV SFRPGCN,	#0x00	; Запретить автоматическое переключение страниц ("SFRPGCN" стр. "F")
	MOV OSCICN,		#0x83	; Внутренний генератор включения, частота 24,5 MГц (OSCICN" стр. "F")
;---------------------------------------------------------------------------------------------

;Настраиваем все пины.
	MOV		SFRPAGE,	#0x00		;Стр. "0"
	
	MOV		SPI0CKR,	#4 			;Эту частоту ДВ на рандом поставил. 
	MOV		SPI0CFG,	#01000000b	;Включаем ведущий режим
	MOV		SPI0CN,		#00000001b	;Включаем модуль SPI0
	
	MOV		SFRPAGE,	#0x0F		;Стр. "F"
	MOV		P0MDOUT,	#00010101b	
	MOV		P0,			#11111111b

	MOV		P2MDOUT,	#00000010b	
	MOV		P2,			#11111111b

;Подключаем пины к матрице
	MOV		XBR0,		#00000010b
	MOV		XBR2,		#01000000b
	
	MOV		SFRPAGE,	#0x00			
	MOV		R2,			#6
	
	MOV		PSBANK,		#00010001b			;ВАЖНО ТУТ ПОМЕНЯТЬ 0 БАЙТ.

;1. Реализуем сброс кодека. Для этого на пине RESETN установим 0, подождем немного, а потом установим 1.
	CLR		PIN_RESETN
	ACALL	Wait_long
	SETB	PIN_RESETN	
	ACALL	Wait_long			;Как оказалось, кодеку туть нужно время на подумать.


;2. Прочитаем содержимое регистра $4F, для этого организуем потоковую транзацию с импользованием SPI.
	Wait_for_3_control_words:
		CLR		PIN_CSN
		ACALL	Wait_short
	
		MOV		A,		#0x4F	;Передаем в подрограмму адрес регистра кодека, который хотим прочитать.
		ACALL	SPI0			
		ACALL	SPI0			;На втором байте считываем данные от кодека.
	
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
	MOV		DPTR,	#0x8000		;Задаем начальный адрес указателя флэш-памяти И НИКУДА НЕ ПЕРЕНОСИМ ЭТУ СТРОЧКУ!
	
	Start_of_N_block:
		ACALL	Wait_short
		MOV		R0,		DPH
		MOV		R1,		DPL
		
		CJNE	R7,		#1,		Not_1st_block
		ACALL	Writing_constants_to_RAM_1
		Not_1st_block:	
			CJNE	R7,		#2,		Not_2st_block
			ACALL	Writing_constants_to_RAM_2
			Not_2st_block:
				CJNE	R7,		#3,		Not_3st_block
				ACALL	Writing_constants_to_RAM_3
				Not_3st_block:
		
		MOV		DPH,	R0
		MOV		DPL,	R1
		
		
;5. В регистр кодека $49 нужно передать длину блока из регистров $27 и $28 МК.
	MOV		R1,		#0x28
	
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x49
	ACALL	SPI01
	
	MOVX	A,		@R1
	ACALL	SPI01
	
	DEC		R1
	MOVX	A,		@R1
	ACALL	SPI01
	
	SETB	PIN_CSN
	ACALL	Wait_short


;6. В регистр кодека $49 нужно передать начальный адрес блока из регистров $25 и $26 МК.
	MOV		R1,		#0x26
	
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x49
	ACALL	SPI01
	
	MOVX	A,		@R1
	ACALL	SPI01
	
	DEC		R1
	MOVX	A,		@R1
	ACALL	SPI01
	
	SETB	PIN_CSN
	ACALL	Wait_short
	
	
;7. Если перед нами 3 блок, то сразу переходим к активации.
	CJNE	R7,		#3,		Processing_of_basic_blocks
	;LJMP	Processing_of_the_activation_block


;8. Передаем слова кодеку из основных блоков.
	Processing_of_basic_blocks:
	
;8.1. Ожидаем опустошения буфера FIFO-in, т.е. регистра $4B.
	Wait_for_FIFO_emptying:	
		CLR		PIN_CSN
		ACALL	Wait_short
	
		MOV		A,		#0x4B
		ACALL	SPI0
		ACALL	SPI0
		CJNE	A,		#0,		Wait_for_FIFO_emptying
		
	MOV		R6,		#128			;Задаем начальное значение счетчику слов.
	
	CLR		PIN_CSN
	ACALL	Wait_short
	
;8.2. Передаем одно слово.
	MOV		A,		#0x49
	ACALL	SPI01

	;Not_end_of_128_words_fragment:
	Next_word:
		MOV		R5,		#2
		Next_byte_of_word:
			MOVC	A,			@A+DPTR			;Перенесем из флэш-памяти в аккумулятор 1 байт с адресом DPTR.
			ACALL	SPI01						;Передаем этот байт по SPI.
			INC 	DPTR
			DJNZ	R5,		Next_byte_of_word
	
;8.3. Проверяем, не закончился ли банк.
	;8.3.1. Поместим в аккумулятор старший (т.е. левый) байт регистра DPTR.
	MOV		A,		DPH
	CJNE 	A,		#0,		Not_end_of_the_bank
	
	MOV		A,			PSBANK		;Выбираем следующий банк.
	ADD		A,		#00010000b		
	MOV		PSBANK,			A	
	
	MOV		DPTR,	#0x8000			;Задаем начальный адрес указателя флэш-памяти.

	Not_end_of_the_bank:
	
;8.4. Декремент длины блока в ручную, т.е. регистров $27 и $28.
	MOV		R1,		#0x28
	MOVX	A,		@R1
	CJNE	A,		#0,		Register_28_is_not_0
	
	MOV		A,		#0xFF
	MOVX	@R1,	A
	
	MOV		R1,		#0x27
	MOVX	A,		@R1
	DEC		A
	MOVX	@R1,	A
	LJMP	Next_step
	
	Register_28_is_not_0:
		DEC		A
		MOVX	@R1,	A
		LJMP	Next_step
	
	
	Next_step:	
;8.5. Логическое "или" регистров $27 и $28.
	MOV		R1,		#0x28
	MOVX	A,		@R1
	MOV		R2,		A
	
	MOV		R1,		#0x27
	MOVX	A,		@R1
	
	ORL		A,		R2			;При этом результат заносится в аккумулятор.
	CJNE	A,		#0,		Not_end_of_block
	
	SETB 	PIN_CSN
	
;8.6. Считываем регистр $4F и ожидаем там увидеть цифру 2, т.е. пришло 2 контрольных слова.
;	Wait_for_2_control_words:
;		CLR		PIN_CSN
;		ACALL	Wait_short
	
;		MOV		A,		#0x4F	
;		ACALL	SPI0			
;		ACALL	SPI0			
	
;		SETB		PIN_CSN
;		CJNE	A,		#0x02,		Wait_for_2_control_words
	
;8.7. Считываем из регистра $4D 4 байта контрольной суммы и сравниваем их с верными значениями из регистров $21-$24.
		CLR		PIN_CSN
		ACALL	Wait_short
	
		MOV		A,		#0x4D	
		ACALL	SPI0			
		ACALL	SPI0
			;CJNE 	A,		#0xFF,		Error		
		ACALL	SPI0
			;CJNE 	A,		#0xFF,		Error
		ACALL	SPI0
			;CJNE 	A,		#0xCE,		Error
		ACALL	SPI0
			;CJNE 	A,		#0x46,		Error
		
		SETB		PIN_CSN
		INC		R7
	
	Not_end_of_block:
		DJNZ 	R6,		Next_word 
		
		SETB		PIN_CSN
		LJMP		Wait_for_FIFO_emptying
	
	
;9. Решение на все случчаи жизни - перезагрузка.
	Error:
		;LJMP	Start_program
			Loop:
			NOP
			LJMP Loop
	
;	Processing_of_the_activation_block:
;		Wait_for_chip_activation:
;10. Проверяем, загружен ли FI.
;			CLR		PIN_CSN
;			ACALL	Wait_short
	
;			MOV		A,		#0x7E	
;			ACALL	SPI0			
;			ACALL	SPI0
;			CJNE 	A,		#01000000b,		Wait_for_chip_activation	
		
;			SETB		PIN_CSN
		
;			ACALL		Wait_for_chip_ID
		
;Считываем из $4D 2 байта и сравниваем их с ID.
;			CLR		PIN_CSN
;			ACALL	Wait_short
	
;			MOV		A,		#0x49	
;			ACALL	SPI0			
;			ACALL	SPI0
;			CJNE 	A,		#0x72,		Error		;Может быть, тут другой порядок байт.
;			ACALL	SPI0
;			CJNE 	A,		#0x61,		Error
			
;			SETB		PIN_CSN
;			ACALL		Wait_for_chip_ID
;Считываем из $4D 2 байта и сравниваем их с версией.
;			CLR		PIN_CSN
;			ACALL	Wait_short
	
;			MOV		A,		#0x49	
;			ACALL	SPI0			
;			ACALL	SPI0
;			CJNE 	A,		#0x20,		Error		
;			ACALL	SPI0
;			CJNE 	A,		#0x00,		Error
			
;			SETB		PIN_CSN
			
			;Loop:
			;NOP
			;LJMP Loop
$include (My_library.inc)
	
END
