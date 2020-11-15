;debug routines

	IFDEF	debug
tr:				defb		"TR:  -  ",0

PRBC		EQU #5B00
PRTXT		EQU #5B02		;Will hold Units,Tens and 0x00 for print

;Print text as per  IY  in hexadecimal
;D'=Row (0..23) E'=Column (0..63)
;Print 2 values in PRBC and PRBC+1 each reg is a value to print(0..255)
PrintIYLH:
			PUSH	IX,AF
			PUSH	IY
			POP		IX
			PUSH	DE,BC
			CALL	PrintIXText

			POP		BC,DE
			.3		INC	E				;Locate after TR:

			LD		IY,PRBC
PrintIY_Loop:
			PUSH	BC					;C=Nums to print
			LD		A,(IY)
			CALL	AtoHex
			PUSH	DE
			LD		IX,PRTXT
			CALL	PrintIXText
			POP		DE
			.3		INC	E				;Locate after previous number
			
			INC		IY
			POP		BC					;C=Nums to print
			DEC		C
			JR		NZ,PrintIY_Loop
			
			POP		AF,IX
			RET

AtoHex:
			LD		C,A
			
			AND		#0F
			ADD		A,"0"
			CP		"9"+1
			JR		C,OKUnit
			ADD		A,"A"-("9"+1)
OKUnit:			
			
			LD		B,A					;B=Units

			LD		A,C
			.4		RRCA
			AND		#0F
			ADD		A,"0"
			CP		"9"+1
			JR		C,OKTens
			ADD		A,"A"-("9"+1)
OKTens:
			LD		(PRTXT),A			;Tens
			LD		A,B
			LD		(PRTXT+1),A			;Units
			XOR		A
			LD		(PRTXT+2),A			;Units
			RET
		ENDIF
		
		IFDEF	soloesunejemplo
RUTDEBUG:
			LD		IY,tr
			EXX		
			LD		DE,32+(8<<8)					;Row 8, Column 32 (mini screen area)
			LD		A,(IX+FILEINDEX+1)
			LD		(PRBC),A
			LD		A,(IX+FILEINDEX)
			LD		(PRBC+1),A						;Save 2 values to print
			LD		C,2								;2 values to print
			CALL	PrintIYLH
			EXX		

		ENDIF