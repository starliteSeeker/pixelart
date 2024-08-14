.INCLUDE "include/header.inc" ONCE

.BANK 0 SLOT 0
.ORG 0
.SECTION "desert_sunset" NAMESPACE "desert_sunset"
.ACCU 8
.INDEX 16

; run at first load
init:
    ; load palette
    lda #$00 ; start from palette 0
    sta $2121
    lda #$ff ; color 0 is white (#$7fff), overwritten by HDMA
    sta $2122
    lda #$7f
    sta $2122
    stz $2122 ; color 1 is black (#$0000)
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

    ;set up the screen
    lda #%00110000  ; 16x16 tiles, mode 0
    sta $2105       ; screen mode register
    lda #$20  ; data starts from $2000
    sta $2107       ; for BG1
    stz $210b ; tileset starts at $0000

    ; move backgrounds to correct position
    stz $210d
    stz $210d
    stz $210e
    stz $210e

    lda #%00000001 ; enable BG1
    sta $212c

    ; setup HDMA
    lda #%00000000 ; one address write once
    sta $4300
    lda #$21 ; CGADD
    sta $4301
    ldx #cgadd_table.w
    stx $4302
    lda #:cgadd_table
    sta $4304

    lda #%00000010 ; one address write twice
    sta $4310
    lda #$22 ; CGDATA
    sta $4311
    ldx #cgdata_table.w
    stx $4312
    lda #:cgdata_table
    sta $4314

    lda #%00000011 ; enable HDMA 0 and 1
    sta $420c

    rtl

; run during vblank
update:
    lda #0
    rtl

.ENDS

; graphics data
.bank 1 slot 0       ; We'll use bank 1
.org 0
.section "gfxdata" NAMESPACE "desert_sunset"

cgadd_table:
    .DB 100, 0
    .DB 60, 0
    .DB 30, 0
    .DB 20, 0
    .DB 20, 0
    .DB 0
cgdata_table:
    .DB 100, %11011101, %00101101 ; gradient from orange ...
    .DB 60, %01011001, %00100101
    .DB 30, %11010110, %00010100
    .DB 20, %01110000, %00001100
    .DB 20, %00101011, %00000100 ; ... to brown
    .DB 0

tile_data:
LOAD_FILE "gfx/desert_sunset/tileset.bin" 
@end:

bg1_data:
LOAD_FILE "gfx/desert_sunset/bg1.bin" 
@end:

.ENDS
