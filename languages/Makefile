# Build, test and package the service.
CC      ?= cc
CFLAGS  := -O2 -Wall -Wextra -std=c11
PREFIX  ?= /usr/local
SRC     := $(wildcard src/*.c)
OBJ     := $(SRC:src/%.c=build/%.o)
VERSION := $(shell git describe --tags --always)

.PHONY: all test install clean

all: build/inventory

build/inventory: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ -lsqlite3

build/%.o: src/%.c | build
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -c $< -o $@

build:
	mkdir -p $@

test: build/inventory
	./tests/run.sh $<

install: build/inventory
	install -m 755 $< $(DESTDIR)$(PREFIX)/bin/inventory

clean:
	$(RM) -r build
