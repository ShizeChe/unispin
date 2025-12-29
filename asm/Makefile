CC      := gcc
CFLAGS  := -std=c17 -Wall -Wextra -Werror -O0 \
           -g -fsanitize=address,undefined -fno-omit-frame-pointer \
		   -Iinclude
LDFLAGS := -fsanitize=address,undefined

EXE ?= 0
DEBUG ?= 0
CFLAGS += -DEXE=$(EXE) -DDEBUG=$(DEBUG)

OBJDIR := build

SRCS := $(wildcard src/*.c)
OBJS := $(patsubst src/%.c,$(OBJDIR)/%.o,$(SRCS))

BIN := squish

$(OBJDIR)/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS) -lm

.PHONY: all clean

all: $(BIN)

clean:
	rm -f $(BIN)
	rm -rf $(OBJDIR)

