;Mult_eewriter.asm
; Routines for writing to eeprom from Multiply

J5555			EQU $1555				; Jedec $5555 with a15,a14=0 to force rom write (PIC will set page 1 so final address will be $5555)
J2AAA			EQU	$2AAA				; Jedec $2AAA, Pic will select page 0

			DI
			LD SP,$0000					; Set Stack to Ramtop
						
			PUSH	HL					;Save address of filename
	
			XOR A
			OUT ($FE),A

			LD		HL,eew_scr
			LD		DE,#4000
			CALL	dzx7_turbo

			LD HL, ROMROUTINE
			LD DE, RAMROUTINE
			LD BC, ENDROMROUTINE-ROMROUTINE
			LDIR
			LD HL,Load4bitBlk
			;LD DE,ENDROMROUTINE
			LD	BC,EndLoad4bitBlk-Load4bitBlk
			LDIR
			JP CHECKROMOK
			
ROMROUTINE:			
	DISP #F000
RAMROUTINE:			
TOSBOMB:	LD A, $47					; Bright White on paper 0
			LD B, 6						; 6 chars in TOSBOMB Graphic 
			LD IX, TBPOS
			LD HL, $4000+$1800			; Attributes on Screen for TOSBOMB
			LD D,0
PAINTTB:	LD E, (IX)					; Get offset
			ADD HL,DE					; Move HL to Attr position
			LD (HL),A					; Change TOSBOMB Color
			INC IX						; Next icon offset
			DJNZ PAINTTB				; Loop
			LD A,%01000110				; Wick Bright yellow
TBDLOCK:	
			LD (TOSBOMBATTR),A			; Change attribute to A colour
			LD BC,64
WAIT50ms:
			DJNZ WAIT50ms
			DEC C
			JR NZ,WAIT50ms
			XOR %00000100				; alternate yellow (110) with red (010)
			JR TBDLOCK					; Deadlock		
TBPOS:		DEFB	$41,$1,$1F,$1,$1,$1F; TOSBOMB attr relative position			
TOSBOMBATTR		equ		$5800+(2*32)+1	; Attribute of bomb's wick


CHECKROMOK:								; Dandanator was detected and it's now ready to receive 
			;LD HL,1						; Select slot 0 and set it as reset slot
			
			LD B,1						;LD A,1	- Set slot 1 (required any EEP slot for correct programming)
			SENDNRCMD_B PAUSELOOPSN		;CALL SENDNRCMD

			LD B,39						;LD A,39	- CMD_SET_RESETSLOT - Set Reset Slot. Current Slot is selected in case of an Spectrum-Triggered Reset.
			SENDNRCMD_B PAUSELOOPSN		;CALL SENDNRCMD
			
			LD A,1
			LD (NBLOCK),A

			;LD A,CMD_ZX2SD_OFREAD

			;POP	HL						; address of filename
			POP	IX						; address of filename

			;LD HL, romset
			;CALL	RAMReqFileA			;	CALL ReqFileA
			
			LD		A,CMD_ZX2SD_OFREAD_IX				;Command = Open File (Relative Path)
			CALL	RAMSendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+32)							;1st byte of index
			CALL	RAMSendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+33)							;2nd byte of index
			CALL	RAMSendSerByteLC					;Command to ask for more info about file
			
BUC:
			LD A,(NBLOCK)
			CALL DISPADVANCE			;Show advance arrow
			LD A,(NBLOCK)
			CALL DISPDIGIT				; Show number of block processing (1..16)
			DEC A						; A=0..15
			ADD A,A						;A*2
			ADD A,A						;A*4
			ADD A,A						;A*8
			LD C,1						; 1 = LOADING, A = N.SECTOR
			LD B,8
