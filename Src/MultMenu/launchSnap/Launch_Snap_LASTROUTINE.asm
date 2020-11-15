;Launch_Snap_LASTROUTINE.asm
; Improved routine for using minimal RAM... using only B, AF and HL, no other register... exists with B=0, HL=#8000, AF=something....
		;	SP=LastINT, DE=dir PC

			LD		A,(File_FTYPE)					;File Type for loading blocks

		DAN_BIG_COMMAND_NOW DANCMD_MULTIPLY, DANDAT_MULTIPLY, A
		;Customized PAUSE_LONG without using SP
.mypauselong:	.4		AND (IX);LD	HL,(#8000)					;Replace EX (SP),HL
			DJNZ .mypauselong
		
		;PAUSE_LONG

		DAN_BIG_COMMAND_NOW DANCMD_MULTIPLY, DANDAT_MULTIPLY, SNAP_CHUNK

			LD		HL,ADDRRAM						; Destination of data 
			LD		BC,LENCHUNK						; Length of chunk to load
;------------------------------------
;Last  Load4bitBlk customized only for  last chunk... 512 bytes to load between #7E00-#7FFF
; Using only HL and AF
;	IN HL=#7E00
FINALLoad4bitBlk:

			DEC HL						;6Ts
FINALLoopByte:

FINALLoopFor1:
			IN		A,(#1F)				;11 Ts
			RRA							;4 Ts - bit 0 to carry, load value shifted to bits 3,2,1,0
			JR		NC,FINALLoopFor1		;12/7 Ts - 1st nibble have always bit0=1

;EndLoopFor1:
			INC		HL					;6 Ts
			DEC		BC					;6 Ts
			LD (HL),A					;7 Ts - RLD							;18 Ts - Move LOW nibble of A (really is the HIGH nibble we need)  to (HL) into LOW nibble


FINALLoopFor0:
			IN		A,(#1F)				;11 Ts
			RRA							;4 Ts - bit 0 to carry, load value shifted to bits 3,2,1,0
			JR		C,FINALLoopFor0			;12/7 Ts - 2nd nibble have always bit0=0

;EndLoopFor0:
			RLD							;18 Ts - Move LOW nibble to (HL) into LOW nibble, previous LOW nibble in (HL) goes to HIGH nibble in (HL)
			LD		A,B
			OR		C
			JR		NZ,FINALLoopByte			;12 Ts - Bit 7 of H is zero.... continue.... 1 for we finish loading last 512 bytes

;------------------------------

		;	SP=LastINT

			LD	HL,0
			ADD	HL,SP			;So HL=LastINT
			EX	DE,HL			;so DE=LastINT
			LD	SP,#8000		;SP point to RAM so EI-HALT can work correctly (if points to #0000-#3FFF dandanator receive pulse as command)
			LD		BC,(#7FFE)
			EI
			HALT
			LD		(#7FFE),BC
;-----------------------------------------------------------

; Locate a RET (#C9) op-code in #4000-#FFFF.... ajuste en LastPreRET+1 (tiene un LD HL,xxxx + PUSH HL)
			LD  H,D
			LD  L,E				;HL=LastINT
			.5  INC HL			;so HL points to value of LastSP
			LD A,(HL)			;Low byte of LastSP
			INC HL
			LD H,(HL)			;High byte of LastSP
			LD L,A				;HL=LastSP
			LD  SP,HL			;SP=LastSP
			
	;So now we can locate in RAM a RET
			LD	HL,#4000
			LD	BC,#C000
			LD	A,#C9
LocaRET_Loop:
			CPIR
	;CPIR stop when found #C9.... it should be very very strange no one #C9... it always should appear
	;so HL=address after #C9... also check it's not in range SP-2 <-> SP-1 and if so discard it and check for a new address
			DEC		HL				;Adjust as CPIR finish in the next address after #C9
			AND    A			;Remove carry
			SBC    HL,SP			;HL=HL-SP	
			JR     NC,RetValid		;Carry if HL>=SP (no conflict)
			ADD	HL,SP			;Recuperate value (DON'T USE CARRY)
			.2	INC HL			
			AND    A			;Remove carry
			SBC    HL,SP			;HL=HL-SP	
			JR     C,RetValid2		;Carry if HL<SP (conflict) -really check is address with #C9 - 2 < SP
			ADD	HL,SP			;Recuperate value (DON'T USE CARRY)
			DEC HL			;skip SP-2 and SP-1 that are not valid
			JR	LocaRET_Loop		;Repeat to locate another position
RetValid2:
		.2	DEC HL
RetValid:
			ADD	HL,SP			;Recuperate value (DON'T USE CARRY)

	;Finally we have HL=Position in RAM with a RET
;-----------------------------------------------------------	
			EX DE,HL			;So DE=AddrwithRET, HL=LastINT
			
		;Now we send Special command 40,33,8: 
			LD		B,40							;Command 40=Fast command
			DAN_BIG_COMMAND_NOWAIT	33,8			;	 Data1=33 for Internal ROM, 8=Disable dandanator

			LD	SP,HL								;SP = LastINT
			POP	BC									;Take IMx-DI/EI-SNA48 bits (C) and R byte (B) 
			LD  A,C									;C=0 for IM0, 1 for IM1, 2 for IM2
			AND 3									;Isolate bits for IMx
			DEC A
			DEC A
			JR	NZ,setIM1							;If A=0 it was IM2
			IM	2									;if not set IM2 then we're in IM1
setIM1:
			BIT	2,C									;Check if DI (0) or EI (1)
			JR	Z,setDI
			EI										;if not EI we're in DI Still we have enought time before arriving Screen Interrupt
setDI:
			LD	A,B									;B=R
			LD	R,A									;R adjusted ....pending value

			POP	AF									;Restore AF (take from LastAF)
			.4	INC HL								;skip LastINT, LastR and LastAF (4 bytes)...HL=LastRoutine

			LD	B,0									;So BC=address points into EEP zone for activate previous Fast Command
			JP	(HL)								;Jump to HL=LastRoutine
