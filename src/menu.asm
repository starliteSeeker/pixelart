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
    ; initialize with zeros
    ldy #$1000 ; VRAM starting address
    sty $2116
    ldx #zero_data   ; Address
    lda #:zero_data  ; of tiles
    ldy #(32*32*2)      ; length of data
    stx $4302           ; write
    sta $4304           ; address
    sty $4305           ; and length
    lda #%00001001 ; fixed address, transfer words
    sta $4300
    lda #$18            ; $211[89]: VRAM data write
    sta $4301           ; set destination
    lda #%00000001      ; start DMA, channel 0
    sta $420b
    ; put arrow
    ldy #$1103
    sty $2116
    lda #$01
    sta $2118

    ; load bg2 (menu text)
    ; dma0 (low byte of text data), dma1 (high byte of text data, all zeros),
    ; and dma2 (zero fill rest) 
    ldx #menu_entry
    stx $4302
    lda #:menu_entry
    sta $4304
    lda #$18
    sta $4301
    lda #%00000000 ; one address write once
    sta $4300
    ldx #zero_data
    stx $4312
    lda #:zero_data
    sta $4314
    lda #$19
    sta $4311
    lda #%00001000 ; fixed address, transfer bytes
    sta $4310
    ldx #zero_data
    stx $4322
    lda #:zero_data
    sta $4324
    lda #$18
    sta $4321
    lda #%00001001 ; fixed address, transfer words
    sta $4320

    rep #$20 ; 16bit a
    ; length of text data = 32 * min(entry_count, 16)
    lda menu_entry_count.l
    and #$00ff
    cmp #16 ; cap to 16 entries
    blt +
    lda #16
+   asl ; *32 (each menu entry has 32 characters)
    asl
    asl
    asl
    asl
    sta $4305
    sta $4315
    ; length of zero block = 2 * (32 * 32 - length of text data)
    eor #-1
    ina
    clc
    adc #(32*32)
    asl ; *2 because we're writing 2 bytes at once
    sta $4325
    sep #$20 ; 8bit a

    ldx #$2000 ; VRAM starting address
    stx $2116
    stz $2115 ; increment vram address after write to $2118
    lda #%00000001 ; enable dma 0
    sta $420b
    lda #$80
    sta $2115 ; reset register value to before
    ldx #$2000 ; VRAM starting address
    stx $2116
    lda #%00000110 ; enable dma 1 and 2
    sta $420b

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
    stz $210c

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

    rtl

; run during vblank
update:
    ; check button -> update CURSOR_IDX -> update text and selection cursor
    ; cursor can be at top (0~6), middle (not top or bottom) or bottom (menu_count-8~menu_count-1)
    ; update menu text when cursor is in the middle section

    ; A/B button
    lda INPUT_PRESSED
    ora INPUT_PRESSED+1
    bit #%10000000
    beq +
    ; entry selected, set CUR_SEL to CURSOR_IDX
    lda CURSOR_IDX
    sta CUR_SEL
    lda #-1
    rtl

    ; up button
+   lda INPUT_PRESSED+1
    bit #%00001000
    beq +
    ; up button pressed
    lda CURSOR_IDX
    beq + ; can't scroll up
    dec CURSOR_IDX
    jmp update_arrow

    ; down button
+   bit #%00000100
    bne +
ret lda #0
    rtl
+   ; down button pressed
    lda CURSOR_IDX
    ina
    cmp.l menu_entry_count
    bge ret ; can't scroll down
    inc CURSOR_IDX
    ; move selection arrow
update_arrow:
    lda CURSOR_IDX
    cmp #$07
    blt scroll_top
    sec
    sbc.l menu_entry_count
    clc
    adc #$08
    bge scroll_bot
    bra scroll_mid

scroll_top: ; idx = 0~6
    ; y offset of menu text
    lda #-(8<<3)
    sta $2110
    stz $2110
    ; y offset of cursor = -(cursor_idx * 8)
    rep #$20 ; 16bit a
    lda CURSOR_IDX
    and #$00ff
    bra ++
scroll_bot: ; idx = count-8~count-1
    ; y offset of menu text
    .ACCU 8
    lda menu_entry_count.l
    sec
    sbc #16
    bge +++
    lda #0
+++ sec
    sbc #8
    asl
    asl
    asl
    sta $2110
    stz $2110
    ; y offset of cursor = -((min(0, 16 - menu_entry_count) + cursor_idx) * 8)
    lda #16
    sec
    sbc menu_entry_count.l
    blt +
    lda #0
