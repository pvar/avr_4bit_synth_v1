; ****************************************************************
; * timer/counter1 compare match ISR
; ****************************************************************

updates: ; 169 clock ticks available
	lds tmp3, ch1_phase_delta_h				; get high byte of phase delta for channel1
	cpi tmp3, 0xff							; check if equal to 0xff
	brne keep_playing						; if not, keep playing music
	clr mode								; else, set stop mode (reached end of melody) and exit ISR
	rjmp updates_end						;

keep_playing: ; 160 clock ticks available (40 per channel)

; ==========================================================================
; ==========================================================================
ch1_checks:
	dec ch1_duration						; if duration has ended...
	breq ch1_update							; get next note

	cpi ch1_duration, 1						; if duration is about to end...
	breq ch1_prep							; prepare for next note

	cpi ch1_duration, 5						; if duration is about to end...
	brlo ch1_fade_out						; decrease volume AND apply effects

	rjmp ch1_fade_in						; if duration is NOT about to end...
											; increase volume AND apply effects
ch1_prep: ; ---------------------------------
	clr tmp4								;
	ldi tmp3, 2								;
	add ch1_note_ptr_l, tmp3				; increase note pointer for this channel
	adc ch1_note_ptr_h, tmp4				;
	rjmp ch2_checks							;
ch1_fade_out:  ; ----------------------------
	lds tmp3, ch1_volume					;
	subi tmp3, 2							; decrease volume by two
	sts ch1_volume, tmp3					;
	rjmp ch1_effects						; apply effects
ch1_fade_in:  ; -----------------------------
	ldi tmp3, 15							; reset volume
	sts ch1_volume, tmp3					;
	rjmp ch1_effects						; apply effects
ch1_update: ; -------------------------------
	mov ZH, ch1_note_ptr_h					; get effect and duration for new note
	mov ZL, ch1_note_ptr_l					;
	lpm										;
	sts ch1_effect_data, r0					; store effect in aproppiate location

	ldi tmp3, 0b00011111					;
	and r0, tmp3							; keep only duration
	mov ch1_duration, r0					;

											; multiply duration by 5 for 180bpm
											; multiply duration by 6 for 150bpm
											; multiply duration by 7 for 120bpm
											; multiply duration by 10 for 90bpm
	lsl ch1_duration						; x 2
	add ch1_duration, r0					; + 1
	lsl ch1_duration						; x 2
;	add ch1_duration, r0					; + 1

	adiw ZH:ZL, 1							; get note/octave pointer
	lpm										;

	ldi ZH, high(deltas*2)					; get phase delta for specified note/octave
	ldi ZL, low(deltas*2)					;
	clr tmp4								;
	add ZL, r0								;
	adc ZH, tmp4							;
	lpm										;
	sts ch1_phase_delta_h, r0				;
	adiw ZH:ZL, 1							;
	lpm										;
	sts ch1_phase_delta_l, r0				;
	rjmp ch2_checks							;
ch1_effects: ; -----------------------------
	lds tmp3, ch1_effect_data				; load effect data and check value
	sbrc tmp3, 7							;
 	rjmp ch1_vibrato						; if = 1xxxxxxx, vibrato
	sbrs tmp3, 6							;
	rjmp ch2_checks							; if = 00xxxxxx, no effect
	sbrs tmp3, 5							;
	rjmp ch1_pbdown							; if = 010xxxxx, pitch bend down
	rjmp ch1_pbup							; if = 011xxxxx, pitch bend up

ch1_vibrato: ; ----------------------------- vibrato
	lds ZL, ch1_phase_delta_l				;
	lds ZH, ch1_phase_delta_h				;
	sbrs ch1_duration, 2					;
	rjmp ch1_vib_sub						;
ch1_vib_add: ; -----------------------------
	adiw ZH:ZL, 16							;
	sts ch1_phase_delta_l, ZL				;
	sts ch1_phase_delta_h, ZH				;
	rjmp ch2_checks							;
ch1_vib_sub: ; -----------------------------
	sbiw ZH:ZL, 16							;
	sts ch1_phase_delta_l, ZL				;
	sts ch1_phase_delta_h, ZH				;
	rjmp ch2_checks							;
