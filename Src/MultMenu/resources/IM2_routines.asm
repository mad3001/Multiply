;IM2 routines - Compatible with Inves +
;Routine to support aborting checking if Multiply is connected to dandanator
;Used only in CheckHardware as IM1 is not enought (we need an INT for discarding return after int)
Init_IM2:
			;DI										;We're in DI so not required
			LD		A,HIGH FalseIM2Table			;Change I interrupt for IM2 so it always take address from #FFFF.
			LD		I,A
			LD		HL,ROMFalseIM2
			LD		DE,IM2ADDR
			LD		BC,#000C						;IM2 uses only these 12 bytes
			LDIR
			RET
Spare_IM2:
		align	256,0
			DISPLAY "Current Spare zone for IM2 : ",/A,$-Spare_IM2
@FalseIM2Table:
			DEFS	#101,#FF
			DISPLAY "IM2ADDR:",/A,IM2ADDR
			DISPLAY "False IM2 table:",/A,FalseIM2Table
			DISPLAY "False IM2 table end:",/A,$
;END FALSE IM2 TABLE CONSTRUCTOR
ROMFalseIM2:
		DISP	IM2ADDR
			POP		DE								;Discard return address so last CALL is aborted
			RETI
			
			DEFS	$FFFF-$,#FF
			DEFB	#18								;This #18 with #F3 (from DI address #0000) makes a JR #FFF4 (JR IM2ADDR)
		ENT
;GetMultiplyVer
GetMultiplyVer:
			CALL	Init_IM2						;Initialize IM2 routine (but does not activate yet)
						
;GetMultiplyVer_WaitInit:
			IM		1
			EI
			HALT									;Sinchronize to int (can't use IM2 because it discards return address)

			LD		C,10							;C=10 tries of getting info from Arduino
GetMultiplyVer_Loop:
		;1st Check Arduino is not sending data (maybe it was finishing sending data)
			LD		B,0								;Be sure 256 times reading Kempston it's in value 0
			LD		L,B								;Initialize with 0, and will OR port #1F 256 times:required a 0 for ok
.loopB:
			IN		A,(#1F)							;Test kemspton port
			;AND		#1F							;Isolate valid 5 low bits <-Parece que sin el AND va todo mejor, p.ej. en +2/+3
			OR		L
			LD		L,A
			DJNZ	.loopB
			JR		NZ,GetMultiplyCheck_Retry		;If value<>0 then count for new try

			LD		A,CMD_ZX2INO_REQ_ID				;Require version from Arduino
			CALL	SendSerByte;LC					;Send Command
			IM		2								;Change to IM2 for aborting
			EI
			LD		HL,MultiplyVer
			LD		DE,8
			CALL	Load4bitBlk						;Try to get 8 bytes for Multiply version
			DI
			IM		1
			LD		A,D								;Although Load4bitBlk finish with Z=activate, if it did not finish Z can be anything
			OR		E								;so better check DE=0
			JR		Z,GetMultiplyCheck				;Load4bitBlk finished so we have the info
GetMultiplyCheck_Retry:
			DEC		C
			JR		NZ,GetMultiplyVer_Loop
			
		;Here if Multiply did not response
			LD		A,(AUTOBOOTCHK)
			AND		A
			JP		NZ,Goto_Dan1stSlot				;If Multiply was autoboot then return to 1st slot without notification
		;Here if not multiply and it was launched manually from Dandantor menu.... show notification and return to Dan Menu
			LD		IX,TXTNOMultiply
			LD		A,(SEL_GAME_NUM)				;Selected game number (value 1..10)
GetMultiplyVer_Game:
			SUB		10
			JR		NC,GetMultiplyVer_Game
			ADD		19
			;
			;ADD		9
			LD		D,A
			LD		E,6								;Row 10+selected, Column 6
			CALL	PrintIXText
			
			LD		B,50
GetMultiplyVer_Loop_Wait:
			EI
			HALT
			DJNZ	GetMultiplyVer_Loop_Wait
			JP		Goto_Dan1stSlot					;Jump there to return to 1st MLD slot

GetMultiplyCheck:
			LD		HL,MultString
			LD		DE,MultiplyVer
			LD		B,4
GetMultiplyCheck_Loop:
			LD		A,(DE)
			CP		(HL)
			INC		HL
			INC		DE
			JR		NZ,GetMultiplyVer_Loop			;Not equal, not valid....repeat
			DJNZ	GetMultiplyCheck_Loop
			
			JP 		DisableButtons					;Go there to disable left button (dansnap / pause)
						
MultString:		defb	"MULT"