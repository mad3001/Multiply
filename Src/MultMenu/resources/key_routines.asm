;INT Key routine

;Check Joystick and keys. Store into (KeyToExe) if key pressed and if repeated only when
;		timing expired
; Value is	0 for no key pressed
;			5 for Right
;			4 for Left
;			3 for Down
;			2 for Up
;			1 for Fire

;ProcessKey - Read kempston joystick and keys and update bits in Kempston Style
ProcessKey:
			LD		A,(CurKey)						;At this moment this really represent the previous value (not the current)
			LD		(LastKey),A						;Update last key pressed with previous value

			IN		A,(#1F)							;Reading Kempston			
			AND		%00011111						;Isolate Joy bits
			JR		Z,NoJoy							;No Joy movement, continue with Keys
		;Here for Any Joy movement... avoid multiple direction and/or fire combined, so let check in this precedence order: Left, Up, Right, Down, Fire
			LD		HL,JoyTable
			LD		B,A								;B=Bits for Joy (always value <>0)
JoyTest:
			LD		A,(HL)
			INC		HL
			AND		B
			JR		Z,JoyTest						;If not this direction then maybe will be the next...always 1 of 5 meet
			CP		#03								;Check for Left+Right (Fire 2)
			JR		NZ,KeyToJoy						;Jumping there A had only 1 bit activated (as A<>0 and A<>#03)
			LD		A,%00100000						;Fire2 like SPACE key is for going to ROOT
			JR		KeyToJoy
			
NoJoy:
			LD		HL,KeyTable
			LD		C,#FE							;BC=xxFE
WaitForKeys_Loop:
			LD		B,(HL)							;Value xx for port to read key(s)
			INC		HL
			IN		A,(C)
			OR		(HL)							;Isolate valid keys
			INC		HL
			INC		A								;If valid key pressed then A<>0 after INC A
			LD		A,(HL)							;A=Code value as per Joystick (don't affect flags)
			INC		HL								;Update HL for next time (don't affect flags)
			JR		NZ,KeyToJoy						;Valid key pressed, jump there
;NoThisKey:
			LD		A,(HL)							;Next value xx for port
			AND		A								;Check if 0 for end of testing
			JR		NZ,WaitForKeys_Loop				;No 0 still have to check
		;Here with Z active if no key was pressed, Z inactive if joy/key was moved/pressed
KeyToJoy:
		;Here with A=0 (no key) or bits 4,3,2,1,0 for directions/fire

			LD		B,A								;Copy key pressed to B
			LD		(CurKey),A						;Update CurKey as Movement
			AND		A
			JR		NZ,TestKey						;any Key pressed jump there
		;Here for no key pressed with A=0
ReKey:
			LD		A,B								;Current key
			LD		(KeyToExe),A					;No key to process A=0
			LD		A,Time1Val						;Time 1st for repeating
			LD		(LastKeyTime),A					;Time for repeat
			RET
			
		;Key pressed, check if this is the 1st time or repeated or it's a different key
TestKey:
			LD		A,(LastKey)						;Get LastKey so check if repeat or not
			CP		B
			JR		NZ,ReKey						;for different key... re-initialize time but also execute that key
			
Rep_Time:
		;Repeat Time countdown
			LD		A,(LastKeyTime)					;Time for repeat
			DEC		A
			LD		(LastKeyTime),A					;decrease repeating time
			JR		Z,Rep_Time_EXE					;Arriving to Zero execute
	IF (1=0)
		;Added as pre-loading preview has "impact" with repeat key, if pre-loading repeat is decreased 2 times
			LD		A,(PreviewLoad)
			CP		PreviewSHOWING					;Check if PreviewStat was nn+1 so repeat time is the usual
			JR		Z,ToNoProc						;No loading preview time is the usual
			CP		1
			JR		NC,ToNoProc						;For value below 1: 0 or FF repeat time is the usual
		;pre-loading so repeat time is lowered to half time here
			LD		A,(LastKeyTime)
			DEC		A
			LD		(LastKeyTime),A					;decrease repeating time
			JR		Z,Rep_Time_EXE
ToNoProc:
	ENDIF
			XOR		A						 		;no process key
			JR		End_Rep_Time
		;Repeat Time expired.. repeat key
Rep_Time_EXE:
			LD		A,TimesVal
			LD		(LastKeyTime),A					;Repeating time for repetitions
			LD		A,B
End_Rep_Time:
			LD		(KeyToExe),A					;Key to process
			RET


;KeyTable - Table for Key-Joy correspondence
;	1st byte - High of Port xxFE. 1 key, or many kays of the row can be checked at a time
;	2nd byte - Mask for keys to test, 0=Test that key, 1=Key doesn't matter
;	3rd byte - Equivalent to Joystick value: Bit 0 for Right, 1 for Left, 2 for Down, 3 for Up, 4 for Fire
;		Table is revised so the 1st key detected that will be the key pressed ( precedence order Left, Up, Right, Down, Fire)
KeyTable:
		;Scancodes for Left (Bit 1)
		;	DEFB	#EF,%11101111,%00000010			;6 is like Joy LEFT (SJ1)
		;	DEFB	#F7,%11111110,%00000010			;1 is like Joy LEFT (SJ2)
			DEFB	#F7,%11101111,%00000010			;5 is like Joy LEFT (Cursor)
;			DEFB	#FE,%11111110,%00000010			;CAPS is like Joy LEFT
			DEFB	#DF,%11110101,%00000010			;O, U  are like Joy LEFT
		;Scancodes for UP (Bit 3)
		;	DEFB	#EF,%11111101,%00001000			;9 is like Joy UP (SJ1)
		;	DEFB	#F7,%11110111,%00001000			;4 is like Joy UP (SJ2)
			DEFB	#EF,%11110111,%00001000			;7 is like Joy UP (Cursor)
			DEFB	#FB,%11100000,%00001000			;QWERT are like Joy UP
		;Scancodes for Right (Bit 0)
		;	DEFB	#EF,%11110111,%00000001			;7 is like Joy RIGHT (SJ1) SJ is for Sinclair Joystick
		;	DEFB	#F7,%11111101,%00000001			;2 is like Joy RIGHT (SJ2)
			DEFB	#EF,%11111011,%00000001			;8 is like Joy RIGHT (Cursor)
			DEFB	#7F,%11111101,%00000001			;SYMBS is like Joy RIGHT
			DEFB	#DF,%11111010,%00000001			;P and I are like Joy RIGHT
		;Scancodes for Down (Bit 2)
		;	DEFB	#EF,%11111011,%00000100			;8 is like Joy DOWN (SJ1)
		;	DEFB	#F7,%11111011,%00000100			;3 is like Joy DOWN (SJ2)
			DEFB	#EF,%11101111,%00000100			;6 is like Joy DOWN (Cursor)
			DEFB	#FD,%11100000,%00000100			;ASDFG are like Joy DOWN

			DEFB	#FE,%11111110,%00000010			;CAPS is like Joy LEFT

		;Scancodes for FIRE (Bit 4)
		;	DEFB	#EF,%11111110,%00010000			;0 is like Joy FIRE (SJ1)
		;	DEFB	#F7,%11101111,%00010000			;5 is like Joy FIRE (SJ2)
			DEFB	#BF,%11111110,%00010000			;ENTER is like Joy FIRE
			
		;Scancodes for ROOT (Bit 5)
			DEFB	#7F,%11111110,%00100000			;SPACE is for going to ROOT
		;No more keys
			DEFB	0	

JoyTable:
			DEFB	%00000011						;Joy LEFT+RIGHT	0x03 (Fire 2)
			;DEFB	%00000010						;Joy LEFT	0x02
			DEFB	%00001000						;Joy UP		0x08
			;DEFB	%00000001						;Joy RIGHT	0x01
			DEFB	%00000100						;Joy DOWN	0x04
			DEFB	%00010000						;Joy FIRE	0x10
			DEFB	0								;No more moves to check			
