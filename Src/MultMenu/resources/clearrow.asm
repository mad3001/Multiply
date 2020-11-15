;Clear SemiRow-Left
;	IN	A=row				%000RRrrr
;	IN	B=Colour
;	IN	C=1 less of Length to clear
;Pixel
;			Address (High)	76543210	(Low) 76543210
;							010RRsss		  rrrccccc

;Attr
;			Address (High)	76543210  (Low) 76543210
;							010110RR		rrrccccc
ClearRow:
			.3	RRCA			;%rrr000RR
			LD	L,A				;save for later %rrr000RR
			AND %00000011		;%000000RR
			OR	%01011000		;%010110RR
			LD	H,A

			LD	A,L				;%rrr000RR
			AND	%11100000		;%rrr00000
			LD	L,A
			
			PUSH	HL			;HL=Attr address
			LD		D,H
			LD		E,L
			INC		DE			;DE=Attr address + 1
			LD		(HL),B		;B=Colour
			LD		B,0
			PUSH	BC			;B=0, C=1 less of Length to clear
			LDIR

			POP		BC			;B=0, C=1 less of Length to clear
			POP		HL			;H=%010110RR L=rrr00000
			LD		A,H			;A=%010110RR
			.3		RLCA		;A=%110RR010
			AND		%01011000	;A=%010RR000
			LD		H,A
			
			LD		A,8
Pix_Loop_Zero:

			LD		D,H
			LD		E,L			;HL=Pix Address
			INC		DE			;DE=Pix Address + 1
			LD		(HL),B
			PUSH	HL,DE,BC
			LDIR

			POP		BC,DE,HL
			INC		H
			INC		D

			DEC		A
			JR		NZ,Pix_Loop_Zero
			
			RET
			
ClsFiles:
			LD		A,MaxRowFiles					;Beginning a new folder 
ClsFiles_Loop:
			PUSH	AF
			LD		BC,15+(NoSel_Color<<8)
			CALL	ClearRow
			POP		AF
			DEC		A
			JR		NZ,ClsFiles_Loop
			RET
