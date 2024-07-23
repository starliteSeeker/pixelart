NAME=pixelart

SRCS = $(NAME).asm

.DEFAULT_GOAL := all

ifneq (clean,$(MAKECMDGOALS))
include $(patsubst %.asm,%.d,$(SRCS))
endif

%.o: %.asm %.d
	wla-65816 -o $@ $<

%.d: %.asm
	wla-65816 -M -MF $@ $<

all: $(patsubst %.asm,%.o,$(SRCS)) gfx/palette.bin
	echo '[objects]' > temp
	echo '$(NAME).o' >> temp
	wlalink temp $(NAME).smc
	rm temp

# tiles.inc: graphics.chr chr2asm.py
# 	./chr2asm.py
# 
# palettes.inc: graphics.pal pal2asm.py
# 	./pal2asm.py

clean:
	rm -f *.smc *.o *.d temp
