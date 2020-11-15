
		DEFINE NEWVERS			;Comment for Old Load4bitBlk version, uncomment for NEW version

	
;------------------------------------------------------------------------------------------------------------------------
; Load 4bits block of data at address specified by HL, DE contains size
;  IN HL:Beginning address to store data
;  IN DE:Length of data to read
;
;	OUT HL:Beging address + Length
;	OUT DE:0
;	OUT A:0
;	OUT Flags modified... Z=activated always
;------------------------------------------------------------------------------------------------------------------------
;Here for waiting a "1" to start / process next bit
	IFDEF NEWVERS
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
		RET								;Return with Z active
		
	ELSE
Load4bitBlk:
		DEC HL
trans_1:
		IN    A,(#1F)          ; 11 Ts = 3,142857143 uS    %XXX3210F
		RRCA               ;  4 Ts = 1,142857143 uS  F goes to carry  %XXXX3210
		JR NC,trans_1           ; 12 Ts = 3,428571429 uS (if met) // 7 Ts = 2 uS (not met)
		.4 RRCA               ; 12 Ts = 3,428571429 uS    %3210FXXX
		AND #F0              ;  7 Ts = 2           uS  %3210____
		LD    B,A            ;  4 Ts = 1,142857143 uS  %3210____
		INC HL               ;  6 Ts = 1,714285714 uS
		DEC DE              ;  6 Ts = 1,714285714 uS

;Here for waiting a "0" to process next bit
trans_0:
		IN     A,(#1F)         ; 11 Ts = 3,142857143 uS    %XXX3210F
		RRCA               ;  4 Ts = 1,142857143 uS  %____3210
		JR C,trans_0           ; 12 Ts = 3,428571429 uS (if met) // 7 Ts = 2 uS (not met)
		AND    #0F            ;  7 Ts = 2           uS  %____3210
		OR    B            ;  4 Ts = 1,142857143 uS
		LD (HL),A            ;  7 Ts = 2           uS   Final value
		LD A,D               ;  4 Ts = 1,142857143 uS
		OR E               ;  4 Ts = 1,142857143 uS
		JR NZ,trans_1           ; 12 Ts = 3,428571429 uS (if met) // 7 Ts = 2 uS (not met)
  
		RET
	ENDIF
;------------------------------------------------------------------------------------------------------------------------

	IF	(1=0)		;ROUTINE DISABLED, NOT USED
;------------------------------------------------------------------------------------------------------------------------
; Request a file Name pointed by HL. Must end in 0
;	IN - HL : Pointer to Name of file or Data to pass to command
;	IN - A : command for requesting file
;
;	OUT - HL : Next position after filename, (the address of the #00 after the text)
;	OUT - A : #00
;	OUT - Flags modified, Z=1 always
;
;------------------------------------------------------------------------------------------------------------------------
ReqFileA:
		DAN_BIG_COMMAND_NOW DANCMD_MULTIPLY, DANDAT_MULTIPLY, A
		PAUSE_LONG
		AND		A
		RET		Z
		LD		A,(HL)
		INC		HL
        JR      ReqFileA
	ENDIF			;ROUTINE DISABLED, NOT USED

;------------------------------------------------------------------------------------------------------------------------


;------------------------------------------------------------------------------------------------------------------------
; Send a Serial Byte contained in A, with Long Confirmation. (Command DANCMD_MULTIPLY,DANDAT_MULTIPLY,A)
;	IN - A : Value to send to serial
;
;	OUT - B: 0
;	OUT - A: same value as input
;	Flags are not affected, same value as input
;	Equivalent to SENDSPCMDLC
;------------------------------------------------------------------------------------------------------------------------
SendSerByteLC:
;        LD      E,A
;        LD      A,DANCMD_MULTIPLY
;        LD      D,DANDAT_MULTIPLY
;        JP		SENDSPCMDLC
		DAN_BIG_COMMAND_NOW DANCMD_MULTIPLY, DANDAT_MULTIPLY, A
		PAUSE_LONG
		RET 
		
;------------------------------------------------------------------------------------------------------------------------
; Send a Serial Byte contained in A with Short Confirmation. (Command DANCMD_MULTIPLY,DANDAT_MULTIPLY,A)
;	IN - A : Value to send to serial
;
;	OUT - B: 0
;	OUT - A: same value as input
;	Flags are not affected, same value as input
;
; ---- This is equivalente to CALL SENDSPCMD with A=DANCMD_MULTIPLY, D=DANDAT_MULTIPLY, E=register A
;------------------------------------------------------------------------------------------------------------------------
SendSerByte:
		DAN_BIG_COMMAND_NOW DANCMD_MULTIPLY, DANDAT_MULTIPLY, A
		RET

	IF	(1=0)		;ROUTINE DISABLED, NOT USED
;------------------------------------------------------------------------------------------------------------------------
; Common routine for send a Serial Byte contained in A, without confirmation. (Command DANCMD_MULTIPLY,DANDAT_MULTIPLY,A)
;	IN - A : Value to send to serial
;
;	OUT - B: 0
;	OUT - A: same value as input
;	Flags are not affected, same value as input
;------------------------------------------------------------------------------------------------------------------------
SendSerCMD:
		LD	B,DANCMD_MULTIPLY
		SLOT_B
		WAIT_B PAUSELOOPSN
		LD  B,DANDAT_MULTIPLY
		SLOT_B
		WAIT_B PAUSELOOPSN
		LD  B,A
;		JR SendCMD_B	;not required as SendCMD_B is just next address


;------------------------------------------------------------------------------------------------------------------------
; Send command using only B register and don't affects to Flags
;	IN - B : Value to send as command or data to Dandanator
;	OUT - B : 0
;------------------------------------------------------------------------------------------------------------------------
SendCMD_B:
		SLOT_B
		WAIT_B PAUSELOOPSN
		RET

;------------------------------------------------------------------------------------------------------------------------
	ENDIF				;ROUTINE DISABLED, NOT USED
	
EndLoad4bitBlk:

