;water_effect
;Initialize lines data into RAM
InitLines:
			LD		HL,PosLines
			LD		DE,BufLines
			LD		BC,EndPosLines-PosLines
			LDIR
			
			RET

INTLines:
			XOR		A
			LD		(MovedLines),A

			LD		IX,BufLines
			CALL	MovingLines

			LD		IX,BufLines+LineLENDATA
			CALL	MovingLines

			LD		IX,BufLines+LineLENDATA+LineLENDATA
			CALL	MovingLines

			LD		A,(MovedLines)
			AND		A								;So return with (Z) Z activated if no line was moved, (NZ) Z deactivated if lines was moved

			RET
	
;-------------------------------------------------------------------------------
MovingLines:
			LD		A,(IX+LineCnt)					;Counter for executing movement
			INC		A
			LD		(IX+LineCnt),A
			CP		(IX+LineMXC)					;Check if arrived to Max value
			RET		NZ								;Return if not arrived
			INC		A								;As per RET NZ A is 0 so change the value to 1
			LD		(MovedLines),A					;Mark MovedLines as "did a move line"

			XOR		A
			LD		(IX+LineCnt),A					;Reset counter for next time

			LD		A,(IX+LineDir)					;Pos 3 is Direction: 0=Left, other=Right
			AND		A								;So we can check Zero and Sign (CPL does not change these Flag)
			JR		Z,LinesToLeft

		;Here LineToRight		
			LD		H,(IX+LineAdd)					;1st scanline to move
			LD		L,#F0							;Last Row in Third (Row 7), Column 16
			LD		B,H
			LD		C,#FF							;Last Row in Third (Row 7), Column 31
			LD		A,(BC)							;Column 31
			
			;LD		HL,#51F0						;Row 23, Column 16, Scanline 1
			;LD		A,(#51F0+15)
			RRCA									;Copy right bit to Carry
			
			LD		B,16
LoopLines:
			RR		(HL)							;Rotate right, carry comes into bit 7
			INC		HL
			DJNZ	LoopLines

			LD		H,(IX+LineAdd)					;1st scanline to move
			INC		H								;Convert into 2nd scanline
			LD		L,#F0							;Last Row in Third (Row 7), Column 16
			;LD		HL,#52F0						;Row 23, Column 16, Scanline 2
			LD		B,H								;2nd scanline
			LD		A,(BC)
			;LD		A,(#52F0+15)
			RRCA									;Copy right bit to Carry
			
			LD		B,16
LoopLines_a:
			RR		(HL)							;Rotate right, carry comes into bit 7
			INC		HL
			DJNZ	LoopLines_a

			LD		A,(IX+LineVal)					;Position of line 1
			INC		A
			LD		(IX+LineVal),A					;Update
			CP		(IX+LineMax)					;Check if arrived to maximum
			JR		NZ,End_Lines
			XOR		A
			LD		(IX+LineDir),A					;Change direction

			JR		End_Lines
			
LinesToLeft:
			LD		H,(IX+LineAdd)					;1st scanline to move
			LD		L,#FF							;Last column
			;LD		HL,#51F0+15						;Row 23, Column 31, Scanline 1
			LD		B,H
			LD		C,#F0
			LD		A,(BC)
			;LD		A,(#51F0)
			RLCA									;Copy left bit to Carry
			
			LD		B,16
LoopLines_b:
			RL		(HL)							;Rotate left, carry comes into bit 0
			DEC		HL
			DJNZ	LoopLines_b

			LD		H,(IX+LineAdd)					;1st scanline to move
			INC		H								;2nd scanline to move
			LD		L,#FF							;Last column
			;LD		HL,#52F0+15						;Row 23, Column 31, Scanline 2
			LD		B,H
			LD		A,(BC)
			;LD		A,(#52F0)
			RLCA									;Copy left bit to Carry
			
			LD		B,16
LoopLines_c:
			RL		(HL)							;Rotate left, carry comes into bit 7
			DEC		HL
			DJNZ	LoopLines_c

			LD		A,(IX+LineVal)					;Position of line 1
			DEC		A
			LD		(IX+LineVal),A
			CP		(IX+LineMin)					;Check if arrived to minimum
			JR		NZ,End_Lines
			LD		A,#FF
			LD		(IX+LineDir),A					;Update direction
End_Lines:
			RET

LineAdd		equ		0
LineVal		equ		1
LineDir		equ		2
LineMin		equ		3
LineMax		equ		4
LineCnt		equ		5
LineMXC		equ		6

;Position of scanlines 1-2, 3-4, 5-6 (0 and 7 are not moved)
;High byte of address(0),LValue(1),LDirection(2),LMin(3),LMax(4),Counter(5),MaxCounter(6)
PosLines	defb	#51,0,0,-2,2,0,25
PosLine2	defb	#53,0,#FF,-5,5,0,13
PosLine3	defb	#55,0,0,-7,7,0,11
EndPosLines:
LineLENDATA	equ		PosLine2-PosLines
