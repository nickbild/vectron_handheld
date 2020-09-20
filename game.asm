;;;;
;
; Reserved memory:
;
; $0000-$7EFF - RAM
; 		$0100-$01FF - 6502 stack
; $7FF0-$7FFF - 6522 VIA
; $8000-$FFFF - ROM
; 		$FFFA-$FFFB - NMI IRQ Vector
; 		$FFFC-$FFFD - Reset Vector - Stores start address of this ROM.
; 		$FFFE-$FFFF - IRQ Vector
;
; ORA Register:
; Bit: 7  | 6  | 5    | 4   | 3     | 2 | 1 | 0 |
;      DC | CS | MOSI | CLK | RESET | 2 | 1 | 0 |
;;;;

		processor 6502

; Named variables in RAM.
		ORG $0000

Paddle1X
		.byte #$00
Paddle1Color
		.byte #$00
Paddle2X
		.byte #$00
Paddle2Color
		.byte #$00
BallX
		.byte #$00
BallXDir					; 0 = up; 1 = down
		.byte #$00
BallY
		.byte #$00
BallYDir					; 0 = left; 1 = right
		.byte #$00
BallYSpeed
		.byte #$00
BallColor
		.byte #$00


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

		jsr InitDisplay
		jsr DrawBackground
		jsr DrawPlayfield

		; Set paddle 1 initial location and draw.
		lda #$23
		sta Paddle1X
		lda #$FF
		sta Paddle1Color
		jsr DrawPaddle1

		; Set paddle 2 initial location and draw.
		lda #$23
		sta Paddle2X
		lda #$C0
		sta Paddle2Color
		jsr DrawPaddle2

		; Set ball initial location and draw.
		lda #$60
		sta BallX
		lda #$60
		sta BallY
		lda #$FF
		sta BallColor
		lda #$00
		sta BallXDir
		lda #$01
		sta BallYSpeed
		lda #$00
		sta BallYDir
		jsr DrawBall

		; Clear interrupts in IFR.
		lda #$FF
		sta $7FFD

		cli


MainLoop
		jsr Delay

		; Erase ball.
		lda #$00
		sta BallColor
		jsr DrawBall

		; Move and redraw ball.
		lda #$FF
		sta BallColor
		jsr MoveBall
		jsr DrawBall

		jmp MainLoop


ViaIsr
		pha
		.byte #$DA ; phx
		.byte #$5A ; phy

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

InterruptCB1 ; Up

		; Erase paddle.
		lda #$00
		sta Paddle1Color
		jsr DrawPaddle1

		; Move paddle and draw.
		lda Paddle1X
		sec
		sbc #$05

		cmp #$00
		beq SkipUp

		sta Paddle1X

SkipUp
		lda #$FF
		sta Paddle1Color
		jsr DrawPaddle1

		jmp InterruptDone
InterruptCB2

		;jsr CB2Pixel

		jmp InterruptDone
InterruptCA1

		;jsr CA1Pixel

		jmp InterruptDone
InterruptCA2 ; Down

		; Erase paddle.
		lda #$00
		sta Paddle1Color
		jsr DrawPaddle1

		; Move paddle and draw.
		lda Paddle1X
		clc
		adc #$05

		; Branch if A >= 107
		cmp #$6B
		bcs SkipDown

		sta Paddle1X

SkipDown
		lda #$FF
		sta Paddle1Color
		jsr DrawPaddle1

		jmp InterruptDone

InterruptDone
		; Clear interrupts in IFR.
		lda #$FF
		sta $7FFD

		.byte #$7A ; ply
		.byte #$FA ; plx
		pla

		rti


