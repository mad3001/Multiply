;SD Card and files
;Different calls for dealing with Directories / Files

;ZX2SD_CD_ROOT - Return to root directory
;  IN - Nothing
;  Changes A and B, Flags are not affected
ZX2SD_CD_ROOT:
			LD		A,CMD_ZX2SD_CD_ROOT
			JP		SendSerByteLC					;Go to Root directory (return from there)
			
			
			
;Command with Index and Long Confirmation (if Carry set) or Short Confirmation (if carry reset)
;	IN - A: Command to send
;	IN - D:	Data 1
;	IN - E: Data 2
;	IN - Flags: Carry activated for Long Confirmation, Carry inactive for Short Confirmation
;  Changes A and B, Flags are not affected
ZX2SD_COMMAND:
			CALL	SendSerByteLC					;Send A=Command
			LD		A,D
			CALL	SendSerByteLC					
			LD		A,E
			JP		NC,SendSerByte					;Send with Short Confirmation and return from there
			JP		SendSerByteLC					;Send with Long Confirmation and return from there
			




