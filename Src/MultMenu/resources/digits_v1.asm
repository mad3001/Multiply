;digits_v1.asm - modified version for Multiply_v1 - mad3001 April 2020

;------------------------------------------------------------------------------
;DISPADVANCE - Display arrows of advance bar
;------------------------------------------------------------------------------
; A = Number to show (1..16)
;------------------------------------------------------------------------------

;DISPDIGIT Local Variables	
RowLine		equ		15					;Row (0..23) of Line (line is only 12 char length)
ColLine		equ		6					;1 less than Col (0..32) of Line (line is only 14 char length)
DISPADVANCE:
			CP  16
			JR  NZ,DISPADVANCE_Nolast
DISPADVANCE_Nolast:
			DEC A						;A=1..15 to 0..14 (16 was discarded)
			RET Z						;Nothing to do with 1st block (now value was 0)
			LD	B,A						;Copy 0..14 into B
			RowCol2PIX  HL,RowLine,ColLine		;Pixel address for Row RowLine, Column ColLine:  After Rectangle
			LD  A,L
			ADD A,B
			LD  L,A
			DEC B
			JR  Z,DISPADVANCE_ClearPrev	;1st time we have not to "clear" previous arrow
			LD DE,CharsLine
			PUSH HL
			DEC HL						;Clear previous Arrow
			CALL Printmichar
			POP HL
DISPADVANCE_ClearPrev:			
			LD DE,CharsArrow
			
			CALL Printmichar
			RET

;Mini routine to print directly with pixel address (no attribute changes)
Printmichar:
			LD	B,8
DISPADVANCE_Char:
			LD	A,(DE)
			LD	(HL),A
			INC	DE
			INC	H
			DJNZ	DISPADVANCE_Char
			RET
CharsLine:
		defb 0, 0, 0, 0, 255, 0, 0, 0; used for line in ROMSET WRITER
CharsArrow:
		defb 0, 160, 80, 40, 20, 40, 80, 160; Used for Arrow in ROMSET WRITER 



;------------------------------------------------------------------------------
; DISPBAR - Colorize Progress Bar
;------------------------------------------------------------------------------
; A = Number of Sector (0..127)
; C = Colour of attribute (0:PEND, 1:LOAD, 2:WRIT, 3:FINIS)
;------------------------------------------------------------------------------
DISPBAR:
			PUSH AF						;Send A to Stack to recuperate at the end
			PUSH BC						;Send C to Stack to recuperate at the end
			;First convert A=N.Sector to Row/Col (in reg D/E)
			LD D,BARROW					;D=Row, begin in that ROW
BUCROWS:
			CP BARWIDTH					;Check if C>BARWIDTH
			JR C,DISPLASTROW			;if not then this is the last row
			SUB BARWIDTH				;if C>BARWIDTH, substract BARWIDTH...
			INC D						;...and One Row more
			JR BUCROWS					;Continue until C<=BARWIDTH
DISPLASTROW:
			;LD E,A						;Residual of substractions
			ADD BARCOL					;Add BARCOL
			;We have D=Row, E=Col for this sector
			; now we need D*32+E
			LD H,0						;High byte of 16bit address to 0
			LD L,D						;Low byte of 16bit address store ROW
			RL L						;L<32 (no carry)		L*2
			RL L						;L<64 (no carry)		L*4
			RL L						;L<128 (no carry)		L*8
			RL L						;We can have carry...	L*16
			RL H						;so pass to H the Carry (if any)
			RL L						;We can have carry...	L*32
			RL H						;so pass to H the Carry (if any)
			ADD L						;Add Column to attribute calculated
			LD L,A						;Store column to L
			JR NC,DISPBAR1
			INC H						;If there was a carry then add 1 to High Address
DISPBAR1:
			LD DE,$5800					;Begin of attribute screen zone
			ADD HL,DE					;
			;We have the attribute pointer in HL
			LD A,C
			OR A
			JR NZ,DISPNOPEND
			LD C,COLPEND
			JR DISPBARCOL
DISPNOPEND:
			DEC A
			JR NZ,DISPNOLOAD
			LD C,COLLOAD
			JR DISPBARCOL
DISPNOLOAD:
			DEC A
			JR NZ,DISPNOWRIT
			LD C,COLWRIT
			JR DISPBARCOL
DISPNOWRIT:
			LD C,COLFINI
DISPBARCOL:
			LD (HL),C					;Store colour of attribute
			POP BC						;Recuperate initial C
			POP AF						;Recuperate initial A
			RET
			
