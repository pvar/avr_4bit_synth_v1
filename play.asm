; ****************************************************************
; * timer/counter0 overflow ISR
; * calculate next sample of each waveform (channel)
; ****************************************************************

waveform:
	ldi tmp3, 224							; set counter to appropriate starting value (determines sample frequency)
	out TCNT0, tmp3							;

sample_ch1: ; ------------------------------- square wave 50% duty cycle [14 clock ticks]

	lds tmp3, ch1_phase_delta_l				; get phase_delta
	lds tmp4, ch1_phase_delta_h				;

	add ch1_phase_accum_l, tmp3				; add phase_delta to phase_accumulator
	adc ch1_phase_accum_h, tmp4				;
	brcc not_yet1
	clr ch1_phase_accum_l					; if accumulator overflows, clear both bytes
	clr ch1_phase_accum_h					;
not_yet1:

	clr ch1_sample							; compute new sample according to duty cycle
	cpi ch1_phase_accum_h, 0b10000000		; high nibble determines duty cycle (1000: 50%)
	brcs stay_low1							;
	lds ch1_sample, ch1_volume				;
stay_low1:

sample_ch2: ; ------------------------------- square wave 75% duty cycle [14 clock ticks]

	lds tmp3, ch2_phase_delta_l				; get phase_delta
	lds tmp4, ch2_phase_delta_h				;

	add ch2_phase_accum_l, tmp3				; add phase_delta to phase_accumulator
	adc ch2_phase_accum_h, tmp4				;
	brcc not_yet2
	clr ch2_phase_accum_l					; if accumulator overflows, clear both bytes
	clr ch2_phase_accum_h					;
not_yet2:

	clr ch2_sample							; compute new sample according to duty cycle
	cpi ch2_phase_accum_h, 0b11000000		; high nibble determines duty cycle (1100: 75%)
	brcs stay_low2							;
	lds ch2_sample, ch2_volume				;
stay_low2:

sample_ch3: ; ------------------------------- 4bit triangle wave [17 clock ticks]

	lds tmp3, ch3_phase_delta_l				; get phase_delta
	lds tmp4, ch3_phase_delta_h				;

	add ch3_phase_accum_l, tmp3				; add phase_delta to phase_accumulator
	adc ch3_phase_accum_h, tmp4				;
	brcc not_yet3
	clr ch3_phase_accum_l					; if accumulator overflows, clear both bytes
	clr ch3_phase_accum_h					;
not_yet3:

	mov ch3_sample, ch3_phase_accum_h		; get high byte of accumulator
	swap ch3_sample							; swap nibbles
	lsl ch3_sample							; shift 1bit left (high nibble of high byte of accumulator is now shifted 3times right)
	andi ch3_sample, 0b00001110				; keep 3lsb of shifted high nibble

	ldi tmp3, 0b00001110					; prepare a mask according to msb of high nibble of high byte of accumulator
	sbrs ch3_phase_accum_h, 7				;
	ldi tmp3, 0b00000001					;

	eor ch3_sample, tmp3					; Exclusive OR with mask to "center" values around 7

sample_ch4: ; ------------------------------- LFSR white noise [max 18 clock ticks]

	lds tmp3, ch4_phase_delta_l				; get phase_delta
	lds tmp4, ch4_phase_delta_h				;

	add ch4_phase_accum_l, tmp3				; add phase_delta to phase_accumulator
	adc ch4_phase_accum_h, tmp4				;

	brcc skip_lfsr							; if accumulator overflows, compute new sample

	ldi tmp3, 2								;
	lsl lfsr_l								;
	rol lfsr_h								; LFSR random number generator
	brvc skip_xor							;
	eor lfsr_l, tmp3						;
skip_xor:

	mov ch4_sample, lfsr_l					; get sample from LFSR low byte
	ldi tmp3, 0b00000111					; max value for sample = 0b00000111
	and ch4_sample, tmp3					; apply mask to sample
skip_lfsr:

