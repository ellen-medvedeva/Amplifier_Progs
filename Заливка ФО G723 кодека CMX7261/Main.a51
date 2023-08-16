$include (c8051F120.inc)
	
CSEG AT 0

	CLR EA					; ��������� ��� ����������
	MOV WDTCN,		#0xDE	; ��������� ��������� ������
	MOV WDTCN,		#0xAD	; ��������� ���������� ������
	MOV SFRPAGE,	#0x0F	; ������� �������� "F" 
	MOV SFRPGCN,	#0x00	; ��������� �������������� ������������ ������� ("SFRPGCN" ���. "F")
	MOV OSCICN,		#0x83	; ���������� ��������� ���������, ������� 24,5 M�� (OSCICN" ���. "F")

;---------------------------------------------------------------------------------------------

; ����������� ��� ����.
	MOV		SFRPAGE,	#0x00		; ���. "0"
	
	MOV		SPI0CKR,	#4 ; ��� ������� �� �� ������ ��������. 
	MOV		SPI0CFG,	#01000000b	; �������� ������� �����
	MOV		SPI0CN,		#00000001b	; �������� ������ SPI0
	
	MOV		SFRPAGE,	#0x0F		; ���. "F"
	MOV		P0MDOUT,	#00010101b	
	MOV		P0,			#11111111b

	MOV		P2MDOUT,	#00000010b	
	MOV		P2,			#11111111b

; ���������� ���� � �������
	MOV		XBR0,		#00000010b
	MOV		XBR2,		#01000000b
	
	MOV		SFRPAGE,	#0x00		; ���. "0"	
	MOV		R2,			#6
	
	
;0. ������� � XRAM ��������� ��� ������, ����� �� ������ ����������� �����, ����� ����� ��� ��������� ���������� ������.
	ACALL	Save_block_data_to_XRAM

;1. ��������� ����� ������. ��� ����� �� ���� RESETN ��������� 0, �������� �������, � ����� ��������� 1.
	CLR		PIN_RESETN
	ACALL	Wait_long
	SETB	PIN_RESETN	
	ACALL	Wait_long		;��� ���������, ������ ���� ����� ����� �� ��������.


Loop:

;2. ��������� ���������� �������� $4F, ��� ����� ���������� �������� ��������� � �������������� SPI.
	Wait_for_3_control_words:
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x4F	;�������� � ����������� ����� �������� ������, ������� ����� ���������.
	ACALL	SPI0			

	ACALL	SPI0			;�� ������ ����� ��������� ���� ������.
	
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
	
	;MOV		DPTR,	#0x8000		;������ ��������� ����� ��������� ����-������.
	
	;MOV		DPTR,	#0x0004
	;MOVX	A,		@DPTR
	CLR		PIN_CSN
	ACALL	Wait_short
	
	MOV		A,		#0x49	;�������� � ����������� ����� �������� ������, ������� ����� ���������.
	ACALL	SPI0			
	
	CLR		A
	ACALL	SPI0			;�� ������ ����� ��������� ���� ������.
	
	SETB		PIN_CSN
	
SJMP	Loop

$include (My_library.inc)
	
END
