;SAVESECT - Save sector info... writing 1 byte is
;	Comando 48, 1, sector number (0..127)		
;	OUT (PAYLOAD_addr)=Zone in #2000-#2FFF where sector was saved				

RAMSECTOR	equ		ADDRRAM							;#7E00


;Prepare routines in RAM to execute Erasing/Programming (always have to run from RAM... it trying from Slot it will hang speccy)
LaunchSAVESECT:
			LD		HL,SECROUTINES
			LD		DE,RAMSECTOR
			LD		BC,ENDSECROUTINES-SECROUTINES
			LDIR
			LD		A,(MLDoffset)					;Get from MLD the current slot number (0..31)
			INC		A								;Convert to 1..32
			LD		(LAUNCH_MyCurMLD),A				;Saving in RAM so we can return to the correct slot when return from RAM
			DEC		A								;Againt 0..31
;Calculate sector   SlotMLD * 4 + 2
			ADD A,A						
			ADD A,A						
			ADD A,2									; A =sector number (0..127)... always is the 2nd sector (0,1,2,3) of the MLD slot
			LD  E,A									;Save in E the value of Sector (0..127)		
							
;Routine to obtain address as per used bits (bits in "0"). MLD have bits in "1" intially in area #2000-#2FFF (bits in "1" for writing "0")							
			LD C,#00								;Will have the count of bits in 0 (used).		
			LD HL,#2000								;#2000-#200F are 16 bytes x 8 bits, indicating each bit the usage of a block of 32 bytes. #2010-#201F are not used (always #FF)
			LD A,(HL)						
			INC A									;If A=#FF then now A=0…. This means the MLD have not been used so #2000 is #FF (empty)		
			JR Z,AfterErase							;As sector is erased (clean), jump there to begin to use it		
Loop32:							
			LD B,8									;To process upto 8 bits		
			LD A,(HL)								;Value from address #2000-#200F	for getting the used sectors	
Loop8:							
			RRCA									;Take lower bit… "1" Carry for not used, "0" Not carry if it's used
			JR C,LastBitActive						;if we find a bit in "1" is because is not used so exit (bit with 0 are always consecutive)
			INC C									;Count 1 group of 16 bytes used
BitIs1:							
			DJNZ Loop8								;Repeat upto 8 bits
			INC L									;Next address, only low byte is required as range is #2000-#201F		
			;LD A,L
			;CP #10									;Finish when arriving address #2010 (last valid address is #200F)		<-Not required as #2010 always have #FF
			JR NZ,Loop32							;Repeat while in zone #2000-#201F and still getting bit with "0" value
LastBitActive:
			LD A,C
			CP #7F									;Finish when we saved #7f (127) times
			JR NZ,SaveZone							;No arriving to address #2010 is sign of we did not use all the saves (we have 127)
							
;Here for erase sector (we used all saves - 127)
EraseSecExe:
			CALL EraseSectorRegE					;Erase sector as per E value 0..127	
							
;Here for initial saving							
AfterErase:							
			LD C,%11111110							;So will write 1 bit with "0", indicating fist block of 32 bytes were used		
			LD HL,#2000						
			CALL WriteValueRegE						;Write value in #2000 for sector as per E value 0..127
			LD C,1									;C=1 indicating to begin after 1 initial block of 32 bytes
			LD		B,E								;E=B=Sector (0..127)
			PUSH	BC								;Saving C for using later-on
			JR		AfterWriteLocByte				;Skip writing Loc byte
;C says how much blocks of 32 bytes have been used (so next will be used this time). Value 1..127
;	HL Points to last address in which "spare" bit was found (first bit with "1")				
;So go to write LocByte
SaveZone:
			LD		B,E								;E=B=Sector (0..127)
			PUSH	BC								;Saving C for using later-on
			AND		A								;Clear carry
			LD		A,(HL)							;Get current value
			RLA										;Insert a "0" from right
			LD		C,A
			CALL WriteValueRegE						;Write value in #20xx for sector as per E value 0..127		
			POP		BC								;Restore B sector, C value (LocByte)
			PUSH	BC								;Save B sector, C value (LocByte)
			INC		C								;C=C+1 so this block is the next saved
;Now write the own data in the correct address as per last LocByte
AfterWriteLocByte:

			LD		L,C								;C=Number of block saved up to now
			LD		H,0
			ADD		HL,HL							;*2
			ADD		HL,HL							;*4
			ADD		HL,HL							;*8
			ADD		HL,HL							;*16
			ADD		HL,HL							;*32
			LD		BC,#2000
			ADD		HL,BC							;Calculated address where to save data

			LD		(PAYLOAD_addr),HL				;Store used address in sector

			POP		BC								;Restore B sector, C value (LocByte)

			LD		C,EndLastRoutine-LastINT; #20							;upto 32 bytes to save... using only the bytes required

			LD		DE,LastINT						;Position for writing data

