CC      := gcc
CFLAGS  := -std=c17 -Wall -Wextra -Werror -O2 \
           -g -fsanitize=address,undefined -fno-omit-frame-pointer
LDFLAGS := -fsanitize=address,undefined
INCS    := -I.

# Objects for your module
OBJS := dc.o

# Build the module (dc.c should exist)
dc.o: dc.c dc.h
	$(CC) $(CFLAGS) $(INCS) -c dc.c -o $@

tests/test_dc: tests/dc_tests.c $(OBJS)
	$(CC) $(CFLAGS) $(INCS) $^ -o $@ $(LDFLAGS) -lm

.PHONY: test
test: tests/test_dc
	./tests/test_dc
