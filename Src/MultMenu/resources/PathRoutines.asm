;Path and change directory routines
;	Using PathBuffer (61 bytes of path) , LenPath (1 byte) length of current path (always <= 60)
;			BuffGetDir (256 bytes of filename) 
;			MaxLenPath (constant) Max length of Path
;	Call this routine after a CALL ZX2SD_COMMAND with command CMD_ZX2SD_GETDIR (It will fill BuffGetDir)
;	OUT C: Len of Directory name


;UpdatePath - Update path to show in PathBar
UpdatePath:
			LD		C,0								;C?len of Directory name.... 0 for root
			LD		HL,BuffGetDir					;1st Char of new Dir to add to path
			LD		A,(HL)
			CP		"/"
			RET		Z								;If Root then return without any update
Fill_NoRoot:
			XOR		A
			LD		C,A								;Initiallize counter of Len of Name=> C=A=0
UpdatePath_Locate0:
			CP		(HL)
			JR		Z,UpdatePath_Pos0
			INC		HL
			INC		C								;One more char for Len of Name
			JR		UpdatePath_Locate0
UpdatePath_Pos0:
			PUSH	BC								;Save C=Len of Directory name in BuffGetDir
		;Here located last char, address is HL
			LD		A,C
			CP		MaxLenPath-1					;Check if new length is >MaxLenPath-1 (aka >=59 char)... remember we have to add "/" so 1 less)
			JR		C,UpdatePath_NewLess60

			LD		A,(LenPath)
			AND		A
			JR		NZ,UpdatePath_NewGE60
		;If CurrentPath is Root (no path) then check against MaxLenPath
			LD		A,C
			CP		MaxLenPath
			JR		C,UpdatePath_NewLess60
		;Here if NewPath is greater or equal to MaxLenPath

		
UpdatePath_NewGE60:

		
			LD		A,"~"
			LD		(PathBuffer),A
			LD		A,MaxLenPath					;A=Len of Name
			LD		(LenPath),A						;Update new Len
			LD		BC,MaxLenPath					;Coping 1 less of len (so don't overwrite "~") 
UpdatePath_NoMaxLen:
			LD		DE,PathBuffer+MaxLenPath		;DE=Last position of PathBuffer (just in 0x00 after path)
			LDDR									;Copy the path to show
			JR		EndUpdatePath

		;Here for NewDir is less than 59
UpdatePath_NewLess60:
			PUSH	BC								;Save C=Len of Name
			DEC		HL								;So get position prior to 0x00 (last char of Dir Name)
			LD		DE,BuffGetDir+254				;Last position in buffer prior to the ending 0x00
			LD		B,0								;So BC=Len of Name
			LDDR									;Copy Name to end of buffer
		;At this moment DE=position in buffer prior to 1st Char
			LD		A,"/"
			LD		(DE),A							;Add "/" to the new directory so it's like /Dir

		;Now will add the current Path prior to the name of new dir
			LD		HL,PathBuffer-1					;So ADD HL,BC below will get last char prior to 0x00
			LD		A,(LenPath)						;Len of current Path
			LD		C,A								;For BC=Len of current Path
			AND		A								;Check the case LenPath=0 (Root)
			JR		NZ,PathCopy
			POP		BC								;C=Len of Name
			JR		AfterCopy
PathCopy:
			;LD		B,0								;Not required as per last LDDR B=0
			ADD		HL,BC							;Last char (prior to 0x00)
			DEC		DE								;So we're prior to "/" char
			LDDR									;Copy PathBuffer prior to "/" and new dir

		;At this moment DE=position in buffer prior to 1st Char
			POP		BC								;C=Len of Name
			INC		C								;C=Len of Name (now is 1 char more as per "/")
AfterCopy:
			;LD		A,(LenPath)						;No needed as per previous LD A,(LenPath) and A was not changed

			ADD		A,C								;Calculate new length
			LD		C,A
			CP		MaxLenPath-1					;Check if new length is > MaxLenPath (aka >= 60 char)

			LD		HL,BuffGetDir+255				;For the chance A>=60 jump to copy last chars and adding "~" or "~/" as pen C
			JR		NC,UpdatePath_NewGE60			;NC if A>=60    C if A<60
		;Here for new len <60, so we can copy directly
			EX		DE,HL							;HL=Position in buffer of 1st Char
			LD		DE,PathBuffer
			LD		A,C								;A=New len of path
			LD		B,0								;BC=New len of path
			INC		HL								;Move to 1st char
			LD		(LenPath),A
			LDIR
			XOR		A
			LD		(DE),A

EndUpdatePath:
		;Restore C=Len of GetDirBuff Directory name
			POP		BC								;C=Len of Directory Name
			RET
			