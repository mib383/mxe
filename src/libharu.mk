# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := libharu
$(PKG)_WEBSITE  := http://libharu.org/
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 2.4.5
$(PKG)_CHECKSUM := 0ed3eacf3ceee18e40b6adffbc433f1afbe3c93500291cd95f1477bffe6f24fc
$(PKG)_URL      := https://github.com/libharu/libharu/archive/refs/tags/v2.4.5.tar.gz
$(PKG)_DEPS     := cc libpng zlib

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
        -DCMAKE_C_FLAGS=$(if $(BUILD_STATIC),,-DHPDF_DLL_MAKE) \
        -DLIBHPDF_SHARED=$(CMAKE_SHARED_BOOL) \
        -DLIBHPDF_STATIC=$(CMAKE_STATIC_BOOL) \
        -DDEVPAK=ON
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' VERBOSE=1
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install VERBOSE=1

    # create pkg-config files
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/pkgconfig'
    (echo 'Name: $(PKG)'; \
     echo 'Version: $($(PKG)_VERSION)'; \
     echo 'Description: open source library for generating PDF files'; \
     echo 'Cflags: $(if $(BUILD_STATIC),,-DHPDF_DLL)'; \
     echo 'Libs: $(if $(BUILD_STATIC),-lhpdfs,-lhpdf)'; \
     echo 'Requires: libpng zlib';) \
     > '$(PREFIX)/$(TARGET)/lib/pkgconfig/$(PKG).pc'

    '$(TARGET)-gcc' \
        -W -Wall -ansi \
        '$(SOURCE_DIR)/demo/slide_show_demo.c' \
        -o '$(PREFIX)/$(TARGET)/bin/test-$(PKG).exe' \
        `'$(TARGET)-pkg-config' $(PKG) --cflags --libs`
endef
