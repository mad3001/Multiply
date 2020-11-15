;Print Info routines.....Icon routines and info box

RowIconSel		equ		2							;Row (0..23) for showing Icon16x16 info of selected
ColIconSel		equ		17							;Column (0..31) for showing Icon16x16 info of selected
RowDescSel		equ		2							;Row (0..23) for showing Desc of selected
ColDescSel		equ		19*2						;Column (0..63) for showing Desc info of selected
ColOPTSel		equ		17*2						;Column (0..63) for showing Options info of selected
WidthDesc		equ		24							;Num of columns into box for Descs

Colour_Cloud	equ	%01101111						;No Flash, Bright, Paper Cyan, Ink White
Colour_ROMSET	equ %01001111						;No Flash, Bright, Paper Blue, Ink White

;Print Icon8x8 for current item Locate, by filetype, the 1st Icon equal or greater (they are sorted low to high)
;PrintIcon8x8 - Print Icon8x8 as per B reg into Row D and Column E
PrintIcon8x8:
			PUSH 	DE								;Row,column for priting
			LD		HL,Icons						;Icons for filetype
			LD		DE,IconNext						;Offset from Icon to Next Icon
Icon_Loop8x8:
			LD		A,(HL)							;A=current type
			CP		B								;A-B = current type-file type searching
			JR		NC,Icon_Located8x8				;A-B >= 0 finish loop
			ADD		HL,DE
			JR		Icon_Loop8x8
Icon_Located8x8:
			LD		DE,Icon8x8						;Offset from Icon type to Icon 8x8 data
			ADD		HL,DE							;Position of Icon8x8 info (8 bytes pixel and 1 byte attribute)
		;HL is the position of the Icon8x8
			POP		DE								;Row,column for priting
			PUSH	DE								;Row,column for priting
			PUSH	HL								;Address of Icon8x8
			CALL	XYtoAddr						;with D=Row, E=Col, returns HL=position in screen
			POP		DE								;Address of Icon8x8
			
			LD	B,8									;Printing 8 scanlines
PrintIcon8x8_Loop:
			LD	A,(DE)
			LD	(HL),A
			INC	DE									;Next byte of Icon8x8
			INC H									;Next scanline in screen
			DJNZ PrintIcon8x8_Loop
			
			LD	A,(DE)								;A=attribute colour
			LD	C,A									;C=Attribute colour
			
			POP DE									;DE=row,column to print
			CALL XYtoAttr							;Calculate attr screen pos, HL=position in screen
			LD	(HL),C								;Change attribute colour
			RET

;Print Icon16x16 for current item Locate, by filetype, the 1st Icon equal or greater (they are sorted low to high)
;PrintIcon16x16 - Print Icon16x16 as per B reg into Row RowIconSel and Column ColIconSel
PrintIcon16x16:
			LD		HL,Icons						;Icons for filetype
			LD		DE,IconNext						;Offset from Icon to Next Icon
Icon_Loop16x16:
			LD		A,(HL)							;A=current type
			CP		B								;A-B = current type-file type searching
			JR		NC,Icon_Located16x16			;A-B >= 0 finish loop
			ADD		HL,DE
			JR		Icon_Loop16x16
Icon_Located16x16:
			INC		HL
		;HL is the position of the pixels info for Icon16x16

			RowCol2PIX DE, RowIconSel, ColIconSel

			CALL	Print8x16
			
			RowCol2PIX DE, RowIconSel+1, ColIconSel

			CALL	Print8x16
			
			RowCol2ATTR DE,RowIconSel, ColIconSel
			LDI
			LDI										;Copied 2 attributes

			RowCol2ATTR DE,RowIconSel+1, ColIconSel
			LDI
			LDI
			RET

Print8x16:
			LD	B,8									;Printing 8 scanlines
PrintIcon16x16_Loop:
			LD	A,(HL)
			LD	(DE),A
			INC	HL									;Next byte of Icon16x16
			INC DE									;Next byte (2nd column in screen)
			LD	A,(HL)
			LD	(DE),A
			DEC DE									;Prev byte (1st column in screen)
			INC	HL									;Next byte of Icon16x16
			INC D									;Next scanline in screen
			DJNZ PrintIcon16x16_Loop
			RET
	
;MiniScreenAttrs - Change attributes to miniscreen Preview
MiniScreenAttrs:
		;Here to clear attributes as per C reg in preview
			LD		B,12
			LD		HL,#5800+(PreviewRow*32)+PreviewCol	;Attr address of preview screen
			LD		DE,16
PrintClrPreview_Loop:
			LD		A,E
PrintClrPreview2_Loop:		
			LD		(HL),C							;Colour of Attr
			INC		HL
			DEC		A
			JR		NZ,PrintClrPreview2_Loop
			ADD		HL,DE							;Skip Columns not used by preview
			DJNZ	PrintClrPreview_Loop
			RET

