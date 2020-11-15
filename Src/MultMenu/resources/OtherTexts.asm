;OtherTexts.asm
;	General texts for some uses

TXTDanPath:		defb	FT_ROMSET,"../Dan MENU",0		;Dandanator "Go to menu" text
SizeEndTXTDanPath equ	$-TXTDanPath

TXTZXPath:		defb	FT_BASIC,"../ZX Basic",0		;Dandanator "Go to BASIC" text
SizeEndTXTZXPath equ	$-TXTZXPath

TXTLoading:		defb	"Retrieving File Names...",0
TXTSorting:		defb	"Sorting Files...",0

TXTPageof:		defb	127,"  /  ",0					;"  /  ",127,0

TXTMaxPageEmpty:
				defs	TXTMaxPageEmpty-TXTPageof-1," "
				defb	0
				
TXTNOMultiply:	defb	" < Multiply NOT DETECTED > ",0

;Texts for ROMSET preview
TXTROMPage:		defb	"/",0
;Texts for ROMSET options
TXTROMWRITE:	defb	"Sure to write?  "
TXTROMWRITENO:	defb	" NO "
				defb	"  "			;2 Bytes separator so we have text aligned with Screen Attr
				defb	" YES",0
TXTROMWRoffNO	equ		(TXTROMWRITENO-TXTROMWRITE)/2

TXTROM10:		defb	"No Multiply support!",0

TXTTAPnoScreen:	defb	"Screen not found",0

;Texts for File System Degraded
TXTDEGRA:		defb	"    Folder with many hidden,",0
				defb	" deleted or incompatible files.",0
				defb	"     Degraded performance.",0
				
TXTTOODEGRA:	defb	"Folder with way too many hidden,",0
				defb	" deleted or incompatible files.",0
				defb	"     Very bad performance.",0