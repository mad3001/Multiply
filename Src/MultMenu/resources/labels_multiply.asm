;labels_multiply

;inherited from ROMSET MENU
MAXGAMES		EQU 25							; Max number of games 

;Constants for Files in screen
MaxChapter	equ		9								;Maximum Chapter (Chapters will be 1..MaxChapter)
MaxPageChap	equ		11								;Maximum Pages for each Chapter (Pages will be 1..MaxPageChap)
MaxFilePage	equ		23								;Maximum File number for each Page (will be 1..MaxFilePage)

;Constants for Position in screen
MinRowFiles	equ		1								;Row (0..23) for minimum used for Files
MaxRowFiles	equ		23								;Row (0..23) for maximum used for Files
FilesPerPag equ		MaxRowFiles-MinRowFiles+1		;Number of Files showing per Page
MinColFiles	equ		2								;Column (0..63) for minimum used for Files
MaxColFiles	equ		30								;Max length of file to print in screen
Sel_Bar_Len	equ		(MaxColFiles+2)/2				;Len of file + icon
PosRowPath	equ		0								;Row (0..23) for showing the path
PosColPath	equ		4								;Column (0..63) for showing the path
MaxColPath	equ		63								;Max Column (0..63) for showing the path
MaxLenPath	equ		MaxColPath-PosColPath+1			;Maximum length of Path

RowPage		equ		1								;Row (0..23) for showing text "Page xx of xx"
ColPage		equ		26								;Column (0..63) for showing text "xx/yy"


FILEENTRY_NAME	equ		30  						;Max.Length of name
FILEENTRY_LEN	equ		FILEENTRY_NAME+4			;Length of data for each FileName
FILEEMPTY		equ		1+FILEENTRY_NAME			;Position of value 0x00 after FileName in the FILEENTRY data
FILEINDEX		equ		1+FILEENTRY_NAME+1			;Position of Index in the FILEENTRY data
MAXNFILES		equ		MaxPageChap*MaxFilePage		;Max number of files for listing (MaxPageChap x MaxFilePage = 253), That value contains also entry ".." for 1st chapter
maxFLen 		equ		256							;Max. length of filename (including last 0x00)
BorderMenu		equ		7							;Border color for Menu
MAXSUBDIRS		equ		64							;Max number of subdirectories levels.... 64 are a lot....

;Constants for Preview screen
PreviewMax		equ		8							;Counter for updating Preview "miniscreen"
PreviewLoadWait	equ		3							;Counter for Loading Preview "miniscreen". Don't change!!! to a value below 3 or Routines will Hang it depending the SDCard speed
PreviewMaxROM	equ		50*5						;Max time for changing preview page for ROMSET (asociated to PrevROMTime) 50*5= 5 seconds (value below 255)

ScreensSCR  equ		#C000							;C000-DAFF used for Loading Screens .SCR
ScratchRAM	equ		#8000							;Scratch Area
;Variables above end of ScreenSCR
MultiplyVer	equ		ScreensSCR+#1B00				;(8 bytes) Multiply version. It will be "MULTxx.x"
PathBuffer	equ		MultiplyVer+8					;(61 bytes) Buffer for Current Directory (full path in SDCard) to show in 1st Row of screen
LenPath		equ		PathBuffer+61					;(1 byte) Len of Current Path (PathBuffer)
BuffGetDir	equ		LenPath+1						;(256 bytes) Buffer for name as per GetDir (FAT / FAT32 limite it to 255 + 0x00 ending)
PathIndex	equ		BuffGetDir+256					;(x bytes) 64 x 3 :Max 64 directory entre levels... 1 byte Name len, 2 bytes index of directory.
PathIndexLast	equ	PathIndex+(MAXSUBDIRS*3)		;(1 byte) Number of last entry level (value 0..64) 0 means root, 1 is "/dir1", 2 is "/dir1/dir2" and so on
CHK_48K_VAR	equ		PathIndexLast+1					;(1 byte) Will hold Hardware detected: 1=16k, 2=48k, 3=128k
BufLines	equ		CHK_48K_VAR+1					;(21 bytes) Data for moving Logo (Water effect)
MovedLines	equ		BufLines+(7*3)					;(1 byte) 0 if not moved lines in this INT (Water effect)

