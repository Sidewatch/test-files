# ── Comments ──
# Build, test and package the warehouse service.
# TODO: add a coverage target. FIXME: parallel install.
#!/usr/bin/make -f   (not a shebang for make, just a comment)

# ── Special variables and directives ──
.DEFAULT_GOAL := all
.PHONY: all test install uninstall clean distclean help lint docs
.SUFFIXES:
.SUFFIXES: .c .o
.DELETE_ON_ERROR:
.SECONDARY:
.PRECIOUS: build/%.o
.ONESHELL:
.SILENT: help
.NOTPARALLEL:
.POSIX:
.EXPORT_ALL_VARIABLES:
.IGNORE: clean
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ── Variable assignment flavours ──
CC       ?= cc
CFLAGS   := -O2 -Wall -Wextra -std=c11
LDFLAGS  =
LDLIBS  += -lsqlite3
PREFIX   ?= /usr/local
VERSION  != git describe --tags --always 2>/dev/null || echo dev
BUILD    = build
SRC      := $(wildcard src/*.c)
OBJ      := $(SRC:src/%.c=$(BUILD)/%.o)
DEPS     := $(OBJ:.o=.d)
EMPTY    :=
SPACE    := $(EMPTY) $(EMPTY)
COMMA    := ,
override CFLAGS += -DVERSION=\"$(VERSION)\"
export PATH := $(PREFIX)/bin:$(PATH)
export API_KEY = example-not-a-real-key
unexport DEBUG
private SECRET := hidden
define NEWLINE


endef
define BANNER
Warehouse $(VERSION)
  built with $(CC)
endef
export BANNER

# ── Conditionals ──
ifeq ($(OS),Windows_NT)
  EXE := .exe
else ifeq ($(shell uname -s),Darwin)
  EXE :=
  LDFLAGS += -Wl,-dead_strip
else
  EXE :=
endif

ifdef DEBUG
  CFLAGS += -g -O0
endif
ifndef QUIET
  Q :=
else
  Q := @
endif
ifneq ($(strip $(PREFIX)),)
  DESTDIR ?=
endif

# ── Includes ──
include config.mk
-include $(DEPS)
sinclude local.mk

# ── Rules: default, explicit, pattern, static pattern ──
all: $(BUILD)/inventory$(EXE)

$(BUILD)/inventory$(EXE): $(OBJ)
	$(Q)$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(OBJ): $(BUILD)/%.o: src/%.c Makefile
	@echo "compiling $* ($(<F) in $(<D)) -> $(@F)"
	$(CC) -c $< -o $@

%.pdf: %.md
	pandoc $< -o $@

$(BUILD):
	mkdir -p $@

# Grouped targets and double-colon rules
gen.h gen.c &: gen.def
	./generate $<

log::
	@echo first
log::
	@echo second

# Order-only prerequisite and secondary expansion
.SECONDEXPANSION:
$(BUILD)/%.bin: $$(wildcard src/$$*/*.c)
	$(CC) -o $@ $^

# ── Automatic variables ──
show-autos: a b c
	@echo "target=$@ first=$< all=$^ unique=$+ newer=$? stem=$* order=$|"
	@echo "dir=$(@D) file=$(@F) pdir=$(<D) pfile=$(<F)"
	@echo "archive member=$% shell pid=$$$$ dollar=$$HOME"

