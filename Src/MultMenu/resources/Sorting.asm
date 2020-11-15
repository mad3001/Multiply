;Sort - Sort of Directories
; Filenames have up to 30 chars... not used are filled up with 0x00
;	Each entry is:  
;		#00 - Filetype (1 byte)
;		#01 - Filename (30 bytes)
;		#1F - Always 0x00 (1 byte)
;		#20-#21 - Index (low byte, high byte) (2 bytes)
;		#22 - Next entry....
;
; Steps for sort:
;		**Process for Directories
;				a)".." is retain as "1st entry" but not sorted
;				b)copy addresses of each Dir to SortBuffer.... only for FT_DIRECTORY.. 
;				c)IY points to 1st entry, B=counted entries to sort (discarding ".." that is not sorted)
;				d)Sorting:
;					d1)B=B-1 (save for later-on usage)
;					d2)if this item is greater than next item then swap them, also mark C=1 if any swapped in "this round"
;					d3)repeat d1-d2 up to current value of B=0
;					d4)if C=0 we finished (nothing was swapped in "this round")
;					d5)if C=1 then repeat, so restore B and repeat from d1
;
;		**Process for Files
;				Repeat the procedure done with directories

;	After that we'll have a addresses list with the sorted items for both: Directories and Files

Sort:
;				a)".." is leaved with 0x00 and retain as "1st entry"
			LD		(SortSP),SP						;saving SP for later-on

			LD		HL,Buffer						;Buffer of 34 x 254 (last entry is always 0x00) so only 253 can be used
			LD		IY,SortBuffer					;Buffer of 2 x 254 (last entry is always 0x00) so only 253 can be used (arranged for 23 * 11 screens)

			LD		SP,IY							;We'll use SP for moving data

			LD		DE,FILEENTRY_LEN
			
		;Check if we're in Root dir or subdir.... subdir have 1st entry as ".." so skip it in the sort
			LD		A,(Buffer+1)					;1st char of first item
			CP		"."
			JR		NZ,FillupSort					;Root dir does not have a ".." entry, in that case jump to begin sorting
		;Here if 1st entry is ".." (subdirectory) so that entry is out of sort
			POP		BC;.2		INC SP				;Move SP+2 (BC is discarded)
			PUSH	HL
			POP		HL
			LD		IY,SortBuffer+2
			ADD		HL,DE							;So points to next entry
FillupSort:
;				Unpdate SortBuffer with all current entries, type FT_DIRECTORY
			LD		BC,0							;0 entries, also C=0 for later on

Sort_Fillup:
			LD		A,(HL)
			CP		FT_DIRECTORY
			JR		NZ,Sort_EndFillup				;There is no Directories
			INC		B
			.2		INC SP
			PUSH	HL
			POP		HL
			ADD		HL,DE							;So points to next entry
			JR		Sort_Fillup	
			
Sort_EndFillup:
			POP		DE;.2		INC SP				;Move SP+2 (DE is discarded)
			LD		DE,0
			PUSH	DE								;Assure ends in 0x00

			LD		(PosFiles),SP					;Position for later with pointer to files
			LD		(HLPosFiles),HL					;Position for later with files
			
			LD		A,B								;B=Number of items of Directory type to sort
			DEC		A								;Always process 1 less... we'll compre 2 items between them 
			LD		HL,TotalB
			LD		(HL),A
			INC		A
			CP		2								; No sort if 0 or 1 item so compare against 2
			JR		C,Sort_NoDirsEntries			;If no directories or only 1 dir, then no sort required

			LD		IX,Sort_NoDirsEntries			;SortIY will return with JP(IX)
			JR		SortIY

Sort_NoDirsEntries:

;Now for Files
			LD		IY,(PosFiles)					;Position with pointers to files
			LD		SP,IY
			LD		HL,(HLPosFiles)					;Position for filenames
			LD		DE,FILEENTRY_LEN

FillupSort2:
;				Fill IY table for files
			LD		BC,0							;0 entries, also C=0 for later on
			;PUSH	IY								;IY=Begining of Files data
Sort_Fillup2:
			LD		A,(HL)
			AND		A
			JR		Z,Sort_EndFillup2				;When file type 0 we finish with files
			INC		B
			.2		INC SP
			PUSH	HL
			POP		HL
			ADD		HL,DE							;So points to next entry
			JR		Sort_Fillup2	

Sort_EndFillup2:
			POP		DE;.2		INC SP				;Move SP+2 (DE is discarded)
			LD		DE,0
			PUSH	DE								;Assure ends in 0x00

			LD		A,B								;B=Number of items
			DEC		A								;Always process 1 less... we'll compre 2 items between them 
			LD		HL,TotalB
			LD		(HL),A
			INC		A
			CP		2								; No sort if 0 or 1 item so compare against 2
			JR		C,Sort_NoFilesEntries			;If no files or only 1 file, then no sort required
			
			LD		IX,Sort_NoFilesEntries			;To return after SortIY -uses JP(IX)-
			JR		SortIY							;Sort Files

Sort_NoFilesEntries:
			
			LD		SP,(SortSP)						;restoring SP

			RET

;SortIY - IY points to 1st item for sorting... be sure there is a 0x00,0x00 after last item
SortIY:
			LD		HL,TotalB
SortIY2:
			LD		B,(HL)
			LD		C,0
;				c)HL=1st entry, B=counted entries to sort (discarding "..")
			LD		SP,IY
Sort_sorting:
			POP		HL
			POP		DE
			PUSH	DE
			PUSH	HL
Sort_sorting_Loop:
			INC		HL
			INC		DE
			LD		A,(DE)							;A=char for next entry
			CP		(HL)							;Char for next entry - char for this entry
			JR		Z,Sort_sorting_Loop				;While the same chars.... loop
			JR		NC,Sort_NoSwap					;Next entry is not lower than this so no swap
		;;Next entry is lower than this so have to swap
Sort_Swap:
			LD		C,1								;Mark as "swapped something"
			POP		HL
			POP		DE								;Extraced HL,DE
			PUSH	HL
			PUSH	DE								;Pushed in reverse so they are swapped in RAM
		;here for no swap items
Sort_NoSwap:
			POP		HL								;HL discarded
			DJNZ	Sort_sorting					;Repeat upto last entry
			
			LD		A,C								;C=0 if nothing swapped, any other value if someone was swapped
			AND		A								;Test for C was 0 (nothing swapped)
			;POP		IY
			JR		Z,Sort_Dir_Ending				;If nothing was swapped then finish sorting directories
			LD		HL,TotalB
			DEC		(HL)
			JR		NZ,SortIY2						;Repeat for a new "round"

		;	JR		Sort_Dir_Ending
			
Sort_Dir_Ending:

			JP		(IX)							;return to caller
			