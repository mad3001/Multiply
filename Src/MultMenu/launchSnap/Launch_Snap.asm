;Launch_Snap -
;	IN HL = Address where filename to launch is stored


SNALEN			EQU 64								; length of SNA header
SNA7FFD			EQU 29								; Position in SNA header of #1FFD register
SNA1FFD			EQU 30								; Position in SNA header of #1FFD register
SNATYPE			EQU 31								; Position in SNA header of SNA type: 16k, 48k, 128k
SNAAY			EQU 32								; Position in SNA header of AY registers
LENCHUNK		EQU	512								; Size of Chunk (last 512 bytes of RAM5), also maximum size or Snapshot loading/launching routine
ADDRSP			EQU #8000							; Addr for stack
ADDRRAM			EQU ADDRSP-LENCHUNK					; Place to put the loading routine (load4bit will be in ROM)
			DI
			;IM		1
			LD		A,1
			OUT		(#FE),A							;Blue border for waiting
			LD		SP,ADDRSP
			PUSH	HL								;Save HL address for filename to launch (1 byte File type, then chars finished in 0x00,0xFF)
			
			LD		HL,BeginRAM
			LD		DE,ADDRRAM
			LD		BC,EndRAM-BeginRAM
			LDIR									;Copy routine to RAM
		DISPLAY "DanSnap_Val: ",/A,DanSnap_Val
		DISPLAY "End of chunk routine : ",/A,ADDRRAM+(EndRAM-BeginRAM)
		ASSERT (ADDRRAM+(EndRAM-BeginRAM))<ADDRSP-#0010		;Avoid collision of routine with stack (free 16 bytes even less will be used)

			;Clear attr area of screen
			LD		HL,#5800
			CALL	CLS_ATTR

			;for the chance this was 128k, also clear shadow screen
			LD DE,#0407
			CALL RAMSPAGEDE						;Page #1FFD with D, #7FFD with E
			
			LD HL,#D800
			CALL CLS_ATTR
			
			LD		E,#00							;E=#00 to be sure RAM 0 is paged
			CALL	RAMSPAGEE						;Page only #7FFD with E

		;Send (command CMD_RESET) to arduino so it resets-itself
		;	LD		A, CMD_RESET					; Request Arduino to auto-reset (Command DANCMD_MULTIPLY,DANDAT_MULTIPLY,CMD_RESET)

		;    CALL	SendSerByteLC

		;	
		;	LD		B,75					;Wait 75 times, that is 75/50 = 1.5 seconds... so Arduino can finish auto-reset
		;	CALL	WAITING
			
			JP		StartRoutine

WAIT_B:
			LD		BC,#1000
WAITING:
			DEC		BC
			LD		A,B
			OR		C
			JR		NZ,WAITING
			RET


BeginRAM:
		DISP ADDRRAM

;Required SPARE SPACE so here to ADDRSNA there is 0x25 bytes... DON'T CHANGE THIS
			defs	30,#FF
StartRoutine:

			POP		IX
			LD		A,(IX)
			LD		(File_FTYPE),A					;Copy to RAM so we know File Type for loading blocks...
			
			LD		A,CMD_ZX2SD_OFREAD_IX				;Command = Open File (Relative Path)
			LD		D,(IX+FILEINDEX)					;Low byte of Index
			LD		E,(IX+FILEINDEX+1)					;High Byte of index
			SCF											;Long confirmation for last byte sent
			CALL 	ZX2SD_COMMAND

		;Send command  to arduino asking for SNA data
			LD		HL,ENDSNA-SNALEN				; Destination of data
			LD		DE,SNALEN						; Length of data (SNA header as send by Arduino)
			LD		C,SNAP_HEADER					;c=SNAP_HEADER so command is get SNA or Z80 header

			CALL	LoadBlock						;Load Snap_Header
		
ENDSNA:	;Used so we calculate where to store SNA header so it finished just here
ADDRSNA		EQU ENDSNA-SNALEN
		DISPLAY "ENDSNA-SNALEN should be more than 0x25:",/A,$-ADDRRAM
	ASSERT ($-ADDRRAM) > 0X25
		
		;Restore some registers not used in next routines. Other registers will be moved to stack (SP=ADDRSP at this moment)
			LD		A,(ADDRSNA)
			LD		I,A								;Restored I
			LD		SP,ADDRSNA+1
			POP		HL
			POP		DE
			POP		BC
			EXX										;Restored HL', DE', BC'
			
			POP		AF
			EX		AF,AF							;Restored AF'
			POP		HL
			LD		(LastHL+1),HL					;Save into RAM for the final routine that will be saved to sector
			POP		HL
			LD		(LastDE+1),HL					;Save into RAM for the final routine that will be saved to sector
			POP		HL
			LD		(LastBC+1),HL					;Save into RAM for the final routine that will be saved to sector
			POP		IY								;Restored IY

			POP		IX								;Restores IX

			POP		BC								;C=EI/DI (bit 2), B=R
			LD		A,C
			AND		%00000100						;Isolate bit 2
			LD		(LastINT),A						;Store EI/DI directly in LastINT (so bit 2 is DI/EI)

			LD		A,B								;Copy value of R to A
			AND		#7F								;Remove bit 7 => 0
			ADD		#6F								;Adjust R for returning routine
			AND		#7F								;Remove bit 7 => 0
			BIT 	7,B								;if bit 7 = 1 then Z=deactivated
			JR		Z,noBit7
			OR		#80								;Restore bit 7 = 1
noBit7:
			LD		(LastR),A					    ;For saving into RAM for the final routine that will be saved to sector
			
			POP		HL								;AF reg in SNA
			LD		(LastAF),HL					    ;For saving into RAM for the final routine that will be saved to sector
			POP		HL								;SP reg in SNA
			LD		(LastSP+1),HL					;For saving into RAM for the final routine that will be saved to sector

		;restore more registers
			POP		HL								;H=border / L=IIMx 0,1,2
			LD		A,H
			LD		(LastBorder+1),A				;Store border colour for change at the end (prior to load chunk and jump to game)
			CP		1
			LD		A,1								;Usual loading border is blue
			JR		NZ,OkBorderLoad
			LD		A,5								;Alternative loading border cyan (when real border is blue)
OkBorderLoad:
			OUT		(#FE),A							;Restore border colour from SNA
			
			LD		A,L
			AND		3								;Isolate bits for IMx
			LD		HL,LastINT					    ;For saving into RAM for the final routine that will be saved to sector
			OR		(HL)
			LD		(HL),A							;Update final value
IM_EndSet:

		;adjust PC for final jump
			POP		HL								;PC for jump, or 0 if PC was already into stack
			LD		(LastPreHL+1),HL			    ;For saving into RAM for the final routine that will be saved to sector
			LD		A,H
			OR		L
			JR		NZ,HavePUSHDE					;If PC was <>0 it had value 
			LD		(LastRET),A						;Change PUSH DE to NOP (SNA48 have PC in stack so no need to do anything else) -in RAM to be saved in sector-
HavePUSHDE:			
			LD		SP,ADDRSP						;Provisional stack address during loading blocks (end of chunk)
			
		;Now load the blocks (except chunk with length=LENCHUNK )
			LD		HL,Table16K
			LD		A,(ADDRSNA+SNATYPE)				;SNA type: 1=16k, 3=48k, 8=128k
			CP		1
			JR		Z,LoadBlocks					;1=16k, jump
			LD		HL,Table48K
			CP		3
			JR		Z,LoadBlocks					;3=48k, jump
			LD		HL,Table128K
			LD		A,(ADDRSNA+SNA7FFD)				;Value in port #7FFD
			AND		#08								;Isolate Shadow/Normal screen bit
			JR		Z,LoadBlocks
			LD		HL,Table128KShadow
LoadBlocks:

		;(HL)= <ram to page>,<HIGH start>,<HIGH Len>,<value to ask arduino>
			LD		A,(HL)							;<ram to page>
			CP		#FF
			JR		Z,NowLoadChunk					;End loading so jump there
			
			CALL	RAMSPAGEA						;Map Upper RAM as per A reg
			INC		HL
			LD		E,(HL)							;E=<HIGH start>
			INC		HL
			LD		D,(HL)							;E=<HIGH len>
			INC		HL
			LD		C,(HL)							;E=<value to ask arduino>
			INC		HL								;Prepare HL for next time
			PUSH	HL								;Save HL for next time
			XOR		A
			LD		L,A								;L=0 => HL will be xx00
			LD		H,E								;HL=start
			LD		E,A								;DE=lenght => DE will be xx00
		;LoadBlock require HL=Destination of data (start), DE=Length of data, C=block to load 1..8

			CALL	LoadBlock						;Will load correspondent Block 1..8 starting HL and length DE

			POP		HL								;Restore HL for next block to load
			JR		LoadBlocks

NowLoadChunk:
		;banks for 128k models
			LD		A,(ADDRSNA+SNA1FFD)				; A=value for Port #1FFD
			LD		D,A
			LD		A,(ADDRSNA+SNA7FFD)				; A=value for Port #7FFD
			LD		E,A
			CALL	RAMSPAGEDE

		;Restore AY registers

			LD		HL,ADDRSNA+SNAAY+1				;HL=First AY reg (0..15)
			LD      C,#FD
			XOR		A								; Recuperate 16 regs (0..15)
RESTAY128_Loop: 
			LD		E,(HL)							;L=Value for AY reg
			LD		B,#FF
			OUT		(C),A							; AY reg
			LD		B,#BF
			OUT		(C),E							; Change value
			INC		HL								;IX points to AYreg value
			INC		A
			CP		16								;if 0..15 saved z will be activated
			JR		NZ,RESTAY128_Loop				;Continue for 0..15 regs		

			LD		A,(ADDRSNA+SNAAY)				;Last out to #FFFD
			LD		BC,#FFFD
			OUT		(C),A
;EndAY:
		
LastBorder:	LD		A,0								;Don't change that to XOR A.... it will hold the real value of border (maybe 0 or 1..7)
			OUT		(#FE),A							;Restore real border colour

Begin_LaunchSAV:
			CALL	LaunchSAVESECT					;Save sector with last routine, Address of sector is in (PAYLOAD_addr)
End_LaunchSAV:
		DISPLAY "End_LaunchSAV - ENDRAMSECTOR > 0:",/A,End_LaunchSAV - ENDRAMSECTOR
			ASSERT (End_LaunchSAV - ENDRAMSECTOR) > 0x00		;If (ENDRAMSECTOR < End_LaunchSAV)=False then send ERROR, if =True then continue compiling

			CALL ReenableButtons					;Reenable Left button as per Pause / DanSnap (if they exists in internal Dan EEPROM)

			LD		SP,(PAYLOAD_addr)				;Will point to LastINT
		;Copy all neccesary data to Final routine (still in RAM) so we can save it in the sector
		;	SP=LastINT

			JP SLOT0_TOGAME							;From RAM goto Slot to 

;TableRamPages, contains <ram to page>,<HIGH start>,<HIGH Len>,<value to ask arduino>
CHK		EQU	HIGH (ADDRRAM-#4000)
Table16K:
			DEFB	#00,#40,CHK,1, #FF
Table48K:
			DEFB	#00,#40,CHK,1, #00,#80,#40,2, #00,#C0,#40,3,#FF
Table128K:
			DEFB	#00,#40,CHK,1, #00,#80,#40,2, #00,#C0,#40,3, #01,#C0,#40,4, #03,#C0,#40,5, #04,#C0,#40,6, #06,#C0,#40,7, #07,#C0,#40,8, #FF
Table128KShadow:
			DEFB	#0F,#C0,#40,8, #08,#40,CHK,1, #08,#80,#40,2, #08,#C0,#40,3, #09,#C0,#40,4, #0B,#C0,#40,5, #0C,#C0,#40,6, #0E,#C0,#40,7, #FF
			

;CLS_ATTR - Clear only Attributes of screen, Normal or Shadow
;	IN HL - #5800 for Normal Screen, #D800 for Shadow Screen
CLS_ATTR:
			LD		D,H
			LD		E,L
			INC		E								;So DE=HL+1
			LD		BC,#300-1						;BC=Size of attributes - 1
			LD		(HL),L							;L has to be 0, so use it to fill
			LDIR
			RET
;RAMSPAGEDE - Page #1FFD with value in D, #7FFD with value in E
RAMSPAGEDE:
			LD		A,D
			LD		BC,#1FFD
			OUT		(C),A
;RAMSPAGEE - Page #7FFD with value in E
RAMSPAGEE:		; Page only #7FFD with value in E
			LD		A,E
;RAMSPAGEA - Page #7FFD with value in A
RAMSPAGEA:		; Page only #7FFD with value in A
			LD		BC,#7FFD
			OUT		(C),A
			RET

DanSnap		defb	0								;Will Hold slot in Dandantor for Pause or DanSnap (valid value 2-32)
File_FTYPE	defb	0								;Will Hold File Type for using with LoadBlock
; ----------------------------------------------------------------------------------------
LastINT:	defb	0								;(1 byte) 1st byte Bit0= 0 IM 1, 1 IM2, Bit1=0 DI, 1 EI.
LastR:		defb	0								;(1 byte) R final (adjusted)
LastAF:		defw	0								;(2 bytes) AF final
LastRoutine:	
LastSP: 	LD	SP,#FFFF							;(3 bytes) SP final
LastPreHL:	LD  HL,#FFFF							;(3 bytes) Address of PC to put into stack (except SNA48)
LastRET:	PUSH	HL 								;(1 byte) For SNA48 it's a NOP, for others PUSH DE so DE will have PC address
			PUSH	DE								;(1 byte) Position in RAM to Jump where is a RET 
LastHL:		LD	HL,#FFFF							;(3 bytes) HL final
LasftFast:	LD	(BC),A								;(1 byte) B = 0 so launch FastChange...we'll have 30-34Ts until changing to internal ROM and danzx locked...required more time
LastDE: 	LD	DE,#FFFF							;(3 bytes) 10Ts	
LastBC: 	LD	BC,#FFFF							;(3 bytes) 10Ts	
			RET										;(1 byte) 10Ts <-Return to address with the RET, from there return to game (PC)

	;total 23 bytes+6 = 29
EndLastRoutine:
DanSnap_Val:										;(1 byte) Copy of DANSNAP_PAUSE value from internal Dandanator slot 1
													; does not use defb so LDIR to RAM will not overwrite value
		ENT
EndRAM:

;Next will be executed from ROM...

;-----------------------------------------------------
; IN HL - Destination of data
; IN DE - Length of Data
; IN (File_FTYPE)  - Command for ask block
; IN C  - Value to send for command
;-----------------------------------------------------
LoadBlock:
		;Send (command as per File_FTYPE) to arduino asking for block (data= 6 for RAM5)
			LD		A,(File_FTYPE)					;File Type for loading blocks
		
LoadBlockDirect1Par:		;Insertion point to pass 1 byte parameter (i.e load screen)
		    CALL	SendSerByteLC
LoadBlockDirect:			
			LD		A,C
			CALL	SendSerByte						; Request data of SNA block from SD (Command DANCMD_MULTIPLY,DANDAT_MULTIPLY,A)

			CALL	Load4bitBlk 					; Load block using 4bit Kempston (HL=Destination data, DE=Length)

			JP		WAIT_B							;Wait a bit to sincronize Dandanator <-> Arduino and then return	

;-------------------new version less RAM usage
SLOT0_TOGAME:
;-------------------new version less RAM usage
			include "launchSnap/Launch_Snap_LASTROUTINE.asm"
		
			include "launchSnap/Launch_Snap_SAVESECT.asm"
;-------------------------------------------------
