
# Catching the Ball Game

**The program is using PIC assembly language and written for PIC18F8722
working at 40 MHz.**

The purpose of the game is that moving the bar horizontally with buttons to
catch balls onto the bar. The game consists of 3 levels. The player starts 
with 5 health points (HP). For every missed ball the player loses one HP. 
The current game level and HP of the player are displayed on 7-segment display
screen. Once, the player misses 5 balls (or no HP left), or survives against
all the created balls game will be over. 


* The first digit (D3) of the 7-segment display shows the game level.
* The last digit (D0) of the 7-segment display shows the remaining HP of the player.
* The game starts as soon as RG0 button is released.
* The bar is represented with two consecutive LEDs and placed on RA5-RB5. 
* The bar will move horizontally between RA5 and RF5.
* PORTA, PORTB, PORTC, PORTD, PORTE and PORTF are used to show the bar and the balls.
* PORTH and PORTJ are used as output ports to show numbers on 7-Segment displays.
* PORTG is used to move the bar.
* The game will be played in the area of the LEDs trough RA0-RA5, RB0-RB5, RC0-RC5, RD0-RD5.



### Levels
1. For Level-I:
 * A new ball is created in every 500 ms.
 * The balls are moved to the next location in every 500 (+/−100) ms.
 * 5 balls will be created at this level.
2. For Level-II:
 * A new ball is created in every 400 ms.
 * The balls are moved to the next location in every 400 (+/−100) ms.
 * 10 balls will be created at this level.
3. For Level-III:
 * A new ball is created in every 350 ms.
 * The balls are moved to the next location in every 350 (+/−100) ms.
 * 15 balls will be created at this level.
