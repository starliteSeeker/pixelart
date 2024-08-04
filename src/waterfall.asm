.INCLUDE "include/header.inc" ONCE

.DEFINE BG1_XOFF $0100 ; 2 bytes, Q15.1
.DEFINE BG2_XOFF $0102 ; 2 bytes, Q15.1
.DEFINE BG2_YOFF $0104 ; 2 bytes

.BANK 0 SLOT 0
.ORG 0
.SECTION "waterfall" NAMESPACE "waterfall"
.ACCU 8
.INDEX 16

; run at first load
init:
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

    ; load tiles
    ldy #$0000          ; Write to VRAM from $0000
    sty $2116
    ldx #tile_data   ; Address
    lda #:tile_data  ; of tiles
    ldy #(tile_data@end - tile_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    ; load tilemap
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
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    ldy #$3000 ; VRAM starting address
    sty $2116
    ldx #bg2_data   ; Address
    lda #:bg2_data  ; of tiles
    ldy #(bg2_data@end - bg2_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    ;set up the screen
    lda #%00110000  ; 16x16 tiles, mode 0
    sta $2105       ; screen mode register
    lda #$20  ; data starts from $2000
    sta $2107       ; for BG1
    lda #$30  ; data starts from $3000
    sta $2108       ; for BG2
    stz $210b ; tileset starts at $0000

    lda #%00000011 ; enable BG1, BG2
    sta $212c

    ; initialize variables
    rep #$20        ; 16bit a
    ; reset 16-bit variables
    stz BG1_XOFF
    stz BG2_XOFF
    stz BG2_YOFF
    sep #$20        ; 8bit a
    rtl

; run during vblank
update:
    rep #$20        ; 16bit a
    lda BG1_XOFF 
    ina
    sta BG1_XOFF
    lsr
    sep #$20        ; 8bit a
    sta $210d
    xba
    and #%00000111
    sta $210d

    rep #$20        ; 16bit a
    lda BG2_XOFF 
    ina
    sta BG2_XOFF
    lsr
    sep #$20        ; 8bit a
    sta $210f
    xba
    and #%00000111
    sta $210f

    rep #$20        ; 16bit a
    lda BG2_YOFF 
    dea
    sta BG2_YOFF
    sep #$20        ; 8bit a
    sta $2110
    xba
    and #%00000111
    sta $2110

    lda #0
    rtl

.ENDS

; graphics data
.bank 1 slot 0       ; We'll use bank 1
.org 0
.section "gfxdata" NAMESPACE "waterfall"

palette_data:
.fopen "gfx/waterfall/palette.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

tile_data:
.fopen "gfx/waterfall/tileset.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

bg1_data:
.fopen "gfx/waterfall/bg1.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

bg2_data:
.fopen "gfx/waterfall/bg2.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

.ENDS
