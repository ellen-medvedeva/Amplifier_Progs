Start_program:
$include (c8051F120.inc)
	
CSEG AT 0

	CLR EA					; ��������� ��� ����������
	MOV WDTCN,		#0xDE	; ��������� ��������� ������
	MOV WDTCN,		#0xAD	; ��������� ���������� ������
	MOV SFRPAGE,	#0x0F	; ������� �������� "F" 
	MOV SFRPGCN,	#0x00	; ��������� �������������� ������������ ������� ("SFRPGCN" ���. "F")
	MOV OSCICN,		#0x83	; ���������� ��������� ���������, ������� 24,5 M�� (OSCICN" ���. "F")
;---------------------------------------------------------------------------------------------

;����������� ��� ����.
	MOV		SFRPAGE,	#0x00		;���. "0"
	
	MOV		SPI0CKR,	#4 			;��� ������� �� �� ������ ��������. 
	MOV		SPI0CFG,	#01000000b	;�������� ������� �����
	MOV		SPI0CN,		#00000001b	;�������� ������ SPI0
	
	MOV		SFRPAGE,	#0x0F		;���. "F"
	MOV		P0MDOUT,	#00010101b	
	MOV		P0,			#11111111b

	MOV		P2MDOUT,	#00000010b	
	MOV		P2,			#11111111b

;���������� ���� � �������
	MOV		XBR0,		#00000010b
	MOV		XBR2,		#01000000b
	
	MOV		SFRPAGE,	#0x00			
	MOV		R2,			#6
	
	MOV		PSBANK,		#00010001b			;����� ��� �������� 0 ����.

;1. ��������� ����� ������. ��� ����� �� ���� RESETN ��������� 0, �������� �������, � ����� ��������� 1.
	CLR		PIN_RESETN
	ACALL	Wait_long
	SETB	PIN_RESETN	
	ACALL	Wait_long			;��� ���������, ������ ���� ����� ����� �� ��������.


;2. ��������� ���������� �������� $4F, ��� ����� ���������� ��������� ��������� � �������������� SPI.
	Wait_for_3_control_words:
		CLR		PIN_CSN
		ACALL	Wait_short
	
		MOV		A,		#0x4F	;�������� � ����������� ����� �������� ������, ������� ����� ���������.
		ACALL	SPI0			
		ACALL	SPI0			;�� ������ ����� ��������� ������ �� ������.
	
		SETB		PIN_CSN
		CJNE	A,		#0x03,		Wait_for_3_control_words	;��������� ������������ � ���������� � �������, ���� �� �����.


;3. ������� �� �������� $4D 6 ����. �� ����, �� � ���� ������ ������ �� ������.
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x4D	
	ACALL	SPI0			
	
	Read_6_bytes:
		ACALL	SPI0			
		DJNZ 	R2,		Read_6_bytes
	MOV		R2,		#6
		
	SETB		PIN_CSN
	
	
;4. ����������, ����� ���� �� ���������� ������������.
	MOV		R7,		#1			;������ ��������� �������� �������� ������.
	MOV		DPTR,	#0x8000		;������ ��������� ����� ��������� ����-������ � ������ �� ��������� ��� �������!
	
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
		
		
;5. � ������� ������ $49 ����� �������� ����� ����� �� ��������� $27 � $28 ��.
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


;6. � ������� ������ $49 ����� �������� ��������� ����� ����� �� ��������� $25 � $26 ��.
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
	
	
;7. ���� ����� ���� 3 ����, �� ����� ��������� � ���������.
	CJNE	R7,		#3,		Processing_of_basic_blocks
	;LJMP	Processing_of_the_activation_block


;8. �������� ����� ������ �� �������� ������.
	Processing_of_basic_blocks:
	
;8.1. ������� ����������� ������ FIFO-in, �.�. �������� $4B.
	Wait_for_FIFO_emptying:	
		CLR		PIN_CSN
		ACALL	Wait_short
	
		MOV		A,		#0x4B
		ACALL	SPI0
		ACALL	SPI0
		CJNE	A,		#0,		Wait_for_FIFO_emptying
		
	MOV		R6,		#128			;������ ��������� �������� �������� ����.
	
	CLR		PIN_CSN
	ACALL	Wait_short
	
;8.2. �������� ���� �����.
	MOV		A,		#0x49
	ACALL	SPI01

	;Not_end_of_128_words_fragment:
	Next_word:
		MOV		R5,		#2
		Next_byte_of_word:
			MOVC	A,			@A+DPTR			;��������� �� ����-������ � ����������� 1 ���� � ������� DPTR.
			ACALL	SPI01						;�������� ���� ���� �� SPI.
			INC 	DPTR
			DJNZ	R5,		Next_byte_of_word
	
;8.3. ���������, �� ���������� �� ����.
	;8.3.1. �������� � ����������� ������� (�.�. �����) ���� �������� DPTR.
	MOV		A,		DPH
	CJNE 	A,		#0,		Not_end_of_the_bank
	
	MOV		A,			PSBANK		;�������� ��������� ����.
	ADD		A,		#00010000b		
	MOV		PSBANK,			A	
	
	MOV		DPTR,	#0x8000			;������ ��������� ����� ��������� ����-������.

	Not_end_of_the_bank:
	
;8.4. ��������� ����� ����� � ������, �.�. ��������� $27 � $28.
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
;8.5. ���������� "���" ��������� $27 � $28.
	MOV		R1,		#0x28
	MOVX	A,		@R1
	MOV		R2,		A
	
	MOV		R1,		#0x27
	MOVX	A,		@R1
	
	ORL		A,		R2			;��� ���� ��������� ��������� � �����������.
	CJNE	A,		#0,		Not_end_of_block
	
	SETB 	PIN_CSN
	
;8.6. ��������� ������� $4F � ������� ��� ������� ����� 2, �.�. ������ 2 ����������� �����.
;	Wait_for_2_control_words:
;		CLR		PIN_CSN
;		ACALL	Wait_short
	
;		MOV		A,		#0x4F	
;		ACALL	SPI0			
;		ACALL	SPI0			
	
;		SETB		PIN_CSN
;		CJNE	A,		#0x02,		Wait_for_2_control_words
	
;8.7. ��������� �� �������� $4D 4 ����� ����������� ����� � ���������� �� � ������� ���������� �� ��������� $21-$24.
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
	
	
;9. ������� �� ��� ������� ����� - ������������.
	Error:
		;LJMP	Start_program
			Loop:
			NOP
			LJMP Loop
	
;	Processing_of_the_activation_block:
;		Wait_for_chip_activation:
;10. ���������, �������� �� FI.
;			CLR		PIN_CSN
;			ACALL	Wait_short
	
;			MOV		A,		#0x7E	
;			ACALL	SPI0			
;			ACALL	SPI0
;			CJNE 	A,		#01000000b,		Wait_for_chip_activation	
		
;			SETB		PIN_CSN
		
;			ACALL		Wait_for_chip_ID
		
;��������� �� $4D 2 ����� � ���������� �� � ID.
;			CLR		PIN_CSN
;			ACALL	Wait_short
	
;			MOV		A,		#0x49	
;			ACALL	SPI0			
;			ACALL	SPI0
;			CJNE 	A,		#0x72,		Error		;����� ����, ��� ������ ������� ����.
;			ACALL	SPI0
;			CJNE 	A,		#0x61,		Error
			
;			SETB		PIN_CSN
;			ACALL		Wait_for_chip_ID
;��������� �� $4D 2 ����� � ���������� �� � �������.
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
