;== Include memorymap, header info, and SNES initialization routines
.INCLUDE "include/header.inc" ONCE
.INCLUDE "include/InitSNES.asm"

;========================
; Start
;========================

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

.DEFINE CUR_SEL $0000 EXPORT

Start:
    InitializeSNES            ; Init Snes :)

    rep #%00010000  ;16 bit xy
    sep #%00100000  ;8 bit ab

    ; initialize variable
    stz CUR_SEL

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
    jmp forever


VBlank:
    lda #$00
    xba
    lda CUR_SEL
    asl
    tax
    jsr (update_jump_table, X)
update_end:
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


.BANK 1 SLOT 0
.ORG 0
.SECTION "menu_data"

menu_entry_count:
    .DB 2

menu_entry:
    ;   "each.entry.is.32.bytes.........."
    .DB "ZERO                            "
    .DB "ONE                             "

.ENDS
