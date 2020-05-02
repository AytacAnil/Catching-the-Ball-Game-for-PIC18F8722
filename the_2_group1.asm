 LIST    P=18F8722

#INCLUDE <p18f8722.inc> 

    CONFIG OSC=HSPLL, FCMEN=OFF, IESO=OFF,PWRT=OFF,BOREN=OFF, WDT=OFF, MCLRE=ON, LPT1OSC=OFF, LVP=OFF, XINST=OFF, DEBUG=OFF

;variables
 UDATA_ACS
level             res 1	;   variable for 7seg Level display
hp                res 1	;   variable for 7seg HP display
pad_loc           res 1	;   variable for checking where the pad is
		        ;   abcd|0000 -> 1100|0000 means that pad is on the
                        ;   RA and RB, 0011|0000 means that pad is
                        ;   on RC and RD
display_flag	  res 1 ;   flag for selecting which digit to display; 0=level, 1=hp
counter           res 1
w_temp            res 1
status_temp       res 1
pclath_temp       res 1
       
saved_timer1_low  res 1 ;   for new ball generation
saved_timer1_high res 1 ;   for new ball generation
new_ball_location res 1 ;   for new ball generation
t_dts		  res 1 ;   for new ball generation, trivial
		  
timer0_intrpt_no  res 1 ;   for checking if all balls gone, vould be named differently @metin
is_ended	  res 1 ;   set (=0x01) means the game has been ended and goto init state
 
 ORG     0000h
 goto	init
 ORG     0008h
 goto	high_isr
 ORG     0018h
 goto	low_isr

; LOW ISR FOR SHOWING 7 SEGMENT DISPLAY |---------------------------------------
low_isr:
    ;	1 -> b,c:	0110|0000
    ;	2 -> a,b,d,e,g: 1101|1010
    ;	3 -> a,b,c,d,g: 1111|0010
    ;	4 -> b,c,f,g:   0110|0110
    ;	5 -> a,c,d,f,g: 1011|0110    
    call    save_registers
    
    bcf	    PIR1,1	    ;   clear timer 2 intrpt flag
    btfss   display_flag,0  ;	if(flag == 0)
    goto    level_display   ;	then go to level_display
    goto    hp_display	    ;	else go to hp_display
    
    level_display:
	movff   level,LATJ  ;   show level
	bcf	PORTH,3	    ;   close display 3
	bsf	PORTH,0	    ;   open display 0
	bsf	display_flag,0
	goto	finish_isr

    hp_display:
	movff   hp,LATJ  ;   show hp
	bcf	PORTH,0	    ;   close display 0
	bsf	PORTH,3	    ;   open display 3
	bcf	display_flag,0
	goto	finish_isr
    
    finish_isr:
	call restore_registers
	retfie
;-------------------------------------------------------------------------------
	
init:
    clrf    TRISA
    clrf    TRISB
    clrf    TRISC
    clrf    TRISD
    clrf    TRISG
    clrf    TRISH
    clrf    TRISJ
    clrf    INTCON
    clrf    PIR1
    clrf    WREG;
    
    movlw   b'00001111'
    movwf   ADCON1	    ;	makes PORTA Digital

    movlw   b'11000000'     ;   initialize <5:0>
    movwf   TRISA           ;   of ports a->d
    movwf   TRISB           ;   to be output
    movwf   TRISC           ;   <7:6> set for input
    movwf   TRISD           ;   but we will not use them

    movlw   b'00001101'     ;   set RG0, RG2 and RG3 as inputs
    movwf   TRISG

    movlw   b'01100000'     ;   level = 1, sets b and c of 7seg
    movwf   level           ;

    movlw   b'10110110'     ;   hp = 5, sets a,f,g,c,d of 7seg
    movwf   hp              ;

    movlw   b'11000000'     ;   pad is on RA5 and RB5
    movwf   pad_loc
    
    movlw   0x00	    ;	
    movwf   is_ended	    ;	clear is_ended flag
    movwf   display_flag    ;	clear display_flag

    bsf     LATA,5          ;   set RA5 and RB5
    bsf     LATB,5          ;   for pad initialization

    bsf	    RCON,7	    ;	IPEN = 1, makes GIE->GIEH, PEIE->GIEL
    bsf	    INTCON,7	    ;	enables Global High Priority Interrupts
    bsf	    INTCON,6	    ;	enables Global Low Priority Interrupts
    bsf	    PIE1,1	    ;	enables timer2 interrupts, intrpt flag is on PIR1,1
    bsf	    T2CON,2
    bcf	    IPR1,1	    ;	set Timer2 as Low Priority
    
    call    init_timer1     ;	initialize Timer1

    goto    main