BUCLOAD8:
			CALL DISPBAR				; DISPBAR returns with A=SECTOR Num (BC returns untouched PUSH-POP)
			INC A
			DJNZ BUCLOAD8
			
			
			LD A, CMD_ZX2SD_ROMSETBLK4B			; Command of request SD block
			OUT (#FE),A
		    CALL RAMSendSerByteLC		;CALL SendSerByteLC
			LD A,(NBLOCK)
			CALL RAMSendSerByte			;CALL SendSerByte			; Request Serial Block

			LD  A,1
			OUT (#FE),A

			LD HL,loadarea				; Destination of data 
			LD DE,loadsize				; Length of data (+1 for slot number + 2 for crc)
LOADSERIAL:	CALL RAMLoad4bitBlk ;Load4bitBlk ;LoadSerBlk				; Load block using Serial Kempston

AFTER_LOAD:	LD HL,loadarea+loadsize-3	; Address of number of slot from file
			LD A,(NBLOCK)				; number of 16k slot to write to eeprom (1-32)
			CP (HL)						; check if slot loaded is correct
			JR NZ,LOADERR				; If not the correct slot Show TOSBOMB

			ld de,loadarea				; DE=Begining of loaded area
			ld hl,0						; HL will have the sum
			ld bc,$8001					; $8000 + 1 (length of area and n.slot byte)
bucCRC:
			ld a,(de)
			add	a,l
			ld l,a
			jr nc,bucNOCarry
			inc h						; Include Carry if existing
bucNOCarry:
			inc de
			dec bc
			ld a,b
			or c
			jr nz,bucCRC
			
			ld ix,de
			ld de,(ix)					; Load DE with CRC from file

			;or a						; clear carry flag - not needed as previous "or c" reset carry flag
			sbc hl,de					; substract computed CRC
			jr z, ALLGOOD				; ok, continue with burning
LOADERR:	JP TOSBOMB					; Show Bomb and deadlock if CRC no ok
			
ALLGOOD:
			XOR A
			OUT (#FE),A
			LD HL,loadarea				; First address is scratch area
			CALL	PROGRAMSECTOR		; Erase and then burn 8 4k eeprom Sectors
			LD A,(NBLOCK)
			INC A
			LD (NBLOCK),A
			CP 17						
			JP C,BUC					; Cycle all 16 Blocks
			
ENDEND:
			RST 0
			;JP DDNTRRESET				; Enable Dandanator and jumpt to menu

NBLOCK:		DEFB 0x00					; Reserve space for var 

;------------------------------------------------------------------------------
; VARS
;------------------------------------------------------------------------------
loadsize		equ		$8003			; Length of data loaded = 32kbyte data + 1 byte + 2 bytes crc
loadarea		equ		$6F00-3			; Destination of load data (aligned to EF00 when done)
TXTSLOTCOUNTER	equ 	$5800+(8*32)+8	; Position of Slot Counter
TXTSECTCOUNTER	equ 	$5800+(18*32)+8	; Position of Slot Counter
				
;------------------------------------------------------------------------------
;PROGRAMSECTOR - 
; (NBLOCK) = Number of slot (1..16)
; HL = Address of data (32k = 8 sectors x 4K)
; C will be counting from 0 to 7
; Number in screen will be 1 to 8
; Combining (NBLOCK) and C will have the sector in range 0..127 stored in B register
; B will be copied to A prior to calling SECTOR_ERASE (old SSTSECERASE) and SECTOR_PROGRAM (old SSTSECTPROG)
; HL will begin with the address of first 4K sector and incremented 4k by 4k prior to calling SSTSECTPROG
;------------------------------------------------------------------------------
PROGRAMSECTOR:
			;PUSH HL						; Page in External eeprom -> Needed for programming
			;LD A,1
			;LD HL,1
			;CALL SENDNRCMD 
			;POP HL
			LD C,0						; N.of sector in this programming area (0..7)
BUCPROGRAMSECTOR:
			PUSH HL						; Save Initial address
			LD A,(NBLOCK)				; N.slot (1..16), need to convert in sector (*8)
			DEC A						; Convert to 0..15
			ADD A,A						; *2
			ADD A,A						; *4
			ADD A,A						; *8
			ADD C						; Add sector subnumber(0..7) to acummulator A
			LD B,A						; Copy Sector (0-127) from A to B for next usage
			PUSH BC						; Save copy of B and C

			LD C,2						; 2 = WRITING, A = N.SECTOR
			CALL DISPBAR				; DISPBAR returns with A=N.SECTOR

			POP BC						; We need B=sector (0-127)
			PUSH BC						; Save copy of B and C
			
			
			CALL SECTOR_ERASE			; Using B=sector (0..127)
			POP BC						; Retrieve copy of B and C
			POP HL						; Recuperate Address of data
			PUSH HL						; Save this Address of data (4 of 32k)
			PUSH BC						; Save copy of B and C

			CALL SECTOR_PROGRAM			;Using only C value (0..7) with that it calculate correct sector address for programming
			POP BC						; Retrieve copy of B and C (only C is needed this time, B is n.sector 0..127)
			PUSH BC						; Save copy of B and C
			LD A,B						; A = N.Sector
			LD C,3						; 3 = FINISHED, A = N.SECTOR
			CALL DISPBAR				; DISPBAR returns with A=N.SECTOR

			POP BC						; Retrieve copy of B and C (only C is needed this time, B is discarded now)
			POP HL						; Recuperate Address of data

			LD DE,$1000					; Lenght of sectors = 4Kbyte = 1024*4 = 4096 = $1000
			ADD HL,DE					; Calculate next address
			INC C						; Next subsector 0..7
			LD A,C						; Copy the value of this sector to acumulator A
			CP 8						; Check A<8 (only 0..7 is valid)
			JR C,BUCPROGRAMSECTOR		; REPEAT WHILE subsector<8
			
			RET



; ----------------------------------------------------------------------------------------
; Send special command with long confirmation
; ----------------------------------------------------------------------------------------
;SENDSPCMDLC: CALL SENDSPCMD
;			 CALL LONGSPCONF
;			 RET
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Confirm Special Command and wait some ms ( > 5ms that PIC eeprom write operations require)
; ----------------------------------------------------------------------------------------
;LONGSPCONF:	LD (0),A		; Signal Dandanator the command confirmation (any A value for ZESARUX)
;			LD B,0					
;PAUSELCONF:	EX (SP),HL
;			EX (SP),HL
;			EX (SP),HL
;			EX (SP),HL
;			DJNZ PAUSELCONF
;			RET
; ----------------------------------------------------------------------------------------

cursector:
		DEFB	0

			include "resources/digits_v1.asm"
	
;			include "sstwriter_romset_6.5MODED.ASM"
;RAM Routines for dealing with Erasing and Writing Dandanator's EEPROM			
;   This routine is relocatable and have to be in RAM (can't be called from EEPROM-will hang the speccy)

; SECTOR_ERASE
;	IN - B=value 0..127 for sector to erase	
;		 with that we calculte DE= Address of zone in sector to erase (#0000-#3FFF)
SECTOR_ERASE:
			CALL ADDR_SECTOR			;With B=0..127 returns DE=Address in sector (#0000,#1000,#2000,#3000)

			LD A,B						;B=sector number 0..127
			DAN_BIG_COMMAND 48, 16, A	;Command 48, Data 1=16, Data 2=sector number
			WAIT_B PAUSELOOPSN
			
SE_Step1:	LD A, $AA
			LD (J5555),A			
SE_Step2:	RRCA						;LD A, $55	; replaced as $AA >> is $55
			LD (J2AAA),A	
SE_Step3:	LD A, $80
			LD (J5555),A
SE_Step4:	LD A, $AA
			LD (J5555),A
SE_Step5:	RRCA						;LD A, $55	; replaced as $AA >> is $55
			LD (J2AAA),A
SE_Step6:	LD A, $30					; Actual sector erase		
			LD (DE),A					; First Address of zone in sector to erase

		IFDEF OldWriteSST
			LD BC,1400					; wait over 25 ms for Sector erase to complete (datasheet pag 13) -> 1400*18us= 25,2 ms
WAITSEC:								; Loop ts = 64ts -> aprox 18us on 128k machines
			EX (SP),HL					; 19ts
			EX (SP),HL					; 19ts
			DEC BC						; 6ts
			LD A,B						; 4ts
			OR C						; 4ts
			JR NZ, WAITSEC				; 12ts / 7ts		
		ELSE
SECTOR_ERASE_loop:						;This new wait routine use the toggle bit of EEPROM (see SST39SF040 datasheet)
			LD A,(DE)
			LD H,A
			LD A,(DE)
			CP H						;toggle bit of EEPROM return alternate values for each reading when it's Erasing
			JR NZ, SECTOR_ERASE_loop
			; Finally return to correct slot.
		ENDIF
Ret_Slot:
			LD B,1
			SENDNRCMD_B	PAUSELOOPSN		;Assure we're in 1 slot (required for writing)
			RET

;Prepare sector for programming
;	HL=ORIGIN OF DATA
;		- B=0..127 sector to program, with that calculate DE= Address of zone to program (#0000,#1000,#2000,#3000)
;		- Length to write is always #4000
SECTOR_PROGRAM:
			CALL ADDR_SECTOR			;With B=0..127 return DE=Address in sector (#0000,#1000,#2000,#3000)
			LD A,B						;B=sector number 0..127
			DAN_BIG_COMMAND 48, 32, A	;Command 48, Data 1=16, Data 2=sector number
			WAIT_B PAUSELOOPSN

;Write the data in sector
SECTLP:									; Sector Loop BC times
			LD A, $AA
			LD (J5555),A
PB_Step2: 	RRCA						;LD A, $55	; replaced as $AA >> is $55
			LD (J2AAA),A
PB_Step3: 	LD A, $A0
			LD (J5555),A	
PB_Step4:	LD A,(HL)					; Write actual byte
			LD (DE),A
										; Datasheet asks for 14us write time, but loop takes longer between actual writes
			INC HL						; Next Data byte
			INC DE						; Next Byte in sector
			LD A,D						; Check for 4096 iterations (D=0x_0, E=0x00)
			AND 15						; Get 4 lower bits
			OR E						; Now also check for a 0x00 in E
			JR NZ, SECTLP

			JR Ret_Slot 				;Be sure slot 1 is active and return to caller

;ADDR_SECTOR - With C=0..7 
;	IN B - Number 0..127 (value for sector)
;  OUT DE=Address in sector (#0000,#1000,#2000,#3000)
;  OUT  A=scratch value #00,#10,#20,#30
ADDR_SECTOR:
			LD A,B
			AND 3									;We have value #00,#01,#02,#03
			ADD A,A									;*2
			ADD A,A									;*4
			ADD A,A									;*8
			ADD A,A									;*16	so we have value #00, #10, #20, #30
			LD D,A
			LD E,0									;DE=address of zone in sector to erase #0000-#3FFF
			RET
LastRAMRoutine:
	ENT
ENDROMROUTINE:
RAMLoad4bitBlk	EQU	LastRAMRoutine					;Load4bitBlk will be copy in ENDROMROUTINE address
;RAMReqFileA		EQU	RAMLoad4bitBlk+(ReqFileA-Load4bitBlk)	;Equivalent address	; DISABLED AS IT'S NOT USED
RAMSendSerByteLC EQU RAMLoad4bitBlk+(SendSerByteLC-Load4bitBlk)	;Equivalent address
RAMSendSerByte EQU RAMLoad4bitBlk+(SendSerByte-Load4bitBlk)	;Equivalent address
eew_scr:
		incbin "resources/romsetwriter_v1.scr.zx7"