; DISPBAR LOCAL CONSTANS
BARROW		equ 	1
BARCOL		equ		4
BARATTR		equ		$5800+(BARROW*32+BARCOL);Row BARROW, Column BARCOL (Row 0-23, Column 0-31)
BARWIDTH	equ		24					;Number of Blocks per row (center rows)
COLPEND		equ		%01000111			;Bright, Paper black, Ink White
COLLOAD		equ		%01000110			;Bright, Paper black, Ink Yellow
COLWRIT		equ		%01000010			;Bright, Paper black, Ink Red
COLFINI		equ		%01000100			;Bright, Paper black, Ink Green
			
;------------------------------------------------------------------------------
; DISPDIGIT - 
;------------------------------------------------------------------------------
; A = Number to show (1..16)
; DIGIATTR = Left-Top corner of 6x5 AREA of Digits
;------------------------------------------------------------------------------
DISPDIGIT:
			PUSH AF						;Save A to Stack

			LD HL,ZONE6X5
			LD (HL),DIGIOFF
			PUSH HL
			POP DE
			INC DE
			LD BC,ENDZONE-ZONE6X5-1
			LDIR						;Fill table with 0
			LD HL,TABLEDIGITS-1
			LD B,A						;Load B with copy of A for lookup in TABLEDIGITS
LOOKTABLEDIGITS:
			INC HL
			DJNZ LOOKTABLEDIGITS
			; Now lookup to attributes to be painted in zone6x6
			LD IX,TABLEATTRS
			LD B,8						;Process the 8 bits of A
DISPSEGMENT:
			RRC	(HL)					;Rotate right (bit 0 -> bit 7 , bit 0-> Carry)
			JR NC,THISSEGMEND			;No bit = no change attributes 0
			
			;Bit for segment activated, lets process upto 5 segments for this bit
			LD C,5						;Process up to 5 data for attribute offset
THISSEGM:
			LD IY,ZONE6X5				;IY will be used to locate in attribute to be changed
			LD A,(IX)
			INC A						;if A=255 -> 0
			JR Z,NOTSEGMENT
			DEC A						;return A to it's value before INC A
			ADD A,IYL
			LD IYL,A
			JR NC,NOHIGH
			INC IYH
NOHIGH:
			LD (IY),DIGICOLOR			;Change this attribute to DIGICOLOR (green ink)
NOTSEGMENT:			
			INC IX						;Next value from IX table
			DEC C						;Next digit
			JR NZ,THISSEGM				;Repeat until C=0
			JR ENDTHISSEGM
THISSEGMEND:
			INC IX
			INC IX
			INC IX
			INC IX
			INC IX						;Next Segment (next bit)
ENDTHISSEGM:
			DJNZ DISPSEGMENT
			
			;Copy ZONE6X5 to screen (6 lines of 5 attributes)
			LD A,6
			LD HL,ZONE6X5
			LD DE,DIGIATTR
BUCPAINTATTR:			
			LD BC,5
			LDIR
			LD BC,32-5
			EX DE,HL
			ADD HL,BC
			EX DE,HL
			DEC A
			JR NZ,BUCPAINTATTR

			POP AF						;Restore initial A Value
			RET
; DIGITS From 1 to 16
TABLEDIGITS:
			DEFB	18,61,59,90,107,111,50,127,123,247,146,189,187,218,235,239	;Coded for 1..16
			
TABLEATTRS:
			DEFB	22,23,27,28,255		;Segment 7		(BIT 6)
			DEFB	19,24,255,255,255	;Segment 6		(BIT 5)
			DEFB	16,21,255,255,255	;Segment 5		(BIT 4)
			DEFB	12,13,17,18,255		;Segment 4		(BIT 3)
			DEFB	4,9,14,255,255		;Segment 3		(BIT 2)
			DEFB	2,3,255,255,255		;Segment 2		(BIT 1)
			DEFB	1,6,11,255,255		;Segment 1		(BIT 0)
			DEFB	0,5,10,15,20		;Segments A/B	(BIT 7)

ZONE6X5:	BLOCK	5*6,0				;Scratch area to prepare attributes
ENDZONE:			
	
;DISPDIGIT Local Variables	
;DIGIATTR	equ	$5800+(11*32)+22		;Row 11, Column 22 (Row 0-23, Column 0-31)
DIGIATTR	equ	$5800+(13*32)+25		;Row 13, Column 25 (Row 0-23, Column 0-31)
DIGICOLOR	equ	%00101001				;Paper 5 (cyan), Ink 1 (blue), no bright
DIGIOFF		equ	%00101101				;Paper 5 (cyan), Ink 5 (cyan), no bright

	