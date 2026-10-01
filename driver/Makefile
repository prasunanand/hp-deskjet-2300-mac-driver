# Standalone macOS build of HPLIP's hpcups filter for the HP DeskJet 2300 series
# (DeskJet 2320/2330/2332, USB 03f0:3654, printer language pcl3gui2).

HPLIP   ?= ../src/hplip-3.26.4+dfsg0
DEPS    ?= ../src/deps
ARCH    ?= arm64
MINOS   ?= 12.0

BUILD   := build
# Patched copy of prnt/hpcups + common/utils.* (see the $(STAMP) rule)
HP      := $(BUILD)/src

CPPFLAGS := -DAPDK_LITTLE_ENDIAN -DDISABLE_IMAGEPROCESSOR -DNDEBUG -DCONFDIR=\"/etc/hp\" \
            -I$(HP) -I$(HPLIP)/io/hpmud -I$(DEPS)/include
CFLAGS   := -O2 -arch $(ARCH) -mmacosx-version-min=$(MINOS) -w
CXXFLAGS := $(CFLAGS) -std=gnu++11
LDFLAGS  := -arch $(ARCH) -mmacosx-version-min=$(MINOS)
LDLIBS   := $(DEPS)/lib/libjpeg.a -lcups -lcupsimage -lz

CXX_SRCS := HPCupsFilter dbuscomm Compressor Mode2 Mode3 Mode9 Mode10 ModeDeltaPlus \
            ModeJbig ErnieFilter EncapsulatorFactory Encapsulator Pcl3 Pcl3Gui Pcl3Gui2 \
            LJMono LJColor LJFastRaster LJJetReady LJZjStream LJZxStream Job Pipeline \
            Processor RasterSender ColorMatcher Halftoner Scaler dj400ColorMaps \
            dj600ColorMaps dj970ColorMaps dj8xxColorMaps dj4100ColorMaps BreakTables Utils \
            SystemServices QuickConnect ModeJpeg Lidil LidilCompress dj3320ColorMaps \
            dj3600ColorMaps Hbpl1 Hbpl1_Wrapper genPCLm genJPEGStrips RunLenEncoding
C_SRCS   := jccolor jdatadbf

OBJS  := $(addprefix $(BUILD)/,$(addsuffix .o,$(CXX_SRCS) $(C_SRCS) cutils))
STAMP := $(HP)/.prepared

all: $(BUILD)/hpcups

$(BUILD)/hpcups: $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

# macOS filesystems are case-insensitive, so "utils.h" (common/) collides with
# hpcups' own "Utils.h". Copy the sources and rename common/utils.* to cutils.*.
# Also <malloc.h> does not exist on macOS.
$(STAMP):
	rm -rf $(HP) && mkdir -p $(HP)
	cp $(HPLIP)/prnt/hpcups/*.cpp $(HPLIP)/prnt/hpcups/*.c $(HPLIP)/prnt/hpcups/*.h $(HP)/
	cp $(HPLIP)/common/utils.h $(HP)/cutils.h
	cp $(HPLIP)/common/utils.c $(HP)/cutils.c
	sed -i '' -e 's|#include "utils.h"|#include "cutils.h"|' \
	          -e 's|#include "./../../common/utils.h"|#include "cutils.h"|' \
	          -e 's|#include <malloc.h>|#include <stdlib.h>|' $(HP)/*.cpp $(HP)/*.c $(HP)/*.h
	touch $@

CXX_OBJS := $(addprefix $(BUILD)/,$(addsuffix .o,$(CXX_SRCS)))
C_OBJS   := $(addprefix $(BUILD)/,$(addsuffix .o,$(C_SRCS) cutils))

$(CXX_OBJS): $(BUILD)/%.o: $(STAMP)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $(HP)/$*.cpp

$(C_OBJS): $(BUILD)/%.o: $(STAMP)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $(HP)/$*.c

# Download HPLIP and build a static libjpeg into ../src (not checked in)
HPLIP_TAR := hplip_3.26.4+dfsg0.orig.tar.xz
JPEG_TAR  := jpegsrc.v9f.tar.gz

deps: $(DEPS)/lib/libjpeg.a $(HPLIP)/prnt/hpcups

$(HPLIP)/prnt/hpcups:
	mkdir -p ../src
	curl -fL -o ../src/$(HPLIP_TAR) https://deb.debian.org/debian/pool/main/h/hplip/$(HPLIP_TAR)
	tar -C ../src -xf ../src/$(HPLIP_TAR)

$(DEPS)/lib/libjpeg.a:
	mkdir -p ../src
	curl -fL -o ../src/$(JPEG_TAR) https://www.ijg.org/files/$(JPEG_TAR)
	tar -C ../src -xzf ../src/$(JPEG_TAR)
	cd ../src/jpeg-9f && ./configure --disable-shared --enable-static --prefix=$(abspath $(DEPS)) \
		CFLAGS="-O2 -arch $(ARCH) -mmacosx-version-min=$(MINOS)" && $(MAKE) && $(MAKE) install
	cp ../src/jpeg-9f/jpegint.h $(DEPS)/include/

clean:
	rm -rf $(BUILD)

.PHONY: all clean deps
