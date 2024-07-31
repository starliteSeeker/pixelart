.INCLUDE "include/header.inc" ONCE

.BANK 0 SLOT 0
.ORG 0
.SECTION "menu" NAMESPACE "menu"
.ACCU 8
.INDEX 16

; CUR_SEL current selection defined in main
.DEFINE CURSOR_IDX $0100 

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
    rep #$20 ; 16bit a
    lda #$2000 ; VRAM starting address
    sta $2116
    ldx #0
    lda menu_entry_count.l
    and #$00ff
    cmp #16 ; cap to 16 entries
    bcc + ; branch if less than
    lda #16
+   asl ; *32 (each menu entry has 32 characters)
    asl
    asl
    asl
    asl
    tay
-   lda menu_entry.l, x
    and #$00ff
    sta $2118
    inx
    dey
    bne -
    ; fill with empty tiles
    lda menu_entry_count.l
    and #$00ff
    sec
    sbc #16
    bcc +
    lda #0
+   sec
    sbc #16
    asl
    asl
    asl
    asl
    asl
    tay
-   stz $2118
    iny
    bmi -
    sep #$20 ; 8bit a
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

    lda #%00000111 ; enable BG1, 2 and 3
    sta $212c

    ; move backgrounds to correct position
    ; bg1
    stz $210d
    stz $210d
    stz $210e
    stz $210e
    ; bg2
    lda #(5<<3)
    eor #-1
    ina
    sta $210f
    lda #$ff
    sta $210f
    lda #(8<<3)
    eor #-1
    ina
    sta $2110
    lda #$ff
    sta $2110
    ; bg3
    stz $2111
    stz $2111
    stz $2112
    stz $2112

    ; initialize variable
    stz CURSOR_IDX

    rts

; run during vblank
update:
    ; up button
    lda INPUT_PRESSED+1
    bit #%00001000
    beq +
    ; up button pressed
    lda CURSOR_IDX
    beq + ; can't scroll up
    dec CURSOR_IDX
    ; update menu entry text
    ; erase bottom entry
    ; add top entry
    ; change y offset
    ; TODO
    jmp update_arrow

    ; down button
+   bit #%00000100
    beq +
    ; down button pressed
    lda CURSOR_IDX
    ina
    cmp.l menu_entry_count
    bcs + ; branch if greater than or equal to, can't scroll down
    inc CURSOR_IDX
    ; move selection arrow
update_arrow:
    lda CURSOR_IDX
    cmp #$08
    bcc scroll_top
    sec
    sbc.l menu_entry_count
    clc
    adc #$08
    bcs scroll_bot
scroll_mid:
    ; y offset = -(7 * 8)
    lda #(7<<3)
    eor #-1
    ina
    sta $210e
    lda #-1
    sta $210e
    jmp +
scroll_top: ; idx = 0~7
    ; y offset = -(cursor_idx * 8)
    rep #$20 ; 16bit a
    lda CURSOR_IDX
    and #$00ff
    asl
    asl
    asl
    eor #-1
    ina
    sep #$20
    sta $210e
    xba
    sta $210e
    jmp +
scroll_bot: ; idx = count-8~count-1
    ; y offset = -((16 - menu_entry_count + cursor_idx) * 8)
    lda #16
    sec
    sbc menu_entry_count.l
    clc
    adc CURSOR_IDX
    rep #$20 ; 16bit a
    and #$00ff
    asl
    asl
    asl
    eor #-1
    ina
    sep #$20
    sta $210e
    xba
    sta $210e

+   lda #0
    rts

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "menu_data"

; max count 127? because jump table code
menu_entry_count:
    .DB (menu_entry@end - menu_entry) / 32

menu_entry:
    ;   "each.entry.is.32.bytes.........."
    .DB "ZERO                            "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONE                             "
    .DB "ONEX                            "
@end

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
