CC ?= gcc
CXX ?= g++
LIBS ?=
VERSION = $(shell git describe --always)
CFLAGS += -Wall -Wno-sign-compare -g -DVERSION=\"$(VERSION)\"
CXXFLAGS += $(CFLAGS) -std=c++14 -Wnon-virtual-dtor
PREFIX ?= /usr/local
UNAME ?= $(shell uname)

CROSS ?= mips-linux-gnu-

ifeq ($(UNAME), Linux)
	LIBS += -lssl -lcrypto
endif

ifeq ($(UNAME), Darwin)
	CFLAGS +=
endif

profile_OBJ = profile.o profiledef.o

bcm2dump_OBJ = io.o rwx.o interface.o ps.o bcm2dump.o \
	util.o progress.o mipsasm.o $(profile_OBJ)
bcm2cfg_OBJ = util.o nonvol2.o bcm2cfg.o nonvoldef.o \
	gwsettings.o $(profile_OBJ) crypto.o
psextract_OBJ = util.o ps.o psextract.o
t_nonvol_OBJ = util.o nonvol2.o t_nonvol.o $(profile_OBJ)

.PHONY: all clean bcm2cfg.exe

all: bcm2dump bcm2cfg t_nonvol psextract

release-linux: clean bcm2cfg bcm2dump
	strip bcm2cfg
	strip bcm2dump
	zip bcm2utils-$(VERSION)-linux.zip README.md bcm2cfg bcm2dump

release-macos: release-linux
	mv bcm2utils-$(VERSION)-linux.zip bcm2utils-$(VERSION)-macos.zip

release-win32:
	zip bcm2utils-$(VERSION)-win32.zip README.md bcm2cfg.exe bcm2dump.exe

#bcm2cfg.exe:
#	UNAME=Wine CC=winegcc CXX=wineg++ CFLAGS=-m32 make bcm2cfg

bcm2cfg: $(bcm2cfg_OBJ)
	$(CXX) $(CXXFLAGS) $(bcm2cfg_OBJ) -o $@ $(LIBS) $(LDFLAGS)

bcm2dump: $(bcm2dump_OBJ)
	$(CXX) $(CXXFLAGS) $(bcm2dump_OBJ) -o $@ $(LDFLAGS)

psextract: $(psextract_OBJ)
	$(CXX) $(CXXFLAGS) $(psextract_OBJ) -o $@ $(LDFLAGS)

t_nonvol: $(t_nonvol_OBJ)
	$(CXX) $(CXXFLAGS) $(t_nonvol_OBJ) -o $@ $(LDFLAGS)

rwx.o: rwx.cc rwx.h rwcode.c
	$(CXX) -c $(CXXFLAGS) $< -o $@

%.o: %.c %.h
	$(CC) -c $(CFLAGS) $< -o $@

%.o: %.cc %.h
	$(CXX) -c $(CXXFLAGS) $< -o $@

%.inc: %.asm
	$(CROSS)gcc -c -x assembler-with-cpp $< -o $*.o
	$(CROSS)objcopy -j .text -O binary $*.o $*.bin
	echo "// Autogenerated from $*.asm, $(VERSION)" > $@
	./bin2hdr.rb defines $*.o >> $@
	./bin2hdr.rb code $*.bin >> $@

check: t_nonvol
	./t_nonvol

clean:
	rm -f bcm2cfg bcm2cfg.exe bcm2dump t_nonvol psextract *.o

install: all
	install -m 755 bcm2cfg $(PREFIX)/bin
	install -m 755 bcm2dump $(PREFIX)/bin
