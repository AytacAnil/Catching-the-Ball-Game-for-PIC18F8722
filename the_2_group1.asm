LIST    P=18F8722

#INCLUDE <p18f8722.inc>

CONFIG OSC=HSPLL, FCMEN=OFF, IESO=OFF,PWRT=OFF,BOREN=OFF, WDT=OFF, MCLRE=ON, LPT1OSC=OFF, LVP=OFF, XINST=OFF, DEBUG=OFF

;   variables
level        udata 0X20
level
hp           udata 0X21
hp

ORG     0000h
goto init
ORG     0008h
goto high_isr
ORG     0018h
goto low_isr



init:
    clrf    TRISA
    clrf    TRISB
    clrf    TRISC
    clrf    TRISD
    clrf    TRISG
    clrf    TRISH
    clrf    TRISJ

    clrf    WREG;

    movlw   b'01000000'

    movwf   PORTA
    movwf   PORTB

    movlw   b''

    goto main

main:




