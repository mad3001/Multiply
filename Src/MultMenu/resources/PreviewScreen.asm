;PreviewScreen
PreviewRow		equ		8
PreviewCol		equ		16
UsedRows		equ		12

LastRow			equ		PreviewRow+UsedRows				;When arriving to this Row in Screen process will finish
HLRow			equ		PreviewCol +16 + ((LastRow & 7)<<5) + (($58 | (3 & (LastRow>>3))) <<8 )	;Equivalent to Attribute Addr for that LastRow

SCRAttr			equ		ScreensSCR+#1800	

SRC1TH			equ		HIGH SCRAttr					;1st Third of screen
SRC2TH			equ		HIGH SCRAttr + 1				;2nd Third of screen
SRC3TH			equ		HIGH SCRAttr + 2				;3rd Third of screen

SRC1PX			equ		HIGH ScreensSCR					;1st Third of screen
SRC2PX			equ		HIGH ScreensSCR + 8				;2nd Third of screen
SRC3PX			equ		HIGH ScreensSCR + 16			;3rd Third of screen

SCR_BLKSIZE	equ		432

PreviewSHOWING	equ		1+(6912/SCR_BLKSIZE)			;Value in which the preview is launched
PreviewROMSET	equ		PreviewSHOWING+1				;Value in which ROMSET preview could be done
PreviewROMDone	equ		PreviewROMSET+1					;Value in which ROMSET preview was done

PreviewInit:
			LD		A,(PreviewStat)
			CP		PreviewSHOWING					;Greater or equal to PreviewSHOWING have to repaint a new cloud
			JR		C,PreviewInit_NoHadPreview		;If no showing then we had a cloud, so no paint a new one
			CP		PreviewROMSET
			JR		Z,PreviewInit_NoHadPreview		;If PreviewROMSET was not executed, skip create new cloud
PreviewInitial:
			CALL	MiniScreenCloud					;Repaint Screen cloud
PreviewInit_NoHadPreview:

			XOR		A
			LD		(PreviewStat),A					;Initialize preview to 0 (nothing)
			LD		(PreviewFT),A					;0=Nothing to preview
			LD		A,1								;Value = 1 so 1st time appears just after loaded
			LD		(PreviewCnt),A					;So when activated it appears quickly
			LD		A,PreviewLoadWait+1				;So 1st OFREAD will begin not  this int, in the next time
			LD		(PreviewLoad),A					;Max Counter for preview while loading
			LD		HL,#5800+(PreviewRow*32)+PreviewCol+16	;Destination Attr address in screen, always is the same
			LD		(RepDest),HL
			LD		HL,TableMove					;Table of movements
			LD		(LastMove),HL
			RET

