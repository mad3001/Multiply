;setbuttons - Setting buttons
DisableButtons:
		;change default buttons set by Dandanator main slot 1


			LD		B,41
			LD		L,0								;0=Standard Launch (normal boot)
			LD		A,(MLDoffset)					;MLDoffset is bank of Multiply (0..31)
			INC		A								;Change to 1..32
			LD		H,A
			CALL	SENDSPCMDLC


			LD		B,49
			LD		L,#01							;Allow receiving commands on boot
			CALL	SENDSPCMDLC

			LD		B,39							;Single command for asign reset to current slot
			CALL    SENDNRCMD						;Send command and return from there
					
			LD		B,43							;Sw 2 behaviour
			LD		L,#07							;Enable as select ROM n + Reset + Enable & Unlock Commands
			CALL	SENDSPCMDLC

			LD		B,42
			LD		HL,#0100						;Disable pause/dansnap in Multiply Menu
			JP		SENDSPCMDLC						;Execute and return from there


;Launch set left button
ReenableButtons:	
			LD		A,(DanSnap_Val)					;Pause / Dansnap slot (valid 2-32)
			CP		2
			RET		C								;Value below 2 is not valid, return
			CP		33
			RET		NC								;Value over 32 is not valid
ReenableButtonsA:
			LD		B,42							;Command Change button behaviour
			LD		H,A								;Data 1, bank of Pause / Dansnap
			LD		L,2								;bits 0..2= 2 => Enable as ROM n + NMI + Enable Commands, bits 3..4=0 Short Click
			JP		SENDSPCMDLC
