;CheckHardware
CheckHardware:
			CALL	GetMultiplyVer

		;Now check if we're in 48 or 128k spectrum (16k is not allowed)
			LD		A,4
   			LD		BC,#1FFD
			OUT		(C),A
			XOR		A
			LD		HL,CHK_48K_VAR
   			LD		B,#7F							;LD BC,7FFDh
			OUT		(C),A							;Bank 0
			LD		A,3								;A=8
			LD		(HL),A							;3 in Bank 0
			LD		A,2								;A=2
			OUT		(C),A							;Bank 2
			LD		(HL),A							;2 in Bank 2
			LD		A,#10
			OUT		(C),A							;Return to Bank 0
			LD		A,(HL)							; A=2 (48k) / A=3 (128k) / A=#FF or maybe any other (16k)
			CP		2								; A will be 2 if no RAM Page ocuurs (48k)
			JR		Z,CheckHardware_Set				;A=2 so it's 48k
			CP		3								; A will be 3 if RAM Page was success (128k)
			JR		Z,CheckHardware_Set				;A=3 so it's 128k
			LD		A,1								; A=1 (16k)
CheckHardware_Set:

			LD		D,A								;D=Hw model (1,2,3)
			LD		A,CMD_ZX2SD_SETZXTYPE
			CALL	SendSerByteLC					;Send Command
			LD		A,D
			JP		SendSerByteLC					;Send Data (and return from there)