;Variables for preview screen (see PreviewScreen.asm)
;PreviewStat - used in preview screen. 0 if type of file is not SCR...other values as shown below
PreviewIX	equ		MovedLines+1					;(2 byte) Address of file to load
PreviewFT	equ		PreviewIX+2						;(1 byte) Type of File for preview between FT_SCR and FT_SNA_SCR so we use the correct command
PreviewStat	equ		PreviewFT+1						;(1 byte) Small screen preview: 0=NO Preview, 1..nn=Block pending to load, nn+1=Showing
PreviewCnt	equ		PreviewStat+1					;(1 byte) Down Counter (PreviewMax down to 0) when PreviewStat is nn+1=Showing
PreviewLoad	equ		PreviewCnt+1					;(1 byte) Down Counter (PreviewLoadWait down to 0) while loading
RepSRC		equ		PreviewLoad+1					;(2 bytes) Source address for repaint
RepDest		equ		RepSRC+2						;(2 bytes) Dest address for repaint
PreviewSP	equ		RepDest+2						;(2 bytes) storing last SP in preview
LastMove	equ		PreviewSP+2						;(2 bytes) storing current movement
;Next variables used for Sorting routine
TotalB		equ		LastMove+2						;(1 byte)Num of elements sorting (0..253)
PosFiles	EQU		TotalB+1						;(2 bytes) Will hold the address begining for pointers of files
HLPosFiles	equ		PosFiles+2						;(2 bytes) Will hold the address begining for files
SortSP		equ		HLPosFiles+2					;(2 bytes) Will hold SP while sorting
NumOfFiles	equ		SortSP+2						;(1 byte) Will hold number of files retrieved from Arduino ( < MAXNFILES)
CurPage		equ		NumOfFiles+1					;(1 byte) Will hold Current Page Number (1..99)
CurPageOff	equ		CurPage+1						;(1 byte) Will hold Number of Item as per Page Number (1..11) so it's a value: (Pagenumber-1) * 23
;Variables for preview ROMSET
PrevROMPag	equ		CurPageOff+1					;(1 byte) Will hold current page showing romset
PrevROMxPag	equ		PrevROMPag+1					;(1 byte) Will hold max page for showing romset
PrevROMTime	equ		PrevROMxPag+1					;(1 byte) Counter of time for changing page in ROMSET preview
Rom2Write	equ		PrevROMTime+1					;(2 bytes) Address of ROMSET info for writing
;Variables for MENU SubMenus
SubMenuOpt	equ		Rom2Write+2						;(1 byte) 0=Main Menu, 1=ROMSET ENTER submenu, etc...Further additional submenus



