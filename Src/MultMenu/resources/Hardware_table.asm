;Hardware_Tables

HW_Table:
	defw	HW_48k									;Index 0
	defw	HW_48k_IF1								;Index 1
	defw	SAMRAM									;Index 2
	defw	HW_48k_MGT								;Index 3
	defw	HW_128k									;Index 4
	defw	HW_128k_IF1								;Index 5
	defw	HW_128k_MGT								;Index 6
	defw	HW_PLUS3								;Index 7
	defw	HW_PLUS3B								;Index 8
	defw	HW_PENTAGON								;Index 9
	defw	HW_SCORPION								;Index 10
	defw	HW_DIDAKTIC								;Index 11
	defw	HW_PLUS2								;Index 12
	defw	HW_PLUS2A								;Index 13
	defw	HW_TC2048								;Index 14
	defw	HW_TS2068								;Index 15

;table for "changed" machines
	defw	HW_16k									;Index 16
	defw	HW_16k_IF1								;Index 17
	defw	SAMRAM16								;Index 18
	defw	HW_16k_MGT								;Index 19
	defw	HW_PLUS2								;Index 20
	defw	HW_PLUS2_IF1							;Index 21
	defw	HW_PLUS2_MGT							;Index 22
	defw	HW_PLUS2A								;Index 23
	defw	HW_PLUS2A								;Index 24

HW_Unknown:
	defb	"Unknown",0

HW_48k:
	defb	"48K",0
	
HW_48k_IF1:
	defb	"48K+IF1",0
	
SAMRAM:
	defb	"SamRam",0	

HW_48k_MGT:
	defb	"48K+MGT",0

HW_128k:
	defb	"128K",0

HW_128k_IF1:
	defb	"128K+IF1",0

HW_128k_MGT:
	defb	"128K+MGT",0

HW_PLUS3:
HW_PLUS3B:
	defb	"128K +3",0

HW_PENTAGON:
	defb	"Pentagon128",0
	
HW_SCORPION:
	defb	"Scorpion256",0	
	
HW_DIDAKTIC:
	defb	"Didaktic",0	
	
HW_PLUS2:
	defb	"128K +2",0

HW_PLUS2A:
	defb	"128K +2A",0

HW_TC2048:
	defb	"TC 2048",0

HW_TC2068:
	defb	"TC 2068",0

HW_TS2068:
	defb	"TS 2068",0

;Extended machines (bit 7=1 for byte 0x25 and machine btw 0..8)
HW_16k:
	defb	"16K",0
	
HW_16k_IF1:
	defb	"16K+IF1",0
	
SAMRAM16:
	defb	"16k SamRam",0	

HW_16k_MGT:
	defb	"16K+MGT",0

HW_PLUS2_IF1:
	defb	"128K+2 +IF1",0

HW_PLUS2_MGT:
	defb	"128K+2 +MGT",0
