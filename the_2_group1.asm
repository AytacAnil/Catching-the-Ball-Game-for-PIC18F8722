 LIST    P=18F8722

#INCLUDE <p18f8722.inc>

    CONFIG OSC=HSPLL, FCMEN=OFF, IESO=OFF,PWRT=OFF,BOREN=OFF, WDT=OFF, MCLRE=ON, LPT1OSC=OFF, LVP=OFF, XINST=OFF, DEBUG=OFF

;   variables
    UDATA_ACS
level res 1	;   variable for 7seg Level display
hp res 1	;   variable for 7seg HP display
pad_loc res 1	;   variable for checking where the pad is
		;   abcd|0000 -> 1100|0000 means that pad is on the
                ;   RA and RB, 0011|0000 means that pad is
                ;   on RC and RD
wait_counter res 1

counter   udata 0x22
counter

w_temp  udata 0x23
w_temp

status_temp udata 0x24
status_temp

pclath_temp udata 0x25
pclath_temp

    ORG     0000h
    goto init
    ORG     0008h
    goto error_loop;high_isr
    ORG     0018h
    goto low_isr

low_isr:
    ;	1 -> b,c:	0110|0000
    ;	2 -> a,b,d,e,g: 1101|1010
    ;	3 -> a,b,c,d,g: 1111|0010
    ;	4 -> b,c,f,g:   0110|0110
    ;	5 -> a,c,d,f,g: 1011|0110

    call    save_registers

    bcf	    PIR1,1	;   clear timer 2 intrpt flag

    movff   level,LATJ	;   show level
    bcf	    PORTH,3	;   close display 3
    bsf	    PORTH,0	;   open display 0

    goto wait_a_bit

wait_a_bit:

    decfsz  wait_counter
    goto    wait_a_bit

    movlw   0x0F
    movwf   wait_counter

    movff   hp,LATJ	;   show hp
    bcf	    PORTH,0	;   close display 0
    bsf	    PORTH,3	;   open display 3

    call restore_registers
    retfie

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

    movlw   b'00001000'
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

    movlw   0x0F
    movwf   wait_counter  ;	variable for waiting in

    bsf     PORTA,5         ;   set RA5 and RB5
    bsf     PORTB,5         ;   for pad initialization
    bsf     LATA,5          ;   < gerek var m? bilmiyorum
    bsf     LATB,5          ;   < THE 1'de LAT kullanm?s?sm ledler için

    bsf	    RCON,7	    ;	IPEN = 1, makes GIE->GIEH, PEIE->GIEL
    bsf	    INTCON,7	    ;	enables Global High Priority Interrupts
    bsf	    INTCON,6	    ;	enables Global Low Priority Interrupts
    bsf	    PIE1,1	    ;	enables timer2 interrupts, intrpt flag is on PIR1,1
    bsf	    T2CON,2
    bcf	    IPR1,1	    ;	set Timer2 as Low Priority

    goto    main

main:
    ;   call show 7 segment display
    btfss   PORTG,0         ;   go to start_after_release when RG0 pressed
    goto    main
    goto    start_after_release

start_after_release:
    ;   call show 7 segment display
    btfsc   PORTG,0         ;   go to start_game when RG0 released
    goto    start_after_release
    goto    start_game

start_game:
    ;   call create_random_ball
    goto game_loop

game_loop:
    ;   show 7 segment display
    btfsc   PORTG,2         ;   if set, go to RG2 pressed state
    goto    rg2_pressed
    btfsc   PORTG,3         ;   if set, go to RG3 pressed state
    goto    rg3_pressed
    goto    game_loop       ;   if RG2 = RG3 = 0, check again

rg2_pressed:
    ;   show 7 segment display
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
    ;   show 7 segment display
    btfss   pad_loc,6       ;   checks if the left part of pad is on RB5
    goto    game_loop       ;   goto game_loop because pad is on the right edge
    bcf     PORTB,5
    bsf     PORTD,5
    bcf     LATB,5          ;   clear RA5
    bsf     LATD,5          ;   set RC5
    rrncf   pad_loc,1       ;   shift pad_loc varble to right, now: 0011|0000
    goto    game_loop       ;   pad shifted, go to game_loop

rg3_pressed:
    ;   show 7 segment display
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
    ;   show 7 segment display
    btfss   pad_loc,5       ;   checks if the right part of pad is on RC5
    goto    game_loop       ;   goto game_loop because pad is on the left edge
    bsf     PORTA,5         ;   set RC5
    bsf     LATA,5
    bcf     PORTC,5         ;   clear RA5
    bcf     LATC,5
    rlncf   pad_loc,1       ;   shift pad_loc varble to left, now: 1100|0000
    goto    game_loop       ;   pad shifted, go to game_loop

error_loop:
    goto error_loop

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

    end