;Variables below ScreenSCR
SortBuffer	equ		ScreensSCR-(2*(1+MAXNFILES))			;(508 bytes) Buffer for directory listing sorted (2 bytes per name x 254 -last entry is always in 0x00-)
Buffer		equ		SortBuffer-(FILEENTRY_LEN*(1+MAXNFILES))	;(8636 bytes) Buffer for directory listing (34 bytes per name x 254 -last entry is always in 0x00-)
CurRow		equ		Buffer-1						;(1 byte) Current Row for selected files
AuxCurRow	equ		CurRow-1						;(1 byte) Current Row for printing files
MaxRow		equ		AuxCurRow-1						;(1 byte) Maximum Row for selected files (based of number of files and current page of listing)
RowNewPage	equ		MaxRow-1						;(1 byte) Row to go when changing page (depends if using UP-DOWN or LEFT-RIGHT)
CurKey		equ		RowNewPage-1					;(1 byte) Last key pressed 0 for none, 1..5 as per direction/fire
LastKey		equ		CurKey-1						;(1 byte) Last key pressed 0 for none, 1..5 as per direction/fire
LastKeyTime	equ		LastKey-1						;(1 byte) Counting time for repeat key
KeyToExe	equ		LastKeyTime-1					;(1 byte) Key to process as INT key routine interpreted a key have to be processed
InfoShown	equ		KeyToExe-1						;(1 byte) Hold value 1 for Pending to show Info BOX, 0 for Info BOX showed
BufGetInfo	equ		InfoShown-12					;(12 bytes) Used for command CMD_ZX2SD_GETINFO
InfoVersion	equ		BufGetInfo-9					;(9 bytes) 8 bytes for Version of Menu (slot 1) and 1 byte for num of games
TXTNumber	equ		InfoVersion-3					;(3 bytes) 2 digits and zero
ROMVersion  equ 	TXTNumber-9						;(9 bytes) 8 bytes for Version of ROMSET followed by a 0x00 (for printing)
CurrChapter	equ		ROMVersion-1					;(1 byte) Current Chapter for current folder.
LastChapter	equ		CurrChapter-1					;(1 byte) Max Chapter for current folder. Value between MinChapter and MaxChapter
CurrPages	equ		LastChapter-1					;(1 byte) Current Page for current Chapter. Value 1..MaxPageChap (1..11)
LastPages	equ		CurrPages-1						;(1 byte) Max Page for current Chapter. Value between 1 and MaxPageChap*MaxChapter (1..99)
CurrFile	equ		LastPages-1						;(1 byte) Current File for current Page Value between 1 and MaxFilePag (1..23)
LastFile	equ		CurrFile-1						;(1 byte) Max File for Last Page of this Chapter. Value between 1 and MaxFilePage
ChapTable	equ		LastFile-(MaxChapter*2)			;(18 bytes) Table of chapter indexes
;Variables for Degraded
MsgDegrad	equ		ChapTable-1						;(1 byte) 0=not degraded, 1=degraded, 2=too much degraded
;spare		equ		MsgDegrad-x						;(x bytes) spare spare spare spare

Chap1Chapt	equ		0x02							;Offset into ChapTable for Total of chapters
Chap1Pages	equ		0x03							;Offset into ChapTable for Total of Pages
Chap1LastF	equ		0x04							;Offset into ChapTable for Num. of files in last Page (usually 253, except for last chapter and last page 1..253)
Chap1Offset	equ		0x0A							;Offset into ChapTable for 1st chapter index
ChapDegrad	equ		0x1C							;Offset into ChapTable for Degradation of file system


SP_VALUE	equ		#FFF4							;(244 bytes) Used less than 244 bytes, but reserveD #FF00-#FFF4
IM2ADDR		equ		#FFF4							;(12 bytes) reserved for IM2 routine compatible with inves+

Selec_Color	equ		%01111000						;Selected color is paper white, ink black, bright, no flash
NoSel_Color	equ		%00111000						;Non selected color is paper white, ink black, no bright, no flash
Page_Color	equ		%01111000						;Selected color is paper white, ink black, bright, no flash

Time1Val	equ		25								;25/50 sec for first repeat time
TimesVal	equ		2								;2/50 sec for maintain repeat time


;Variables copied from Dandanator MENU.... so be sure they are "sincronized" with it
GAMEDATATABADDR	EQU 3584						; Holder for Number of Games and then GameData
VINFOTXT		EQU 16352						; Version Info Text
RAMAREAPG2		EQU 32768						; Address of RAM destination for RAM PAGE2 16k block
TOPRAMMAP		EQU RAMAREAPG2	;RAMTOP			; Set top of variable area (RAM MAP) Adjusted for 16k
RAM_VARS		EQU	TOPRAMMAP-256				; Zone for Ram Vars (256 bytes)
SEL_GAME_NUM	EQU RAM_VARS+004				; Selected Game Number (1 byte)	
AUTOBOOTCHK		EQU	RAM_VARS+142				; Copy of Autoboot game (Slot 2 code will clear it) (1 byte)
DANSNAP_PAUSE	EQU 16383						; Slot for NMI during play -> 2 for pause, slot (1-32) for Dan-Snap
PAUSELOOPSN		EQU 64							; Pause function - Number of loops
