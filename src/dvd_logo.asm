.INCLUDE "include/header.inc" ONCE

; memory address $0000 to $00ff are reserved for main function
; additional variables should use memory address $0100 and onwards
.ENUM $0100
X0 .DW ; Q8.8 for both position and velocity
X0_L DB
X0_H DB
Y0 .DW
Y0_L DB
Y0_H DB
VX0 .DW
VX0_L DB
VX0_H DB
VY0 .DW
VY0_L DB
VY0_H DB
COUNT0 DB ; 0 -> 24 -> 12 -> loop, used for updating palette
X1 .DW
X1_L DB
X1_H DB
Y1 .DW
Y1_L DB
Y1_H DB
VX1 .DW
VX1_L DB
VX1_H DB
VY1 .DW
VY1_L DB
VY1_H DB
COUNT1 DB
FLAG DB ; track sprites hitting walls
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
    ldx #0
    stx X0
    stx Y0
    stx X1
    stx Y1
    stz COUNT0
    stz COUNT1
    ldx #$0180 ; vx = vy = 1.5
    stx VX0
    stx VY0
    stx VX1
    stx VY1

    ; load palette
    stz $2121
    stz $2122 ; background is black
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
    
    ; load background
    ldy #$2000 ; VRAM starting address
    sty $2116
    ldx #bg1_data   ; Address
    lda #:bg1_data  ; of tiles
    ldy #(bg1_data@end - bg1_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    ldx #empty_tile   ; Address
    lda #:empty_tile  ; of tiles
    ldy #(32*24*2)      ; length of data
    stx $4312           ; write
    sta $4314           ; address
    sty $4315           ; and length
    lda #%00001001 ; fixed address, transfer words
    sta $4310
    lda #$18            ; $211[89]: VRAM data write
    sta $4311           ; set destination
    lda #%00000011      ; start DMA, channel 0 and 1
    sta $420b

    ; background initialization
    lda #%00010000  ; 16x16 tiles, mode 0
    sta $2105       ; screen mode register
    lda #$20  ; data starts from $2000
    sta $2107       ; for BG1
    ; set background scroll
    stz $210d
    stz $210d
    lda #(-$40)
    sta $210e
    lda #-1
    sta $210e

    ; load graphics
    ldy #$0000          ; Write to VRAM from $0000
    sty $2116
    ldx #graphics_data   ; Address
    lda #:graphics_data  ; of tiles
    ldy #(graphics_data@end - graphics_data)      ; length of data
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
    lda #%00110000 ; priority = 3
    sta $2104
    ; sprite 1
    stz $2104 ; x = 0
    stz $2104 ; y = 0
    stz $2104 ; tile idx = 0
    lda #%00110010 ; priority 3, palette 1
    sta $2104

    ldx #$0100
    stx $2102
    lda #%00001000 ; size = 0 for sprite 0, 1 for sprite 1
    sta $2104

    ; enable object layer and bg1
    lda #$11
    sta $212c

    rtl

; run during vblank
; INPUT_PRESSED and INPUT_DOWN can be used to read controller data
; return -1 if a reload is required (used in menu), 0 otherwise, other return values are undefined
update:
    ; update variables
    stz FLAG
    rep #$20 ; 16bit a
    lda X0
    clc
    adc VX0
    sta X0
    lda Y0
    clc
    adc VY0
    sta Y0
    lda X1
    clc
    adc VX1
    sta X1
    lda Y1
    clc
    adc VY1
    sta Y1
    sep #$20 ; 8bit a
    
    ; detect bounce
    ; sprite 0 horizontal
    lda X0_H
    bpl +
    cmp #-16
    blt +

    ; collided with wall
    ; set flag
    lda #%00000001
    tsb FLAG
    ; flip velocity
    rep #$20 ; 16bit a
    lda VX0
    eor #-1
    ina
    sta VX0
    sep #$20 ; 8bit a
    ; cycle palette
    jsr cycle_palette_0

    ; update position
    lda VX0_H
    bpl ++
    ; right wall
    ldx #((256-16)<<8)
    stx X0
    bra +