+   clc
    adc CURSOR_IDX
    rep #$20 ; 16bit a
    and #$00ff
++  asl
    asl
    asl
    eor #-1
    ina
    sep #$20 ; 8bit a
    sta $210e
    xba
    sta $210e
    lda #0
    rtl

scroll_mid:
    ; update menu entry text
    lda INPUT_PRESSED+1
    bit #%00001000
    beq ++
    ; up pressed
    lda CURSOR_IDX
    sec
    sbc menu_entry_count.l
    cmp #-9
    beq + ; no need to update text
    ; erase bottom entry (idx + 9)
    lda CURSOR_IDX
    clc
    adc #9
    rep #$20 ; 16bit a
    and #$001f ; mod 32
    asl ; *32 tiles per row
    asl
    asl
    asl
    asl
    clc
    adc #$2000
    sta $2116
    ldx #32
-   stz $2118
    dex
    bne -
    ; add top entry (idx - 7)
    lda CURSOR_IDX
    sec
    sbc #7
    and #$001f
    asl
    asl
    asl
    asl
    asl
    tax
    adc #$2000
    sta $2116
    ldy #32
-   lda menu_entry.l, x
    and #$00ff
    sta $2118
    inx
    dey
    bne -
    sep #$20 ; 8bit a
+   bra +

++  ; down pressed
    lda CURSOR_IDX
    cmp #7
    beq + ; no need to update text
    ; erase top entry (idx - 8)
    sec
    sbc #8
    rep #$20 ; 16bit a
    and #$001f ; mod 32
    asl ; *32 tiles per row
    asl
    asl
    asl
    asl
    clc
    adc #$2000
    sta $2116
    ldx #32
-   stz $2118
    dex
    bne -
    ; add bottom entry (idx + 8)
    lda CURSOR_IDX
    clc
    adc #8
    and #$001f
    asl
    asl
    asl
    asl
    asl
    tax
    adc #$2000
    sta $2116
    ldy #32
-   lda menu_entry.l, x
    and #$00ff
    sta $2118
    inx
    dey
    bne -
    sep #$20 ; 8bit a
    
+   ; y offset of menu text
    lda CURSOR_IDX
    sec
    sbc #15 ; -7 because (idx - 7) then -8 because default offset
    and #$1f ; mod 32
    asl
    asl
    asl
    sta $2110
    stz $2110
    ; y offset of cursor = -(7 * 8)
    lda #(7<<3)
    eor #-1
    ina
    sta $210e
    lda #-1
    sta $210e
    lda #0
    rtl

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "menu_data" NAMESPACE "menu"

zero_data:
    .DB 0, 0

; max allowed count less than 255, not that there's plan to use up all of them
menu_entry:
    ;   "each.entry.is.32.bytes.........."
    .DB "./                              "
    .DB "Hello World                     "
    .DB "Waterfall                       "
    .DB "Desert sunset                   "
    .DB "DVD logo                        "
@end

.DEFINE COUNT (menu_entry@end - menu_entry) / 32
menu_entry_count:
    .DB COUNT

init_jump_table:
    .DW menu.init
    .DW hello_world.init
    .DW waterfall.init
    .DW desert_sunset.init
    .DW dvd_logo.init
@end
init_jump_table_bank:
    .DB :menu.init
    .DB :hello_world.init
    .DB :waterfall.init
    .DB :desert_sunset.init
    .DB :dvd_logo.init
@end

update_jump_table:
    .DW menu.update
    .DW hello_world.update
    .DW waterfall.update
    .DW desert_sunset.update
    .DW dvd_logo.update
@end
update_jump_table_bank:
    .DB :menu.update
    .DB :hello_world.update
    .DB :waterfall.update
    .DB :desert_sunset.update
    .DB :dvd_logo.update
@end

; sanity check: do jump tables have the same number of entries as menu names
.IF COUNT != ((init_jump_table@end - init_jump_table) / 2) || COUNT != (init_jump_table_bank@end - init_jump_table_bank) || COUNT != ((update_jump_table@end - update_jump_table) / 2) || COUNT != (update_jump_table_bank@end - update_jump_table_bank)
    .FAIL "Entry count doesn't match up."
.ENDIF

palette_data:
LOAD_FILE "gfx/menu/palette.bin"
@end:

text_data:
LOAD_FILE "gfx/ascii.bin" 
@end:

bg3_data:
LOAD_FILE "gfx/menu/bg3.bin" 
@end:

.ENDS