;MiniScreenCloud - Paint Miniscreen with Cloud Effect rom pseudo-random numbers
MiniScreenCloud:
			LD		C,Colour_Cloud					;Attribute colour cloud
			CALL	MiniScreenAttrs
		;Now fill Pixels with "random" values... using a mix of "R" reg and value from own romset 0-#5FF is used (8 x 16 x 12)

			
			RowCol2PIX HL, PreviewRow, PreviewCol	;DE = Addr for pix in Row,Col of MiniScreen

			LD		DE,16							;offset btw scanlines
			LD		C,12							;C=num of Rows to process
MSC_Next:
			PUSH	HL
MSC_Scan:	
			LD		B,16							;B=Rows to process
			PUSH	HL
MSC_Row:
			LD		A,R
			RES		6,H								;Convert HL address into a ROM address
			XOR		(HL)							;Should be enoght for a pseudo-random
			SET		6,H								;Convert HL address into a Screen address
			LD		(HL),A							;Update pixels
			INC		HL
			DJNZ	MSC_Row
			POP		HL
			INC		H								;Next scanline for this row
			LD		A,H
			AND		7
			JR		NZ,MSC_Scan						;Repeat until done 8 scanlines
			POP		HL
			ADD		HL,DE
			;AQUI CHEQUEAR....si L es 0 (cambio de Third) #4900 tiene que pasar a #4800
			LD		A,L
			AND		A
			JR		NZ,MSC_NoThirdChg
		;Here change of third
			LD		A,7
			ADD		A,H
			LD		H,A								;So #4100->#4800 or #4900->#5000
MSC_NoThirdChg:
			ADD		HL,DE
			DEC		C
			JR		NZ,MSC_Next
			
			RET
			
;MiniScreenEmpty - Paint Miniscreen with C attributes and empty pixels
MiniScreenEmpty:
			;LD		C,Colour_
			CALL	MiniScreenAttrs
		;Now fill Pixels with "random" values... using a mix of "R" reg and value from own romset 0-#5FF is used (8 x 16 x 12)

			
			RowCol2PIX HL, PreviewRow, PreviewCol	;DE = Addr for pix in Row,Col of MiniScreen

			LD		DE,16							;offset btw scanlines
			LD		C,12							;C=num of Rows to process
MSE_Next:
			PUSH	HL
MSE_Scan:	
			LD		B,16							;B=Rows to process
			PUSH	HL
MSE_Row:
			LD		(HL),0							;Empty pixels
			INC		HL
			DJNZ	MSE_Row
			POP		HL
			INC		H								;Next scanline for this row
			LD		A,H
			AND		7
			JR		NZ,MSE_Scan						;Repeat until done 8 scanlines
			POP		HL
			ADD		HL,DE
			;AQUI CHEQUEAR....si L es 0 (cambio de Third) #4900 tiene que pasar a #4800
			LD		A,L
			AND		A
			JR		NZ,MSE_NoThirdChg
		;Here change of third
			LD		A,7
			ADD		A,H
			LD		H,A								;So #4100->#4800 or #4900->#5000
MSE_NoThirdChg:
			ADD		HL,DE
			DEC		C
			JR		NZ,MSE_Next
			
			RET

;PrintIXInfo - Print Info in right box
PrintIXInfo:
			LD		B,(IX)							;B=File 
			CALL	PrintIcon16x16					;Print Icon16x16 into Row RowIconSel and Column ColIconSel
			;JP		PrintFileType					;Print FileType additional information
			
;PrintFileType - Additional info of file in the right BOX
PrintFileType:
		;Now check filetype in order to update BOX with the correspondent information
			LD		A,(IX)							;A=Filetype
			CP		FT_SCR
			JR		Z,PrintFileType_SCR
			JR		C,PrintFileType_NoPreview		;Less than FT_SCR does not show preview
			CP		FT_Z80_SCR
			JR		C,PrintFileType_Z80
			CP		FT_SNA_SCR+1
			JR		NC,PrintFileType_NoPreview		;Greater than FT_SNA_SCR does not show preview
			LD		A,FT_SNA_SCR
			JR		PrintFileType_SCR
PrintFileType_Z80:
			LD		A,FT_Z80_SCR
			LD		(PreviewFT),A					;Update type so we call correct command to load scr preview
			JR		PrintFileType_NoPreview			;Don't call OFREAD_IX at this moment... will do it after GetInfo
PrintFileType_SCR:
			LD		(PreviewFT),A					;Update type so we call correct command to load scr preview