# ── Functions ──
FILES := $(sort $(wildcard *.c) $(wildcard src/*.c))
NAMES := $(notdir $(basename $(FILES)))
UPPER := $(shell echo hello | tr a-z A-Z)
JOINED := $(subst $(SPACE),$(COMMA),$(strip a  b  c))
FILTERED := $(filter %.c %.h,$(FILES)) $(filter-out test_%,$(FILES))
PATSUB := $(patsubst %.c,%.o,$(FILES))
WORDS := $(words $(FILES)) $(word 2,$(FILES)) $(wordlist 1,3,$(FILES)) $(firstword $(FILES)) $(lastword $(FILES))
DIRS := $(dir $(FILES)) $(suffix $(FILES)) $(addprefix obj/,$(NAMES)) $(addsuffix .o,$(NAMES))
ABS := $(abspath ../x) $(realpath .) $(join a b,c d)
COND := $(if $(DEBUG),debug,release) $(or $(A),$(B),none) $(and $(A),$(B))
FOREACH := $(foreach d,src lib,$(wildcard $(d)/*.h))
CALLED := $(call reverse,a,b)
reverse = $(2) $(1)
EVALED := $(eval GENERATED := yes)
ORIGIN := $(origin CC) $(flavor CC) $(value CC)
MSG := $(info info message) $(warning warning message)
FILE := $(file < config.mk)
BOOM := $(if $(BAD),$(error bad configuration: $(BAD)))

define make-rule
$(1)-test: $(1)
	./$(1) --self-test
endef
$(eval $(call make-rule,inventory))

# ── Phony targets ──
test: $(BUILD)/inventory$(EXE)
	@echo "Running tests"
	./tests/run.sh $<
	-./tests/optional.sh
	+@$(MAKE) -C tests all
	@for f in tests/*.sh; do \
	  echo "== $$f"; \
	  sh "$$f" || exit 1; \
	done

install: all
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(BUILD)/inventory$(EXE) $(DESTDIR)$(PREFIX)/bin/inventory
	@printf '%s\n' "$$BANNER"

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/bin/inventory

lint:
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh || echo "shellcheck missing"

docs: ; @echo "building docs" ; doxygen Doxyfile

help:
	@echo 'Targets: all test install clean'
	@echo "Version: $(VERSION) ($(if $(DEBUG),debug,release)); contact ops@example.com at 192.0.2.10"

clean:
	$(RM) -r $(BUILD)

distclean: clean
	$(RM) config.mk local.mk

# Target-specific and pattern-specific variables
debug: CFLAGS += -g -DDEBUG
debug: all
%.o: CFLAGS += -fPIC

# Escaped newlines, trailing comment and line continuations
LONG_LIST = alpha \
            beta \
            gamma # trailing comment
SPECIAL = \# not a comment, \$ literal dollar, 100%% done

# ── Rare constructs ──
VPATH = src:include:../common
vpath %.c src lib
vpath %.h include
vpath
vpath %.c

.INTERMEDIATE: tmp.o
.LOW_RESOLUTION_TIME: stamp
.SECONDARY: foo.o
.NOEXPORT:
.EXPORT_ALL_VARIABLES:

# conditional forms
ifeq "$(CC)" "gcc"
  TOOL := gnu
endif
ifeq '$(CC)' 'clang'
  TOOL := llvm
endif
ifeq ($(CC),cc)
  TOOL := generic
endif
ifneq "$(origin CC)" "undefined"
  HAS_CC := yes
else ifdef FORCE_CC
  HAS_CC := forced
else ifndef NO_CC
  HAS_CC := maybe
else
  HAS_CC := no
endif
ifndef UNDEFINED_THING
  UNDEFINED_THING = default
endif
ifeq (,$(strip $(NOTHING)))
  NOTHING_SET := no
endif
ifneq ($(findstring clang,$(CC)),)
  FOUND_CLANG := 1
endif

# variable forms
A = recursive $(B)
B := simple
C ?= conditional
D += appended
F != echo shell-assign
G = a$(EMPTY)b
H = $(subst a,b,$(A))
I = ${braces} and $(parens) and $x single-char and $$escaped and $(foo bar) and ${baz qux}
export J
export K L M = multi
unexport N
override O = overridden
override P += overridden-append
override define Q
multi-line
override
endef
ifneq ($(filter 4.% 5.%,$(MAKE_VERSION)),)
define R =
recursive define
endef
define S :=
immediate define
endef
define T +=
appended define
endef
undefine A
undefine override
endif
MAKEFLAGS += --no-print-directory -j4
.DEFAULT:
	@echo "no rule for $@"
.SUFFIXES: .c .o .y .l .s
.c.o:
	$(CC) $(CFLAGS) -c $< -o $@
.c:
	$(CC) $(CFLAGS) $< -o $@
.o.a:
	$(AR) rv $@ $<
%.tab.c %.tab.h: %.y
	bison -d $<
lib.a(a.o b.o): a.o b.o
	$(AR) r $@ $%
lib.a: lib.a(a.o) lib.a(b.o)
(%.o): %.o
	$(AR) r $@ $<
$(foreach t,a b c,$(eval $(t)-target: ; @echo $(t))) 

# automatic variable variants
auto: a.c b.c | order.o
	@echo $@ $< $^ $+ $? $* $% $| $(@D) $(@F) $(<D) $(<F) $(^D) $(^F) $(+D) $(+F) $(?D) $(?F) $(*D) $(*F) $(%D) $(%F)
	@echo $$@ $$$$ $${HOME} $$(date) $$((1+2)) \# literal hash \$$ dollars

# every text function
text:
	@echo $(subst a,b,aaa) $(patsubst %.c,%.o,a.c b.c) $(strip   x   y ) $(findstring a,abc) $(filter %.c %.h,a.c b.h c.o) $(filter-out %.o,a.c b.o) $(sort b a b c)
	@echo $(word 2,a b c) $(wordlist 2,3,a b c d) $(words a b c) $(firstword a b) $(lastword a b) $(dir a/b c) $(notdir a/b c) $(suffix a.c b.h) $(basename a.c b/c.h)
	@echo $(addsuffix .o,a b) $(addprefix src/,a b) $(join a b,1 2) $(wildcard *.c) $(realpath .) $(abspath ..) $(shell echo hi) $(if x,yes,no) $(or ,b) $(and a,b)
	@echo $(foreach v,a b,$(v)!) $(call reverse,1,2) $(value HOME) $(origin HOME) $(flavor HOME) $(eval X=1) $(info i) $(warning w) $(subst $(SPACE),_,a b)
	@echo $(CURDIR) $(MAKE) $(MAKELEVEL) $(MAKECMDGOALS) $(MAKEFILE_LIST) $(MAKEFLAGS) $(MFLAGS) $(MAKE_VERSION) $(MAKE_COMMAND) $(MAKEOVERRIDES) $(SHELL) $(.VARIABLES) $(.FEATURES) $(.INCLUDE_DIRS) $(.DEFAULT_GOAL) $(.RECIPEPREFIX)

# GNU make 4.x-only syntax kept behind a version guard
ifneq ($(filter 4.% 5.%,$(MAKE_VERSION)),)
  load ./plugin.so
  -load ./optional.so
  GREETING := $(let first rest,a b c,$(first)/$(rest))
  CMP := $(intcmp 1,2,lt,eq,gt)
  PIPE := $(file >out.txt,text) $(file >>out.txt,more) $(file <in.txt)
  TARGETS = a b c
  $(TARGETS) &: dep ; touch $(TARGETS)
  .WAIT:
  all: one .WAIT two
  .NOTINTERMEDIATE: keep.o
  .EXTRA_PREREQS = extra
  .ONESHELL:
  SCRIPT != cat script.sh
  X ::= immediate-posix
  GUILE := $(guile (+ 1 2))
endif

# static pattern, order-only, target-specific forms
$(OBJS): %.o: %.c | $(BUILD)
	$(CC) -c $< -o $@
%.elf: LDFLAGS += -static
special-target: export FOO := bar
ifneq ($(filter 4.% 5.%,$(MAKE_VERSION)),)
special-target: private PRIV := 1
endif
special-target: override OVR = 2
special-target:
	@echo $(FOO)
.PHONY: auto text special-target \
        $(SUBDIRS) \
        more-phony

# recipes: continuation, silent, ignore, always-run, embedded comments
continued:
	@echo one \
	  two \
	  three
	-@rm -f missing # trailing # comment in recipe passes to shell
	+@$(MAKE) -C sub $@
	@if [ -f x ]; then \
	  echo yes; \
	else \
	  echo no; \
	fi
	@echo "# not a make comment" 'single $$quoted'
	@echo "tab	inside"; echo done
# comment lines
	# indented-with-tab comment goes to the shell

tricky\ name: dep\ with\ space
	@echo escaped spaces in names
target-a target-b: common-dep
x := a # a hash always starts a comment
y = $(subst \#,hash,\#)
\#escaped-hash-target:
	@echo ok
-include .deps/*.d
include $(wildcard conf.d/*.mk)