NMIIsr
		pha
		.byte #$DA ; phx
		.byte #$5A ; phy

		; digitalWrite(cs, LOW);
		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

	  ; // Column address set.
	  ; writeCommand(0x2A);
		lda #$2A
		jsr WriteCommandToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda #$14
		jsr WriteByteToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda #$14
		jsr WriteByteToDisplay

	  ; // Row address set.
	  ; writeCommand(0x2B);
		lda #$2B
		jsr WriteCommandToDisplay

	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$0A
		jsr WriteByteToDisplay
	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$0A
		jsr WriteByteToDisplay

	  ; // RAM write.
	  ; writeCommand(0x2C);
		lda #$2C
		jsr WriteCommandToDisplay

	  ; writeData16(color);
		lda #$FF
		jsr WriteByteToDisplay
		lda #$FF
		jsr WriteByteToDisplay

	  ; digitalWrite(cs, HIGH);
		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		.byte #$7A ; ply
		.byte #$FA ; plx
		pla

		rti


InitDisplay
		lda #$88	; DC and reset high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		lda #$08	; Reset low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		jsr Delay

		lda #$08	; Reset high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		jsr Delay

		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		; writeCommand(0xEF);
		lda #$EF
		jsr WriteCommandToDisplay

		; writeData(0x03);
		lda #$03
		jsr WriteByteToDisplay

		; writeData(0x80);
		lda #$80
		jsr WriteByteToDisplay

		; writeData(0x02);
		lda #$02
		jsr WriteByteToDisplay

		; writeCommand(0xCF);
		lda #$CF
		jsr WriteCommandToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeData(0xC1);
		lda #$C1
		jsr WriteByteToDisplay

		; writeData(0x30);
		lda #$30
		jsr WriteByteToDisplay

	  ; writeCommand(0xED);
		lda #$ED
		jsr WriteCommandToDisplay

	  ; writeData(0x64);
		lda #$64
		jsr WriteByteToDisplay

	  ; writeData(0x03);
		lda #$03
		jsr WriteByteToDisplay

	  ; writeData(0x12);
		lda #$12
		jsr WriteByteToDisplay

	  ; writeData(0x81);
		lda #$81
		jsr WriteByteToDisplay

		; writeCommand(0xE8);
		lda #$E8
		jsr WriteCommandToDisplay

		; writeData(0x85);
		lda #$85
		jsr WriteByteToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeData(0x78);
		lda #$78
		jsr WriteByteToDisplay

		; writeCommand(0xCB);
		lda #$CB
		jsr WriteCommandToDisplay

		; writeData(0x39);
		lda #$39
		jsr WriteByteToDisplay

		; writeData(0x2C);
		lda #$2C
		jsr WriteByteToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeData(0x34);
		lda #$34
		jsr WriteByteToDisplay

		; writeData(0x02);
		lda #$02
		jsr WriteByteToDisplay

		; writeCommand(0xF7);
		lda #$F7
		jsr WriteCommandToDisplay

		; writeData(0x20);
		lda #$20
		jsr WriteByteToDisplay

		; writeCommand(0xEA);
		lda #$EA
		jsr WriteCommandToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeCommand(0xC0);
		lda #$C0
		jsr WriteCommandToDisplay

		; writeData(0x23);
		lda #$23
		jsr WriteByteToDisplay

		; writeCommand(0xC1);
		lda #$C1
		jsr WriteCommandToDisplay

		; writeData(0x10);
		lda #$10
		jsr WriteByteToDisplay

		; writeCommand(0xC5);
		lda #$C5
		jsr WriteCommandToDisplay

		; writeData(0x3E);
		lda #$3E
		jsr WriteByteToDisplay

		; writeData(0x28);
		lda #$28
		jsr WriteByteToDisplay

		; writeCommand(0xC7);
		lda #$C7
		jsr WriteCommandToDisplay

		; writeData(0x86);
		lda #$86
		jsr WriteByteToDisplay

		; writeCommand(0x36);
		lda #$36
		jsr WriteCommandToDisplay

		; writeData(0x48);
		lda #$48
		jsr WriteByteToDisplay

		; writeCommand(0x37);
		lda #$37
		jsr WriteCommandToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeCommand(0x3A);
		lda #$3A
		jsr WriteCommandToDisplay

		; writeData(0x55);
		lda #$55
		jsr WriteByteToDisplay

		; writeCommand(0xB1);
		lda #$B1
		jsr WriteCommandToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeData(0x18);
		lda #$18
		jsr WriteByteToDisplay

		; writeCommand(0x86);
		lda #$86
		jsr WriteCommandToDisplay

		; writeData(0x08);
		lda #$08
		jsr WriteByteToDisplay

		; writeData(0x82);
		lda #$82
		jsr WriteByteToDisplay

		; writeData(0x27);
		lda #$27
		jsr WriteByteToDisplay

		; writeCommand(0xF2);
		lda #$F2
		jsr WriteCommandToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeCommand(0x26);
		lda #$26
		jsr WriteCommandToDisplay

		; writeData(0x01);
		lda #$01
		jsr WriteByteToDisplay

		; writeCommand(0xE0);
		lda #$E0
		jsr WriteCommandToDisplay

		; writeData(0x0F);
		lda #$0F
		jsr WriteByteToDisplay

		; writeData(0x31);
		lda #$31
		jsr WriteByteToDisplay

		; writeData(0x2B);
		lda #$2B
		jsr WriteByteToDisplay

		; writeData(0x0C);
		lda #$0C
		jsr WriteByteToDisplay

		; writeData(0x0E);
		lda #$0E
		jsr WriteByteToDisplay

		; writeData(0x08);
		lda #$08
		jsr WriteByteToDisplay

		; writeData(0x4E);
		lda #$4E
		jsr WriteByteToDisplay

		; writeData(0xF1);
		lda #$F1
		jsr WriteByteToDisplay

		; writeData(0x37);
		lda #$37
		jsr WriteByteToDisplay

		; writeData(0x07);
		lda #$07
		jsr WriteByteToDisplay

		; writeData(0x10);
		lda #$10
		jsr WriteByteToDisplay

		; writeData(0x03);
		lda #$03
		jsr WriteByteToDisplay

		; writeData(0x0E);
		lda #$0E
		jsr WriteByteToDisplay

		; writeData(0x09);
		lda #$09
		jsr WriteByteToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeCommand(0xE1);
		lda #$E1
		jsr WriteCommandToDisplay

		; writeData(0x00);
		lda #$00
		jsr WriteByteToDisplay

		; writeData(0x0E);
		lda #$0E
		jsr WriteByteToDisplay

		; writeData(0x14);
		lda #$14
		jsr WriteByteToDisplay

		; writeData(0x03);
		lda #$03
		jsr WriteByteToDisplay

		; writeData(0x11);
		lda #$11
		jsr WriteByteToDisplay

		; writeData(0x07);
		lda #$07
		jsr WriteByteToDisplay

		; writeData(0x31);
		lda #$31
		jsr WriteByteToDisplay

		; writeData(0xC1);
		lda #$C1
		jsr WriteByteToDisplay

		; writeData(0x48);
		lda #$48
		jsr WriteByteToDisplay

		; writeData(0x08);
		lda #$08
		jsr WriteByteToDisplay

		; writeData(0x0F);
		lda #$0F
		jsr WriteByteToDisplay

		; writeData(0x0C);
		lda #$0C
		jsr WriteByteToDisplay

		; writeData(0x31);
		lda #$31
		jsr WriteByteToDisplay

		; writeData(0x36);
		lda #$36
		jsr WriteByteToDisplay

		; writeData(0x0F);
		lda #$0F
		jsr WriteByteToDisplay

		 ;writeCommand(0x11);
		lda #$11
		jsr WriteCommandToDisplay

		jsr Delay

		; writeCommand(0x29);
		lda #$29
		jsr WriteCommandToDisplay

		; writeCommand(0x00);
		lda #$00
		jsr WriteCommandToDisplay

		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		rts