PrintFileType_Preview:
	
		;Here for scr/sna so activate preview
			LD		(PreviewIX),IX					;Save address of file to show preview
			CALL	Print_RQ_Preview				;Activate preview

			
PrintFileType_NoPreview:
			PUSH	IX								;Pointer to FileData

			LD		A,(MsgDegrad)					;Degraded message was show if A<>0
			AND		A								;check for 0x00
			JR		Z,ChaptMsg_End					;0x00 for no Message

			BIT		7,A								;Bit 7 = 0 if message not show yet / Bit 7 = 1 if was shown
			JR		NZ,ChaptMsgShown

			PUSH	AF
			LD		C,%01101000
			CALL	MiniScreenEmpty
			
			LD		IX,TXTDEGRA
			POP		AF
			DEC		A
			JR		Z,ChaptMsg
			
			LD		IX,TXTTOODEGRA
ChaptMsg:

			LD		DE,32+(11<<8)					;D=Row 11, E=Column 32
			CALL	PrintIXText						;Print text in IX at Row D, Column E
			LD		DE,32+(13<<8)					;D=Row 13, E=Column 32
			CALL	PrintIXText						;Print text in IX at Row D, Column E
			LD		DE,32+(15<<8)					;D=Row 15, E=Column 32
			CALL	PrintIXText						;Print text in IX at Row D, Column E

			LD		HL,MsgDegrad
			SET		7,(HL)							;Active bit degradation
			JR		ChaptMsg_End
			
ChaptMsgShown:
			CALL	MiniScreenCloud
			XOR		A
			LD		(MsgDegrad),A					;Clear variable, not needed anymore for this folder

ChaptMsg_End:
			POP		IX								;Pointer to FileData
			PUSH	IX								;Pointer to FileData

			LD		B,(IX)							;B=File type searching
			LD		HL,FileTypeTexts				;Table for filetype texts
			LD		DE,FileTypeTexts_Size			;Offset btw record of table
PrintFileType_Search:
			LD		A,(HL)							;A=current type
			CP		B								;A-B = current type-file type searching
			JR		NC,PrintFileType_Found			;A-B >= 0 finish loop
			ADD		HL,DE
			JR		PrintFileType_Search
