;------------------------------ Header File ---------------------------------
;   This is basically a combo of MarctheMER's and Neviksti's header files
; Perhaps reading their's will also help your understanding of the header,
; but I believe this will be the simplest method of defining your header,
; as Marc's doesn't provide a full explanation, and Neviksti's can be
; a bit more difficult for beginners (using the WLA directives is easier).
;----------------------------------------------------------------------------
 
;==LoRom==                      ; We'll get to HiRom some other time.
.MEMORYMAP                      ; Begin describing the system architecture.
  SLOTSIZE $8000                ; The slot is $8000 bytes in size.
  DEFAULTSLOT 0                 ; There's only 1 slot in SNES
  SLOT 0 $8000                  ; Define's Slot 0's starting address.
.ENDME                          ; End MemoryMap definition
 
.ROMBANKSIZE $8000              ; Every ROM bank is 32 KBytes in size
.ROMBANKS 8                     ; 2 Mbits - Tell WLA we want to use 8 ROM Banks
 
.SNESHEADER
  ID "SNES"                     ; 1-4 letter string, just leave it as "SNES"
 
  NAME "SNES Program Name    "  ; Program Title - can't be over 21 bytes,
  ;    "123456789012345678901"  ; use spaces for unused bytes of the name.
 
  SLOWROM
  LOROM
 
  CARTRIDGETYPE $00             ; $00 = ROM only, see WLA documentation for others
  ROMSIZE $08                   ; $08 = 2 Mbits,  see WLA doc for more..
  SRAMSIZE $00                  ; No SRAM         see WLA doc for more..
  COUNTRY $01                   ; $01 = U.S.  $00 = Japan, that's all I know
  LICENSEECODE $00              ; Just use $00
  VERSION $00                   ; $00 = 1.00, $01 = 1.01, etc.
.ENDSNES
 
.SNESNATIVEVECTOR               ; Define Native Mode interrupt vector table
  COP EmptyHandler
  BRK EmptyHandler
  ABORT EmptyHandler
  NMI VBlank
  IRQ EmptyHandler
.ENDNATIVEVECTOR
 
.SNESEMUVECTOR                  ; Define Emulation Mode interrupt vector table
  COP EmptyHandler
  ABORT EmptyHandler
  NMI VBlank
  RESET Start
  IRQBRK EmptyHandler
.ENDEMUVECTOR
 
.EMPTYFILL $00
;---------------------------------- END -------------------------------------


;  both blt and bge are unsigned compares
.MACRO blt ARGS label ; branch if less than
    bcc label
.ENDM
.MACRO bge ARGS label ; branch if greater than or equal to
    bcs label
.ENDM

.MACRO LOAD_FILE ARGS path
.fopen path fp
.fsize fp t
.repeat t
.fread fp d
.db d
.endr
.undefine t, d
.ENDM

