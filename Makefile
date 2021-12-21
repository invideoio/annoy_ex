MIX = mix
CFLAGS = -std=c++14 -g -O3 -fPIC -shared -ansi -pedantic

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)
CFLAGS += -Isrc

.PHONY: all annoy clean

all: annoy

annoy: priv/annoy.so
	$(MIX) compile

priv/annoy.so: src/annoy.cc
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ src/annoy.cc

clean:
	$(MIX) clean
	$(RM) priv/annoy.so