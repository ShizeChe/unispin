CC      := gcc
CFLAGS  := -std=c17 -Wall -Wextra -Werror -O2 \
           -g -fsanitize=address,undefined -fno-omit-frame-pointer \
		   -Iinclude
LDFLAGS := -fsanitize=address,undefined

TEST ?= 1
DEBUG ?= 0
CFLAGS += -DTEST=$(TEST) -DDEBUG=$(DEBUG)

OBJDIR := build
DUMPDIR := dump

SRCS := $(wildcard src/*.c)
APPS := $(wildcard app/*.c)
OBJS := $(patsubst src/%.c,$(OBJDIR)/%.o,$(SRCS))
BINS := $(patsubst app/%.c,%,$(APPS))


$(OBJDIR)/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

%: app/%.c $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS) -lm
	mkdir $(DUMPDIR)

.PHONY: clean
clean:
	rm -f $(BINS)
	rm -rf $(OBJDIR)
	rm -rf $(DUMPDIR)
