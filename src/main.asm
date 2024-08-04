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
    stz CUR_SEL

restart:
    ; jump to init function based on jump table
    jsl prepare_jump_init

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
+   jsl prepare_jump_update
    rti

; jump table with rti trick to emulate long jump to subroutine witn index
; jsl [jump_table, x]
prepare_jump_init:
    ; push program bank
    lda #0
    xba
    lda CUR_SEL
    tax
    lda init_jump_table_bank.l, x
    pha
    ; push program counter
    rep #$20 ; 16bit a
    lda CUR_SEL
    and #$00ff
    asl
    tax
    lda init_jump_table.l, x
    pha
    sep #$20
    ; push processor status
    php
    ; fake rti, emulate long jump with index
    rti

prepare_jump_update:
    ; push program bank
    lda #0
    xba
    lda CUR_SEL
    tax
    lda update_jump_table_bank.l, x
    pha
    ; push program counter
    rep #$20 ; 16bit a
    lda CUR_SEL
    and #$00ff
    asl
    tax
    lda update_jump_table.l, x
    pha
    sep #$20
    ; push processor status
    php
    ; fake rti, emulate long jump with index
    rti

init_jump_table:
    .DW menu.init
    .DW waterfall.init
init_jump_table_bank:
    .DB :menu.init
    .DB :waterfall.init

update_jump_table:
    .DW menu.update
    .DW waterfall.update
update_jump_table_bank:
    .DB :menu.update
    .DB :waterfall.update

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

