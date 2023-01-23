MIX = mix
CFLAGS = -std=c++14 -fPIC -shared -Wall -Wno-long-long -Wno-variadic-macros

ERLANG_PATH ?= $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)
CFLAGS += -Isrc

ifeq ($(shell uname),Darwin)
LDFLAGS += -dynamiclib -undefined dynamic_lookup
endif

.PHONY: all annoy clean check-env

all: annoy

mkpriv:
	mkdir -p priv

annoy: check-env mkpriv priv/annoy.so
	$(MIX) compile

priv/annoy.so: src/annoy.cc
	clang++ $(CFLAGS) $(LDFLAGS) -o $@ src/annoy.cc

check-env:
ifeq ("$(ERLANG_PATH)","")
	$(error ERLANG_PATH is undefined, ensure `erl` is in PATH)
endif

clean:
	$(MIX) clean
	$(RM) priv/annoy.so
