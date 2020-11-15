
		;MACRO SLOT_B
		;    Send Dandanator command
		;		IN	- B	: B=Command/Data
		;		All pulses go to address 0
		;		Destroys B (return with B=0), Flags are not affected
		; NOTE: 0 is signaled by 256 pulses.
		;	Equivalent to SENDNRCMD without pause btw commands
		MACRO SLOT_B
.slot_b		INC HL
			DEC HL
			LD (0),A
			DJNZ .slot_b
		ENDM

		;MACRO WAIT_B_EXT. Reduced version (3 bytes) waiting the B value (loaded prior to call this)
		;		Destroys B (return with B=0), Flags are not affected
		
		MACRO WAIT_B_EXT
.wait_b0	DJNZ .wait_b0
		ENDM

		;MACRO WAIT_B value
		;		IN - time value
		;		Destroys B (return with B=0), Flags are not affected
		
		MACRO WAIT_B value
			LD B,value
			WAIT_B_EXT
		ENDM

		;MACRO SENDNRCMD_B
		;    Send Dandanator command
		;		IN	- B	: B=Command/Data
		;		All pulses go to address 0
		;		Destroys B (return with B=0), Flags are not affected
		; NOTE: 0 is signaled by 256 pulses.
		;	Equivalent to SENDNRCMD with pause as per value
		MACRO SENDNRCMD_B value
			SLOT_B
			WAIT_B value			
		ENDM
		
		;DAN_BIG_COMMAND_NOWAIT
		; ---- This is equivalente to CALL SENDSPCMD with A=DANCMD_MULTIPLY, D=DANDAT_MULTIPLY, E=register A
		; 			but it does not send the confirmation pulse
		;	IN - B = Command to send
		;	IN - Values passed for Data 1 and Data 2
		; OUT - Destroys B (return with B=0), Flags are not affected
		MACRO DAN_BIG_COMMAND_NOWAIT C2, C3
			;LD	B,C1			; Command is set externally in B reg
			SLOT_B
			WAIT_B PAUSELOOPSN			
			LD	B,C2			; Data 1
			SLOT_B
			WAIT_B PAUSELOOPSN
			LD  B,C3			; Data 2
			SLOT_B
			WAIT_B PAUSELOOPSN
		ENDM
		
		;DAN_BIG_COMMAND_NOW
		; ---- This is equivalente to CALL SENDSPCMD with A=DANCMD_MULTIPLY, D=DANDAT_MULTIPLY, E=register A
		; 			including confirmation pulse
		;	IN - As per values passed...
		; OUT - Destroys B (return with B=0), Flags are not affected
		MACRO DAN_BIG_COMMAND_NOW C1, C2, C3
			LD	B,C1			; Command
			DAN_BIG_COMMAND_NOWAIT C2, C3
			LD 	(0),A
		ENDM

		;DAN_BIG_COMMAND_NOWAIT
		; ---- This is equivalente to CALL SENDSPCMD with A=DANCMD_MULTIPLY, D=DANDAT_MULTIPLY, E=register A
		; 			but it does not send the confirmation pulse
		;	IN - As per values passed...
		; OUT - Destroys B (return with B=0), Flags are not affected
		MACRO DAN_BIG_COMMAND C1, C2, C3
			DAN_BIG_COMMAND_NOW C1, C2, C3
		ENDM


		;MACRO PAUSELONG aprox 65mS
		; Enter here with B=0, Flags are not affected, require SP value >#3FFF (if SP is #0000-#3FFF it will send pulses to dandanator)
		MACRO PAUSE_LONG
.pauselong:
			.4		EX (SP),HL
			DJNZ	.pauselong
		ENDM
		
		;MACRO PAUSE_LONGIXA aprox 65mS
		; Enter here with B=0, A and Flags are affected but don't require SP so SP can be #0000-#FFFF
		MACRO PAUSE_LONGIXA
		;Customized PAUSE_LONG without using SP but affects A and Flags
.pauselongIX:
			.4		AND (IX);			;Replace EX (SP),HL
			DJNZ	.pauselongIX
		ENDM
		