start_after_release:
    btfsc   PORTG,0         ;   go to start_game when RG0 released
    goto    start_after_release
    goto    start_game

start_game:
    ;   call create_random_ball
    goto game_loop

game_loop:
    btfsc   is_ended,0	    ;	if game ended flag is set, goto init part and start again
    goto    init
    btfsc   PORTG,2         ;   if set, go to RG2 pressed state
    goto    rg2_pressed
    btfsc   PORTG,3         ;   if set, go to RG3 pressed state
    goto    rg3_pressed
    goto    game_loop       ;   if RG2 = RG3 = 0, check again

rg2_pressed:
    btfsc   is_ended,0	    ;	if game ended flag is set, goto init part and start again
    goto    init
    btfsc   PORTG,2         ;   if RG2 is held pressed, loop here
    goto    rg2_pressed
    btfss   pad_loc,7       ;   checks if the left part of pad is on RA5
    goto    check_pad_loc_BC_right
    bcf     PORTA,5
    bsf     PORTC,5
    bcf     LATA,5          ;   clear RA5
    bsf     LATC,5          ;   set RC5
    rrncf   pad_loc,1       ;   shift pad_loc varble to right, now: 0110|0000
    goto    game_loop       ;   pad shifted, go to game loop

check_pad_loc_BC_right:
    btfsc   is_ended,0	    ;	if game ended flag is set, goto init part and start again
    goto    init
    btfss   pad_loc,6       ;   checks if the left part of pad is on RB5
    goto    game_loop       ;   goto game_loop because pad is on the right edge
    bcf     PORTB,5
    bsf     PORTD,5
    bcf     LATB,5          ;   clear RA5
    bsf     LATD,5          ;   set RC5
    rrncf   pad_loc,1       ;   shift pad_loc varble to right, now: 0011|0000
    goto    game_loop       ;   pad shifted, go to game_loop

rg3_pressed:
    btfsc   is_ended,0	    ;	if game ended flag is set, goto init part and start again
    goto    init
    btfsc   PORTG,3         ;   if RG3 is held pressed, loop here
    goto    rg3_pressed
    btfss   pad_loc,4       ;   checks if the right part of pad is on RD5
    goto    check_pad_loc_BC_left
    bsf     PORTB,5         ;   set RB5
    bsf     LATB,5
    bcf     PORTD,5         ;   clear RD5
    bcf     LATD,5
    rlncf   pad_loc,1       ;   shift pad_loc varble to left, now: 0110|0000
    goto    game_loop       ;   pad shifted, go to game_loop

check_pad_loc_BC_left:
    btfsc   is_ended,0	    ;	if game ended flag is set, goto init part and start again
    goto    init
    btfss   pad_loc,5       ;   checks if the right part of pad is on RC5
    goto    game_loop       ;   goto game_loop because pad is on the left edge
    bsf     PORTA,5         ;   set RC5
    bsf     LATA,5
    bcf     PORTC,5         ;   clear RA5
    bcf     LATC,5
    rlncf   pad_loc,1       ;   shift pad_loc varble to left, now: 1100|0000
    goto    game_loop       ;   pad shifted, go to game_loop

high_isr:
    ;	... metin's code
    call    end_game_check
    goto    high_isr

;;;;;;;;;;;; Register handling for proper operation of main program ;;;;;;;;;;;;
save_registers:
    movwf 	w_temp          ;Copy W to TEMP register
    swapf 	STATUS, w       ;Swap status to be saved into W
    clrf 	STATUS          ;bank 0, regardless of current bank, Clears IRP,RP1,RP0
    movwf 	status_temp     ;Save status to bank zero STATUS_TEMP register
    movf 	PCLATH, w       ;Only required if using pages 1, 2 and/or 3
    movwf 	pclath_temp     ;Save PCLATH into W
    clrf 	PCLATH          ;Page zero, regardless of current page
	return

restore_registers:
    movf 	pclath_temp, w  ;Restore PCLATH
    movwf 	PCLATH          ;Move W into PCLATH
    swapf 	status_temp, w  ;Swap STATUS_TEMP register into W
    movwf 	STATUS          ;Move W into STATUS register
    swapf 	w_temp, f       ;Swap W_TEMP
    swapf 	w_temp, w       ;Swap W_TEMP into W
    return
    
;;;;;;;;;;;;      Random ball generation algorithm starts here      ;;;;;;;;;;;;    
init_timer1
    ;Initialize timer1 
    MOVLW b'11001001'   ;Set 16 bit mode, enable timer1
    MOVWF T1CON		;Set conf
    BCF PIE1, TMR1IE	;Disable timer1 interrupt
    RETURN
    
