;== Include memorymap, header info, and SNES initialization routines
.INCLUDE "include/header.inc" ONCE
.INCLUDE "include/InitSNES.asm"

;========================
; Start
;========================

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

; RAM $0000 to $00FF reserved for main
.DEFINE CUR_SEL $0000 EXPORT
.DEFINE INPUT_PRESSED $0001 EXPORT ; 2 bytes, is button pressed on this frame
.DEFINE INPUT_DOWN $0003 EXPORT ; 2 bytes, is button held down

Start:
    InitializeSNES            ; Init Snes :)

    rep #%00010000  ;16 bit xy
    sep #%00100000  ;8 bit ab

    ; initialize variable
    lda #1
    sta CUR_SEL

restart:
    ; jump to init function based on jump table
    lda #$00
    xba
    lda CUR_SEL
    asl
    tax
    jsr (init_jump_table, X)

init_end:
    lda #$0F
    sta $2100           ; Turn on screen, full brightness

    lda #%10000001  ; enable NMI and joypads
    sta $4200

forever:
    wai
    cmp #0
    beq +
    ; turn off screen and restart
    lda #%10000000
    sta $2100
    jmp restart

+   jmp forever


VBlank:
    ; process input
    lda $4212       ; get joypad status
    and #%00000001  ; if joy is not ready
    bne VBlank      ; wait
    rep #$20 ; 16bit a
    lda INPUT_DOWN
    eor #-1
    sta INPUT_PRESSED
    lda $4218       ; read joypad
    sta INPUT_DOWN
    eor #-1
    trb INPUT_PRESSED
    sep #$20

    ; restart from menu if start and select are pressed
    lda INPUT_PRESSED+1
    bit #%00110000
    beq + 
    lda INPUT_DOWN+1
    and #%00110000
    cmp #%00110000
    bne +
    stz CUR_SEL ; set to menu
    lda #-1
    rti

    ; jump to update function
+   lda #$00
    xba
    lda CUR_SEL
    asl
    tax
    jsr (update_jump_table, X)
    rti

init_jump_table:
    .DW menu.init
    .DW waterfall.init

update_jump_table:
    .DW menu.update
    .DW waterfall.update

dummy:
    rtl

.ENDS

; bring out from header file to avoid multiple instances of EmptyHandler label
.BANK 0 SLOT 0      ; Defines the ROM bank and the slot it is inserted in memory.
.ORG 0              ; .ORG 0 is really $8000, because the slot starts at $8000
.SECTION "EmptyVectors" SEMIFREE
 
EmptyHandler:
    rti
.ENDS

