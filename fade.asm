; ****************************************************************
; * fading of main LED for initial program state
; ****************************************************************

dimming_cycle:
	; --- get new dimming level -------------
	lds tmp3, dimming_ptr					; get dimming level pointer
	clr r0									;
	ldi ZH, high(dim_levels*2)				; set up Z pointer to the beginning of a wave table
	ldi ZL, low(dim_levels*2)				;
	add ZL, tmp3							; add offset to Z pointer
	adc ZH, r0								;
	lpm										; load new dimming level in r0
	; --- "high" part of PWM cycle ----------
	sbi PORTD, 4							; turn LED on
	rcall delay								; delay
	; --- "low" part of PWM cycle -----------
	cbi PORTD, 4							; turn LED off
	com r0									;
	rcall delay								; complementary delay
	; --- repetition coutner ----------------
	inc tmp4								; increase counter	
	brne dimming_cycle						; if counter cleared (after overflowing) stop looping
	; --- change dimming level --------------
	inc tmp3								; increase dimming level pointer
	cpi tmp3, 32							; check if pointer reached limit
	brne fading_end							; if not, proceed to end of subroutine
	clr tmp3								; if yes, clear pointer and proceed to end of subroutine

fading_end:
	sts dimming_ptr, tmp3					; save updated dimming_ptr ;-)
	ret

; ****************************************************************
; * delay subroutine
; ****************************************************************

delay:		; ---- [(r0 - 1) * 4 + 4] clock ticks
	nop
	dec r0
	brne delay
	ret