save_timer1_value       
    ;call when RG0 is pressed to save the timer1 value
    MOVLW b'01100010';test
    MOVWF TMR1L;test
    MOVLW b'10010101';test
    MOVWF TMR1H;test
    MOVFF TMR1H, saved_timer1_high ;swap when test over
    MOVFF TMR1L, saved_timer1_low
    
    MOVLW b'00000000'   ;Disable timer1
    MOVWF T1CON
    RETURN

compute_ball_location
    ;puts the new ball location to the new_ball_location variable
    MOVF saved_timer1_low, W    
    BCF  WREG, 0                
    BCF  WREG, 1                   
    SUBWF saved_timer1_low, W   ;2 rightmost bit are now in the wreg
    MOVWF new_ball_location 
    RETURN
	

timer1_right_shift	
    ;does a single shift on the saved timer1 values
    MOVF  saved_timer1_high, W ;save to WREG
    BTFSC saved_timer1_low , 0 ;if bit 0 is set
    BSF   saved_timer1_high, 0 ;set bit 8
    BTFSS saved_timer1_low , 0 ;if bit 0 is clear
    BCF   saved_timer1_high, 0 ;clear bit 8
    BTFSC WREG             , 0 ;if bit 8 is set
    BSF   saved_timer1_low , 0 ;set bit 0	
    BTFSS WREG             , 0 ;if bit 8 is clear
    BCF   saved_timer1_low , 0 ;clear bit 0
    RRNCF saved_timer1_low     ;rotate low
    RRNCF saved_timer1_high    ;rotate high
    RETURN
    
do_timer1_shifts
    ;does shifts according to the current level
    MOVLW d'1'      ;if   level 1
    CPFSGT level    
    GOTO level_no_1 
    MOVLW d'2'	    ;elif level 2
    CPFSGT level
    GOTO level_no_2
    GOTO level_no_3 ;else level 3
    
    level_no_1:     ;shift count 1
	MOVLW d'1'
	MOVWF t_dts
	GOTO loop_dts
    level_no_2:     ;shift count 3
	MOVLW d'3'
	MOVWF t_dts
	GOTO loop_dts
    level_no_3:     ;shift count 5
	MOVLW d'5'
	MOVWF t_dts
	GOTO loop_dts
	
    loop_dts:       ;do the shifts
	CALL timer1_right_shift
	DECFSZ t_dts, F
	GOTO loop_dts
    RETURN
    
generate_ball_location
    ;call this to compute the ball location
    CALL compute_ball_location
    CALL do_timer1_shifts
    RETURN  
;;;;;;;;;;;;       Random ball generation algorithm ends here       ;;;;;;;;;;;;

    
;   END GAME CHECK
end_game_check
    cpfslt	d'35'
    goto	set_end_game_flag
    cpfseq	b'00000000'	    ;   if level variable is shows level 0
    goto	set_end_game_flag
    return
    
    set_end_game_flag:
	movlw	0x01	    ;   set flag to end game
	movwf	is_ended    ;
    return
;

;   HP DECREMENT FUNCTION
decrement_hp
    movwf	hp,0	    ;	get hp value in 7 segment format
    cpfseq	b'00000000' ;	if( hp != 0 ) goto hp_1 check
    goto	hp_1
    movlw	0x01	    ;	set is_ended flag to end game
    movwf	is_ended    ;
    return
    
    hp_1:
	cpfseq	b'01100000' ;	if( hp != 1 ) goto hp_2 check
	goto	hp_2
	movlw	b'00000000' ;	change hp to 0 in 7 segment format
	movwf	hp
	movlw	0x01	    ;	set is_ended flag to end game
	movwf	is_ended    ;
	return
	
    hp_2:
	cpfseq	b'11011010' ;	if( hp != 2 ) goto hp_3 check
	goto	hp_3
	movlw	b'01100000' ;	change hp to 1 in 7 segment format
	movwf	hp
	return
    
    hp_3:
	cpfseq	b'11110010' ;	if( hp != 3 ) goto hp_4 check
	goto	hp_4
	movlw	b'11011010' ;	change hp to 2 in 7 segment format
	movwf	hp
	return
    
    hp_4:
	cpfseq	b'01100110' ;	if( hp != 4 ) goto hp_5 check
	goto	hp_5
	movlw	b'11110010' ;	change hp to 3 in 7 segment format
	movwf	hp
	return
    
    hp_5:
	cpfseq	b'10110110' ;	if( hp != 5 ) return
	goto	hp_gt_5
	movlw	b'01100110' ;	change hp to 4 in 7 segment format
	movwf	hp
	return
	
    hp_gt_5:
	return
;
    
main:
    btfss   PORTG,0         ;   go to start_after_release when RG0 pressed
    goto    main
    goto    start_after_release
 end
