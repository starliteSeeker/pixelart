.INCLUDE "include/header.inc" ONCE

; memory address $0000 to $00ff are reserved for main function
; additional variables should use memory address $0100 and onwards
.ENUM $0100
 X0 DB
 Y0 DB
 COUNT0 DB
 X1 DB
 Y1 DB
 COUNT1 DB
.ENDE

.BANK 0 SLOT 0
.ORG 0
.SECTION "dvd_logo" NAMESPACE "dvd_logo"
.ACCU 8
.INDEX 16

; run once at start of animation
; palette/tileset/tilemap data and register/variable initialization
init:
    ; initialize variables
    stz X0
    stz Y0
    stz COUNT0
    stz X1
    stz Y1
    stz COUNT1

    ; load palette
    lda #$00 ; background is black
    sta $2121
    stz $2122
    stz $2122
    ; fill in 4bpp palette 0 and 1 for 2 sprites
    lda #$81
    sta $2121
    ldx #0
-   lda color_data.l, x
    sta $2122
    inx
    cpx #12
    bne -
    lda #$ff ; white for color 7 (center)
    sta $2122
    lda #$7f
    sta $2122
    stz $2122 ; black for color 8
    stz $2122
    lda #$91
    sta $2121
    ldx #0
-   lda color_data.l, x
    sta $2122
    inx
    cpx #12
    bne -
    lda #$ff ; white for color 7 (center)
    sta $2122
    lda #$7f
    sta $2122
    stz $2122
    stz $2122
    
    ; load sprite
    ldy #$0000          ; Write to VRAM from $0000
    sty $2116
    ldx #sprite_data   ; Address
    lda #:sprite_data  ; of tiles
    ldy #(sprite_data@end - sprite_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    ; sprite starting position?
    lda #%01100000 ; sprite stored at $0000, sizes are 16x16 and 32x32
    sta $2101

    ; set sprites
    ldx #$0000 ; OAM address $000
    stx $2102
    ; sprite 0
    stz $2104 ; x = 0
    stz $2104 ; y = 0
    lda #4 ; tile idx = 4
    sta $2104
    stz $2104
    ; sprite 1
    stz $2104 ; x = 0
    stz $2104 ; y = 0
    stz $2104 ; tile idx = 0
    stz $2104

    ldx #$0100
    stx $2102
    lda #%00001000 ; size = 0 for sprite 0, 1 for sprite 1
    sta $2104

    ; enable object layer
    lda #$10
    sta $212c

    rtl

; run during vblank
; INPUT_PRESSED and INPUT_DOWN can be used to read controller data
; return -1 if a reload is required (used in menu), 0 otherwise, other return values are undefined
update:
    lda #0
    rtl

.ENDS

; graphics data
.bank 1 slot 0       ; We'll use bank 1
.org 0
.section "gfxdata" NAMESPACE "dvd_logo"

.DEFINE R $001f
.DEFINE G $03e0
.DEFINE B $7c00
.DEFINE C $7fe0
.DEFINE Y $03ff
.DEFINE M $7c1f
color_data:
    .DW R, G, Y, B, M, C
    .DW G, B, C, R, Y, M
    .DW B, R, M, G, C, Y

sprite_data:
LOAD_FILE "gfx/dvd_logo/sprite.bin"
@end:

.ENDS
