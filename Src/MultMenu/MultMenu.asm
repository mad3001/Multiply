	;	DEFINE debug			;debug mode for use with es.pectrum (until Habi changes extension Problem)
	;DEFINE SPACE_IS_ROOT		;Uncomment for SPACE/FIRE2 execute going to ROOT directly. Comment for SPACE/FIRE2 execute going to ".." if current selection is not ".." or Parent Dir is current is ".."
			output "MultMenu.MLD"
			org	#0000


			include "resources/labels_multiply.asm"
			include "resources/macro_multiply.asm"
			include "resources/multiply_commands_v1.asm"			;Commands for multiply /File types for listing
			
			DI										;Don't change this DI...it's used also for IM2 interrupts.... #18 #F3 (JR $-#0D) #FFF4
			IM		1
			LD		SP,SP_VALUE						;it goes down... SP is under IM2 routine for detecting Multiply

			CALL	GetDANMENUData					;Get data of 1st slot (if it's a valid Dandanator slot)
			
			CALL	CheckHardware					;Check hardware and send it to Arduino or return to 1st MLD slot if no Arduino detected

			LD		A,BorderMenu
			OUT		(#FE),A

			LD		HL,screenzx7
			LD		DE,#4000
			CALL	dzx7_turbo

			CALL	PreviewInitial					;Force to painting Cloud Effect in mini screen preview
		;Jump here for going to Root
Goto_ROOT:
			LD		A,MinRowFiles					;First row for filenames is MinRowFiles
			LD		(CurRow),A						;Initialize Current Row
			LD		(MaxRow),A						;Initialize Max Row	

		;Initialize logo water effect
			CALL	InitLines

		;Preload PathBuffer with "/",0x00. Reset PathIndexLast (used for index through subdirectories)
			CALL	ZX2SD_CD_ROOT					;Multiply: Go to Root directory
Goto_PostROOT:
			;DI

			XOR		A
			LD		(PathBuffer),A					;Root is Empty Directory (64 bytes with 0x00)
			LD		(PathIndexLast),A				;0=No subdir, we're in ROOT "/"
			LD		(SubMenuOpt),A					;0=Main Menu, 1=Submenu ROMSET Writer, MARIO PENDIENTE SUBMENUS ADICIONALES

			JR		Continue
		
; ----------------------------------------------------------------------------------------
			DEFS	#38-$,#FF
;RST38 - INT IM1

			;EI										;Not enable ints after return
			RETI									;Return Interrupt (with ints disabled)
; ----------------------------------------------------------------------------------------
TXTClearPath:
			defs	MaxColPath-PosColPath+1,32
			defb	0
;Contine (comes from start)
Continue:
			LD		(LenPath),A						;Length of current Path to show
GoTo_Dir:
			XOR		A
			LD		(CurrChapter),A					;Initialize current chapter to 0 (so will ask not only for chapter 1, but also info for all chapters)
			INC		A
			LD		(CurPage),A						;Reading 1st chapter so position in Page 1 (curPage value 1..99)
			LD		(CurrPages),A					;Reading chapter and position in Page 1 (currPages value 1..11)
			LD		(RowNewPage),A					;Row to select initially is 1 (1..23)
GoTo_Chapter:
			CALL	SetCurPageOff					;Adjust CurPageOff (1..11) as per CurrPages (1..99) so browsing correct page

			CALL	PreviewInitial					;Force to painting Cloud Effect in mini screen preview
			
			LD		A,(RowNewPage)
			LD		(CurrFile),A					;Initilize CurrFile to RowNewPage (currFile value 1..23)

			CALL	ClsFiles
		;Clear old path
			LD		DE,0 + (PosRowPath<<8) + PosColPath  	;D=Row (0..23), E=Column (0..63)
			LD		IX,TXTClearPath
			CALL	PrintIXText
		;Print current path in Row PosRowPath (limited to MaxColFiles columns)
			LD		DE,0 + (PosRowPath<<8) + PosColPath  	;D=Row (0..23), E=Column (0..63)
			LD		IX,PathBuffer					;Show Path...Initially empty, after that will be update through "UpdatePath"

			CALL	PrintIXText						;Print text in IX at Row D, Column E		

		;Now show Multiply version
			LD		IX,MultiplyVer+4
			LD		A,(IX+4)
			PUSH	AF
			LD		(IX+4),0
			LD		DE,60+(20 << 8)					;Print Multiply version (3 bytes only)
			CALL	PrintIXText
			POP		AF
			LD		(IX-1),A						;Restore old value there (IX returned with address after 0x00)
			
			LD		IX,TXTLoading
			LD		DE,(2*ColIconSel) + ((5+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for text outside the box	
			
		;Choose chapter to load as per chapters table
			LD		A,(CurrChapter)
			AND		A								;Test for CurrChapter = 0
			JR		NZ,ChapterIX					;CurrChapter no 0 so jump there
			LD		D,A								;As A=0 we do that for D=0
			LD		E,A								;DE=0000 for loading chapter 1 and also retrieve info for all chapters
			JR		LoadChapters
				
		;Here for loading chapters 1 to MaxChapter
ChapterIX:
			LD		HL,ChapTable					;Chapter table (1st item is for chapter 1)
			DEC		A								;A=0 for Chapter 1
			ADD		A,A								;A*2
			LD		D,0
			LD		E,A
			ADD		HL,DE							;Address into Chapter table for chapter required
			LD		D,(HL)							;Low byte of ChapterIX
			INC		HL
			LD		E,(HL)							;High byte of ChapterIX, so DE=ChapterIX

LoadChapters:
			LD		A,CMD_ZX2SD_LS_RELATIVE			;A=Ask for list of current directory, chapter index as per DE (although inverted bytes D=low, E=High)
			SCF 
     		CALL 	ZX2SD_COMMAND					; Ask for current directory and chapter

			;CALL	SendSerByte						;Request directory listing

			LD		A,(RowNewPage)					;First row for filenames
			LD		(CurRow),A						;Initialize Current Row
			
			LD		HL,Buffer						;Buffer of file names to recevies Directory/Filenames
					
LoopGetList:
			PUSH	HL								;Save address of File type of current Filename
			LD		DE,FILEENTRY_LEN				;DE=Length of package to read

			CALL	Load4bitBlk						;Get info for dir/file

			EX		(SP),HL							;Save HL in Stack, retrieve HL=Address of 1st char of current name just readed
			LD		A,(HL)							;1st byte of received data... 0x00 if no more data
			POP		HL								;HL will be last position of filename readed (HL=Address of filename readed + FILEENTRY_LEN -1)
			COMPARE	FT_END_DIRECTORY				;Check if A=FT_END_DIRECTORY
			JR		Z,EndGetList					;If no more data (A=FT_END_DIRECTORY) then finish getting filenames
			INC		HL								;HL=Next position in buffer of filenames (HL=Address of filename readed + FILEENTRY_LEN)
			JR		LoopGetList						;Get more dir/filenames
			
		;Here for finished getting dir/filenames
EndGetList:

		;Now check if we have loaded chapters info
			LD		A,(CurrChapter)
			AND		A								;Test for CurrChapter = 0
			JR		Z,Chapter0
			DEC		A
			JP		Z,Chapter1						;CurrChapter = 1 should test if Root or not (for "../Dan" or "../ZX")
			JP		NoRootGetList
			
Chapter0:


		;Here for retrieved info about chapters (received in last entry)
			LD		DE,Chap1Chapt-FILEENTRY_LEN+1
			ADD		HL,DE							;So HL points to offset for Chap1Chapt
			LD		A,(HL)							;Total of chapters (1..MaxChapter)
			LD		(LastChapter),A
			INC		HL								;HL points to offset for Chap1Pages
			LD		A,(HL)							;Total of Pages (1..MaxChapter*MaxPageChap)
			LD		(LastPages),A
			INC		HL								;HL points to offset for Chap1LastF
			LD		A,(HL)							;Num. of files in last Page (usually 253, except for last chapter and last page 1..253)
			LD		(LastFile),A
			LD		DE,Chap1Offset-Chap1LastF		;Difference btw Offsets  Chap1LastF and Chap1Offset
			ADD		HL,DE							;so now HL points to Chap1Offset (Address of Chapter 1 index)
			LD		DE,ChapTable
			LD		BC,MaxChapter*2
			LDIR
			LD		A,1								;So chapter 1
			LD		(CurrChapter),A					;Chapter 1 so next time in this Folder does not retrieve chapter info again
			LD		(CurrPages),A					;Page 1R

			LD		A,(HL)							;Check HL pointing to ChapDegrad
			LD		(MsgDegrad),A					;Copy degraded to MsgDegrad
			
Chapter1:
			LD		A,(PathIndexLast)
			AND		A								;If PathIndexLast=0 we're in root
			JR		NZ,NoRootGetList					;So root does not have ".." entry, but have "../Dandanator MENU"
		;Here for ROOT SD. If exists 1st slot as Dandanator then show it, if not then show return to zx basic
			;PUSH	BC			;B not used anymore for Num of files
			;Checking if exists 1st slot MLD correct
			LD		HL,TXTDanPath					;Type and Text for Dan Path
			LD		DE,Buffer						;DE=Buffer of file names
			LD		BC,SizeEndTXTDanPath
			LD		A,(InfoVersion)
			CP		"v"								;Dandanator always have "v" for version
			JR		Z,ShowRootFirst					;Show "../Dan......." or "../ZX...."
		
			LD		HL,TXTZXPath					;Type and Text for ZX Basic path
			LD		BC,SizeEndTXTZXPath
ShowRootFirst:
			LDIR
			;POP		BC		;B not used anymore for Num of files

NoRootGetList:
		;Update Num of Files for listing
			LD		HL,LastChapter
			LD		A,(CurrChapter)
			CP		(HL)
			JR		NZ,NoLast						;If Current chapter is not the last, then jump
			LD		HL,LastPages
			LD		A,(CurrPages)
			CP		(HL)
			JR		NZ,NoLast						;If current page is not the last, then jump
		;Here only for Last chapter, Last page, so using "LastFile" number of files
			LD		A,(LastFile)
			JR		SetNumFiles
NoLast:
			LD		A,MAXNFILES						;By default chapter should have MAXNFILES except for last chapter
SetNumFiles:
			LD		(NumOfFiles),A					;Update total of files (1..253)
		
		;And sort texts
			;Print text "Sorting" for the chance it takes a bit long....
			LD		IX,TXTSorting
			LD		DE,ColOPTSel + ((5+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for text outside the box

			CALL	Sort							;Sort of Directory


;Here for printing filenames. Printed only MaxColFiles columns
;	Printed only MaxRowFiles-MinRowFiles filenames

Printing_PAGE:
			CALL	ClsFiles

			LD		A,1
			LD		(AuxCurRow),A					;Aux row for printing filenames
			LD		A,(CurPage)						;Current Page to show (1..99)
			LD		IX,TXTNumber
			CALL	NumberAtoIX						;Convert reg A to number and store into (IX)(IX+1)

			LD		IY,SortBuffer					;Buffer of sorted Files (2 bytes each)
			
			LD		A,(CurPageOff)					;Current page number offset
			LD		E,A
			LD		D,0
			ADD		IY,DE
			ADD		IY,DE							;IY + (2 * offset page number)
	;Here for printing from Entry pointed by IX
Printing:
			LD		A,(IY+1)						;High byte of File addr (0x00 for no more entries)
			AND		A
			JR		Z,EndPrinting

			LD		A,(IY)							;Low addr
			LD		IXL,A							;Low addr
			LD		A,(IY+1)						;High addr
			LD		IXH,A							;High addr
			;LD		IX,Buffer						;Buffer of file names
			
			LD		B,(IX)							;B=FileType
			PUSH	IX								;Save Position of this file
			LD		A,(AuxCurRow)
			LD		D,A
			LD		E,0								;E=Column (0..32) / D=Row (0..23)				
			CALL	PrintIcon8x8					;Print Icon8x8 as per B reg into Row D and Column E

			INC		IX								;Skip Type... IX points to name
			LD		A,(AuxCurRow)
			LD		D,A
			LD		E,MinColFiles					;Position											
			CALL	PrintIXText						;Print string pointing by IX
			POP		IX								;Position of this file
						
			.2		INC IY							;Next Entry in the sorting
			LD		A,(AuxCurRow)
			INC		A
			LD		(AuxCurRow),A
			DEC		A
			LD		(MaxRow),A						;Update maximum row for selecting	- MARIO PENDIENTE HACER MEJOR CUANDO HAYAN VARIAS PAGINAS DE FICHEROS
			CP		MaxRowFiles						;Avoid going beyond MaxRowFiles (max.row to be used by filenames)
			JR		NZ,Printing
					
EndPrinting:
		;Still have to print Number of pages (only if more than 1 page)
			LD		A,(LastPages)					;Num of Pages in directory
			RowCol2ATTR HL, RowPage, ColPage/2		;Attr pos for xx/yy for page numbers
			CP		1								;Max Page is 1 ?
			PUSH	AF								;Save value of Max Page, also Z=1 if only 1 pag
			LD		C,NoSel_Color					;C=NoSel_Color if total pages = 1
			LD		IX,TXTMaxPageEmpty				;Blank for Only 1 pg 
			
			JR		Z,ToShowPage
		;change attributes to bright
			LD		C,Page_Color					;C=Selec_Color if total pages > 1
			LD		IX,TXTPageof					;More than 1pg
ToShowPage:
		;No change attr of "xx/yy" to sel_colour if Max Page >1, if Max Page = 1 then nosel_colour

			LD		B,(TXTMaxPageEmpty-TXTPageof-1)/2
.loop:
			LD		(HL),C
			INC		HL								;Changing attrs to bright
			DJNZ	.loop
		;And print the texts	
			LD		DE,ColPage+(RowPage << 8)		;Text "  /  "
			CALL	PrintIXText						;Print Text

			POP		AF
			JR		Z,NoShowPage					;If only 1 page, jump there
			PUSH	BC								;Save C=colour for attrs
			PUSH	AF								;Save value of Max Page
			
			LD		IX,TXTNumber					;Current page
			LD		DE,1+ColPage+(RowPage << 8)		;Text xx into "xx/yy"
			CALL	PrintIXText
			
			POP		AF
			LD		IX,TXTNumber
			CALL	NumberAtoIX						;Convert reg A to number and store into (IX)(IX+1)
			LD		DE,ColPage+4+(RowPage << 8)		;Text yy into "xx/yy"
			CALL	PrintIXText						;Print Text
			
NoShowPage:
	
			LD		A,(RowNewPage)					;Row to change for default selected (1st file or "..", or last row if caming from next page)

MenuUpdateSelected:			
			LD		(CurRow),A						;Selected row
			LD		C,Selec_Color					;Attr for selected
			CALL	RowAttr							;A=Row, C=attribute colour
			LD		A,1
			LD		(InfoShown),A					;1 for Pending to show Info BOX
			CALL	PreviewInit						;Reset information of Pre-view

MenuWaitChange:
			IM		1								;Using IM1 for "normal" interrupt
			EI
			HALT
;Moved from IM1 here (only here we use EI-HALT-DI
			CALL	INTLines						;return with (Z) Z activated if no line was moved, (NZ) Z deactivated if lines was moved

			LD		A,(CurKey)
			AND		A								;Z if no key was pressed (so it's time for loading preview)
			CALL	Z,INTpreview					;return with (Z) Z activated if preview did not execute long calls, (NZ) Z deactivated if did something

			CALL	ProcessKey						;Last thing is to Process keys
;Moved from IM1 here (only here we use EI-HALT-DI
			LD		A,(SubMenuOpt)					;SubMenu selected. 1=ROMSET_SubMenu.... no more yet
			DEC		A
			JP		Z,ROMSET_SubMenu				;Jump for submenu 1
		; MARIO PENDIENTE SUBMENUS ADICIONALES
		
		;Here for no submenu option
			LD		A,(KeyToExe)					;Key pressed for execute something
			RRCA
			JP		C,KeyRIGHT						;Bit 0 for Right
			RRCA
			JP		C,KeyLEFT						;Bit 1 for Left
			RRCA
			JP		C,KeyDOWN						;Bit 2 for Down
			RRCA
			JR		C,KeyUP							;Bit 3 for UP
			RRCA
			JR		C,KeyFIRE						;Bit 4 for FIRE
			RRCA
			JP		C,KeyROOT 						;Bit 5 for ROOT
	
AfterCheckKeys:
		;Only when all keys have been released (or in between repeats) then Info BOX will appear
			LD		A,(InfoShown)					;1 for Pending to show Info BOX, 0 for Info BOX showed
			DEC		A
			JR		NZ,MenuWaitChange				;If info was showed then skip show it again
		;Now show the additional info in right box
			;XOR		A
			LD		(InfoShown),A					;0 for Info BOX showed so next time does not update
			
			LD		IY,SortBuffer					;Buffer of sorted Files (2 bytes each)
			
			LD		A,(CurPageOff)					;Current page number offset
			LD		E,A
			LD		D,0
			ADD		IY,DE
			ADD		IY,DE							;IY + (2 * offset page number)
			
			LD		A,(CurRow)						;Selected row
			SUB		MinRowFiles						;So 1st row will be 0
PrintIconSel_Loop:
			JR		Z,PrintIconSel					;A=0 jump there
			.2		INC IY							;Next entry
			DEC		A
			JR		PrintIconSel_Loop				;Until arrive to current row
PrintIconSel:
			LD		A,(IY)							;Low addr
			LD		IXL,A							;Low addr
			LD		A,(IY+1)						;High addr
			LD		IXH,A							;High addr
			CALL	PrintIXInfo						;Print Info Box: Icon and additional info (see print.asm)
			
			JR MenuWaitChange

	;Here for Fire pressed
KeyFIRE:
			LD		IY,SortBuffer					;Pointers to sorted filenames

			LD		A,(CurPageOff)					;Current page number offset
			LD		E,A
			LD		D,0
			ADD		IY,DE
			ADD		IY,DE							;IY + (2 * offset page number)
			
			LD		A,(CurRow)						;Row=MinRowFiles..MaxRowFiles
			SUB     MinRowFiles						;Converts Row value MinRowFiles..N into value 0..N-MinRowFiles

			LD		B,A								;B=num of file to load (0..x)
			JR		Z,CalcFile_End
CalcFile:
			.2		INC IY
			DJNZ	CalcFile
CalcFile_End:
			LD		L,(IY)							;Low addr
			LD		H,(IY+1)						;High addr		

			JP	ProcessFIRE							;Go there to procees pressing fire

	;Here for UP pressed
KeyUP:
			LD		A,(CurRow)
			CP		MinRowFiles						;Minimum row is MinRowFiles constant
			JR		NZ,KeyUP_Cont					;Trying going before 1st
			LD		A,(LastPages)
			DEC		A
			JR		NZ,KeyUP_SomePages
			LD		A,(CurRow)
			LD		C,NoSel_Color					;Attr for non selected
			CALL	RowAttr							;A=Row, C=attribute colour
			LD		A,(LastFile)					;As we have only 1 page, then it will be value 1..23
			LD		(RowNewPage),A					;After change page go to last Row
			JP		NoShowPage
			
KeyUP_SomePages:
			LD		A,MaxRowFiles
			LD		(RowNewPage),A					;After change page go to last Row
			JR		KeyLEFT_after
KeyUP_Cont:
			LD		C,NoSel_Color					;Attr for non selected
			CALL	RowAttr							;A=Row, C=attribute colour
			LD		A,(CurRow)
			DEC		A
			JP		MenuUpdateSelected
			
	;Here for DOWN pressed
KeyDOWN:
			LD		HL,MaxRow
			LD		A,(CurRow)
			CP		(HL)							;Maximum row
			JR		Z,KeyDOWN_MovePages				;Last Row, try go go Next page(there will be solved)

			LD		C,NoSel_Color					;Attr for non selected
			CALL	RowAttr							;A=Row, C=attribute colour
			LD		A,(CurRow)
			INC		A
			JP		MenuUpdateSelected

KeyDOWN_MovePages:
			LD		A,(LastPages)
			DEC		A
			JR		NZ,KeyRIGHT						;Last Row and more than 1 page so go there to deal with it
			LD		A,(CurRow)
			LD		C,NoSel_Color					;Attr for non selected
			CALL	RowAttr							;A=Row, C=attribute colour
			LD		A,1
			LD		(RowNewPage),A					;After change page go to last Row
			JP		NoShowPage

	;Here for LEFT pressed
KeyLEFT:
			LD		A,(LastPages)
			DEC		A
			JP		Z,MenuWaitChange				;If only 1 page then Left don't do anything
			
			LD		A,MinRowFiles
			LD		(RowNewPage),A					;After change page go to last Row
KeyLEFT_after:
			LD		HL,CurPage						;Current page (1..99)
			LD		A,1
			CP		(HL)
			JP		Z,KeyGoLastPage					;If 1st page, go to last page  ;;JP Z, MenuWaitChange				;If 1st page, nothing to do->jump
			DEC		(HL)							;Decrease current page number
			LD		A,(CurrPages)					;Page 1..11 into chapter
			DEC		A
			JR		NZ,KeyLEFT_Page					;If Page was > 1 then process next page

		;Here arriving if we were in 1st page of this chapter
			LD		A,MaxPageChap
			LD		(CurrPages),A					;Update current page 11 (1..11)
			LD		A,(CurrChapter)
			DEC		A
			LD		(CurrChapter),A					;Go to previous chapter
			JP		GoTo_Chapter

KeyGoLastPage:
			LD		A,(LastPages)
			LD		(CurPage),A						;Goto page 1..99
KeyGoLastPage_Subpage:
			CP		MaxPageChap+1
			JR		C,KeyGoLastPage_EndSubpage		;if less or queal to MaxPageChap (11)
			SUB		MaxPageChap
			JR		KeyGoLastPage_Subpage
			
KeyGoLastPage_EndSubpage:			
			LD		(CurrPages),A					;page 1..11 as per page in chapter
			LD		A,(LastFile)
KeyGoLastPage_SubFile:
			CP		MaxFilePage+1
			JR		C,KeyGoLastPage_EndSubFile		;if less or queal to MaxFilePage (23)
			SUB		MaxFilePage
			JR		KeyGoLastPage_SubFile
KeyGoLastPage_EndSubFile:
			LD		(CurrFile),A
			LD		(RowNewPage),A					;After change page go to last Row

			CALL	SetCurPageOff					;Adjust CurPageOff (1..11) as per CurrPages (1..99) so browsing correct page

			LD		A,(LastChapter)
			LD		(CurrChapter),A
			CP		1
			JP		Z,Printing_PAGE					;Jump if having only 1 chapter (no require to reload chapters)
		;Here if more than 1 chapter (so going to last chapter, last page, last file)
			JP		GoTo_Chapter

KeyLEFT_Page:
			LD		(CurrPages),A					;Update current page

			LD		A,(CurPageOff)
			SUB		FilesPerPag
			JR		LEFT_RIGHT_UPDPage

	;Here for RIGHT pressed
KeyRIGHT:
			LD		A,(LastPages)
			DEC		A
			JP		Z,MenuWaitChange				;If only 1 page then Right don't do anything

			LD		A,MinRowFiles
			LD		(RowNewPage),A					;After change page go to last Row
			LD		HL,CurPage						;Current page (1..99)
			LD		A,(LastPages)					;Max number of page to go to the next (1..99)
			CP		(HL)
			JR		Z,KeyGo1stPage					;If Last page, go to last page  ;;JP		Z,MenuWaitChange				;If last page, nothing to do->jump
			INC		(HL)							;Increase current page number
			LD		A,(CurrPages)					;Page 1..11 into chapter
			INC		A
			CP		MaxPageChap+1
			JR		NZ,KeyRIGHT_Page				;If Page was <11 then process next page
			
		;Here arriving arriving if we were in last page of this chapter
			LD		A,1
			LD		(CurrPages),A					;Update current page 1 (1..11)
			LD		A,(CurrChapter)
			INC		A
			LD		(CurrChapter),A					;Go to next chapter
			JP		GoTo_Chapter
			
KeyGo1stPage:
			LD		A,1
			LD		(CurrChapter),A					;1st chapter
			LD		(CurPage),A						;Goto page 1 (1..99)
			LD		(CurrPages),A					;Subpage 1 (1..11 as per Page into Chapter)
			LD		(CurrFile),A					;1st file selected
			LD		(RowNewPage),A					;After change page go to 1st Row

			CALL	SetCurPageOff					;Adjust CurPageOff (1..11) as per CurrPages (1..99) so browsing correct page

			LD		A,(LastChapter)
			CP		1
			JP		Z,Printing_PAGE					;Jump if having only 1 chapter (no require to reload chapters)
		;Here if more than 1 chapter (so going to 1st chapter, 1st page, 1st file)
			JP		GoTo_Chapter

		
KeyRIGHT_Page:
			LD		(CurrPages),A					;Update current page
			
			LD		A,(CurPageOff)
			ADD		FilesPerPag
		;Common zone for LEFT-RIGHT
LEFT_RIGHT_UPDPage:
			LD		(CurPageOff),A					;Update offset for Page

			CALL	ClsFiles
			
			LD		A,MinRowFiles					;So repaint will begin in MinRowFiles
			LD		(CurRow),A						;Update CurRow for repaint

			JP		Printing_PAGE		

	;Here for go to ROOT or PARENT as per SPACE_IS_ROOT is defined of no
KeyROOT:
	IFDEF SPACE_IS_ROOT
		;Here for Going to ROOT (SPACE_IS_ROOT was defined)
			LD		A,(PathIndexLast)
			AND		A
			JP		NZ,Goto_ROOT					;If we're in a subdir... go to ROOT
		;Here only if current dir is ROOT dir
			LD		HL,CurPage
			LD		A,1
			CP		(HL)
			JP		Z,AfterCheckKeys				;If we were in page 1 then avoid going to ROOT (not needed)
			LD		(HL),A							;Update page as 1
			XOR		A								;A=0 to update curpageoff (offset)
			JP		LEFT_RIGHT_UPDPage				;We're in root but as page > 1 then go to 1st page
; ----------------------------------------------------------------------------------------
	ELSE
		;Here for Going to PARENT (SPACE_IS_ROOT was NOT defined)
			
			LD		A,(CurrChapter)
			DEC		A
			JR		NZ,KeyGo1stPage					;Chapter differs
			LD		A,(CurrPages)
			DEC		A
			JR		NZ,KeyGo1stPage					;Page differs but same chapter
			LD		A,(CurRow)
			DEC		A
			JR		NZ,KeyROOT_no1st_NoRepaint		;Selected is not the 1st so it's goint to parent
			
			;Current is 1st chapter, 1st page, 1st element => Go to Parent ".." (if root nothing happens)
			LD		A,(PathIndexLast)				;A will be >0 (never 0 if entered here, as 0 is for root and don't have ".." )
			AND		A
			JP		Z,AfterCheckKeys				;Nothing to do as we're in ROOT
			
			JP		Load_FT_DIRECTORY_GotoParent	;Proceed going to Parent dir
			
KeyROOT_no1st_NoRepaint:
			LD		A,(CurRow)
			LD		C,NoSel_Color					;Attr for non selected
			CALL	RowAttr							;A=Row, C=attribute colour
			LD		A,1
			LD		(RowNewPage),A
			JP		NoShowPage						;Update selection 1st row without repaint

	
	ENDIF
			
;Process option selected: Change dir, Show SCR, Launch file in SNA directory, etc...
; HL points to data (without directory)
ProcessFIRE:
		;Next commands using Filename,0x00

			LD		A,(HL)							;A=FileType
			CP		FT_BASIC						;Check for type: "Go to ZX Basic" entry
			JP		Z,ReturnTOBASIC 				;If FT_BASIC, then jump there

			CP		FT_ROMSET						;Check for type: ROMSET entry
			JP		NZ,NextProcessFIRE				;If no ROMSET, then jump there

		;Here for ROMSET
			LD A,(CurRow)				;Current row.... if value is MinRowFiles then is to jump to Internal ROMSET
			CP MinRowFiles
			JP NZ,ROMSET_pre			;No 1st row is because we selected a file of type ROMSET
			
		;check for 1st page to be sure is going to Dandanator 1st slot or it's a ROMSET in another page (not 1st)
			LD A,(CurPage)
			DEC A
			JR NZ,ROMSET_pre			;No 1st row is because we selected a file of type ROMSET in 2nd or later-on page

		;Here for internal ROMSET . MARIO PENDIENTE CUANDO SE ELIGIÓ ROMSET EN UNA PAGINA QUE NO ES LA 1...(eso indica que no es el internal romset)
Goto_Dan1stSlot:			
			LD HL,RAMTOINTERNAL
			LD DE,ScratchRAM
			PUSH DE
			LD BC,ENDRAMTOINTERNAL-RAMTOINTERNAL
			LDIR
			RET

RAMTOINTERNAL:
			LD B,1						;Slot to jump to
			SLOT_B
			WAIT_B PAUSELOOPSN
			XOR A
			
			LD (AUTOBOOTCHK),A			; Save it to RAM so autolaunch is disabled
			RST	#08						;Jump there to continue with normal launch (without autolaunch)
ENDRAMTOINTERNAL:
		;End of launch internal Dandanator MENU
ROMSET_pre:
			LD		(Rom2Write),HL					;Save addres of romset info 
		;Check if romset is lower than v10 to show messages as per TXTROM10
			LD		IX,ROMVersion					;As per GetInfo we have there the string of Version of Romset vx.x or vxx.x
			LD		A,(IX)
			CP		'v'								;Check v string for version
			JR		NZ,noROMSETver					;Jump if v char is not found
			LD		A,(IX+3)
			CP		'.'
			JR		Z,ROMSET_pre2					;Jump if vxx.x (that means is a >=10.0)
		;Here if version not compatible with Multiply
noROMSETver:
			LD		DE,(ColDescSel/2) + ((3+RowDescSel) << 8)
			LD		BC,12+(%01111010<<8)			;C=12 bytes to change attr, B=Bright, Paper white, ink red
			CALL	RowAttrMod						; change attribute colours at Row D(0..23), Column E(0..31) with attribute B for a number of byte as per C

			LD		IX,TXTROM10
			LD		DE,ColDescSel + ((3+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for text outside the box
ROMSET_pre2:
			
		;Here to confirm writing romset to Dandanator EEPROM
		
			LD		DE,(ColOPTSel/2) + ((5+RowDescSel) << 8)
			LD		BC,13+(%01111001<<8)			;C=12 bytes to change attr, B=Bright, Paper white, ink blue
			CALL	RowAttrMod						; change attribute colours at Row D(0..23), Column E(0..31) with attribute B for a number of byte as per C

			LD		IX,TXTROMWRITE
			LD		DE,ColOPTSel + ((5+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for text outside the box

		;Now flash option " NO " (2 bytes)
			RowCol2ATTR HL, 5+RowDescSel, (ColOPTSel/2)+TXTROMWRoffNO	;Attr position for NO
			SET		7,(HL)							;Activate flash of 1st attribute
			INC		HL
			SET		7,(HL)							;Activate flash of 2nd attribute

			LD		A,1
ROMSET_SM:
			LD		(SubMenuOpt),A					;Tell Menu routine we're waiting in submenu number 1 (so no process normal Menu keys)
			JP		MenuWaitChange					;Nothing more to do here so return to wait for submenu options	
			
;	DEFINE	LESSKEYS								;Uncomment using only RIGHT-LEFT-FIRE. Comment for using also UP,DOWN,SPACE to exit
			
		;Here when pressed a key in submenu ROMSET (SubMenuOpt)=1
ROMSET_SubMenu:
			LD		A,(KeyToExe)					;Get valid key
			RRCA
			JR		C,ROMSET_SubMenuChange			;Bit 0 for Right
			RRCA
			JR		C,ROMSET_SubMenuChange			;Bit 1 for Left
		IFDEF LESSKEYS
			.3		RRCA
			JR		C,ROMSET_SubMenuENTER			;Bit 4 for FIRE
		ELSE
			RRCA
			JR		C,ROMSET_SubMenuEND				;Bit 2 for Down
			RRCA
			JR		C,ROMSET_SubMenuEND				;Bit 3 for UP
			RRCA
			JR		C,ROMSET_SubMenuENTER			;Bit 4 for FIRE
			RRCA
			JR		C,ROMSET_SubMenuEND				;Bit 5 for ROOT	
		ENDIF
ROMSET_SubMenu_Ret:
			JP		MenuWaitChange					;Nothing selected, return to wait for new keys

;ROMSET_SubMenuChange - Swap  NO-YES for selection
ROMSET_SubMenuChange:
			RowCol2ATTR HL, 5+RowDescSel, (ColOPTSel/2)+TXTROMWRoffNO	;Attr position for NO
			LD		B,#80							;Value to swap flashing on<->off
			LD		A,(HL)							;1st byte of " NO "
			XOR		B
			LD		(HL),A		
			INC		HL
			LD		(HL),A							;2nd byte of " NO "

			.2		INC		HL						;skip empty space
			LD		A,(HL)							;1st byte of " YES"
			XOR		B
			LD		(HL),A		
			INC		HL
			LD		(HL),A							;2nd byte of " YES"
			JR		ROMSET_SubMenu_Ret

ROMSET_SubMenuENTER:
			RowCol2ATTR HL, 5+RowDescSel, (ColOPTSel/2)+TXTROMWRoffNO	;Attr position for NO
			BIT		7,(HL)							;Bit 7=1 if " NO " is activated, 0 for " YES" activated
			JP		Z,Load_FT_ROMSET				;for " YES" jump to eewriter
		;If " NO " then exit submenu
			
		IFNDEF LESSKEYS
ROMSET_SubMenuEND:
			RowCol2ATTR HL, 5+RowDescSel, (ColOPTSel/2)+TXTROMWRoffNO	;Attr position for NO
		ENDIF
			LD  B,5									;5 bytes to clear flash attr
.clear:
			RES	    7,(HL)							;Clear flash attr
			INC		HL
			DJNZ	.clear							;do it for all the bytes

			LD		IX,FT_ROMSET_ENTER				;Usual text
			LD		DE,ColOPTSel + ((5+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for text outside the box

			LD		IX,FT_EMPTY
			LD		DE,ColDescSel + ((3+RowDescSel) << 8)
			CALL	PrintIXText						;Clear text in that line (use for romset not compatible)
			
			LD		DE,(ColDescSel/2) + ((3+RowDescSel) << 8)
			LD		BC,12+(%01111000<<8)			;C=12 bytes to change attr, B=Bright, Paper white, ink black
			CALL	RowAttrMod						; change attribute colours at Row D(0..23), Column E(0..31) with attribute B for a number of byte as per C

			LD		DE,(ColOPTSel/2) + ((5+RowDescSel) << 8)
			LD		BC,13+(%01111000<<8)			;C=12 bytes to change attr, B=Bright, Paper white, ink black
			CALL	RowAttrMod						; change attribute colours at Row D(0..23), Column E(0..31) with attribute B for a number of byte as per C


			XOR		A
			JR		ROMSET_SM						;Jump there to deactivate submenu and return to menu


;Here for NO ROMSET was selected
NextProcessFIRE:
			;LD		A,(HL)							;A=FileType	;<-Not required
			CP		FT_DIRECTORY					;Check for type: Directory entry (so enter there -or go parent if ".." - )
			JP		Z,Load_FT_DIRECTORY
			

			;LD		A,(HL)							;A=FileType ;<-Not required
			CP		FT_SCR							;Check for type: Screen (6912 bytes)
			JP		Z,Load_FT_SCR

			;LD		A,(HL)							;A=FileType ;<-Not required
			CP		FT_TAP							;Check for type: TAP
			JP		Z,Load_FT_TAP
		
		;MARIO PENDIENTE OTROS TIPOS QUE VAYAMOS INTRODUCIENDO A FUTURO....TZX...BIN...
		
		
		
		;Here for load Snapshot (SNA or Z80)
			;JP LaunchSnap		;Not required as it's just here..... REMOVE ; IF CHANGED "LaunchSnap" TO ANOTHER PLACE
LaunchSnap:
		include "launchSnap/Launch_Snap.asm"	;Take care IF CHANGED "LaunchSnap" TO ANOTHER PLACE, see previous lines....

LB:
		;loading routines per file type
		include "resources/loadroutines.asm"
LE:
showinfdzxB:
		include "resources/dzx7_turbo.asm"
showinfdzxE:

PB:	
		;Path Routines
		include	"resources/PathRoutines.asm"
PE:	
		
WB:
		;Water Logo movemente
		include "resources/Water_Effect.asm"
WE:	
PBP:
		;Preview screen routines
		include "resources/PreviewScreen.asm"
PEP:
Charset8x4:
		include "resources/charset8x4.asm"
Charset8x4END:

;;;;;;;;; MARIO PENDIENTE AL FINAL AJUSTAR ESTA RUTINA PARA QUE EL "HUECO" ENTRE LA ANTERIOR Y LA DE IM2 SEA LO MENOR POSIBLE
IMB:
		include "resources/IM2_routines.asm"		;IM2 routines used with "checkhardware.asm"
IME:

PBPR:
		include "resources/print.asm"			;Routine for printing icons and asociated info to selected file and navigation info
PEPR:
OB:
		include "resources/OtherTexts.asm"			;Other texts for different uses (more info inside the own file)
OE:
GetDANMENUData:
		include "resources/GetDANMENUData.asm"		;Get info about the 1st slot in the EEPROM
	
SBS:	
		include "resources/Sorting.asm"				;Sort routines
SES:
	IFDEF	debug
		include "debug.asm"
	ENDIF	

SB:
		;SD Directory and Files routines
		include "resources/SDRoutines.asm"
SE:	

showinfHB:
		;Check Hardware ZX Spectrum type
		include "resources/checkhardware.asm"
showinfHE:

		;Launch TAP routines
Load_FT_TAP:
		include "resources/launchTAP.asm"
ldtapE:

showinfSB:
		;Routines for buttons assignment
		include "resources/setbuttons.asm"
showinfSE:

showinfHWB:
		;Routines dan commands
		include "resources/dandanator_hw_90.asm"
showinfHWE:

showinfFB:
		include "resources/FiletypeTexts.asm"		;Additional text for Box
showinfFE:

	DEFINE SHOWINF

	IFDEF SHOWINF
		DISPLAY "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
		DISPLAY "loadroutines.asm: ",/A,LE-LB
		DISPLAY "dzx7_turbo.asm: ",/A,showinfdzxE-showinfdzxB
		DISPLAY "PathRoutines.asm: ",/A,PE-PB
		DISPLAY "Water_Effect.asm: ",/A,WE-WB
		DISPLAY "PreviewScreen.asm: ",/A,PEP-PBP
		DISPLAY "charset8x4.asm: ",/A,Charset8x4END-Charset8x4
		DISPLAY "IM2_routines.asm: ",/A,IME-IMB
		DISPLAY "IM2_routines Begin: ",IMB
		DISPLAY "IM2_routines End: ",IME
		DISPLAY "print.asm: ",/A,PEPR-PBPR
		DISPLAY "OtherTexts.asm: ",/A,OE-OB
		DISPLAY "Sorting.asm: ",/A,SES-SBS
		DISPLAY "SDRoutines.asm: ",/A,SE-SB
		DISPLAY "checkhardware.asm: ",/A,showinfHE-showinfHB
		DISPLAY "launchTAP.asm: ",/A,ldtapE-Load_FT_TAP
		DISPLAY "setbuttons.asm: ",/A,showinfSE-showinfSB
		DISPLAY "dandanator_hw_90.asm: ",/A,showinfHWE-showinfHWB
		DISPLAY "FiletypeTexts.asm: ",/A,showinfFE-showinfFB
		DISPLAY "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
		DISPLAY "FREE AREA #1000-2000: ",/A,#2000-$
		DISPLAY "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
	ENDIF

	DISPLAY "Espacio libre: ",/A,#2000-$

			DEFS	#2000-$,#FF						;Scratch sector for final routines for launching (each launch uses 16 bytes)
ScratchSECT:

			DEFS	#3000-$,#FF						;Data in last sector

showinfKB:
		;INT key routines
		include "resources/key_routines.asm"		;Routines for dealing with Keyboard/Joystick. 
showinfKE:


showinfHTB:
		include "resources/Hardware_table.asm"		;Hardware tables for Z80 snapshot as per v1/v2/v3
showinfHTE:

showinfIB:
		include "resources/iconos.asm"	;labels inside file
showinfIE:
				
showinf4bB:
		include "resources/4bits_load_relocatable.asm"
showinf4bE:

showinfEEB:

Load_FT_ROMSET:
			LD		HL,(Rom2Write)					;Address of romset info to write
		include "resources/Multiply_eewriter.asm"
showinfEEE:

showinfCB:
		;Clear Row
		include "resources/clearrow.asm"
showinfCE:

PBB:
		;Browsing Directories
		include "resources/browse_dir.asm"
PEB:	

ReturnTOBASIC:
		include "resources/ZXBasic.asm"
ENDReturnTOBASIC:

;;;;;ADDITIONAL DATA FOR MLD-FOOTER

screenzx7:
		incbin "resources/Menu.scr.zx7"
screenzx7end:

DataTable:
			defb	0
ENDDataTable:
DataSize	EQU ENDDataTable-DataTable
DataTableE:


	IFDEF SHOWINF
		DISPLAY "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
		DISPLAY "key_routines.asm: ",/A,showinfKE-showinfKB
		DISPLAY "Hardware_table.asm: ",/A,showinfHTE-showinfHTB
		DISPLAY "Iconos.asm: ",/A,showinfIE-showinfIB
		DISPLAY "4bits_load_relocatable.asm: ",/A,showinf4bE-showinf4bB
		DISPLAY "Multiply_eewriter.asm: ",/A,showinfEEE-showinfEEB
		DISPLAY "clearrow.asm: ",/A,showinfCE-showinfCB
		DISPLAY "browse_dir.asm: ",/A,PEB-PBB
		DISPLAY "ZXBasic.asm: ",/A,ENDReturnTOBASIC-ReturnTOBASIC
		DISPLAY "Menu.scr.zx7: ",/A,screenzx7end-screenzx7
		DISPLAY "DataTable: ",/A,DataTableE-DataTable
		DISPLAY "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
		DISPLAY "FREE AREA #3000-Footer: ",/A,16362-$
		DISPLAY "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
	ENDIF

; _      _     ___         ____  ___   ___  _____  ____  ___
;| |\/| | |   | | \  ___  | |_  / / \ / / \  | |  | |_  | |_)
;|_|  | |_|__ |_|_/ |___| |_|   \_\_/ \_\_/  |_|  |_|__ |_| \
			DEFS	16362-$,#FF		;Fill block up to data required at the end of this MLD slot
MLDoffset	DEFB	0				;Value to be modified by java generator. Value 0..31 (slot number in which this MLD is)
MLDtype		DEFB	#83				;#83 = 48k // #88 = 128k // #C8 = +2A
nsectors	DEFB	0				;Num. of sectors requered for saving special data (0=not used, 1..4=n. sectors)
sector0		DEFB	0				;1st sector for saving data 4Kb (0=not used)
sector1		DEFB	0				;2nd sector 4k (0=no usado)
sector2		DEFB	0				;3rd sector 4k (0=no usado)
sector3		DEFB	0				;4rd sector 4k (0=no usado)
			DEFW	DataTable		;Data Table address (relative to 1st slot)
			DEFW	DataSize				;Length of each row of DataTable
			DEFW	(ENDDataTable-DataTable)/DataSize	;Total rows of Data in DataTable
			DEFB	0				;Slot is in +1 (byte offset in row of Data)
			DEFW screenzx7;screenzx7-MENUBEGIN+scroffset		; addr=begin screen zx7 
			DEFW screenzx7end-screenzx7				; size=len screen zx7	

			DEFB	"MLD",0			;MLDn n=version 

;Next slot is the Patched ROM for LaunchTAP
			incbin	"../Multiply TAP Gen rom modif/ROMMULTTAP.BIN"
