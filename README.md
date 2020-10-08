# Vectron Handheld

Coming Soon!

Vectron Handheld is a retro handheld gaming console based on the [6502 CPU](https://en.wikipedia.org/wiki/MOS_Technology_6502).  It has five input buttons (up, down, left, right, fire) and a 1.8" 128x160 18-bit color TFT LCD display.  

I have developed an [implementation of Pong](https://github.com/nickbild/vectron_handheld/blob/master/game.asm) to demonstrate Vectron Handheld's capabilities.

## How It Works

The KiCad design files are [available here](https://github.com/nickbild/vectron_handheld/tree/master/vectron_handheld_pcb).

The W65C02 is clocked at 8MHz.  The console has 32KB of RAM and 32KB of ROM is available to store the game.  A few 7400-series logic chips are used for address decoding and button debouncing.  All components are through-hole, and aside from the modern display, the components are contemporaries of the original 6502 processor.

A W65C22 VIA is used to extend the number of interrupts available to the CPU for capturing button presses.  The VIA is also used to bit bang the SPI TFT LCD display interface.  My implementation of [Pong](https://github.com/nickbild/vectron_handheld/blob/master/game.asm) demonstrates how to use the buttons and the display in a game.

A 273 mm x 221 mm 4-layer PCB was designed in KiCad.  There is definitely opportunity to reduce the size of the board with a tighter layout if a smaller device is desired (this was my first crack at designing a PCB).

The Vectron Handheld runs at 5V and draws ~150 mA of current.

## Media

YouTube:

Vectron Handheld:

The breadboard prototype from which the PCB was designed:
![prototype](https://raw.githubusercontent.com/nickbild/vectron_handheld/master/media/finished_prototype.jpg)

Playing Pong:

Unpopulated PCB:

## Bill of Materials

- 1	x W65C02
- 1	x W65C22
- 1	x 8MHz Crystal
- 1	x SN74HC32N
- 1	x SN74HC08N
- 1	x SN74LS04N
- 2	x 74LS682
- 1	x SN74HC14N
- 1	x AS6C62256A-70PCN
- 1	x AT28C256-15PU
- 6 x pushbutton
- 9	x 10K resistor
- 8	x 3.3K resistor
- 1	x 1.8" 128x160 18-bit color TFT LCD display
- 1	x 220uF capacitor
- 5	x 1,000 pF capacitor

## Also See

Check out some of my other 6502-based projects:

- [Vectron 64 breadboard computer](https://github.com/nickbild/vectron_64)  
- [6502 virtual reality headset](https://github.com/nickbild/vectron_vr)  
- [Play Atari 2600 games with gestures](https://github.com/nickbild/vectron_ai)

## About the Author

[Nick A. Bild, MS](https://nickbild79.firebaseapp.com/#!/)
