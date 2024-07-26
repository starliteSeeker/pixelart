NAME=pixelart

SRCS = main.asm waterfall.asm

.DEFAULT_GOAL := $(NAME).smc

ifneq (clean,$(MAKECMDGOALS))
include $(patsubst %.asm,%.d,$(SRCS))
endif

%.o: src/%.asm %.d
	wla-65816 -o $@ $<

%.d: src/%.asm
	wla-65816 -M -MF $@ $<

$(NAME).smc: $(patsubst %.asm,%.o,$(SRCS))
	echo '[objects]' > temp
	echo 'main.o' >> temp
	echo 'waterfall.o' >> temp
	wlalink temp $@
	rm temp

clean:
	rm -f *.smc *.o *.d temp
