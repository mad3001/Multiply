			DEVICE ZXSPECTRUM128
			ENCODING "DOS"

PAUSELOOPSN		EQU 64							; Pause function - Number of loops for Dandanator commands

			include "resources/macro_tap_mult.asm"
			include "resources/multiply_commands_v1.asm"

			ORG	0

			;incbin "48k_AUTOLOAD.rom"		;48k Rom for composing the changes
			incbin "48k.rom"		;48k Rom for composing the changes

;This special ROM only works if Multiply when the file was Opened prior to launch the modified ROM. That way the ROM does not need to know the file using
;	and all the data will arrive as it's stored in the TAP file. It's cyclic so when arriving last entry it will go to the very 1st entry again.
;	Multiply will deal with the file in SD so what is into the TAP only concerns to Multiply

;Format of each "Data" in a TAP File
; +-+-+-+-+-+-+-+-+-+-+-+
; |L|L|F|D|.|.|.|.|.|D|C|
; +-+-+-+-+-+-+-+-+-+-+-+
;   | |File information |
;	|
;  L=2 byte for length of "File information" (little endian format: lsb, msb )
;  F=1 byte of Flag (passed to spectrum as "File information"
;  D=x bytes data (passed to spectrum as "File information"
;  C=1 byte of checksum (XOR of Flag and all D bytes), NOT passed to spectrum
;  Doing a XOR of all bytes between F and C have a result of 0 if checksum is correct (checksum is not checked)

;	Checksum is not checked (this is not a tape.... no errors expected because checksum error in the transfer of data).


;			Save routine patch: 04D0-053E			NOT USED as Saving Routine (Save disabled), Multiply will not save data (at least not at this moment, who knows in the future...)
;					A=Flag (usually 00=Header,FF=Data)
;					IX=Begining
;					DE=Length
;				Returns with Carry active after saving. Carry inactive if BREAK was pressed during saving
;
				org	$04D0
				AND A
				RET

;------------------------------------------------------------------------------------------------------------------------
; Load 4bits block of data at address specified by HL, DE contains size
;  IN HL:Beginning address to store data
;  IN DE:Length of data to read
;	IN C = Low address for returning with JP (HL), high is always #05
;	OUT DE:Beging address + Length - 1 (HL=Last address filled with data)
;	OUT A:0
;	OUT Flags modified... Z=activated always, Carry=0 always
;------------------------------------------------------------------------------------------------------------------------
;Here for waiting a "1" to start / process next bit
Load4bitBlk:
		DEC HL
LoopByte:

LoopFor1:
		IN		A,(#1F)				;11 Ts
		RRA							;4 Ts - bit 0 to carry, load value shifted to bits 3,2,1,0
		JR		NC,LoopFor1		;12/7 Ts - 1st nibble have always bit0=1

EndLoopFor1:
		INC		HL					;6 Ts
		DEC		DE					;6 Ts
		LD (HL),A					;7 Ts - RLD							;18 Ts - Move LOW nibble of A (really is the HIGH nibble we need)  to (HL) into LOW nibble


LoopFor0:
		IN		A,(#1F)				;11 Ts
		RRA							;4 Ts - bit 0 to carry, load value shifted to bits 3,2,1,0
		JR		C,LoopFor0			;12/7 Ts - 2nd nibble have always bit0=0

EndLoopFor0:
		RLD							;18 Ts - Move LOW nibble to (HL) into LOW nibble, previous LOW nibble in (HL) goes to HIGH nibble in (HL)
		LD		A,D					;4 Ts
		OR		E					;4 Ts
		JR		NZ,LoopByte			;12 Ts
		LD		D,H
		LD		E,L					;DE=last address loaded
		LD		H,#05				;Return is to address #05xx
		LD		L,C					;Low byte of address
		JP		(HL)
		;RET								;Return with Z active
		DEFS	8,0
;SendDanCMDs - Send command 46 (lock unlock) or 52 (send serial) as per minimal register usage
;	and without using stack.. only uses JP (HL) so don't modifying Stack
;	IN - A = Data 1 and Data 2 for command 46
;	IN - A = Data 2 for command 52 (Data 1 is always 1)
;	IN - Flag Z=0 for command 46, A, A (lock unlock)  A=register A
;	IN - Flag Z=1 for command 52, 1, A (send serial)  A=register A
;	IN - Flag C=0 for Long Command (wait after command)
;	IN - Flag C=1 for Short Command (don't wait after command)
;	IN - C = Low byte of address to return (address will be #05xx)
SendDanCMDs:
			LD		H,#05							;All jumps will be #05xx
			LD		B,46							;Command 46 (lock unlock)
			JR		NZ,Send_Ser
			LD		B,52							;Command 52 (send serial)
Send_Ser:
			LD		L, LOW SendDanCMDs_Ret1				;Address for returning
			JR		SendCMD							;Send Command
SendDanCMDs_Ret1:

			LD		B,A								;Command 46 have Data 1 = A
			JR		NZ,Send_Ser1
			LD		B,1								;Command 52 have Data 1 = 1
Send_Ser1:
			LD		L, LOW SendDanCMDs_Ret2
			JR		SendCMD							;Send Data1
SendDanCMDs_Ret2:

			LD		B,A								;Both, Command 46 and 52 have Data 2 = A
			LD		L, LOW SendDanCMDs_Ret3
			JR		SendCMD							;Send Data2
SendDanCMDs_Ret3:
			LD		(0),A							;Execute command
			JR		C,SendAfterLong					;Carry=1 for short command
			PAUSE_LONG
SendAfterLong:			
			LD		L,C								;Low Address to return
			JP		(HL)

SendCMD:
			SLOT_B									;Send Command as per B reg
			WAIT_B	PAUSELOOPSN						;Little pause
			JP		(HL)	

;Disable Checking BREAK key to avoid strange behaviours, ie games using SPACE that also loads data and could be "hanged" that way
			ORG $054A
				JR #054F
			ORG $0550
				JR #0554					;Skip BREAK key check [ Original is:  JR C,#0554  ;Jump unless a break is to be made ]

		;	ORG $055C
		;		.2 NOP						;Avoid changing Border colour, removing OUT (#FE),A    At this moment A=#0F (border white)

;			Load routine patch: #056B - #0604 both inclusive total available is #A3=163 bytes
;					A'=Flag (usually 00=Header,FF=Data)
;					IX=Begining
;					DE=Length
;				Returns with:
;					Carry=1 and Z=0 if sucessfully loaded, also A=1, H=0, DE=0, IX=BeginIX+lengthDE   (ie 5CE2+11 = 5CF3 , 5CCB+658 = 6323)
;					Carry=0 and Z=0 if Flag was incorrect -Also if Break was pressed (for Multiply BREAK is never checked) - Also IX=BeginIX, DE=lengthDE
;					Carry=0 and Z=1 if error loading data - IX,DE as per last address loaded correctly or at the end if error with CRC
;					Carry=1 and Z=1 => will never happend
			ORG	$056B
;BeginLoadRoutine:

				LD		A,#10				;#10 for unlocking dandanator
				AND		A					;Z=0 for Command 46, also Carry=0 for Long Confirmation
				LD		C, LOW AfterUnlock	;Return address after command sent
				JR		SendDanCMDs			;Send command (using long confirmation to be sure Dandanator is ready)
AfterUnlock:
				JR		ZX2SD_ASK_TAP		;Ask for Data from TAP : A'= Flag, DE=length, IX=Start address. Will return to ASK_Ret
ASK_Ret:
			;Now check loading area does not enter in conflict with ROM (#0000-#3FFF)
				LD		A,IXH
				CP		#40					;Check start address greater than #3FFF
				JR		NC,AddrOK
				LD		HL,#4000			;If Start Address is <#4000 change Start Address to #4000
				JR		AddrToLoad
AddrOK:
			;	LD		A,IXH
				LD		H,A
				LD		A,IXL
				LD		L,A					;HL=IX
AddrToLoad:
				LD		DE,5				;1st block receiving Status, Valid length and Valid Start Address for loading data.
				LD		C,LOW After1st4bit		;For Load4bitBlk we store in C the low byte (high is always #05) of the returning address
				JP		Load4bitBlk			;Get 3 bytes for Status and Length . Pending ADD 4 more for Start address and value for IX to return MARIO MARIO
After1st4bit:
				EX		DE,HL				;Exchange as this version of Load4bitBlk return address in DE
				LD		DE,4				;Loading 5 bytes return address is Initial+4 (1 less)
				AND		A
				SBC		HL,DE				;So HL is the zone where got 5 bytes
				LD		A,(HL)				;A=Status, will remain in A' reg upto ending the loading
											;		C=0xFF Error Flag, 0x00 Load OK, 0x01 Less , 0x02 Great
				INC		A					;A=0x00 Error Flag, 0x01 Load OK, 0x02 Less , 0x03 Great
				JR		Z,TAP_AfterLoad		;Status was 0xFF (now 0x00) => No load, Error Flag
				EX		AF,AF				;Save A'=0x00 Error Flag, 0x01 Load OK, 0x02 Less , 0x03 Great
TAP_Load:
				INC		HL
				LD		E,(HL)				;lsb of Length
				INC		HL
				LD		D,(HL)				;msb of Length so DE=Length
				INC		HL
				LD		A,(HL)				;lsb of Start Address
				INC		HL
				LD		H,(HL)				;msb of Start Address
				LD		L,A					;So HL=Start Address
				LD		C,LOW After2nd4bit		;For Load4bitBlk we store in C the low byte (high is always #05) of the returning address
				JP		Load4bitBlk			;Get the data, HL=Begin, DE=Length
After2nd4bit:
				INC		DE					;As Load4bitBlk return with DE = Begin+Legth-1
				LD		IXH,D
				LD		IXL,E				;IX=DE so returns with the next address after last loadeed (as real tap routine)
				LD		DE,0				;Return with DE=0 (as spectrum ROM)
				JR		TAP_AfterLoadAF		;Skip ex af,af (we did it previously in this branch)
TAP_AfterLoad:
				EX		AF,AF				;Arriving here from other branch prior to save status to A' so change here
TAP_AfterLoadAF:
				XOR		A
				INC		A					;A=#01 for locking dandanator, also Z=0 for Command 46 and Carry=0 for Long Confirmation
				LD		C, LOW After1Unlock	;Return address after command sent
				JP		SendDanCMDs			;Send command (using long confirmation to be sure Dandanator is ready)
After1Unlock:
			;A'=Previous Status for Load OK or Error after loading: A'=0x00 Error Flag, 0x01 Load OK, 0x02 Less , 0x03 Great
				EX		AF,AF				;A=Previous status, also Z=1 for Error Flag
				JR		Z,ERRORFLAG			;Z=1 for Error Flag
				DEC		A					;A=0x01 for Load OK so dec a => A=0 Z Activate
				JR		Z,LOADINGOK			;If Status was 0x00 Load OK
			
			;Here for Status A=0x02 or A=0x03 so data loaded but with Error (length differs)
LOADINGERROR:	
				XOR A						;C=0, Z=1, A=0x00 (as real tape routine) for error loading
				RET
				
LOADINGOK:
				XOR     A
				CP		1					;Z=0 for OK loading,Carry=1 for OK loading
				RET
				
ERRORFLAG:
				XOR	 	A					;C=0, Z=1
				DEC 	A					;C=0, Z=0, A=0xFF (as real tape routine)
				RET

;ZX2SD_ASK_TAP - Command to ask for TAP Data
;	IN - A': Flag
;	IN - E:	lsb of Length
;	IN - D: msb of Length
;	IN - IXL: lsb of Start Address
;	IN - IXH: msb of Start Address
;  Changes A and B, only Carry flag is modified, return with Carry activated
ZX2SD_ASK_TAP:
			XOR		A								;Clear carry Flag (For adding Long Conf after send command), also Z=1 (required for command 52)
			LD		A,CMD_ZX2SD_TAP					;Command for asking data from TAP (file was opened previously in Multiply MLD slot)
			LD		C,LOW ZX2SD_ASK_TAP_RET1
			JP		SendDanCMDs						;Send A=Command (Carry inactive for Long Conf)
ZX2SD_ASK_TAP_RET1:
			EX		AF,AF							;A'=Flag
			LD		C,A
			EX		AF,AF
			LD		A,C								;Send serial : Flag value							
			LD		C,LOW ZX2SD_ASK_TAP_RET2
			JP		SendDanCMDs						;Send A=Command (Carry inactive for Long Conf)
ZX2SD_ASK_TAP_RET2:
			LD		A,E								;Send serial : lsb of Length
			LD		C,LOW ZX2SD_ASK_TAP_RET3
			JP		SendDanCMDs						;Send A=Command (Carry inactive for Long Conf)
ZX2SD_ASK_TAP_RET3:
			LD		A,D								;Send serial : msb of Length
			LD		C,LOW ZX2SD_ASK_TAP_RET4
			JP		SendDanCMDs						;Send A=Command (Carry inactive for Long Conf)
ZX2SD_ASK_TAP_RET4:
			LD		A,IXL							;Send serial : lsb of Start Address
			LD		C,LOW ZX2SD_ASK_TAP_RET5
			JP		SendDanCMDs						;Send A=Command (Carry inactive for Long Conf)
ZX2SD_ASK_TAP_RET5:
			LD		A,IXH							;Send serial : msb of Start Address
			SCF										;Carry active for short confirmation
			LD		C,LOW ASK_Ret					;After last command will return to ASK_Ret address
			JP		SendDanCMDs						;Send A=Command (Carry inactive for Long Conf)

						;Return to caller
				
	
				DEFS	$0605-$,0

;EndLoadRoutine:
			
		SAVEBIN "ROMMULTTAP.BIN",0,#4000		;Save the composed 48k ROM with the changes
		