DrawBackground
		; digitalWrite(cs, LOW);
		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

	  ; // Column address set.
	  ; writeCommand(0x2A);
		lda #$2A
		jsr WriteCommandToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda #$00
		jsr WriteByteToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda #$7F
		jsr WriteByteToDisplay

	  ; // Row address set.
	  ; writeCommand(0x2B);
		lda #$2B
		jsr WriteCommandToDisplay

	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$00
		jsr WriteByteToDisplay
	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$9F
		jsr WriteByteToDisplay

	  ; // RAM write.
	  ; writeCommand(0x2C);
		lda #$2C
		jsr WriteCommandToDisplay

	  ; writeData16(color);
		lda #$00 ; color

		ldx #$80
BGLoop1
		ldy #$A0
BGLoop2
		jsr WriteByteToDisplay
		jsr WriteByteToDisplay

		dey
		bne BGLoop2
		dex
		bne BGLoop1

	  ; digitalWrite(cs, HIGH);
		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		rts


DrawPlayfield
		sei

		; digitalWrite(cs, LOW);
		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

	  ; // Column address set.
	  ; writeCommand(0x2A);
		lda #$2A
		jsr WriteCommandToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda #$00
		jsr WriteByteToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda #$7F
		jsr WriteByteToDisplay

	  ; // Row address set.
	  ; writeCommand(0x2B);
		lda #$2B
		jsr WriteCommandToDisplay

	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$4E
		jsr WriteByteToDisplay
	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$50
		jsr WriteByteToDisplay

	  ; // RAM write.
	  ; writeCommand(0x2C);
		lda #$2C
		jsr WriteCommandToDisplay

		; writeData16(color);
		lda #$FC ; color

		ldx #$03
XLoopNet
		ldy #$80
YLoopNet
		jsr WriteByteToDisplay
		jsr WriteByteToDisplay

		dey
		bne YLoopNet
		dex
		bne XLoopNet

	  ; digitalWrite(cs, HIGH);
		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		cli
		rts


DrawPaddle1
		; digitalWrite(cs, LOW);
		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

	  ; // Column address set.
	  ; writeCommand(0x2A);
		lda #$2A
		jsr WriteCommandToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda Paddle1X
		jsr WriteByteToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda Paddle1X
		clc
		adc #$13
		jsr WriteByteToDisplay

	  ; // Row address set.
	  ; writeCommand(0x2B);
		lda #$2B
		jsr WriteCommandToDisplay

	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$9C
		jsr WriteByteToDisplay
	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$9E
		jsr WriteByteToDisplay

	  ; // RAM write.
	  ; writeCommand(0x2C);
		lda #$2C
		jsr WriteCommandToDisplay

		; writeData16(color);
		lda Paddle1Color ; color

		ldx #$03
XLoopPaddle1
		ldy #$14
YLoopPaddle1
		jsr WriteByteToDisplay
		jsr WriteByteToDisplay

		dey
		bne YLoopPaddle1
		dex
		bne XLoopPaddle1

	  ; digitalWrite(cs, HIGH);
		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		rts


DrawPaddle2
		; digitalWrite(cs, LOW);
		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

	  ; // Column address set.
	  ; writeCommand(0x2A);
		lda #$2A
		jsr WriteCommandToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda Paddle2X
		jsr WriteByteToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda Paddle2X
		clc
		adc #$13
		jsr WriteByteToDisplay

	  ; // Row address set.
	  ; writeCommand(0x2B);
		lda #$2B
		jsr WriteCommandToDisplay

	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$00
		jsr WriteByteToDisplay
	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda #$02
		jsr WriteByteToDisplay

	  ; // RAM write.
	  ; writeCommand(0x2C);
		lda #$2C
		jsr WriteCommandToDisplay

		; writeData16(color);
		lda Paddle2Color ; color

		ldx #$03
XLoopPaddle2
		ldy #$14
YLoopPaddle2
		jsr WriteByteToDisplay
		jsr WriteByteToDisplay

		dey
		bne YLoopPaddle2
		dex
		bne XLoopPaddle2

	  ; digitalWrite(cs, HIGH);
		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		rts


