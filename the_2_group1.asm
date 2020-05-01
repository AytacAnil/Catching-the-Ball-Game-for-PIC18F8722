 LIST    P=18F8722

#INCLUDE <p18f8722.inc>

 ;CONFIG OSC=HSPLL, FCMEN=OFF, IESO=OFF,PWRT=OFF,BOREN=OFF, WDT=OFF, MCLRE=ON, LPT1OSC=OFF, LVP=OFF, XINST=OFF, DEBUG=OFF

;   variables
level        udata 0X20     ;   variable for 7seg Level display
level
hp           udata 0X21     ;   variable for 7seg HP display
hp
pad_loc      udata 0x22     ;   variable for checking where the pad is
pad_loc                     ;   abcd|0000 -> 1100|0000 means that pad is on the
                            ;   RA and RB, 0011|0000 means that pad is
                            ;   on RC and RD 
 
    ORG     0000h
    goto init
    ORG     0008h
    ;goto high_isr
    ORG     0018h
    ;goto low_isr

init:
    clrf    TRISA
    clrf    TRISB
    clrf    TRISC
    clrf    TRISD
    clrf    TRISG
    clrf    TRISH
    clrf    TRISJ

    clrf    WREG;

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

    ;bsf     PORTA,5         ;   set RA5 and RB5
    ;bsf     PORTB,5         ;   for pad initialization
    bsf     LATA,5          ;   < gerek var m? bilmiyorum
    bsf     LATB,5          ;   < THE 1'de LAT kullanmısısm ledler için



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
    btfsc   PORTG,2         ;   if RG3 is held pressed, loop here
    goto    rg2_pressed
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

 
    end