PrintFileType_Found:
			INC		HL
		;HL is the position of the Record for text as per Type
			LD		A,(HL)
			LD		IXL,A
			INC		HL
			LD		A,(HL)
			LD		IXH,A							;IX points to text to print
			
			LD		DE,ColDescSel + (RowDescSel << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for 1st row of box

			LD		DE,ColDescSel + ((1+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for 2nd row of box

			LD		DE,ColDescSel + ((2+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for 3rd row of box

			LD		DE,ColDescSel + ((3+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for 4rd row of box

			LD		DE,ColOPTSel + ((5+RowDescSel) << 8)
			CALL	PrintIXText_Spaces				;Print text in IX for text outside the box
			POP		IX								;Pointer to FileData
			LD		A,(IX)							;A=Filetype
			CP		FT_TAP
			JP		NZ,PrintF_NoTAP
			
		;Here for TAP type
			LD		A,(IX)							;A=Filetype
			LD		(PreviewIX),IX					;Provisionally Save address of file to show preview

			LD		DE,11							;Length to retrieve for TAP type
			CALL	DO_GetInfo						;Ask Arduino for 11 bytes of info about TAP file
			
			LD		IX,BufGetInfo					;Buffer readed
			LD		(IX+11),0						;Be sure program name ends with 0x00
			LD		A,(IX)							;Gets info about TAP having Screen: 0x00 = No, 0x01=Yes
			LD		(PreviewStat),A					;Update preview stat: 0x00 for no preview, 1 for begin to load for preview
			AND		A
			JR		Z,Tap_nopreview
			LD		A,CMD_ZX2SD_SCRTAP
			LD		(PreviewFT),A					;Update preview type
Tap_nopreview:
			INC		IX								;IX Points to PROGRAM name
			LD		DE,ColDescSel + ((3+RowDescSel) << 8)+(FT_TAP_Program2-FT_TAP_Program)
			CALL	PrintIXText						;Print PROGRAM name and return from there to menu
			LD		A,(BufGetInfo)
			AND		A
			RET		NZ
			LD		IX,TXTTAPnoScreen				;Print text about TAP no having screen
			LD		DE,ColDescSel + 2 + ((2+RowDescSel) << 8)
			CALL	PrintIXText
			RET
		;END OF TAP GET INFO PROCESSING
		
PrintF_NoTAP:
			CP		FT_ROMSET
			JP		NZ,PrintF_NoROMSET

		;Here for ROMSET TYPE
			LD		A,(CurRow)
			CP		MinRowFiles
			JR      NZ,Do_ROMSETINFO				;No 1st row then it's a SD ROMSET selected..... If romset and 1st row is because it's "../Dandanator MENU" 
		;check for 1st page to be sure is going to Dandanator 1st slot or it's a ROMSET in another page (not 1st)
			LD 		A,(CurPage)
			DEC 	A
			JR 		NZ,Do_ROMSETINFO				;No 1st row is because we selected a file of type ROMSET in 2nd or later-on page
		;Here for ../Dan
			LD		HL,InfoVersion
			LD		DE,BufGetInfo
			LD		BC,9
			LDIR
			JR		Do_ROMSETPrint					;Skip get info from Multiply and directly print the info into the BOX
		
Do_ROMSETINFO:
			LD		A,(IX)							;A=Filetype
			
			LD		DE,9							;Length of additional info
			CALL	DO_GetInfo						;Ask Arduino for 9 bytes of info about ROMSET

			LD		HL,BufGetInfo
			LD		DE,ROMVersion
			LD		BC,8
			LDIR
			XOR		A
			LD		(DE),A							;Copied there for later-on usage
			
Do_ROMSETPrint:
			;1st Print version
			
			LD		IX,BufGetInfo					;Buffer readed
			LD		A,(IX+8)						;Num of Games (0..25)
			LD		(IX+9),A						;Save for later-on
			LD		A,(IX)							;Major version
			CP		#FF								;Check for no valid
			JR		NZ,Valid_ROMSE
		;Here for no valid romset
			LD		(IX),"-"
			LD		(IX+1),"-"
			LD		(IX+2),"-"
			LD		(IX+3),0x00
			JR		Text_ROMSE
Valid_ROMSE:			
			LD		(IX+8),0						;Ending (if version use the 8 bytes)
Text_ROMSE:
			LD		DE,((RowDescSel+1)<<8)+ColDescSel+(FT_R_V2-FT_R_V)
			CALL	PrintIXText						;Print Version as per IX in Row D, Column E
			;2nd Print Num of Games
			LD		IX,BufGetInfo
			LD		A,(IX+9)						;Num of Games (0..25)
			CP		MAXGAMES+1						;Check for no valid (great than max number of games in romsets)
			JR		C,Valid_Games
			LD		(IX),"-"
			LD		(IX+1),"-"
			LD		(IX+2),0x00
			JR		PrintGames
Valid_Games:
			LD		(IX),"0"						;Prepare Tens of Num of Games for the case Games:0 .. 9
			LD		A,(IX+9)						;Num of Games (0..25)
TestTens:
			CP		10
			JR		C,No_Tens
			INC		(IX)							;Change "0" to "1".... "1" to "2"
			SUB		10
			JR		TestTens
			
No_Tens:
			ADD		A,"0"							;Convert number in Char of digit 0..9
			LD		(IX+1),A						;Store Units
			LD		(IX+2),0						;End of text to print
			LD		A,(IX)
			CP		"0"
			JR		NZ,PrintGames
			LD		(IX)," "						;If no tens then update with space
PrintGames:
			LD		DE,((RowDescSel+2)<<8)+ColDescSel+2
			CALL	PrintIXText						;Print text in IX in Row D, Column E and return from there

		;Now Get Games and save into table
			LD		A,(CurPage)
			DEC		A
			JR		NZ,NoInternalROMSET				;Only Internal Romset in 1st page
			
			LD		A,(CurRow)
			CP		MinRowFiles
			RET		Z								;Return if selected is "Internal Romset"-> MARIO PENDIENTE AUN SIN PREVIEW

NoInternalROMSET:
			LD		A,(BufGetInfo+9)				;Num of games (0..25)
			AND		A
			RET		Z								;No games, no preview
			
		;Here for external romset...Get data for preview -> MARIO PENDIENTE PONER DATOS EN "MINISCREEN" Y CAMBIAR ATTRIBUTES PARA QUE SE VEA (no usa PREVIEW)
			CP		MAXGAMES+1						;Check for no valid (great than max number of games in romsets)
			RET		NC								;Return if num of games >25
		;Now calculate how much bytes to get (all the games at once time)
			LD		H,0
			ADD		A,A								;A=N.Games * 2 (1..25 => 2..50)
			ADD		A,A								;A=N.Games * 4 (2..50 => 4..100)
			LD		E,A								;E=N.Games * 4
			LD		D,H								;DE=N.Games * 4
			ADD		A,A								;A=N.Games * 8 (4..100 => 8..200)
			LD		L,A								;HL=N.Games * 8
			ADD		HL,HL							;HL=N.Games * 16
			ADD		HL,HL							;HL=N.Games * 32
			ADD		HL,DE							;HL=N.Games * 32 + N.Games * 4 = N.Games * 36

			EX		DE,HL							;DE=Total of bytes to get
			
		;DE=Num of games * 36
			LD		HL,ScreensSCR					;Games will be hold there
			CALL	Load4bitBlk						;Get Game data
			
			INC		HL								;Skip last address with data received
			LD		(HL),0							;Will update after last game with 0x00 (no more games)
			LD		A,PreviewROMSET
			LD		(PreviewStat),A					;Set preview for ROMSET (will be shown further if no keys pressed)

			LD		A,1
			LD		(PrevROMPag),A					;Cur number of page 1
			
			LD		A,(BufGetInfo+9)				;Num of games (1..25)
			LD		B,1
			CP		11
			JR		C,.nomore
			INC		B
			CP		21
			JR		C,.nomore
			INC		B
.nomore:
			LD		A,B								;Num of max pages
			LD		(PrevROMxPag),A					;Max number of pages (1.2.3)
			
			RET
			
		
PrintMyROMSET_NextPage:
			LD		A,(PrevROMxPag)
			CP		1
			RET		Z								;Only 1 page nothing to do here
			
			LD		HL,PrevROMTime
			DEC		(HL)							;Countdown timer
			RET		NZ								;Return if timing did not expire
			
			JR		PMR_Page
		
;PrintMyROMSET - Here for Print Games of a ROMSET
PrintMyROMSET:
			LD		A,(PreviewStat)					;Check if we're in preview for ROMSET
			CP		PreviewROMDone					;IF was printed previously jump there
			JR		Z,PrintMyROMSET_NextPage
			CP		PreviewROMSET
			INC		A								;Convert into PreviewROMDone
			LD		(PreviewStat),A					;Mark as Preview Done (so no repeat -only repeat for new pages when more than 1 page-)

PMR_Page:			
			LD		C,Colour_ROMSET					;Attribute colour ROMSET
			CALL	MiniScreenEmpty					;Set attributes as per C and Empty miniscreen
			
		;print version string
			LD		IX,ROMVersion
			LD		DE,(PreviewCol*2)+((PreviewRow)<<8)	;1st Row of MiniScreen Preview, column 0 inside preview (same as dan menu)
			CALL	PrintIXText			
			
		;If more than 10 games print Pages number
			LD		A,(PrevROMxPag)					;Total of pages
			CP		1								;If 1 page then does not show info about that
			JR		Z,.nopages
		;Here for showing page number
			LD		A,PreviewMaxROM
			LD		(PrevROMTime),A					;Initialize preview of pages
			LD		IX,TXTROMPage					;Text of rompage for ROMSET
			LD		DE,(PreviewCol*2)+30+((PreviewRow)<<8)	;1st Row of MiniScreen Preview, column 23 inside preview (same as dan menu)
			CALL	PrintIXText
			
			LD		A,(PrevROMPag)					;Current page
			LD		IX,TXTNumber
			CALL	UnitAtoIX						;Convert reg A to number and store into (IX)

			LD		DE,(PreviewCol*2)+29+((PreviewRow)<<8)	;1st Row of MiniScreen Preview, column 26 inside preview (same as dan menu)
			CALL	PrintIXText

			LD		A,(PrevROMxPag)					;Max page
			LD		IX,TXTNumber
			CALL	UnitAtoIX						;Convert reg A to number and store into (IX)

			LD		DE,(PreviewCol*2)+31+((PreviewRow)<<8)	;1st Row of MiniScreen Preview, column 27 inside preview (same as dan menu)
			CALL	PrintIXText
		;Now printing games
.nopages:
			LD		IX,ScreensSCR					;Point to Screen so we can Show then
			LD		HL,PrevROMPag					;Address of Current page to print
			LD		A,(HL)							;Current page to print
			DEC		A
			JR		Z,.pages							;jump for Page 1
			LD		DE,36*10						;To skip as per each page
			ADD		IX,DE							;Next page
			DEC		A
			JR		Z,.pages						;jump for Page 2, continue for page 3
			ADD		IX,DE							;Next page
.pages:
			LD		A,(PrevROMxPag)					;Max numbers of pages
			INC		A								;1 more of last page to check page going beyond
			INC		(HL)							;Next page
			CP		(HL)							;Max pages - page
			JR		NZ,.games
			LD		(HL),1							;Reinitialize for page 1
.games:
			LD		DE,(PreviewCol*2)+((2+PreviewRow)<<8)	;1st Row of MiniScreen Preview
PrintGames_ROM_Loop:
			LD		A,(IX)
			AND		A
			RET		Z								;No more games, return
			PUSH	DE,IX
			CALL	PrintIXText
			POP		IX
			LD		DE,36							;MARIO cambiar a su etiqueta correcta
			ADD		IX,DE
			POP		DE
			INC		D								;Next Row
			LD		A,D
			CP		10+(2+PreviewRow)				;Maximun 10 Files per page
			RET		Z								;MARIO pendiente que hacer si hay más de 12 juegos
			
			JR		PrintGames_ROM_Loop

; END OF FT_ROMSET


;PrintF_NoROMSET - NO ROMSET file type.... If no Z80 then return to caller... Pending in future TAP / TZX / BIN / what else????
PrintF_NoROMSET:
			CP		FT_Z80_128K+1
			RET		NC								;Return if greater than FT_Z80_128K
			CP		FT_Z80_16K
			RET		C								;Return if lower than FT_Z80_16K
		;Here only for Z80 Snapshot
			LD		(PreviewIX),IX					;Save address of file to show preview
			LD		DE,3							;Length of additional info
			CALL	DO_GetInfo						;Ask Arduino for 3 bytes of info about Z80 Romset
			LD		IX,BufGetInfo					;Buffer readed
			LD		A,(IX+1)						;Value for Hardware Mode
			CP		#FF								;#FF for unknown (usually for v1)
			JR		Z,Z80_Unk
			CP		#80								;#80 Special case for TS2068
			LD		HL,HW_TS2068
			JR		Z,PrintF_Z80
			CP		#10								;Valid values are lower than 0x10
			JR		NC,Z80_Unk						;greater than 0x0F is unknown
		;Here for a "valid" number (0x00.0x0F)
			LD		HL,HW_Table
			LD		A,(IX)
			CP		#17								;Check for V2
			LD		A,(IX+1)						;Get Hard Mode
			JR		NZ,NoV2							;If was not v2 then jump
			CP		3
			JR		Z,IsV2
			CP		4
			JR		NZ,NoV2
IsV2:
			INC		A								;v2 change value 3..4 to 4..5 to correspond with v3
NoV2:
			CP		9								;Only check bit 7 for Machine btw 0..8
			JR		NC,HW_Machine
			
			BIT		7,(IX+2)						;Check bit 7 of 0x25 (1 for change of Machine)
			JR		Z,HW_Machine
			ADD		#10								;Change value to extended Hardware

HW_Machine:
			ADD		A,A								;A*2
			LD		E,A
			LD		D,0
			ADD		HL,DE							;HL=Position of pointer to text
			LD		E,(HL)
			INC		HL
			LD		D,(HL)							;DE=Address for text
			LD		IXL,E
			LD		IXH,D							;So IX points to Text of Machine
PrintF_Z80:
			LD		DE,((RowDescSel+3)<<8)+ColDescSel+(FT_Z80_V2-FT_Z80_V-1)
			CALL	PrintIXText						;Print text in IX in Row D, Column E

		;After all getinfo done, now we can request image preview
Print_RQ_Preview:
			LD		A,1
			LD		(PreviewStat),A					;Mark for loading
			RET
			
			
;Here for print Unknown version (usually for v1... v2 and v3 should meet a Hardware)
Z80_Unk:
			LD		IX,HW_Unknown
			JR		PrintF_Z80

;DO_GetInfo - Send command to Arduino to get additional data of a File
;	IN - IX points to File struct
;	IN - DE Number of bytes to ask for (or 0 if no response required)
DO_GetInfo:
			LD		A,CMD_ZX2SD_GETINFO
			;DI
			CALL	SendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+FILEINDEX)				;Low byte of index
			CALL	SendSerByteLC					;Command to ask for more info about file
			LD		A,(IX+FILEINDEX+1)				;High byte of index
			CALL	SendSerByte						;Command to ask for more info about file
						
			LD		HL,BufGetInfo
			JP		Load4bitBlk
			
			
;PrintIXText_Spaces - Print string (adding spaces at the end to fill upto last column of BOX)
;	IN - IX = Address for text to print (ending with 0x00)
;	IN - DE = D=Row, E=Column
;  OUT - IX = Address after the pos of the 0x00 of after the "spaces"
PrintIXText_Spaces:
			CALL	PrintIXText						;Print text in IX at Row D, Column E
			PUSH	IX

			LD		A,ColDescSel					;Initial column
			LD		IX,FT_EMPTY						;Points  spacetext
PrintFileType_Spaces:
			CP		E								;Check if arrived to column for printing
			JR		Z,PrintFileType_printit			;print spaces (or nothing if last column)
			INC		IX
			INC		A
			JR		PrintFileType_Spaces
PrintFileType_printit:
			CALL	PrintIXText						;Replace other possible chars in the row with "spaces"		
PrintFileType_End:
			POP		IX
			RET
			
;-----------------------------------------------------------------------------------------
; XYtoAddr - Converts a screen char coord  into a Pixel Address  d,e = y,x positions
;	IN  - D=Row(0..23), E=Column(0..31)
;	OUT - HL=Address of acanline 0 in Screen
;	Conversion:
;			Row FFfff   Column CCCCC
;			HL=%010FF000 fffCCCCC
;-----------------------------------------------------------------------------------------
XYtoAddr:
		;Calculate addr of scanline 0 of the char in screen.
;   Input	: DE => Row D=0..23, Column E=0..31
;	Output  : HL = Address of scanline0 in Screen
;   		How to calc the pixels of screen:
;			Row (bit) 43210	  Column(bit) 43210
; 					  RRrrr				  ccccc
;			Address (High)	76543210	(Low) 76543210
;							010RRsss		  rrrccccc
;   				RR -> 00 = Block.0, 01=B.1 10=B.2
;					rrr = row (0..7) / combining RR & rrr it's the 24 rows (0..23)
;					ccccc -> column (0..31) / sss -> n.scanline (0..7)
				LD		A,D				;	000RRrrr  <=Row 0..23
				.3 RRCA					;	rrr000RR
				AND		%11100000		;	rrr00000
										;E=	000ccccc  <=Column 0..31
				OR		E				;	rrrccccc
				LD		L,A				;L= rrrccccc

				LD		A,D				;	000RRrrr  <=(Row 0..23)
				AND		%00011000		;	000RR000
				OR		%01000000		;	010RR000
				LD		H,A				;H=	010RR000 <-scan line 0
				RET						;HL=010RR000 rrrccccc

;-----------------------------------------------------------------------------------------
; XYtoAttr - Converts a screen char coord  into a ATTR Address  d,e = y,x positions
;	IN  - D=Row(0..23), E=Column(0..31)
;	OUT - HL=Address of Attribute in Screen
;	Conversion:
;			Row FFfff   Column CCCCC
;			HL=%010110FF fffCCCCC
;-----------------------------------------------------------------------------------------
XYtoAttr:
;Calculate addr of Attribute screen.
;   Input	: DE => Row D=0..23, Column E=0..31
;	Output  : HL = Address of Attribute in Screen
;   		How to calc the Attribute of screen:
;   		Attribut Row	76543210	Col	76543210
;							000RRrrr		000ccccc
;			Address (High)	76543210  (Low) 76543210
;							010110RR		rrrccccc
;							RR -> 00 = Block.0, 01=B.1 10=B.2
;							rrr = row (0..7) / combining RR & rrr it's the 24 rows (0..23)
;							ccccc -> column (0..31)
				LD		A,D				;	000RRrrr	(Fila 0..23)
				.3 RRCA					;	rrr000RR
				LD		H,A				;H=	rrr000RR	for calculate High Addr later-on
				AND		%11100000		;A=	rrr00000
				OR		E				;A=	rrrccccc
				LD		L,A				;L=	rrrccccc
				
				LD		A,H				;	rrr000RR
				AND		%00000011		;	000000RR
				OR		%01011000		;	010110RR
				LD		H,A				;H=	010110RR

				RET						;HL = 010110RR rrrccccc

;RowAttrMod - change attribute colours at Row D(0..23), Column E(0..31) with attribute B for a number of byte as per C
RowAttrMod:
			CALL	XYtoAttr			;HL=Attr pos
			LD		D,H
			LD		E,L
			INC		DE					;DE=Next attr pos
			LD		(HL),B				;Change colour to 1st position
			DEC		C
			RET		Z					;Is C was 1 then don't have to do the LDIR
			LD		B,0					;So BC is quantity
			LDIR						;Copy colour to all positions
			RET
			
;RowAttr - change attribute bright for the file selected, 1st char (icon) does not change ink, only bright
;		also if row is MinRowFiles (where page number is) and LastPages>1, then it does not change
;	IN A - Row
;	IN C - Attribute colour
RowAttr:
			PUSH	AF								;Saving Row
			LD		D,A								;D=Row
			LD		E,0								;A=Column 0
			CALL	XYtoAttr						;HL=Attr in screen
			LD		A,(HL)
			;AND		7
			;OR		E
			XOR		NoSel_Color^Selec_Color			;Swap Selec_Color <->NoSel_Color
			LD		(HL),A							;Attribute for the selected/nonselected
			INC		HL
			LD		(HL),C							;Attribute colour
			LD		D,H
			LD		E,L
			INC		DE
			LD		BC,Sel_Bar_Len-1-1				;Filling attributes Bar - Icon - 1st byte filled with LD (HL),C
			POP		AF
			CP		MinRowFiles						;Check if is the 1st
			JR		NZ,RowAttrNo1st
			LD		A,(LastPages)
			CP		1								;Check if only 1 page
			JR		Z,RowAttrNo1st
			LD		BC,Sel_Bar_Len-1-1-((TXTMaxPageEmpty-TXTPageof-1)/2) ;does not change attr for Page Number
RowAttrNo1st:
			LDIR
			RET

;NumberAtoIX - Convert a number (2 digits) into text (routine add 0x00 at the end)
;	IN  A = Number to print
;	IN  IX = Address where to put the chars (changes IX and IX+1, also IX+2 store 0)
;	A is saved so can be used after routine
NumberAtoIX:
			PUSH	AF
			LD		C,0								;C will hold Tens
NumberAtoIX_Loop:
			SUB		10
			JR		C,NumberAtoIX_NoTens
		;Here if have tens
			INC		C								;Increment Tens
			JR		NumberAtoIX_Loop
			
NumberAtoIX_NoTens:
			ADD		10+"0"							;Recuperate Units and also convert to Char
			LD		(IX+1),A						;Store Units as char
			LD		A,C
			AND		A
			JR		Z,NumberAtoIX_TenIsZero
			ADD		"0"								;Convert Tens to Char
			JR		NumberAtoIX_TenNoZero
NumberAtoIX_TenIsZero:
			LD		A," "
NumberAtoIX_TenNoZero:
			LD		(IX),A							;Store Tens as char
			LD		(IX+2),0						;Add a zero at the end for use with PrintIXText
			POP		AF
			RET
	
;UnitAtoIX - Convert a number (1 digit) into text (routine add 0x00 at the end)
;	IN  A = Number to print
;	IN  IX = Address where to put the chars (changes IX, also IX+1 store 0)
;	A is saved so can be used after routine
UnitAtoIX:
			PUSH	AF
			ADD		"0"								;Unit to char
			LD		(IX),A							;Store Units as char
			LD		(IX+1),0						;Add a zero at the end for use with PrintIXText
			POP		AF
			RET	
			
;PrintIXText - Print Text in screen. D=Row, E=Column
PrintIXText:
			PUSH 	DE								;Save copy D=Row, E=Column
			AND		A								;Clear carry
			RR		E								;Half value and bit to carry
			LD		BC,#F00F						;C=#0F for left char in screen to clear (Carry=0, even column) B=#F0 for left char to add from charset
			JR		NC,CharEven						;Carry bit for odd value
			LD		BC,#0FF0						;C=#F0 for right char in screen to clear (Carry=1, odd column) B=#0F for right char to add from charset
CharEven:
			CALL	XYtoAddr						;Calculate pix address from D=Row, E=Column => HL=Pix address
			POP		DE								;D=Row, E=Column as per input
			
		;so HL=Address in screen for pixels
PrintIXText_Loop:
			LD		A,(IX)							;A=Char to print
			INC		IX								;IX point to next char for next time
			AND		A								;Check if A=0 (end of text)
			RET		Z								;If end of text then return
			CALL	PrintChar
			INC		E								;Only column is updated
			JR		PrintIXText_Loop
			
		;This is the PrintChar routine
PrintChar:
			PUSH	DE								;D=Row, E=Column 
			PUSH	HL								;Save HL=Address in screen to print
	;Here for printing a char 32..139
			LD		L,A								;4Ts
			LD		H,0								;7Ts
			ADD		HL,HL							;11 *2
			ADD		HL,HL							;11 *4
			ADD		HL,HL							;11 *8
			LD		DE,Charset8x4-(32*8)			;10
			ADD		HL,DE							;11
	;HL=Address in charset
			EX		DE,HL							;DE=Address in charset
			POP		HL								;HL=Address in screen to print
			PUSH	HL								;HL=Address in screen to print

	;CharLoop for the 8 scanlines
CharLoop:
			LD		A,(HL)							;A=Value on screen so we change only the correct nibble
			AND		C								;Clear nibble we're going to use, mantain the other nibble of screen
			LD		(HL),A							;Update in screen clearing the nibble we're going to change
			LD		A,(DE)							;Value of char (remember it have repeated the scanline in both nibbles)
			AND		B								;Isolate Left/Right as per column even/odd
			OR		(HL)							;"Mix" nibble in screen with nibble in A
			LD		(HL),A							;Store update nibble
			INC		DE								;Next scanline of char in charset
			INC		H								;Next scanline in screen
			LD		A,H
			AND		7
			JR		NZ,CharLoop						;So repeat until again we have an scanline 0
			POP		HL								;HL=Address in screen to print
			POP		DE								;D=Row, E=Column 
			LD		A,B
			LD		B,C
			LD		C,A								;Swapped B<->C values #0F <-> #F0
			AND		A								;and activate Sign as per #0F (positive) , #F0 (Negative)
			RET		M								; Increment HL only when A=#0F (positive). Return if A=#F0 (Negative)
			INC		HL
			RET