; ------------------------------------------- all samples computed [max 59 clock ticks]

	add ch1_sample, ch2_sample				; add samples from each channel
	add ch1_sample, ch3_sample				;
	add ch1_sample, ch4_sample				;

	out PORTB, ch1_sample					; output sum of samples

	reti ; ---------------------------------- ISR completed [max 66 clock ticks]

; ****************************************************************
; * interrupt init for waveform generation and channel updating
; ****************************************************************

play:
	rcall init_music_data

	ldi tmp4, 1								; load 260 (metronome tick sub-division duration)
	ldi tmp3, 4								;
	out OCR1AH, tmp4						;
	out OCR1AL, tmp3						;

	ldi tmp3, 0b00001100					; set prescaller to 1/256 and enable CTC (clear on compare match)
	out TCCR1B, tmp3						; (timer/counter1)

	ldi tmp3, 0b00000010					; set prescaller to 1/8
	out TCCR0, tmp3							; (timer/counter0)

	clr tmp3								; reset timer/counters
	out TCNT1H, tmp3						;
	out TCNT1L, tmp3						;
	out TCNT0, tmp3							;

	ldi tmp3, 0b01000010					; enable overflow interrupt for timer0 and compare match for timer1
	out TIMSK, tmp3							;

	sei										; enable all interrupts

play_loop: ; --------------------------------
	sbrc mode,1								; check mode and proceed accordingly
	rjmp play_loop							;
	ret

; ****************************************************************
; * clear all data concerning music
; ****************************************************************

init_music_data:
	ser tmp3								;
	mov mode, tmp3							; set playing music

	clr tmp3								; clear phase deltas
	sts ch1_phase_delta_l, tmp3				;
	sts ch1_phase_delta_h, tmp3				;
	sts ch1_effect_data, tmp3				;
	sts ch2_phase_delta_l, tmp3				;
	sts ch2_phase_delta_h, tmp3				;
	sts ch2_effect_data, tmp3				;
	sts ch3_phase_delta_l, tmp3				;
	sts ch3_phase_delta_h, tmp3				;
	sts ch3_effect_data, tmp3				;
	sts ch4_phase_delta_l, tmp3				;
	sts ch4_phase_delta_h, tmp3				;
	sts ch4_effect_data, tmp3				;

	ldi tmp3, 15							; set initial volume
	sts ch1_volume, tmp3					;
	sts ch2_volume, tmp3					;

	clr ch1_sample							; clear samples
	clr ch2_sample							;
	clr ch3_sample							;
	clr ch4_sample							;
	clr ch1_phase_accum_h					; clear pahse accumulators
	clr ch1_phase_accum_l					;
	clr ch2_phase_accum_h					;
	clr ch2_phase_accum_l					;
	clr ch3_phase_accum_h					;
	clr ch3_phase_accum_l					;
	clr ch4_phase_accum_h					;
	clr ch4_phase_accum_l					;

	ldi tmp4, high(ch1_melody*2)			; initialize note pointers
	ldi tmp3, low(ch1_melody*2)				;
	mov ch1_note_ptr_h, tmp4				;
	mov ch1_note_ptr_l, tmp3				;
	ldi tmp4, high(ch2_melody*2)			;
	ldi tmp3, low(ch2_melody*2)				;
	mov ch2_note_ptr_h, tmp4				;
	mov ch2_note_ptr_l, tmp3				;
	ldi tmp4, high(ch3_melody*2)			;
	ldi tmp3, low(ch3_melody*2)				;
	mov ch3_note_ptr_h, tmp4				;
	mov ch3_note_ptr_l, tmp3				;
	ldi tmp4, high(ch4_melody*2)			;
	ldi tmp3, low(ch4_melody*2)				;
	mov ch4_note_ptr_h, tmp4				;
	mov ch4_note_ptr_l, tmp3				;

	ldi ch1_duration, 1						; set minimum duration for each note of each channel
	ldi ch2_duration, 1						;
	ldi ch3_duration, 1						;
	ldi ch4_duration, 1						;

	ret