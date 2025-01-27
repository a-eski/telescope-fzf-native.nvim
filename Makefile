CFLAGS += -std=gnu2x -Wall -Wextra -Werror -Wpedantic -pedantic-errors -fpic -Wsign-conversion -Wformat=2 -Wshadow -Wvla -fstack-protector-all

ifeq ($(OS),Windows_NT)
    CC = gcc
    TARGET := libfzf.dll
ifeq (,$(findstring $(MSYSTEM),MSYS UCRT64 CLANG64 CLANGARM64 CLANG32 MINGW64 MINGW32))
	# On Windows, but NOT msys/msys2
    MKD = cmd /C mkdir
    RM = cmd /C rmdir /Q /S
else
    MKD = mkdir -p
    RM = rm -rf
endif
else
    MKD = mkdir -p
    RM = rm -rf
    TARGET := libfzf.so
endif

all: build/$(TARGET)

build/$(TARGET): src/fzf.c src/fzf.h
	$(MKD) build
	$(CC) -O3 $(CFLAGS) -shared src/fzf.c -o build/$(TARGET)

build/test: build/$(TARGET) test/test.c
	$(CC) -Og -ggdb3 $(CFLAGS) test/test.c -o build/test -I./src -L./build -lfzf -lexaminer

build/l: build/$(TARGET) test/test.c
	$(CC) -Og -ggdb3 $(CFLAGS) test/main.c -o build/main -I./src -L./build -lfzf -lexaminer

.PHONY: lint format test test_dyn_link l ntest clangdhappy clean
lint:
	luacheck lua

format:
	clang-format --style=file --dry-run -Werror src/fzf.c src/fzf.h test/test.c

test: build/test
	@LD_LIBRARY_PATH=${PWD}/build:${PWD}/examiner/build:${LD_LIBRARY_PATH} ./build/test

test_dyn_link: build/test
	@LD_LIBRARY_PATH=/usr/local/lib:./build:${LD_LIBRARY_PATH} ./build/test

l:
	@LD_LIBRARY_PATH=/usr/local/lib:./build:${LD_LIBRARY_PATH} ./build/main

ntest:
	nvim --headless --noplugin -u test/minrc.vim -c "PlenaryBustedDirectory test/ { minimal_init = './test/minrc.vim' }"

clangdhappy:
	compiledb make

clean:
	$(RM) build
