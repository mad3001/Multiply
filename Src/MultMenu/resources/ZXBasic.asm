;Lauch ZX Basic

		LD		HL,BasicROM
		LD		DE,ScratchRAM
		LD		BC,ENDBasicROM-BasicROM
		PUSH	DE
		LDIR
		RET
		
BasicROM:
		DISP	ScratchRAM
		
		XOR 	A
		LD		BC,#1FFD
		OUT		(C),A			;If Spectrum type Amstrad (+2A/+2B/+3) then be sure paged #1FFD=0 (as per initial reset)
		LD		B,#7F			;BC=#7FFD
		OUT		(C),A			;be sure paged #7FFD=0 (as per initial reset)
		LD		B,34			;locked internal spectrum rom
		SLOT_B
		WAIT_B	PAUSELOOPSN
		RST 	#0				;Jump to address 0 (so launch basic... 48 or 128 as per model)
		
		ENT
ENDBasicROM: