; *********************************************************************************************************************************
; programming	: pvar a.k.a. spir@l evolut10n
; started		: 22-11-2011
; completed		: 13-02-2012
;
;
; *********************************************************************************************************************************

; ****************************************************************
; * fundamental assembler directives
; ****************************************************************

.include "2313def.inc"

.equ dimming_ptr = 0x60		                ; pointer to (alpha-corrected) dimming values for smooth fading

.equ ch1_phase_delta_l = 0x62
.equ ch1_phase_delta_h = 0x63
.equ ch1_effect_data = 0x64
.equ ch1_volume = 0x65

.equ ch2_phase_delta_l = 0x66
.equ ch2_phase_delta_h = 0x67
.equ ch2_effect_data = 0x68
.equ ch2_volume = 0x69

.equ ch3_phase_delta_l = 0x6a
.equ ch3_phase_delta_h = 0x6b
.equ ch3_effect_data = 0x6c

.equ ch4_phase_delta_l = 0x6d
.equ ch4_phase_delta_h = 0x6e
.equ ch4_effect_data = 0x6f


.def ch1_sample = r16
.def ch1_phase_accum_h = r17
.def ch1_phase_accum_l = r1
.def ch1_note_ptr_l = r2
.def ch1_note_ptr_h = r3

.def ch2_sample = r18
.def ch2_phase_accum_h = r19
.def ch2_phase_accum_l = r4
.def ch2_note_ptr_l = r5
.def ch2_note_ptr_h = r6

.def ch3_sample = r20
.def ch3_phase_accum_h = r21
.def ch3_phase_accum_l = r7
.def ch3_note_ptr_l = r8
.def ch3_note_ptr_h = r9

.def ch4_sample = r22
.def ch4_phase_accum_h = r23
.def ch4_phase_accum_l = r10
.def ch4_note_ptr_l = r11
.def ch4_note_ptr_h = r12

.def lfsr_l = r13							; registers for LFSR (used by channel 4 - noise)
.def lfsr_h = r14							;

.def mode = r15								; prorgam mode (0xff: play / 0x00: stop)

.def ch1_duration = r24 					; counters for duration of current note on each channel
.def ch2_duration = r25 					; 
.def ch3_duration = r26 					; (here lies XL, but X pointer is never used)
.def ch4_duration = r27						; (here lies XH, but X pointer is never used)

.def tmp3 = r28								; temporary working registers
.def tmp4 = r29								; (where YH:YL is lying / Y-pointer is never used)

; ****************************************************************
; * code segment initialization
; ****************************************************************

.cseg
.org 0

	rjmp mcu_init							; $000 RESET Hardware Pin, Power-on Reset and Watchdog Reset
	reti									; $001 INT0 External Interrupt Request 0
	reti									; $002 INT0 External Interrupt Request 1
	reti									; $003 TIMER1 CAPT1 Timer/Counter1 Capture Evend_cht
	rjmp updates							; $004 TIMER1 COMP1 Timer/Counter1 Compare Match
	reti									; $005 TIMER1 OVF1 Timer/Counter1 Overflow
	rjmp waveform							; $006 TIMER0 OVF0 Timer/Counter0 Overflow
	reti									; $007 UART, RX UART, RX Complete
	reti									; $008 UART, UDRE UART Data Register Empty
	reti									; $009 UART, TX UART, TX Complete
	reti									; $00A ANA_COMP Analog Comparator

.include "fade.asm"
.include "play.asm"
.include "sme.asm"

; ****************************************************************
; * microcontroller initialization
; ****************************************************************

mcu_init:
	ldi tmp3, $df							; stack space init
	out SPL, tmp3							; Stack Pointer Low byte

	ldi tmp3, 0b10000000					;
	out ACSR, tmp3							; disable analog comparator

	ldi tmp3, 0b00100000					;
	out MCUCR, tmp3							; enable sleep instruction and select idle mode

	ldi tmp3, 0b00111111					;
	out DDRB, tmp3							; waveform sample-pins are outputs
	ldi tmp3, 0b11000000					;
	out PORTB, tmp3							; enable pull-up resistors on input pins

	ldi tmp3, 0b00010011					;
	out DDRD, tmp3							; LED pins (PD0, PD1 and PD4) are outputs
	ldi tmp3, 0b11101100					;
	out PORTD, tmp3							; enable pull-up resistors on input pins

; ****************************************************************
; * main program loop
; ****************************************************************

main_loop:
	cli										; disable all interrupts

	clr tmp4								; used as counter for dimming_level change and button test
	rcall dimming_cycle

	in tmp3, PIND							; read input pins
	andi tmp3, 0b00100000					; isolate button pin
	brne main_loop							; if not pressed, loop once more

	cbi PORTD, 4							; if pressed, turn LED off and call play routine
	rcall play								;

	rjmp main_loop							; when play routine finishes, start over...

; ****************************************************************
; * flash constant table
; ****************************************************************

dim_levels: ; alpha corrected values for smooth dimming
	.db		1, 2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 40, 80, 120, 190, 250
	.db		250, 190, 120, 80, 40, 32, 24, 20, 16, 12, 10, 8, 6, 4, 2, 1

deltas:		; phase delta for each note
	; 2nd octave --------- 0
	.db		0x00, 0x85   ; (C)
	.db		0x00, 0x8d   ; (C#)
	.db		0x00, 0x95   ; (D)
	.db		0x00, 0x9e   ; (Eb)
	.db		0x00, 0xa7   ; (E)
	.db		0x00, 0xb1   ; (F)
	.db		0x00, 0xbc   ; (F#)
	.db		0x00, 0xc7   ; (G)
	.db		0x00, 0xd3   ; (G#)
	.db		0x00, 0xdf   ; (A)
	.db		0x00, 0xed   ; (Bb)
	.db		0x00, 0xfb   ; (B)
	; 3rd octave --------- 24
	.db		0x01, 0x0a   ; (C)
	.db		0x01, 0x1a   ; (C#)
	.db		0x01, 0x2a   ; (D)
	.db		0x01, 0x3c   ; (Eb)
	.db		0x01, 0x4f   ; (E)
	.db		0x01, 0x63   ; (F)
	.db		0x01, 0x78   ; (F#)
	.db		0x01, 0x8e   ; (G)
	.db		0x01, 0xa6   ; (G#)
	.db		0x01, 0xbf   ; (A)
	.db		0x01, 0xda   ; (Bb)
	.db		0x01, 0xf6   ; (B)
	; 4th octave --------- 48
	.db		0x02, 0x13	; (C)
	.db		0x02, 0x33	; (C#)
	.db		0x02, 0x55	; (D)
	.db		0x02, 0x78	; (Eb)
	.db		0x02, 0x9e	; (E)
	.db		0x02, 0xc5	; (F)
	.db		0x02, 0xf0	; (F#)
	.db		0x03, 0x1c	; (G)
	.db		0x03, 0x4c	; (G#)
	.db		0x03, 0x7e	; (A)
	.db		0x03, 0xb3	; (Bb)
	.db		0x03, 0xeb	; (B)
	; 5th octave --------- 72
	.db		0x04, 0x27   ; (C)
	.db		0x04, 0x66   ; (C#)
	.db		0x04, 0xa9   ; (D)
	.db		0x04, 0xf0   ; (Eb)
	.db		0x05, 0x3b   ; (E)
	.db		0x05, 0x8b   ; (F)
	.db		0x05, 0xdf   ; (F#)
	.db		0x06, 0x39   ; (G)
	.db		0x06, 0x97   ; (G#)
	.db		0x06, 0xfc   ; (A)
	.db		0x07, 0x66   ; (Bb)
	.db		0x07, 0xd7   ; (B)
	; 6th octave --------- 96
	.db		0x08, 0x4f   ; (C)
	.db		0x08, 0xcd   ; (C#)
	.db		0x09, 0x53   ; (D)
	.db		0x09, 0xe1   ; (Eb)
	.db		0x0a, 0x78   ; (E)
	.db		0x0b, 0x16   ; (F)
	.db		0x0b, 0xbf   ; (F#)
	.db		0x0c, 0x72   ; (G)
	.db		0x0d, 0x2e   ; (G#)
	.db		0x0d, 0xf8   ; (A)
	.db		0x0e, 0xcd   ; (Bb)
	.db		0x0f, 0xae   ; (B)
	; 7th octave --------- 120
	.db		0x10, 0x9c   ; (C)
	.db		0x11, 0x98   ; (C#)
	.db		0x12, 0xa4   ; (D)
	.db		0x13, 0xc1   ; (Eb)
	.db		0x14, 0xed   ; (E)
	.db		0x16, 0x2c   ; (F)
	.db		0x17, 0x7e   ; (F#)
	.db		0x18, 0xe3   ; (G)
	.db		0x1a, 0x5d   ; (G#)
	.db		0x1b, 0xef   ; (A)
	.db		0x1d, 0x98   ; (Bb)
	.db		0x1f, 0x5b   ; (B)

	.db		0x00, 0x00   ; pseudo note 144 (pause)
	.db		0xff, 0xff   ; pseudo note 146 (melody end)

	.db		0x9f, 0xf0	 ; pseudo note 148 (noise 0)
	.db		0x7e, 0xf0   ; pseudo note 150 (noise 1)
	.db		0x6c, 0xf0   ; pseudo note 152 (noise 2)
	.db		0x5a, 0xf0   ; pseudo note 154 (noise 3)
	.db		0x48, 0xf0   ; pseudo note 156 (noise 4)
	.db		0x36, 0xf0   ; pseudo note 158 (noise 5)
	.db		0x24, 0xf0   ; pseudo note 160 (noise 6)
	.db		0x12, 0xf0   ; pseudo note 162 (noise 7)

; music notation specifications:
; ----------------------------------------------------------------
; two bytes per note (.db 0x00, 0x00)
; 1st byte - 3 higher bits: effect...
;			0 (000): no effect
;			64 (010): pitch bend down
;			96 (011): pitch bend up
;			128 (100): vibrato
; 1st byte - 5 lower bits: duration...
;			1: 1/32
;			2: 1/16
;			3: 1/16<	(3/32)
;			4: 1/8
;			6: 1/8<		(3/16)
;			8: 1/4
;			12:1/4<		(3/8)
;			16:1/2
;			24:1/2<		(3/4)
;			max value for duration: 31
; 2nd byte: pointer to a specific note/octave

ch1_melody:
.db 2, 58, 2, 66, 2, 52, 2, 58, 2, 48, 2, 56, 2, 52, 2, 56, 2, 52, 2, 58, 2, 52, 2, 62, 2, 52, 2, 64, 2, 52, 2, 66
.db 2, 58, 2, 42, 2, 28, 2, 58, 2, 24, 2, 32, 130, 28, 2, 56, 130, 28, 2, 58, 130, 28, 2, 62, 130, 28, 2, 64, 130, 28, 2, 66
.db 2, 58, 2, 42, 2, 28, 2, 58, 2, 24, 2, 32, 130, 52, 2, 56, 130, 52, 2, 58, 130, 52, 2, 62, 130, 52, 2, 64, 130, 52, 2, 66
.db 2, 58, 2, 42, 2, 28, 2, 58, 2, 24, 2, 32, 130, 28, 2, 56, 2, 28, 2, 58, 130, 28, 2, 62, 2, 28, 2, 64, 130, 28, 2, 66
.db 2, 58, 2, 42, 2, 28, 2, 58, 2, 24, 2, 32, 130, 52, 2, 56, 2, 28, 2, 58, 130, 52, 2, 62, 2, 28, 2, 64, 130, 52, 2, 66
.db 130, 28, 68, 4, 4, 144, 1, 58, 1, 66, 1, 52, 1, 58, 1, 48, 1, 56, 1, 52, 1, 56, 1, 52, 1, 58, 1, 52, 1, 62, 1, 52
.db 1, 64, 1, 52, 1, 66, 67, 28, 1, 146

ch2_melody:
ch3_melody:
ch4_melody:
.db 30, 144, 30, 144, 30, 144, 30, 144, 30, 144, 30, 144, 9, 144
.db 30, 144, 30, 144, 30, 144, 30, 144, 30, 144, 30, 144, 9, 144
.db 30, 144, 30, 144, 30, 144, 30, 144, 30, 144, 30, 144, 9, 144



; imperial march
;	.db		8,66,8,66,8,66,6,58,2,72,8,66,6,58,2,72,31,66
;	.db		8,80,8,80,8,80,6,82,2,72,8,64,6,58,2,72,31,66
;	.db		8,90,6,66,2,66,8,90,4,88,4,86,2,84,2,82,4,84,4,144
;	.db		4,68,8,78,4,76,4,74,2,72,2,70,4,72,4,144
;	.db		2,58,8,64,6,58,2,66,8,72,6,66,2,72,31,80
;	.db		8,90,6,66,2,66,8,90,4,88,4,86,2,84,2,82,4,84,4,144
;	.db		4,68,8,78,4,76,4,74,2,72,2,70,4,72,4,144
;	.db		4,58,8,64,6,58,2,72,8,66,6,58,2,48,31,66,6,144
; silence for imperial-march-duration
;	.db		31,144,31,144,31,144,31,144,31,144
;	.db		31,144,31,144,31,144,31,144,31,144
;	.db		31,144,31,144,31,144,31,144,30,144
