NAME=pixelart

SRCS = src/main.asm src/menu.asm src/waterfall.asm src/hello_world.asm src/desert_sunset.asm src/dvd_logo.asm
OBJS = $(patsubst %.asm,%.o,$(SRCS))
DEPS = $(patsubst %.asm,%.d,$(SRCS))

.DEFAULT_GOAL := $(NAME).smc

ifneq (clean,$(MAKECMDGOALS))
include $(DEPS)
endif

%.o: %.asm %.d
	wla-65816 -o $@ $<

%.d: %.asm
	wla-65816 -M -MF $@ $<

$(NAME).smc: $(OBJS)
	echo '[objects]' > temp
	for obj in $(OBJS) ; do \
		echo $$obj >> temp ; \
	done
	wlalink temp $@
	rm temp

clean:
	rm -f *.smc $(OBJS) $(DEPS) temp