LoopWriteBytes:
			PUSH	BC
			LD		A,(DE)
			LD		C,A
			INC		DE
			PUSH	DE								;Save DE=Adress

			LD		E,B
			CALL	WriteValueRegE					;HL=Addr in sector, E=sector (0..127), C=value to write

			INC		HL
			POP		DE								;Restore DE=Adress
			POP		BC
			DEC		C
			JR		NZ,LoopWriteBytes

			RET

;------------------------------------------------------------------------------------
; NEXT ROUTINES WILL EXECUTE FROM RAM---- NEVER USE FROM SLOT AS IT WILL HANG SPECCY
;------------------------------------------------------------------------------------
SECROUTINES:
			DISP	RAMSECTOR
;------------------------------------------------------------------------------------
; Customized routines for ERASE SECTOR and PROGRAM BYTE

;EraseSectorRegE - Erase sector in EEPROM
;	IN E=Sector (0..127) to erase
;
;	OUT E=Sector (0..127) erased
;	HL, A and B are used internally
EraseSectorRegE:

			LD B,48									; Special Command 48, External eeprom operations			
			DAN_BIG_COMMAND_NOWAIT #10, E			;Data1= #10=16 Sector Erase, Data2= E =Sector to erase (0..127)

			LD		HL,ScratchSECT					;Always is the same address, we use only the correspondent sector to it
			;CALL	LaunchSECTOR_ERASE

; LaunchSECTOR_ERASE. Send commands to EEPROM with the little help of PIC for the address #5555
;		- HL= Address of zone in sector to erase (#0000-#3FFF)
LaunchSECTOR_ERASE:			
			LD	(0),A
			WAIT_B PAUSELOOPSN
			
;SE_Step1:
			LD A, $AA
			LD (J5555),A			
;SE_Step2:
			RRCA						;LD A, $55	; replaced as $AA >> is $55
			LD (J2AAA),A	
;SE_Step3:
			LD A, $80
			LD (J5555),A
;SE_Step4:
			LD A, $AA
			LD (J5555),A
;SE_Step5:
			RRCA						;LD A, $55	; replaced as $AA >> is $55
			LD (J2AAA),A
;SE_Step6:
			LD A, $30					; Actual sector erase		
			LD (HL),A					; First Address of zone in sector to erase

		;After sending JEDEC command Erase sector we use Toggle bit to finish (see SST39SF040 datasheet, time is around 18ms)
		;					Toggle bit is reading value in sector... when 2 reads return the same value then Erase have finished
LaunchSECTOR_ERASE_loop:
			LD		A,(HL)				; 7 Ts
			CP		(HL)				; 7 Ts
			JR		NZ, LaunchSECTOR_ERASE_loop ; 12 Ts for repeat.... total is 26Ts (around 7.43us -miminal is 70ns so we're safe-... it will loop over for around 2423 times !!!)

			; Finally return to correct slot.
LaunchRet_Slot:
			LD		A,(LAUNCH_MyCurMLD)		;That 1 change dinamically as per real Slot to return to
			LD		B,A
			SLOT_B
			WAIT_B	PAUSELOOPSN
			RET


;WriteValueRegE - Write some bytes in sector in EEPROM
;	IN E  =Sector (0..127) to write to
;	IN HL = Address in sector to write to
;	IN C  =Vaue to write in the byte
WriteValueRegE:
			LD B,48									; Special Command 48, External eeprom operations			
			DAN_BIG_COMMAND_NOWAIT #01, E			;Data1= #01=01 Sector Program a byte, Data2= E =Sector to erase (0..127)

			;CALL	SECTOR_WRITE1BYTE

; SECTOR_WRITE1BYTE. Send commands to EEPROM with the little help of PIC for the address #5555
;	IN HL = Address in sector to write to
;	IN C  = Byte to write
SECTOR_WRITE1BYTE:
			LD	(0),A
			WAIT_B PAUSELOOPSN

;Write the data in sector
;SECTLP:												; Sector Loop C times
			LD		A,$AA							;Value to store			(7Ts) - time btw writes is 73Ts (>20.85us) so it's into SST39SF040 specs
			LD		(J5555),A
;PB_Step2:
			RRCA									;LD A, $55	; replaced as $AA >> is $55
			LD		(J2AAA),A
;PB_Step3:
			LD		A,$A0
			LD		(J5555),A	
;PB_Step4:
			LD		A,C								; Value to Write
			LD		(HL),A							; Write it in the address
												; Datasheet tell us 20us max write time
			JR		LaunchRet_Slot						;Return to caller MLD slot... it takes longer than 20us so no worry about EEP writing byte max time
						
;------------------------------------------------------------------------------------
; LOCAL VARIABLES IN RAM USED ONLY FOR SECTOR ROUTINES
LAUNCH_MyCurMLD	defb	0								;Will hold num or slot into EEP (value 0..31)
PAYLOAD_addr	defw	0								;Address for last routine (#2020-#2FF0)

;------------------------------------------------------------------------------------
; END OF ROUTINES FROM RAM---- NEVER USE FROM SLOT AS IT WILL HANG SPECCY
;------------------------------------------------------------------------------------
ENDRAMSECTOR:
			ENT
ENDSECROUTINES:
;------------------------------------------------------------------------------------