ch1_pbdown: ; ------------------------------ pitch bend down
	lds ZL, ch1_phase_delta_l				;
	lds ZH, ch1_phase_delta_h				;
	sbiw ZH:ZL, 1							;
	sts ch1_phase_delta_l, ZL				;
	sts ch1_phase_delta_h, ZH				;
	rjmp ch2_checks							;
ch1_pbup: ; -------------------------------- pitch bend down
	lds ZL, ch1_phase_delta_l				;
	lds ZH, ch1_phase_delta_h				;
	adiw ZH:ZL, 1							;
	sts ch1_phase_delta_l, ZL				;
	sts ch1_phase_delta_h, ZH				;

; ==========================================================================
; ==========================================================================
ch2_checks:
	dec ch2_duration						; if duration has ended...
	breq ch2_update							; get next note

	cpi ch2_duration, 1						; if duration is about to end...
	breq ch2_prep							; prepare for next note

	cpi ch2_duration, 5						; if duration is about to end...
	brlo ch2_fade_out						; decrease volume AND apply effects
	rjmp ch2_fade_in						; if duration is NOT about to end...
											; increase volume AND apply effects
ch2_prep: ; ---------------------------------
	clr tmp4								;
	ldi tmp3, 2								;
	add ch2_note_ptr_l, tmp3				; increase note pointer for this channel
	adc ch2_note_ptr_h, tmp4				;
	rjmp ch3_checks							;
ch2_fade_out:  ; ----------------------------
	lds tmp3, ch2_volume					;
	subi tmp3, 2							; decrease volume by two
	sts ch2_volume, tmp3					;
	rjmp ch2_effects						; apply effects
ch2_fade_in:  ; -----------------------------
	ldi tmp3, 15							; reset volume
	sts ch2_volume, tmp3					;
	rjmp ch2_effects						; apply effects
ch2_update: ; -------------------------------
	mov ZH, ch2_note_ptr_h					; get effect and duration for new note
	mov ZL, ch2_note_ptr_l					;
	lpm										;
	sts ch2_effect_data, r0					; store effect in aproppiate location

	ldi tmp3, 0b00011111					;
	and r0, tmp3							; keep only duration
	mov ch2_duration, r0					;

											; multiply duration by 5 for 180bpm
											; multiply duration by 6 for 150bpm
											; multiply duration by 7 for 120bpm
											; multiply duration by 10 for 90bpm
	lsl ch2_duration						; x 2
	add ch2_duration, r0					; + 1
	lsl ch2_duration						; x 2
;	add ch2_duration, r0					; + 1

	adiw ZH:ZL, 1							; get note/octave pointer
	lpm										;

	ldi ZH, high(deltas*2)					; get phase delta for specified note/octave
	ldi ZL, low(deltas*2)					;
	clr tmp4								;
	add ZL, r0								;
	adc ZH, tmp4							;
	lpm										;
	sts ch2_phase_delta_h, r0				;
	adiw ZH:ZL, 1							;
	lpm										;
	sts ch2_phase_delta_l, r0				;
	rjmp ch3_checks							;
ch2_effects: ; -----------------------------
	lds tmp3, ch2_effect_data				; load effect data and check value
	sbrc tmp3, 7							;
 	rjmp ch2_vibrato						; if = 1xxxxxxx, vibrato
	sbrs tmp3, 6							;
	rjmp ch3_checks							; if = 00xxxxxx, no effect
	sbrs tmp3, 5							;
	rjmp ch2_pbdown							; if = 010xxxxx, pitch bend down
	rjmp ch2_pbup							; if = 011xxxxx, pitch bend up

ch2_vibrato: ; ----------------------------- vibrato
	lds ZL, ch2_phase_delta_l				;
	lds ZH, ch2_phase_delta_h				;
	sbrs ch2_duration, 2					;
	rjmp ch2_vib_sub						;
ch2_vib_add: ; -----------------------------
	adiw ZH:ZL, 16							;
	sts ch2_phase_delta_l, ZL				;
	sts ch2_phase_delta_h, ZH				;
	rjmp ch3_checks							;
