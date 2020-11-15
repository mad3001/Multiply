;FiletypeTexts

;	Index 0x0C to 0x1D
;
;	1st index (1 byte)
;	2nd pointer to related text
;	Total: 3 bytes, also the size of text (variable, maximum 24 -small font 8x4-)

;Take care making this table... index byte have to be sorted, lower to upper !!!

FileTypeTexts:
;	None of the below
	defb	FT_DIRECTORY-1				;So if value < FT_DIRECTORY then it will be as None
	defw	FT_NONE
FileTypeTexts_Size	equ	$-FileTypeTexts

;	Folder
	defb	FT_DIRECTORY
	defw	FT_DIRECTORY_text

;	SCREEN
	defb	FT_SCR
	defw	FT_SCR_text

;	Z80_16
	defb	FT_Z80_16K
	defw	FT_Z80_16K_text
	
;	Z80_48
	defb	FT_Z80_48K
	defw	FT_Z80_48K_text
	
;	Z80_128
	defb	FT_Z80_128K
	defw	FT_Z80_128K_text

;	SNA_48
	defb	FT_SNA_48K
	defw	FT_SNA_48K_text

;	SNA_48
	defb	FT_SNA_128K
	defw	FT_SNA_128K_text


;	TAP TAPE
	defb	FT_TAP
	defw	FT_TAP_text

;	BINARY
	defb	FT_BINARY
	defw	FT_BINARY_text


;	ROM
	defb	FT_ROMSET	
	defw	FT_ROMSET_text

;	ROM
	defb	FT_BASIC
	defw	FT_BASIC_text

;	None of the previous
	defb	#FF
	defw	FT_NONE
	
;Text strings.... each string ending with 0x00
FT_EMPTY:
	defb	"                        ",0
FT_EMPTY_last:	
	
FT_NONE:
	defb	"---",0
	defb	" ",0
	defb	" ",0
	defb	" ",0
	defb	" ",0

FT_DIRECTORY_text:
	defb	"FOLDER",0
	defb	" ",0
	defb	" ",0
	defb	" ",0
	defb	"   ENTER or FIRE to OPEN",0
	
FT_ROMSET_text:
	defb	"ROM DANDANATOR",0
FT_R_V:
	defb	"Version:",0
FT_R_V2:
	defb	"     Games",0
	defb	" ",0		
FT_ROMSET_ENTER:
	defb	" ENTER or FIRE for OPTIONS",0

FT_BASIC_text:
	defb	"Return to BASIC",0
	defb	" ",0
	defb	" ",0
	defb	" ",0
	defb	"   ENTER or FIRE for BASIC",0

FT_Z80_16K_text:
	defb	"GAME SNAPSHOT",0
	defb	"TYPE: Z80",0
	defb	"Size: 16k",0
FT_Z80_V:
	defb	"Captured on: ",0
FT_Z80_V2:
	defb	"   ENTER or FIRE to PLAY",0
	
FT_Z80_48K_text:
	defb	"GAME SNAPSHOT",0
	defb	"TYPE: Z80",0
	defb	"Size: 48k",0
	defb	"Captured on: ",0
	defb	"   ENTER or FIRE to PLAY",0

FT_Z80_128K_text:
	defb	"GAME SNAPSHOT",0
	defb	"TYPE: Z80",0
	defb	"Size: 128k",0
	defb	"Captured on: ",0
	defb	"   ENTER or FIRE to PLAY",0

FT_SNA_48K_text:
	defb	"GAME SNAPSHOT",0
	defb	"TYPE: SNA",0
	defb	"Size: 48k",0
	defb	"Captured on: Unknown",0
	defb	"   ENTER or FIRE to PLAY",0

FT_SNA_128K_text:
	defb	"GAME SNAPSHOT",0
	defb	"TYPE: SNA",0
	defb	"Size: 128k",0
	defb	"Captured on: Unknown",0
	defb	"   ENTER or FIRE to PLAY",0

FT_SCR_text:
	defb	"SCREEN",0
	defb	"TYPE: SCR",0
	defb	"Size: 6912 bytes",0
	defb	" ",0
	defb	"   ENTER or FIRE to VIEW",0

FT_TAP_text:
	defb	"CASSETTE GAME",0
	defb	"Type: TAP",0
	defb	" ",0
FT_TAP_Program:
	defb	" PROGRAM:",0			;xxx Entries
FT_TAP_Program2:
	defb	"   ENTER or FIRE to PLAY",0

FT_BINARY_text:
	defb	"BINARY FILE",0
	defb	"Size: xxxxx bytes",0	;xxxxx size
	defb	" ",0
	defb	" ",0
	defb	" ENTER or FIRE to pending",0

;
