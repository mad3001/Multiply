;dandanator_hw_90 - Reduced versions of dandanator commands
;	using B for drift
;	using only HL as parameters
;	no other register is modified, Flags also not modified
; ----------------------------------------------------------------------------------------
; Send special command with long confirmation
; ----------------------------------------------------------------------------------------
SENDSPCMDLC: CALL SENDSPCMD
			 ;CALL LONGSPCONF
			 ;RET

; ----------------------------------------------------------------------------------------
; Confirm Special Command and wait some ms ( > 5ms that PIC eeprom write operations require)
; ----------------------------------------------------------------------------------------
LONGSPCONF:	LD (0),A			; Signal Dandanator the command confirmation
			LD B,0					
PAUSELCONF:	EX (SP),HL
			EX (SP),HL
			EX (SP),HL
			EX (SP),HL
			DJNZ PAUSELCONF
			RET
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Send Special Command to Dandanator - Sends Command (a), Data 1 (d) and Data 2 (e)- Prepare for Pulse
; Destroys HL, B.
; ----------------------------------------------------------------------------------------
SENDSPCMD:	
			CALL SENDNRCMD				; Send command 	
			LD B,H						; Data 1
			CALL SENDNRCMD				; Send Data 1
			LD B,L						; Data 2
			;CALL SENDNRCMD				; Send Data 2
			;RET							; Now about 512us to confirm command with a pulse to DDNTRADDRCONF
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Send Normal Command to Dandanator - Sends Command/Data
;     B  = Cmd/Data, H = Data 1, L = Data 2 
; 	  Only touch B register (return with B=0). Flags unaffected
; NOTE: 0 is signaled by 256 pulses
; ----------------------------------------------------------------------------------------
SENDNRCMD:	
.slot_b		INC HL
			DEC HL
			LD (0),A
			DJNZ .slot_b
			
			LD B, PAUSELOOPSN
.loop_b:	DJNZ .loop_b
			RET							; Will still take some time to perform actual slot change
; ----------------------------------------------------------------------------------------