ch2_vib_sub: ; -----------------------------
	sbiw ZH:ZL, 16							;
	sts ch2_phase_delta_l, ZL				;
	sts ch2_phase_delta_h, ZH				;
	rjmp ch3_checks							;
ch2_pbdown: ; ------------------------------ pitch bend down
	lds ZL, ch2_phase_delta_l				;
	lds ZH, ch2_phase_delta_h				;
	sbiw ZH:ZL, 1							;
	sts ch2_phase_delta_l, ZL				;
	sts ch2_phase_delta_h, ZH				;
	rjmp ch3_checks							;
ch2_pbup: ; -------------------------------- pitch bend down
	lds ZL, ch2_phase_delta_l				;
	lds ZH, ch2_phase_delta_h				;
	adiw ZH:ZL, 1							;
	sts ch2_phase_delta_l, ZL				;
	sts ch2_phase_delta_h, ZH				;

; ==========================================================================
; ==========================================================================
ch3_checks:
	dec ch3_duration						; if duration has ended...
	breq ch3_update							; get next note

	cpi ch3_duration, 1						; if duration is about to end...
	breq ch3_prep							; prepare for next note
	rjmp ch3_effects						; else apply effects
ch3_prep: ; ---------------------------------
	clr tmp4								;
	ldi tmp3, 2								;
	add ch3_note_ptr_l, tmp3				; increase note pointer for this channel
	adc ch3_note_ptr_h, tmp4				;
	rjmp ch4_checks							;
ch3_update: ; -------------------------------
	mov ZH, ch3_note_ptr_h					; get effect and duration for new note
	mov ZL, ch3_note_ptr_l					;
	lpm										;
	sts ch3_effect_data, r0					; store effect in aproppiate location

	ldi tmp3, 0b00011111					;
	and r0, tmp3							; keep only duration
	mov ch3_duration, r0					;

											; multiply duration by 5 for 180bpm
											; multiply duration by 6 for 150bpm
											; multiply duration by 7 for 120bpm
											; multiply duration by 10 for 90bpm
	lsl ch3_duration						; x 2
	add ch3_duration, r0					; + 1
	lsl ch3_duration						; x 2
;	add ch3_duration, r0					; + 1

	adiw ZH:ZL, 1							; get note/octave pointer
	lpm										;

	ldi ZH, high(deltas*2)					; get phase delta for specified note/octave
	ldi ZL, low(deltas*2)					;
	clr tmp4								;
	add ZL, r0								;
	adc ZH, tmp4							;
	lpm										;
	sts ch3_phase_delta_h, r0				;
	adiw ZH:ZL, 1							;
	lpm										;
	sts ch3_phase_delta_l, r0				;
	rjmp ch4_checks							;
ch3_effects: ; -----------------------------
	lds tmp3, ch3_effect_data				; load effect data and check value
	sbrc tmp3, 7							;
 	rjmp ch3_vibrato						; if = 1xxxxxxx, vibrato
	sbrs tmp3, 6							;
	rjmp ch4_checks							; if = 00xxxxxx, no effect
	sbrs tmp3, 5							;
	rjmp ch3_pbdown							; if = 010xxxxx, pitch bend down
	rjmp ch3_pbup							; if = 011xxxxx, pitch bend up

ch3_vibrato: ; ----------------------------- vibrato
	lds ZL, ch3_phase_delta_l				;
	lds ZH, ch3_phase_delta_h				;
	sbrs ch3_duration, 2					;
	rjmp ch3_vib_sub						;
ch3_vib_add: ; -----------------------------
	adiw ZH:ZL, 16							;
	sts ch3_phase_delta_l, ZL				;
	sts ch3_phase_delta_h, ZH				;
	rjmp ch4_checks							;
ch3_vib_sub: ; -----------------------------
	sbiw ZH:ZL, 16							;
	sts ch3_phase_delta_l, ZL				;
	sts ch3_phase_delta_h, ZH				;
	rjmp ch4_checks							;
ch3_pbdown: ; ------------------------------ pitch bend down
	lds ZL, ch3_phase_delta_l				;
	lds ZH, ch3_phase_delta_h				;
	sbiw ZH:ZL, 1							;
	sts ch3_phase_delta_l, ZL				;
	sts ch3_phase_delta_h, ZH				;
	rjmp ch4_checks							;
