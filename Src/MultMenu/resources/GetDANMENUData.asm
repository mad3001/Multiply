;GetDANMENUData - Get info about the 1st slot in EEPROM
		
			LD HL,GetRDMData
			LD DE,RAMRDMData
			PUSH DE
			LD BC,ENDGetRDMData-GetRDMData
			LDIR
			RET

GetRDMData:
		DISP	ScratchRAM
RAMRDMData:
			LD	A,(MLDoffset)
			INC A
			LD (GetRDMData_MLD),A
			LD B,1						;1st Slot to jump there
			SLOT_B
			WAIT_B PAUSELOOPSN

			LD  A,(DANSNAP_PAUSE)		;Slot for Pause/DanSnap (valid value only 2-32)
			LD	(DanSnap_Val),A			;Copy value to there so Multiply have it for use when launching games

			LD	HL,VINFOTXT
			LD  A,(HL)
			CP  "v"						;Dandanator menu have version there "vxxxxxxx" (8 bytes)
			JR  Z,ValidDanMENU
		;Here if no valid Dan MENU
			XOR A
			LD  (InfoVersion),A
			JR   GetRDMData_Rt
ValidDanMENU:
			LD DE,InfoVersion
			LD BC,8
			LDIR
			LD A,(GAMEDATATABADDR)		;Number of games in Dandanator Menu
			LD	(DE),A

GetRDMData_Rt:
			LD A,(GetRDMData_MLD)
			LD B,A						;Multiply Slot to return
			SLOT_B
			WAIT_B PAUSELOOPSN
			
			RET

GetRDMData_MLD:	defb 0				;Will hold MLD number of Multiply so we can return there
		ENT
ENDGetRDMData: