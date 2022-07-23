MIX = mix
CFLAGS = -std=c++14 -fPIC -shared -Wall -Wno-long-long -Wno-variadic-macros

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)
CFLAGS += -Isrc

.PHONY: all annoy clean

all: annoy

mkpriv:
	mkdir -p priv

annoy: mkpriv priv/annoy.so
	$(MIX) compile

priv/annoy.so: src/annoy.cc
	g++ $(CFLAGS) $(LDFLAGS) -o $@ src/annoy.cc

clean:
	$(MIX) clean
	$(RM) priv/annoy.so
