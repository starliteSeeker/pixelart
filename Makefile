NAME=pixelart

SRCS = $(wildcard src/*.asm)
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
