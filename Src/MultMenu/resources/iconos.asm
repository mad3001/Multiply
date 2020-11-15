; Icons 
;	Index 0x0C to 0x1D
;
;	1st index (1 byte)
;	2nd Icon   (2 x 16 bytes), 4 for attributes -using 36 bytes-
;	3rd Thumbnail (1 x 8 bytes), 1 for Attribute - using 9 bytes-
;	Total: 46 bytes

;Take care making this table... index byte have to be sorted, lower to upper !!!

Icons:
;	Folder
	defb FT_DIRECTORY

Icon16x16	equ	$-Icons			;Offset to Icon16x16
	
;	.Folder
	defb %11111111,%11111111 ; line 0
	defb %11000011,%11111111 ; line 1
	defb %10111101,%11111111 ; line 2
	defb %10111100,%00000001 ; line 3
	defb %10111111,%11111101 ; line 4
	defb %10111111,%11111101 ; line 5
	defb %10111111,%11111001 ; line 6
	defb %10111111,%11111101 ; line 7
	defb %10111111,%11111001 ; line 8
	defb %10111111,%11111101 ; line 9
	defb %10111111,%11111001 ; line 10
	defb %10111111,%11110101 ; line 11
	defb %10111111,%11101001 ; line 12
	defb %10111101,%01010101 ; line 13
	defb %10000000,%00000001 ; line 14
	defb %11111111,%11111111 ; line 15
;	.FolderAttributes
	defb %01000101,%01000101 ; line 0
	defb %01000101,%01000101 ; line 1


Icon8x8		equ	$-Icons			;Offset to Icon8x8

;	.Folder_mini
	defb %00000000 ; line 0
	defb %01110000 ; line 1
	defb %01110000 ; line 2
	defb %01111111 ; line 3
	defb %01111111 ; line 4
	defb %01111111 ; line 5
	defb %01111111 ; line 6
	defb %01111111 ; line 7

;	.Folder_miniAttributes
	defb %00111100 ; line 0

IconNext	equ	$-Icons			;Offset to Next Icon

;	SCR
	defb FT_SCR

;	.SCR
	defb %00000000,%00000000 ; line 0
	defb %01111111,%11111110 ; line 1
	defb %01000000,%00000010 ; line 2
	defb %01010100,%00110010 ; line 3
	defb %01001010,%01111010 ; line 4
	defb %01010100,%01111010 ; line 5
	defb %01000000,%00110010 ; line 6
	defb %01000000,%00000010 ; line 7
	defb %01000010,%00001010 ; line 8
	defb %01000111,%00010010 ; line 9
	defb %01001111,%10001010 ; line 10
	defb %01011111,%11000010 ; line 11
	defb %01011111,%11111010 ; line 12
	defb %01000000,%00000010 ; line 13
	defb %01111111,%11111110 ; line 14
	defb %00000000,%00000000 ; line 15
;	.SCRAttributes
	defb %01101011,%01101011 ; line 0
	defb %01101011,%01101011 ; line 1


;	.SCR_mini
	defb %00000000 ; line 0
	defb %01111111 ; line 1
	defb %01000001 ; line 2
	defb %01010101 ; line 3
	defb %01010001 ; line 4
	defb %01111001 ; line 5
	defb %01111111 ; line 6
	defb %01111111 ; line 7
;	.SCR_miniAttributes
	defb %00111011 ; line 0


;	SNA
	defb FT_SNA_128K

;	.SNA
	defb %00000000, %00000000
	defb %00000000, %00000000
	defb %00011100, %00111000
	defb %01110111, %11111110
	defb %01011011, %11111010
	defb %01110111, %11111110
	defb %00011111, %11111000
	defb %01110111, %11111110
	defb %01011111, %11111010
	defb %01110111, %11111110
	defb %00011111, %11111000
	defb %01111111, %11111110
	defb %01011111, %11111010
	defb %01111111, %11111110
	defb %00011111, %11111000
	defb %00000000, %00000000
;	.SNAAttributes
	defb %01101001, %01101001 ; line 0
	defb %01101001, %01101001 ; line 1

;	.SNA_mini
	defb %00000000 ; line 0
	defb %01011101 ; line 1
	defb %00011100 ; line 2
	defb %01011101 ; line 3
	defb %00011100 ; line 4
	defb %01011101 ; line 5
	defb %00011100 ; line 6
	defb %01011101 ; line 7
;	.SNA_miniAttributes
	defb %00111001

;	TAP
	defb FT_TAP

