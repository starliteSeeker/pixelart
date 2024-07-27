.INCLUDE "include/header.inc" ONCE

.BANK 0 SLOT 0
.ORG 0
.SECTION "menu" NAMESPACE "menu"
.ACCU 8
.INDEX 16

.DEFINE REDRAW_FLAG $0100 ; redraw menu at start and after page scroll

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

    ; load tileset
    ldy #$0000          ; Write to VRAM from $0000
    sty $2116
    ldx #text_data   ; Address
    lda #:text_data  ; of tiles
    ldy #(text_data@end - text_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    ; load bg1 (select arrow)
    ldy #$1000 ; VRAM starting address
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
    ; load bg2 (menu text)
    ; load bg3 (menu background)
    ldy #$3000 ; VRAM starting address
    sty $2116
    ldx #bg3_data   ; Address
    lda #:bg3_data  ; of tiles
    ldy #(bg3_data@end - bg3_data)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00000001      ; set this mode (transferring words)
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b

    stz $2105 ; 8x8 tiles
    lda #$10  ; data starts from $1000
    sta $2107       ; for BG1
    lda #$20  ; data starts from $2000
    sta $2108       ; for BG2
    lda #$30  ; data starts from $3000
    sta $2109       ; for BG3
    stz $210b ; tileset starts at $0000

    lda #%00000101 ; enable BG1 and 3
    sta $212c

    ; initialize variable
    lda #1
    sta REDRAW_FLAG

    rts

; run during vblank
update:
    lda REDRAW_FLAG
    beq update_end
    ; draw menu entries
    ldx #$2000
    stx $2116
    ldy #$0001
    sty $2118
    stz REDRAW_FLAG
    rts

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "menu_data"

palette_data:
.fopen "gfx/menu/palette.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

text_data:
.fopen "gfx/ascii.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

bg1_data:
.fopen "gfx/menu/bg1.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

bg3_data:
.fopen "gfx/menu/bg3.bin" fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
@end:

.ENDS
