;;;;
;
; Reserved memory:
;
; $0000-$7EFF - RAM
;			$0100-$01FF - 6502 stack
; $7FF0-$7FFF - 6522 VIA
; $8000-$FFFF - ROM
; 		$FFFA-$FFFB - NMI IRQ Vector
; 		$FFFC-$FFFD - Reset Vector - Stores start address of this ROM.
; 		$FFFE-$FFFF - IRQ Vector
;;;;

		processor 6502

; Start at beginning of ROM.
StartExe	ORG $8000
		sei

		; Disable all VIA interrupts in IER.
		lda #$7F
		sta $7FFE

		; Enable VIA interrupts in IER - CA1, CA2, CB1, CB2.
		lda #$9B
		sta $7FFE

		; Configure PCR.
		; 0 1 0 = CB2: Input-positive active edge
		; 1 		= CB1: Positive Active Edge
		; 0 1 0 = CA2: Input-positive active edge
		; 1 		= CA1: Positive Active Edge
		lda #$55
		sta $7FFC

		; Set DDRB to all outputs.
		lda #$FF
		sta $7FF2

		; Set DDRA to all outputs.
		lda #$FF
		sta $7FF3

		; Set ORB outputs low.
		lda #$00
		sta $7FF0

		; Set ORA outputs low.
		lda #$00
		sta $7FF1

		; Clear interrupts in IFR.
		lda #$FF
		sta $7FFD

		cli

MainLoop
		jmp MainLoop

ViaIsr
		lda $7FFD ; Load IFR contents.

		; Find source of interrupt.
		asl ; bit 6
		asl ; bit 5
		asl ; bit 4 CB1
		bmi InterruptCB1
		asl ; bit 3 CB2
		bmi InterruptCB2
		asl ; bit 2
		asl ; bit 1 CA1
		bmi InterruptCA1
		asl ; bit 0 CA2
		bmi InterruptCA2
		jmp InterruptDone

InterruptCB1
		lda #$05
		sta $00
		jmp InterruptDone
InterruptCB2
		lda #$00
		sta $00
		jmp InterruptDone
InterruptCA1
		lda #$03
		sta $00
		jmp InterruptDone
InterruptCA2
		lda #$0F
		sta $00
		jmp InterruptDone

InterruptDone
		; Clear interrupts in IFR.
		lda #$FF
		sta $7FFD

		rti

		ORG $FFFC
ResetVector
		.word StartExe		; Start of execution.
IrqVector
		.word ViaIsr			; Interrupt service routine.