;INTpreview - Interruption for preview (load/show)		
INTpreview:
			LD		A,(PreviewStat)					;0 no preview, 1..nn Loading blocks, nn+1 Show preview.
			AND		A
			RET     Z ;JR		Z,PreviewInit
			
			CP		PreviewROMSET
			JP		NC,PrintMyROMSET				;For PreviewROMSET or PreviewROMDone jump there

			CP		PreviewSHOWING					;Check if PreviewStat was nn+1 (it was increases INC A)
			JR		Z,Preview_Show					;Full Image was loaded so can be previewed

		;Check if we did open file (PreviewStat=1 for not open)
			;LD		A,(PreviewStat)
			CP		1								;Check if this is the 1st block
			JR		NZ,INTpreview_NoFirst
		;Here only for 1st block load
			LD		A,(PreviewLoad)
			CP		PreviewLoadWait					;Check if was initialized with PreviewLoadWait (new file preview initialized)
			JR		NZ,INTpreview_NoFirst

			DEC		A
			LD		(PreviewLoad),A					;Update ints wait for loading
			
			LD		IX,(PreviewIX)					;Restore File selected
			LD		A,(IX)
			CP		FT_TAP							;Check if TAP screen (don't use OFREAD)
			JR		Z,Preview_Busy					;      (file is opened and located in screen)
			LD		D,(IX+FILEINDEX)				;Low Byte of Index
			LD		E,(IX+FILEINDEX+1)				;High Byte of index
			LD		A,CMD_ZX2SD_OFREAD_IX			;Command = Open File (Relative Path)
INTpreview_Open:
			AND		A	;SCF for long					;Short confirmation for last byte sent (loading will begin a lot of time after this)
			CALL 	ZX2SD_COMMAND				
			JR		Preview_Busy
			
INTpreview_NoFirst:
		;Check if is time for loading a "piece"	
			LD		A,(PreviewLoad)					;Count for loading blocks so no all ints load data
			DEC		A
			LD		(PreviewLoad),A					;Reinit ints wait for loading
			JR		NZ,Preview_ExitZ				;No loading, jump there to return as (nothing special done)


			CALL	Preview_Subload					;Load a "piece"
			LD		HL,PreviewStat
			INC		(HL)							;Update for next loading block (or 17 when finish all loads)
			LD		A,PreviewLoadWait				;Reinit Max ints wait for loading
			LD		(PreviewLoad),A					;Reinit ints wait for loading

Preview_Busy:
			XOR		A								;So z is activated to indicate largetime-consuming done
			RET

		;Preview SHOW (not using PIC commands to Arduino)
Preview_Show:
			LD		A,(PreviewCnt)
			DEC		A
			LD		(PreviewCnt),A					;Timing for "moving" the preview
			JR		NZ,Preview_ExitZ
			CALL	LoopRoutine						;value=0 for animating
			LD		A,PreviewMax					;Reinit counter
			LD		(PreviewCnt),A					;Timing for "moving" the preview			
Preview_ExitZ:
			;LD		A,1
			AND		A								;So Z will be here deactivated (Z=we did something)
			RET
			
;Preview_Subload - Subroutine for load pieces of screen for preview
Preview_Subload:
			LD		HL,ScreensSCR-SCR_BLKSIZE		; Destination of data
			LD		A,(PreviewStat)					; Num of block to load 1..16
			LD		C,A								;Additional parameter is to load a piece Par: 1 to 16
			LD		DE,SCR_BLKSIZE					;DE=Size to load
Preview_Subload_Loop:
			ADD		HL,DE							;HL=HL+SCR_BLKSIZE
			DEC		A
			JR		NZ,Preview_Subload_Loop
		
			LD		A,(PreviewFT)					;Type of preview so we send the correct command
			;LD		A,CMD_ZX2SD_SCR					;c=CMD_ZX2SD_SCR so command is get screen
			LD		DE,SCR_BLKSIZE					;DE=Size to load
			JP		LoadBlockDirect1Par				;Load Screen piece (HL=Destination of data, DE=Len of data to load)

;LoopRoutine - Move preview screen around "window" as per TableMove			
BeginRoutine:			
			LD		HL,TableMove					;Table of movements
			LD		(LastMove),HL
LoopRoutine:
			LD		HL,(LastMove)
			LD		A,(HL)
			CP		#FF
			JR		Z,BeginRoutine					;Reinit table
			LD		D,(HL)							;Row
			INC		HL
			LD		E,(HL)							;Column
			INC		HL
			LD		(LastMove),HL

			CALL	XYtoAttr						;HL=Position in screen as per D=Row, E=Column
			LD		DE,ScreensSCR-#4000
			ADD		HL,DE							;HL=Position as per ScreensSCR
	
			LD		(RepSRC),HL						;Attr Source in screen
			

;PreviewScreen - All checks are doing with destination (screen)
;		That way is possible to have the source screen in any place (not required aligment)
PreviewScreen:

			PUSH	IY				;RST#38 SAVED HL,DE,BC,AF,IX
			EXX
			EX		AF,AF
			PUSH	HL,DE,BC
			PUSH	AF

	;Here to wait for tracing below required Row of chars
			LD		DE,#260+(PreviewRow*#46)			;Add xxx for each row lower
Loop1:
			DEC		DE
			LD		A,D
			OR		E
			JR		NZ,Loop1
	;Let's go		
			;1st Third
			LD		IX,(RepSRC)		;Source Attr (from SCRBuff area)
			LD		IY,(RepDest)	;Destination Attr in screen +16 columns

			LD		(PreviewSP),SP		;20 Ts
BucleAttr:
;	Fill attributes (16 bytes)
			LD		SP,IX			;10 Ts
			POP		HL,DE,BC,AF		;4x10 Ts
			EXX						;4 Ts
			EX		AF,AF			;4 Ts
			POP		HL,DE,BC,AF		;4x10 Ts
			
			LD		SP,IY			;10 Ts
			PUSH	AF,BC,DE,HL		;4x11 Ts
			EX		AF,AF			;4 Ts
			EXX						;4 Ts
			PUSH	AF,BC,DE,HL		;4x11 Ts

		;Convert Attr of Source in Pixel of Source
			LD		DE,#E800
			LD		A,IXH
			CP		SRC1TH
			JR		Z,SrcThird
			LD		D,#EF
			CP		SRC2TH
			JR		Z,SrcThird
			LD		D,#F6
SrcThird:
			ADD		IX,DE
			
		;Convert Attr of Destination in Pixel of Destination
			
			LD		D,#E8
			DEC		IY				;Avoid problems with last column in screen
			LD		A,IYH			;High of attr address in screen
			CP		#58									;removed as always will be in 2nd and 3rd Third
			JR		Z,BucleAttr_EndThird
			LD		D,#EF
			CP		#59
			JR		Z,BucleAttr_EndThird
			LD		D,#F6
BucleAttr_EndThird:
			INC		IY
			ADD		IY,DE			;Attributes
			
BuclePOPU:
			LD		SP,IX			;10 Ts	- Source
			POP		HL,DE,BC,AF		;4x10 Ts
			EXX						;4 Ts
			EX		AF,AF			;4 Ts
			POP		HL,DE,BC,AF		;4x10 Ts
			
			LD		SP,IY			;10 Ts	- Destination (screen)
			PUSH	AF,BC,DE,HL		;4x11 Ts
			EXX						;4 Ts
			EX		AF,AF			;4 Ts
			PUSH	AF,BC,DE,HL		;4x11 Ts

			INC		IXH
			INC		IYH
			LD		A,IXH
			AND		7				;Finish when scan is 0
			JP		NZ,BuclePOPU
NextRow:			

; Check if we finish with last Row to process


;	Change Pixels of Source to Attr
			LD		DE,#1020
			LD		A,IXH			;High of pix address source
			CP		SRC2PX
			JR		Z,BuclePix_EndThird
			LD		D,#09
			CP		SRC3PX
			JR		Z,BuclePix_EndThird
			LD		D,#02
BuclePix_EndThird:
			ADD		IX,DE			;For next row IX

			LD		D,#10
			DEC		IY				;Avoid problems with last column
			LD		A,IYH			;High of pix address in screen	;removed as always will be in 2nd and 3rd Third
			CP		#48
			JR		Z,BuclePix_EndYThird
			LD		D,#09
			CP		#50
			JR		Z,BuclePix_EndYThird
			LD		D,#02
BuclePix_EndYThird:
			INC		IY
			ADD		IY,DE				;For next row IY
			LD		A,IYL
			CP		LOW HLRow			;A=#00..#1F when try to go beyond Third		(era CP#20)
			JP		NZ,BucleAttr		;Repeat for next row
			LD		A,IYH
			CP		HIGH HLRow			;A=#00..#1F when try to go beyond Third		(era CP#20)
			JP		NZ,BucleAttr		;Repeat for next row
EndPaint:
			;XOR		A
			;LD		(Repaint),A		;Clear flag for repaint

			LD		SP,(PreviewSP)		;20 Ts
			POP		AF
			POP		BC,DE,HL
			EXX
			EX		AF,AF
			POP		IY
			RET
			
;TableMove - Information for moving the "Half-screen"
;	Each data is 2 bytes:
;		Row		: Row of screen 0..12...
;		Column	: Column of screen 0..16
TableMove:
		defb	#00, #00, #00, #01, #00, #02, #00, #03, #00, #04, #00, #05, #00, #06, #00, #07, #00, #08, #00, #09, #00, #0A, #00, #0B, #00, #0C, #00, #0D, #00, #0E, #00, #0F, #00, #10
		defb	#01, #0F, #02, #0E, #03, #0D, #04, #0B, #05, #0A, #06, #08, #07, #07, #08, #05, #09, #04, #0A, #02, #0B, #01
		defb	#0C, #00, #0C, #01, #0C, #02, #0C, #03, #0C, #04, #0C, #05, #0C, #06, #0C, #07, #0C, #08, #0C, #09, #0C, #0A, #0C, #0B, #0C, #0C, #0C, #0D, #0C, #0E, #0C, #0F, #0C, #10
		defb	#0B, #0F, #0A, #0E, #09, #0D, #08, #0B, #07, #0A, #06, #08, #05, #07, #04, #05, #03, #04, #02, #02, #01, #01
		
		defb #FF
		