;.TAP
; line based output of pixel data:

	defb %00000000, %00000000
	defb %00000000, %00000000
	defb %00000000, %00000000
	defb %00000000, %00000000
	defb %00000000, %00000000
	defb %01111111, %11111110
	defb %01100100, %00100110
	defb %01010000, %00001010
	defb %01001111, %11110010
	defb %01000000, %00000010
	defb %01011001, %01011010
	defb %01011010, %10011010
	defb %01000000, %00000010
	defb %01000000, %00000010
	defb %01111111, %11111110
	defb %00000000, %00000000
;.TAPAttributes
	defb %01101001, %01101001
	defb %01101001, %01101001


;.TAP_mini
	defb %00000000 ; line 0
	defb %00000000 ; line 1
	defb %01111111 ; line 2
	defb %01011101 ; line 3
	defb %01000001 ; line 4
	defb %01010101 ; line 5
	defb %01000001 ; line 6
	defb %01111111 ; line 7
;.TAP_miniAttributes
	defb %00111001


;	BIN
	defb FT_BINARY

.BIN16x16
	defb %00000000,%00000000 ; line 0
	defb %01111111,%11111110 ; line 1
	defb %01000000,%00000010 ; line 2
	defb %01100101,%10100010 ; line 3
	defb %01000101,%10100110 ; line 4
	defb %01100101,%10100010 ; line 5
	defb %01000000,%00000110 ; line 6
	defb %01100000,%00000010 ; line 7
	defb %01000000,%00000110 ; line 8
	defb %01101101,%10010010 ; line 9
	defb %01001101,%10010110 ; line 10
	defb %01101101,%10010010 ; line 11
	defb %01000000,%00000110 ; line 12
	defb %01000000,%00000010 ; line 13
	defb %01111111,%11111110 ; line 14
	defb %00000000,%00000000 ; line 15
;.BINAttributes
	defb %01101010,%01101010 ; line 0
	defb %01101010,%01101010 ; line 1


;.BIN_mini
	defb %00000000 ; line 0
	defb %01111111 ; line 1
	defb %00101010 ; line 2
	defb %01101011 ; line 3
	defb %00111110 ; line 4
	defb %01101011 ; line 5
	defb %00101010 ; line 6
	defb %01111111 ; line 7
;.BIN_miniAttributes
	defb %00001111 ; line 0


;	ROM
	defb FT_ROMSET

;	.ROM
	defb %00000000,%00000000 ; line 0
	defb %00111111,%11111100 ; line 1
	defb %01001111,%11111110 ; line 2
	defb %01011100,%01111110 ; line 3
	defb %01111100,%10111110 ; line 4
	defb %01011100,%11011110 ; line 5
	defb %01111100,%11011110 ; line 6
	defb %01111100,%10111110 ; line 7
	defb %01111100,%01111110 ; line 8
	defb %01111111,%11111110 ; line 9
	defb %00111111,%11111100 ; line 10
	defb %00000000,%00000000 ; line 11
	defb %00011111,%11111000 ; line 12
	defb %00011111,%11111000 ; line 13
	defb %00011111,%11111000 ; line 14
	defb %00000000,%00000000 ; line 15
;	.ROMAttributes
	defb %01101010,%01101010 ; line 0
	defb %01101010,%01101010 ; line 1


;	.ROM_mini
	defb %00000000 ; line 0
	defb %01111111 ; line 1
	defb %01100111 ; line 2
	defb %01101011 ; line 3
	defb %01100111 ; line 4
	defb %01111111 ; line 5
	defb %00000000 ; line 6
	defb %00111110 ; line 7
;	.ROM_miniAttributes
	defb %00111010 ; line 0

;	BASIC
	defb FT_BASIC

;	.BASIC
	defb %11111111,%00000000 ; line 0
	defb %11111111,%00000000 ; line 1
	defb %11111111,%00000000 ; line 2
	defb %11111111,%00000000 ; line 3
	defb %11111000,%00111000 ; line 4
	defb %11110001,%01110000 ; line 5
	defb %11100011,%11100000 ; line 6
	defb %11111111,%00000000 ; line 7
	defb %11111000,%11000111 ; line 8
	defb %11110001,%10001111 ; line 9
	defb %11100011,%00011111 ; line 10
	defb %11111111,%11111111 ; line 11
	defb %11111111,%00010110 ; line 12
	defb %11111111,%10011001 ; line 13
	defb %11111111,%01111001 ; line 14
	defb %11111111,%00010110 ; line 15
;	.BASICAttributes
	defb %01010101,%01101110 ; line 0
	defb %01100101,%01001101 ; line 1

;	.BASIC_mini
	defb %11101001 ; line 0
	defb %01100110 ; line 1
	defb %10000110 ; line 2
	defb %11101001 ; line 3
	defb %00000000 ; line 4
	defb %01101101 ; line 5
	defb %11011011 ; line 6
	defb %10110110 ; line 7
;	.BASIC_miniAttributes
	defb %00111010 ; line 0
