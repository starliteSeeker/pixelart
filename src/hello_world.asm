.INCLUDE "include/header.inc" ONCE

; memory address $0000 to $00ff are reserved for main function
; additional variables should use memory address $0100 and onwards

.BANK 0 SLOT 0
.ORG 0
.SECTION "hello_world" NAMESPACE "hello_world"
.ACCU 8
.INDEX 16

; run once at start of animation
; palette/tileset/tilemap data and register/variable initialization
init:
    ; load palette
    lda #$00 ; start from palette 0
    sta $2121
    lda #$ff ; white background ($7fff)
    sta $2122
    lda #$7f
    sta $2122
    stz $2122 ; black text ($0000)
    stz $2122

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
    ; load message
    ldx #$1000 ; VRAM starting address
    stx $2116
    ldx #0 
    ldy #(message@end - message)
    rep #$20 ; 16bit a
-   lda message.l, x
    and #$00ff
    sta $2118
    inx
    dey
    bne -
    sep #$20 ; 8bit a
    ; fill with zero
    ldx #zero_data
    stx $4302
    lda #:zero_data
    sta $4304
    lda #$18
    sta $4301
    lda #%00001001 ; fixed address, transfer words
    sta $4300
    ldx #((32*32 - (message@end - message)) * 2)
    stx $4305
    lda #%00000001 ; enable dma 0
    sta $420b
    
    stz $210d ; reset background scroll
    stz $210d
    stz $210e
    stz $210e
    stz $2105 ; 8x8 tiles
    lda #$10  ; data starts from $1000

    lda #%00000001 ; enable BG1
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
.section "gfxdata" NAMESPACE "hello_world"

zero_data:
    .DB 0, 0

message:
    .DB "Hello world\x7f"
@end:

tile_data:
LOAD_FILE "gfx/ascii.bin"
@end:

.ENDS
