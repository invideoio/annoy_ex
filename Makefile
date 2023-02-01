# Environment variables passed via elixir_make
# ERTS_INCLUDE_DIR
# MIX_APP_PATH

MIX = mix
PRIV_DIR = $(MIX_APP_PATH)/priv
ANNOY_EX_SO = $(PRIV_DIR)/annoy.so

CFLAGS = -std=c++14 -fPIC -shared -Wall -Wno-long-long -Wno-variadic-macros
CFLAGS += -I$(ERTS_INCLUDE_DIR)
CFLAGS += -Isrc

ifeq ($(shell uname),Darwin)
LDFLAGS += -dynamiclib -undefined dynamic_lookup
endif

.PHONY: clean

$(ANNOY_EX_SO): src/annoy.cc
	mkdir -p $(PRIV_DIR)
	g++ $(CFLAGS) $(LDFLAGS) -o $(ANNOY_EX_SO) src/annoy.cc

clean:
	$(MIX) clean
	$(RM) $(ANNOY_EX_SO)