DrawBall
		sei

		; digitalWrite(cs, LOW);
		lda #$40	; CS low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

	  ; // Column address set.
	  ; writeCommand(0x2A);
		lda #$2A
		jsr WriteCommandToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda BallX
		jsr WriteByteToDisplay

	  ; writeData16(x);
		lda #$00
		jsr WriteByteToDisplay
		lda BallX
		clc
		adc #$03
		jsr WriteByteToDisplay

	  ; // Row address set.
	  ; writeCommand(0x2B);
		lda #$2B
		jsr WriteCommandToDisplay

	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda BallY
		jsr WriteByteToDisplay
	  ; writeData16(y);
		lda #$00
		jsr WriteByteToDisplay
		lda BallY
		clc
		adc #$03
		jsr WriteByteToDisplay

	  ; // RAM write.
	  ; writeCommand(0x2C);
		lda #$2C
		jsr WriteCommandToDisplay

		; writeData16(color);
		lda BallColor ; color

		ldy #$10
YLoopBall
		jsr WriteByteToDisplay
		jsr WriteByteToDisplay

		dey
		bne YLoopBall

	  ; digitalWrite(cs, HIGH);
		lda #$40	; CS high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		cli
		rts


MoveBall
		; X movement
		lda BallXDir
		cmp #$00
		bne BallDirDown
		; Move ball up
		dec BallX
		jmp BallXDone
BallDirDown
		; Move ball down
		inc BallX
BallXDone

		; Y movement
		lda BallYDir
		cmp #$00
		bne BallDirRight
		; Move ball left
		lda BallY
		sec
		sbc BallYSpeed
		sta BallY

		jmp BallYDone
BallDirRight
		; Move ball right
		lda BallY
		clc
		adc BallYSpeed
		sta BallY
BallYDone

		rts


WriteCommandToDisplay
		pha
		.byte #$DA ; phx
		.byte #$5A ; phy

		tax

		lda #$80	; DC low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		txa
		jsr WriteByteToDisplay

		lda #$80	; DC high
		.byte #$0C ; tsb - set bit
		.word #$7FF1

		.byte #$7A ; ply
		.byte #$FA ; plx
		pla

		rts


WriteByteToDisplay
		pha
		.byte #$DA ; phx
		.byte #$5A ; phy

		;;; Bit 7
		asl	; bit 7 to carry
		tax	; save accumulator

		bcs Bit7High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit7Done
Bit7High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit7Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 6
		txa ; restore accumulator
		asl	; bit 6 to carry
		tax	; save accumulator

		bcs Bit6High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit6Done
Bit6High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit6Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 5
		txa ; restore accumulator
		asl	; bit 5 to carry
		tax	; save accumulator

		bcs Bit5High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit5Done
Bit5High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit5Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 4
		txa ; restore accumulator
		asl	; bit 4 to carry
		tax	; save accumulator

		bcs Bit4High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit4Done
Bit4High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit4Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 3
		txa ; restore accumulator
		asl	; bit 3 to carry
		tax	; save accumulator

		bcs Bit3High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit3Done
Bit3High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit3Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 2
		txa ; restore accumulator
		asl	; bit 2 to carry
		tax	; save accumulator

		bcs Bit2High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit2Done
Bit2High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit2Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 1
		txa ; restore accumulator
		asl	; bit 1 to carry
		tax	; save accumulator

		bcs Bit1High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit1Done
Bit1High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit1Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		;;; Bit 0
		txa ; restore accumulator
		asl	; bit 0 to carry
		tax	; save accumulator

		bcs Bit0High
		lda #$20 ; MOSI low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1
		jmp Bit0Done
Bit0High
		lda #$20 ; MOSI high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
Bit0Done
		lda #$10 ; Clock high.
		.byte #$0C ; tsb - set bit
		.word #$7FF1
		lda #$10 ; Clock low.
		.byte #$1C ; trb - clear bit
		.word #$7FF1

		.byte #$7A ; ply
		.byte #$FA ; plx
		pla

		rts


Delay		ldx #$FF
DelayLoop1	ldy #$FF
DelayLoop2	dey
		bne DelayLoop2
		dex
		bne DelayLoop1

		rts


		ORG $FFFA
NMIVector
		.word NMIIsr			; NMI Interrupt service routine.
ResetVector
		.word StartExe		; Start of execution.
IrqVector
		.word ViaIsr			; Interrupt service routine.
