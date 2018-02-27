SKYNET_PATH = ../../

include platform.mk

LUA_CLIB_PATH ?= luaclib

LUA_CLIB = webclient

CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS)

# lua
LUA_STATICLIB := 3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= 3rd/lua

all : \
    $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so)

$(LUA_CLIB_PATH)/webclient.so : lualib-src/webclient/webclient.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilualib-src/webclient/webclient $^ -o $@ -lcurl
