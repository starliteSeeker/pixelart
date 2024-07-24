;== Include memorymap, header info, and SNES initialization routines
.INCLUDE "include/header.inc" ONCE
.INCLUDE "include/InitSNES.asm"

; .INCLUDE "src/waterfall.asm"

;========================
; Start
;========================

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"


Start:
    InitializeSNES            ; Init Snes :)

    rep #%00010000  ;16 bit xy
    sep #%00100000  ;8 bit ab

    jsr waterfall.init

    lda #$0F
    sta $2100           ; Turn on screen, full brightness

    lda #%10000001  ; enable NMI and joypads
    sta $4200

forever:
    wai
    jmp forever

VBlank:
    jsr waterfall.update
    rti

.ENDS

; bring out from header file to avoid multiple instances of EmptyHandler label
.BANK 0 SLOT 0      ; Defines the ROM bank and the slot it is inserted in memory.
.ORG 0              ; .ORG 0 is really $8000, because the slot starts at $8000
.SECTION "EmptyVectors" SEMIFREE
 
EmptyHandler:
        rti
.ENDS
