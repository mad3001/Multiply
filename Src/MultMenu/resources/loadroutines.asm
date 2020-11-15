;Load routines per file type


;Load_FT_SCR - Load a screen (show it and return to directory after pressed a key)
Load_FT_SCR:
			;DI
			
			XOR		A
			OUT		(#FE),A
			
			LD		A,(PreviewStat)
			CP		PreviewSHOWING
			JR		NZ,FullLoad

			CALL	Swap_Screen						;We have it loaded so no need to load again
			JR		WaitNKey1st
			
FullLoad:
			LD		A,PreviewSHOWING
			LD		(PreviewStat),A					;As will be loaded, it can be used
			PUSH	HL
			LD		HL,#4000
			LD		DE,ScreensSCR					;Address for saving the current screen (Multiply menu with directory..etc...
			LD		BC,#1B00
			LDIR									;Save screen for later on
			DEC		HL
			LD		D,H
			LD		E,L
			DEC		DE
			LD		(HL),0
			LD		BC,#300-1
			LDDR									;Clear attributes

			POP		IX					;IX=file struct
			;LD HL, FileSNA				; Request Arduino to open the file

			;CALL ReqFileA							;Request to open the file..using command as per register A
			LD		A,CMD_ZX2SD_OFREAD_IX				;Command = Open File (Relative Path)
			CALL	SendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+FILEINDEX)				;Low byte of index
			CALL	SendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+FILEINDEX+1)				;High byte of index
			CALL	SendSerByteLC					;Command to ask for more info about file
			;PAUSE_LONG
		;Send command  to arduino asking for SNA data
			LD		HL,#4000						; Destination of data
			LD		DE,6912							; Length of data (screen)
			LD		A,CMD_ZX2SD_SCR					;c=CMD_ZX2SD_SCR so command is get screen
			LD		C,0								;Additional parameter is to load "full screen" Par:0x00

			CALL	LoadBlockDirect1Par				;Load Screen

;Now wait for joy released or key released
WaitNKey1st:
			IN		A,(#1F)
			AND		%00011111
			AND		A
			JR		NZ,WaitNKey1st					;A=0 for no joy moved

WaitN2Key1st:
			XOR		A
			IN		A,(#FE)
			OR		%11100000						;Isolate keys
			INC		A								;A=0 for no key pressed
			JR		NZ,WaitN2Key1st
			
;Now wait for joy moved or key pressed
WaitKey:
			IN		A,(#1F)
			AND		%00011111
			AND		A								;A=0 for no joy moved
			JR		NZ,WaitNKey						;If joy moved then jump to check joy not moved
			XOR		A
			IN		A,(#FE)
			OR		%11100000						;Isolate keys
			INC		A								;A=0 for no key pressed
			JR		NZ,WaitNKey						;If key pressed then jump to check key released
			JR		WaitKey
			
;Now wait for joy released or key released
WaitNKey:
			IN		A,(#1F)
			AND		%00011111
			AND		A
			JR		NZ,WaitNKey						;A=0 for no joy moved
			;JR		Load_FT_SCR_END
WaitN2Key:
			XOR		A
			IN		A,(#FE)
			OR		%11100000						;Isolate keys
			INC		A								;A=0 for no key pressed
			JR		NZ,WaitN2Key
			
Load_FT_SCR_END:
			LD		A,BorderMenu
			OUT		(#FE),A

			CALL	Swap_Screen

			JP		MenuWaitChange					;Contine where we were
			
Swap_Screen:
			LD		HL,ScreensSCR
			LD		DE,#4000
			LD		BC,#1B00
Swapping:
			LD		A,(DE)
			LDI
			DEC		HL
			LD		(HL),A
			INC		HL
			LD		A,B
			OR		C
			JR		NZ,Swapping
			RET	
			