++  ; left wall
    stz X0_L
    stz X0_H

+   ; sprite 0 vertical
    lda Y0_H
    bpl +
    cmp #-16-(256-224)
    blt +
    ; collided with wall
    ; set flag
    lda #%00000010
    tsb FLAG
    ; flip velocity
    rep #$20 ; 16bit a
    lda VY0
    eor #-1
    ina
    sta VY0
    sep #$20 ; 8bit a
    ; cycle palette
    jsr cycle_palette_0

    ; update position
    lda VY0_H
    bpl ++
    ; bottom wall
    ldx #((224-16)<<8)
    stx Y0
    bra +
++  ; top wall
    stz Y0_L
    stz Y0_H

+   ; sprite 1 horizontal
    lda X1_H
    bpl +
    cmp #-32
    blt +

    ; collided with wall
    ; set flag
    lda #%00000100
    tsb FLAG
    ; flip velocity
    rep #$20 ; 16bit a
    lda VX1
    eor #-1
    ina
    sta VX1
    sep #$20 ; 8bit a
    ; cycle palette
    jsr cycle_palette_1

    ; update position
    lda VX1_H
    bpl ++
    ; right wall
    ldx #((256-32)<<8)
    stx X1
    bra +
++  ; left wall
    stz X1_L
    stz X1_H

+   ; sprite 1 vertical
    lda Y1_H
    bpl +
    cmp #-32-(256-224)
    blt +
    ; collided with wall
    ; set flag
    lda #%00001000
    tsb FLAG
    ; flip velocity
    rep #$20 ; 16bit a
    lda VY1
    eor #-1
    ina
    sta VY1
    sep #$20 ; 8bit a
    ; cycle palette
    jsr cycle_palette_1

    ; update position
    lda VY1_H
    bpl ++
    ; bottom wall
    ldx #((224-32)<<8)
    stx Y1
    bra +
++  ; top wall
    stz Y1_L
    stz Y1_H

    ; flash red on corner hit
+   stz $2121 ; overwrite background color
    lda FLAG
    eor #-1
    bit #%00000011
    beq hit
    bit #%00001100
    beq hit
miss:
    stz $2122 ; black (#$0000)
    stz $2122
    bra +
hit:
    lda #$1f ; red (#$001f)
    sta $2122
    stz $2122

+   ; update sprite position
    ldx #$0000
    stx $2102
    lda X0_H
    sta $2104
    lda Y0_H
    sta $2104

    ldx #$0002
    stx $2102
    lda X1_H
    sta $2104
    lda Y1_H
    sta $2104

    lda #0
    rtl

cycle_palette_0:
    lda #0
    xba
    lda COUNT0
    sec
    sbc #12
    bpl ++
    lda #24
++  sta COUNT0
    tax
    ldy #6
    lda #$81
    sta $2121
-   lda color_data.l, x
    sta $2122
    inx
    lda color_data.l, x
    sta $2122
    inx
    dey
    bne -
    rts

cycle_palette_1:
    lda #0
    xba
    lda COUNT1
    sec
    sbc #12
    bpl ++
    lda #24
++  sta COUNT1
    tax
    ldy #6
    lda #$91
    sta $2121
-   lda color_data.l, x
    sta $2122
    inx
    lda color_data.l, x
    sta $2122
    inx
    dey
    bne -
    rts

.ENDS

; graphics data
.bank 1 slot 0       ; We'll use bank 1
.org 0
.section "gfxdata" NAMESPACE "dvd_logo"

empty_tile:
    .DB $2c, $00

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

; clever trick / war crime: 4bpp (sprite) and 2bpp (background tile) in the same file
graphics_data:
LOAD_FILE "gfx/dvd_logo/graphics.bin"
@end:

bg1_data:
LOAD_FILE "gfx/dvd_logo/bg1.bin"
@end:

.ENDS