ch3_pbup: ; -------------------------------- pitch bend down
	lds ZL, ch3_phase_delta_l				;
	lds ZH, ch3_phase_delta_h				;
	adiw ZH:ZL, 1							;
	sts ch3_phase_delta_l, ZL				;
	sts ch3_phase_delta_h, ZH				;

; ==========================================================================
; ==========================================================================
ch4_checks:
	dec ch4_duration						; if duration has ended...
	breq ch4_update							; get next note

	cpi ch4_duration, 1						; if duration is about to end...
	breq ch4_prep							; prepare for next note
	rjmp ch4_effects						; else apply effects
ch4_prep: ; ---------------------------------
	clr tmp4								;
	ldi tmp3, 2								;
	add ch4_note_ptr_l, tmp3				; increase note pointer for this channel
	adc ch4_note_ptr_h, tmp4				;
	rjmp updates_end						;
ch4_update: ; -------------------------------
	mov ZH, ch4_note_ptr_h					; get effect and duration for new note
	mov ZL, ch4_note_ptr_l					;
	lpm										;
	sts ch4_effect_data, r0					; store effect in aproppiate location

	ldi tmp3, 0b00011111					;
	and r0, tmp3							; keep only duration
	mov ch4_duration, r0					;

											; multiply duration by 5 for 180bpm
											; multiply duration by 6 for 150bpm
											; multiply duration by 7 for 120bpm
											; multiply duration by 10 for 90bpm
	lsl ch4_duration						; x 2
	add ch4_duration, r0					; + 1
	lsl ch4_duration						; x 2
;	add ch4_duration, r0					; + 1

	adiw ZH:ZL, 1							; get note/octave pointer
	lpm										;

	ldi ZH, high(deltas*2)					; get phase delta for specified note/octave
	ldi ZL, low(deltas*2)					;
	clr tmp4								;
	add ZL, r0								;
	adc ZH, tmp4							;
	lpm										;
	sts ch4_phase_delta_h, r0				;
	adiw ZH:ZL, 1							;
	lpm										;
	sts ch4_phase_delta_l, r0				;
	rjmp updates_end						;
ch4_effects: ; -----------------------------
	lds tmp3, ch4_effect_data				; load effect data and check value
	sbrc tmp3, 7							;
 	rjmp ch4_vibrato						; if = 1xxxxxxx, vibrato
	sbrs tmp3, 6							;
	rjmp updates_end						; if = 00xxxxxx, no effect
	sbrs tmp3, 5							;
	rjmp ch4_pbdown							; if = 010xxxxx, pitch bend down
	rjmp ch4_pbup							; if = 011xxxxx, pitch bend up

ch4_vibrato: ; ----------------------------- vibrato
	lds ZL, ch4_phase_delta_l				;
	lds ZH, ch4_phase_delta_h				;
	sbrs ch4_duration, 3					;
	rjmp ch4_vib_sub						;
ch4_vib_add: ; -----------------------------
	adiw ZH:ZL, 60							;
	sts ch4_phase_delta_l, ZL				;
	sts ch4_phase_delta_h, ZH				;
	rjmp updates_end						;
ch4_vib_sub: ; -----------------------------
	sbiw ZH:ZL, 60							;
	sts ch4_phase_delta_l, ZL				;
	sts ch4_phase_delta_h, ZH				;
	rjmp updates_end						;
ch4_pbdown: ; ------------------------------ pitch bend down
	lds ZL, ch4_phase_delta_l				;
	lds ZH, ch4_phase_delta_h				;
	sbiw ZH:ZL, 8							;
	sts ch4_phase_delta_l, ZL				;
	sts ch4_phase_delta_h, ZH				;
	rjmp updates_end						;
ch4_pbup: ; -------------------------------- pitch bend down
	lds ZL, ch4_phase_delta_l				;
	lds ZH, ch4_phase_delta_h				;
	adiw ZH:ZL, 8							;
	sts ch4_phase_delta_l, ZL				;
	sts ch4_phase_delta_h, ZH				;

; ==========================================================================
; ==========================================================================
updates_end:
	reti