.INCLUDE "include/header.inc" ONCE

; memory address $0000 to $00ff are reserved for main function
; additional variables should use memory address $0100 and onwards

.BANK 0 SLOT 0
.ORG 0
.SECTION "orbits" NAMESPACE "orbits"
.ACCU 8
.INDEX 16

.DEFINE EARTH_ORBIT 80
.DEFINE MOON_ORBIT 30

.ENUM $0100
    EARTH_T DW ; angle in Q14.2, 0 degree = #$0000 = #$0200
    MOON_T DW
.ENDE

; run once at start of animation
; palette/tileset/tilemap data and register/variable initialization
init:
    ; initialize variables
    ldx #0
    stx EARTH_T
    stx MOON_T

    ; load palette
    lda #$00 ; start from palette 0
    sta $2121
    ldx #palette_data
    lda #:palette_data
    ldy #(palette_data@end - palette_data)
    stx $4302
    sta $4304
    sty $4305
    lda #%00000010 ; 1 addr write once
    sta $4300
    lda #$22 ; register $2122 (CGDATA)
    sta $4301
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    ; load sprites
    ldy #$0000          ; Write to VRAM from $0000
    sty $2116
    ldx #sprites_data   ; Address
    lda #:sprites_data  ; of tiles
    ldy #(sprites_data@end - sprites_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    lda #%01100000 ; sprite stored at $0000, sizes are 16x16 and 32x32
    sta $2101
    ; sun
    ldx #$0000
    stx $2102
    lda #(256/2-32/2)
    sta $2104
    lda #(224/2-32/2)
    sta $2104
    lda #2 ; tile idx
    sta $2104
    stz $2104
    ; earth
    lda #(256/2+EARTH_ORBIT-16/2)
    sta $2104
    lda #(224/2-16/2)
    sta $2104
    lda #6
    sta $2104
    lda #%00000010 ; palette 1
    sta $2104
    ; moon
    lda #(256/2+EARTH_ORBIT+MOON_ORBIT-8/2)
    sta $2104
    lda #(224/2-8/2)
    sta $2104
    lda #8
    sta $2104
    lda #%00000100 ; palette 2
    sta $2104

    ldx #$0100
    stx $2102
    lda #%00000010 ; 32*32 for sprite 0, 16*16 for others
    sta $2104

    lda #%00010000 ; enable object layer
    sta $212c

    rtl

; run during vblank
; INPUT_PRESSED and INPUT_DOWN can be used to read controller data
; return -1 if a reload is required (used in menu), 0 otherwise, other return values are undefined
update:
    rep #$20 ; 16bit a
    ; update angle
    dec EARTH_T
    dec MOON_T
    dec MOON_T
    dec MOON_T

    ; sin(EARTH_T) at $02
    lda EARTH_T
    lsr
    and #$fffe
    sta $00
    and #$01fe
    tax
    lda sine_table.l, x
    sta $02
    lda #$0200
    bit $00
    beq +
    ; negate value
    lda #-1
    eor $02
    sta $02

    ; cos(EARTH_T) at $04
+   lda #($80 * 2) ; offset by 90 degrees ($80) to get cosine
    clc
    adc $00
    sta $00
    and #$01ff
    tax
    lda sine_table.l, x
    sta $04
    lda #$0200
    bit $00
    beq +
    ; negate value
    lda #-1
    eor $04
    sta $04 

    ; sin(MOON_T) at $06
+   lda MOON_T
    lsr
    and #$fffe
    sta $00
    and #$01fe
    tax
    lda sine_table.l, x
    sta $06
    lda #$0200
    bit $00
    beq +
    ; negate value
    lda #-1
    eor $06
    sta $06

    ; cos(MOON_T) at $08
+   lda #($80 * 2) ; offset by 90 degrees ($80) to get cosine
    clc
    adc $00
    sta $00
    and #$01ff
    tax
    lda sine_table.l, x
    sta $08
    lda #$0200
    bit $00
    beq +
    ; negate value
    lda #-1
    eor $08
    sta $08

+   sep #$20 ; 8bit a

    ; calculate earth position
    lda #EARTH_ORBIT
    sta $211c
    lda $04
    sta $211b
    lda $05
    sta $211b
    lda $2134
    sta $04
    lda $2135
    clc
    adc #(256/2-16/2)
    sta $05 ; x position of earth
    lda $02
    sta $211b
    lda $03
    sta $211b
    lda $2134
    sta $02
    lda $2135
    clc
    adc #(224/2-16/2)
    sta $03 ; y position of earth

    ldx #$0002
    stx $2102
    lda $05
    sta $2104
    lda $03
    sta $2104

    ; calculate moon position
    lda #MOON_ORBIT
    sta $211c
    lda $08
    sta $211b
    lda $09
    sta $211b
    lda $2134
    clc
    adc $04
    lda $2135
    adc $05
    clc
    adc #(16/2-8/2)
    sta $08 ; x position of moon
    lda $06
    sta $211b
    lda $07
    sta $211b
    lda $2134
    clc
    adc $02
    lda $2135
    adc $03
    clc
    adc #(16/2-8/2)
    sta $06 ; y position of moon

    ldx #$0004
    stx $2102
    lda $08
    sta $2104
    lda $06
    sta $2104

    lda #0
    rtl

.ENDS

; graphics data
.bank 2 slot 0
.org 0
.section "gfxdata" NAMESPACE "orbits"

palette_data:
LOAD_FILE "gfx/orbits/palette.bin"
@end:

sprites_data:
LOAD_FILE "gfx/orbits/sprites.bin"
@end:

; half sine table
sine_table:
.DEFINE COUNTER 0
.WHILE COUNTER < $100
.DW round(sin(COUNTER / $100 * 3.141593) * 256)
.REDEFINE COUNTER COUNTER+1
.ENDR

.ENDS
