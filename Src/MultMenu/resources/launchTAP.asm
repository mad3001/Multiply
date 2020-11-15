;Launch_TAP routines for Multiply v1

;27-May-2020 Mad3001

Launch_TAP:

			LD		A,L
			LD		IXL,A
			LD		A,H
			LD		IXH,A							;IX=HL
		;Request to open the file with Index (2 bytes)
			LD		A,CMD_ZX2SD_OFREAD_IX				;Command = Open File (Relative Path)
			CALL	SendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+FILEINDEX)				;Low byte of index
			CALL	SendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+FILEINDEX+1)				;High byte of index
			CALL	SendSerByteLC					;Command to ask for more info about file	

		;PREPARE CORRECT RAM PAGES FOR 128K MODELS
			LD		A,#04
			LD		BC,#1FFD
			OUT		(C),A
			LD		A,#10
			LD		BC,#7FFD
			OUT		(C),A

			LD		A,(DanSnap_Val)					;Pause / Dansnap slot (valid 2-32)... TAP only allow PAUSE, no DanSnap
			CP		2
			LD		A,2								;TAP does not allow DanSnap
			CALL	NC,ReenableButtonsA					;Reenable Left button as per Pause / DanSnap (if they exists in internal Dan EEPROM)

		;Copy next routines to RAM as we have to change slot
			LD		HL,BEGINTAP
			LD		DE,TAPRAM
			PUSH	DE
			LD		BC,ENDTAP-BEGINTAP
			LDIR
			LD		A,(MLDoffset)					;Value 0..31 (slot number in which this MLD is)
			.2		INC A							;Special Patch ROM for launch TAP is the next slot (also convert to 1..32)
			LD		B,A
			SLOT_B
			RET
			
BEGINTAP:
			DISP	ScratchRAM
TAPRAM:		

		WAIT_B		PAUSELOOPSN						;Wait for slot changed
		
		;Lock Dandanator prior to jump to Patched ROM
		DAN_BIG_COMMAND 46, 1, 1
		PAUSE_LONG
		RST	#0		;Launch patched slot (it have autoload so should load inmediatly)
			ENT
ENDTAP: