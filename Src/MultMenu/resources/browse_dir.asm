; Browsing directories
; ----------------------------------------------------------------------------------------
						
;Load_FT_DIRECTORY - Change to subdir (or return to previous if ".." selected)
Load_FT_DIRECTORY:
			DI
			INC		HL								;Skip File Type
			LD		A,(HL)							;1st Char of directory choosen (or .. )
			CP		"."								;Check Name... Is it ".." ?
			JP		NZ,Load_FT_DIRECTORY_GoInto		;If no "." jump there to Go inside subdir

	;Here for going to previous dir... It's a Nightmare because we have to begin in ROOT and going down into subdirectories
;Load_FT_DIRECTORY_GotoParent - Entry for returning to Parent
Load_FT_DIRECTORY_GotoParent:					
		;1st thing is going to root
			CALL	ZX2SD_CD_ROOT					;Go to Root directory (Long confirmation)
			LD		A,(PathIndexLast)				;A will be >0 (never 0 if entered here, as 0 is for root and don't have ".." )
			DEC		A
			LD		(PathIndexLast),A				;Update with 1 less so will go up in directories
			JP		Z,Goto_PostROOT					; If we had only 1 directory now we're in ROOT so jump there (after CD_ROOT commmand)
					
			LD		B,A								;Copy to B (PathIndexLast)

			;Initializing current Path
			XOR		A
			LD		(PathBuffer),A					;Root is Empty Directory (64 bytes with 0x00)
			LD		(LenPath),A						;Length of current Path to show

		;Now going deep inside subdirectories upto the last level
			LD		A,B								;Copy to A (PathIndexLast)
			LD		IX,PathIndex-3					;PathIndex is Space with 192 bytes: 64 x 3 :Up to 63 directory entre levels (1 byte name len, 2 bytes index)
			LD		DE,3							;Length of each entry
GoingDeeperDirectory:
			ADD		IX,DE							;Go to next index (deep)
			DJNZ	GoingDeeperDirectory
		;We arrived to the very deeper directory
		
			LD		DE,-3							;So we can use ADD instead of SBC
		;Here for arrived to Deeper Directory, now return to "surface" until we arrive either the upper or len>59 (we  have to add a "~" so no 60 but 59 available)
			LD		B,A								;B=Num of levels we went inside (for not going beyond) (PathIndexLast)

			LD		A,#FF							;Initialize Len of Dirnames with -1 (1st directory don't add a "/")
LoopMoreRoom:
			ADD		A,(IX)							;Len of this Directory name (It's update when getting into)
			INC		A								;Each directory add a "/" so it's 1 char more
			CP		MaxLenPath-1					;Compare against 59 char maximum
			JR		NC,NoMoreRoom					;If len greater or equal then finish (> = 59 finish)
			ADD		IX,DE							;Go to previous index (shallow)
			DJNZ	LoopMoreRoom

		;Here for arrived to 1st level and path still is less than MaxLenPath-1
			
NoMoreRoom:	;Here for path greater or equal than MaxlenPath-1

			LD		IX,PathIndex					;Begin in 1st level to skip indexes of non used

		;So we're in the 1st index to use for path. B is the num of levels to discard => B=0 if we have to use all levels, B>0 if we have to discard B indexes
			LD		A,(PathIndexLast)				;A=Total of levels
			SUB		B								;A=Total levels-Leves to discard = Num of levels to use
			LD		E,A								;E=Number of levels to use
			
			LD		D,B								;D=B=Number of levels to discard... It can be 0..63
			
			LD		A,B								;A=Total of levels to discard
			AND		A
			JR		Z,NoSkipLevels					;If we have to use all levels (len path not greater than MaxLenPath) then jump

SkipLevels:
		;Loop for geting subdirectories (D=Number of levels to discard)
			LD		A,CMD_ZX2SD_CD_IX				;Command to change to subdir by Index (IX+3,IX+2)
			PUSH	DE
			LD		D,(IX+1)						;Data1: Low byte of Index			
			LD		E,(IX+2)						;Data2: High byte of Index
			SCF										;Carry for send commmand and Long Confirmation
			CALL	ZX2SD_COMMAND					;Send command with Long Confirmation
			POP		DE
			DEC		D
			.3		INC IX							;Next level
			JR		NZ,SkipLevels
NoSkipLevels:

			PUSH	DE
			LD		A,CMD_ZX2SD_GETDIR
			CALL	SendSerByte						;Command to ask for name of current dir
			
			LD		HL,BuffGetDir
			LD		DE,maxFLen						;last byte have to be always 0x00 so ask for 1 less (max file Length in FAT32 is 255 and of course plus a final 0x00)				
			CALL	Load4bitBlk						;Receiving Name in BuffGetDir, maximum length is maxFLen	
			
			CALL	UpdatePath						;Update string for showing Path adding current dir updates
			POP		DE
			
		;Here we're in the directory to begin to get pathnumber so go on
			LD		B,E								;D=Number of levels to use ... It can be 1..63
FillingPath:
			PUSH	BC
		
			LD		A,CMD_ZX2SD_CD_IX				;Command to change to subdir by Index (IX+1,IX+2)
			LD		D,(IX+1)						;Data1: Low byte of Index			
			LD		E,(IX+2)						;Data2: High byte of Index
			SCF										;Carry for send commmand and Long Confirmation
			CALL	ZX2SD_COMMAND					;Send command with Long Confirmation
;			.3		INC IX							;Next level
			
			LD		A,CMD_ZX2SD_GETDIR
			CALL	SendSerByte						;Command to ask for name of current dir
			
			LD		HL,BuffGetDir
			LD		DE,maxFLen						;last byte have to be always 0x00 so ask for 1 less (max file Length in FAT32 is 255 and of course plus a final 0x00)				
			CALL	Load4bitBlk						;Receiving Name in BuffGetDir, maximum length is maxFLen	
			
			CALL	UpdatePath						;Update string for showing Path adding current dir updates
			
			POP		BC
			.3		INC IX							;Next level
			DJNZ	FillingPath						;Continue filling the path with the num of index required

		;Here we have updated the Path and Arduino is located is the last directory
		;		so we can jump to update path string in screen and get new listing 
			JP		GoTo_Dir						;Go to update file names with current dir
			
	;----------------End of going to previous directory in path		
	
	;----------------Going to next directory in path		
Load_FT_DIRECTORY_GoInto:
			LD		DE,FILEENTRY_NAME+1				;Skips Name and 0x00
			ADD		HL,DE							;HL points to required index to get into	

		;Now we have to go deep inside subdirectories upto the last level
			LD		A,(PathIndexLast)				;If here if will be A>0 (1..64)
			CP		MAXSUBDIRS						;Don't allow more than 64 directories
			JP		Z,GoTo_Dir
			INC		A
			LD		(PathIndexLast),A				;So adding a new index
			LD		B,A								;Copy to b for DJNZ usage
			LD		IX,PathIndex-3					;PathIndex is Space with 192 bytes: 64 x 3 :Up to 63 directory entre levels (1 byte name len, 2 bytes index)
													;		using -3 as B=A=1 will be for the 1st index
			LD		DE,3							;Length of each entry
GoingDeeperDirectory2:
			ADD		IX,DE							;Go to next index (deep)
			DJNZ	GoingDeeperDirectory2
			
		;We arrived to IX= Position for the deeper directory (IX+0 is for name len, IX+1/2 for index)
			LD		A,(HL)
			LD		(IX+1),A
			LD		D,A								;Next command Data1: Low byte of Index
			INC		HL
			LD		A,(HL)
			LD		(IX+2),A						;Update index
			LD		E,A								;Next command Data2: High byte of Index
		;Now get filename dir

				
			LD		A,CMD_ZX2SD_CD_IX				;CD by index as per reg DE
			SCF										;Carry for send commmand and Long Confirmation
			CALL	ZX2SD_COMMAND
		
		
			LD		A,CMD_ZX2SD_GETDIR
			CALL	SendSerByte						;Command to ask for name of current dir
			
			LD		HL,BuffGetDir
			LD		DE,maxFLen						;last byte have to be always 0x00 so ask for 1 less (max file Length in FAT32 is 255 and of course plus a final 0x00)				
			CALL	Load4bitBlk						;Receiving Name in BuffGetDir, maximum length is maxFLen	
			
			CALL	UpdatePath						;Update string for showing Path adding current dir (return with C=Len of Directory Name)
			LD		(IX),C							;Saving C=Len of Directory Name into the current Entry

		;Here we have updated the Path and Arduino is located is the last directory
		;		so we can jump to update path string in screen and get new listing 
		
			JP		GoTo_Dir						;Go to update file names with current dir

	;----------------End of going to next  directory in path
	
	
;Routines to adjust Chapter/Page/Row

;SetCurPageOff - Adjust CurPageOff (1..11) as per CurrPages (1..99) so browsing correct page
;SetCurPageOff_RegA - Adjust CurPageOff (1..11) as per register A
SetCurPageOff:
			LD		A,(CurrPages)

SetCurPageOff_RegA:
			LD		B,A								;Times to count for CurPageOff
			LD		A,-FilesPerPag
UpdateCurPageOff_Loop:
			ADD		FilesPerPag
			DJNZ	UpdateCurPageOff_Loop
			:
			LD		(CurPageOff),A
			RET
