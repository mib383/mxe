# This file is part of MXE. See LICENSE.md for licensing information.

PKG               := vtk
$(PKG)_IGNORE     :=
$(PKG)_VERSION    := e0c287d
#9.4.1
$(PKG)_CHECKSUM   := 7f8b6791e8a4b5e0f2f55d6f78eec9e6c0e09a2d8020da653101134b862b5049
#$(PKG)_SUBDIR     := VTK-$($(PKG)_VERSION)
$(PKG)_GH_CONF    := Kitware/VTK/branches/master
#$(PKG)_FILE       := $($(PKG)_SUBDIR).tar.gz
#$(PKG)_URL        := https://www.vtk.org/files/release/$(call SHORT_PKG_VERSION,$(PKG))/$($(PKG)_FILE)
$(PKG)_QT_VERSION := 6
$(PKG)_DEPS       := cc expat brotli bzip2 freetype glew hdf5 jsoncpp libharu libpng libxml2 lz4 qt6-qtbase qt6-qttools tiff $(BUILD)~$(PKG)

$(PKG)_TARGETS       := $(BUILD) $(MXE_TARGETS)
$(PKG)_DEPS_$(BUILD) := cmake

#define $(PKG)_UPDATE
#    $(WGET) -q -O- 'https://vtk.org/gitweb?p=VTK.git;a=tags' | \
#    grep 'refs/tags/v[0-9.]*"' | \
#    $(SED) 's,.*refs/tags/v\(.*\)".*,\1,g;' | \
#    grep -v rc | \
#    $(SORT) -V | \
#    tail -1
#endef
#
define $(PKG)_BUILD_$(BUILD)
    # first we need a native build to create the compile tools
    # must be built in dest since there's no way to install tools only
    # and the build rules reference certain make targets
    rm -rf '$(PREFIX)/$(BUILD)/vtkCompileTools'
    $(INSTALL) -d '$(PREFIX)/$(BUILD)/vtkCompileTools'
    cd '$(PREFIX)/$(BUILD)/vtkCompileTools' && '$(PREFIX)/$(BUILD)/bin/cmake' '$(SOURCE_DIR)' \
        -DBUILD_TESTING=FALSE \
        -DVTK_USE_X=OFF \
        -DVTK_DEFAULT_RENDER_WINDOW_OFFSCREEN=ON \
		-DVTK_BUILD_COMPILE_TOOLS_ONLY=ON \
        -DCMAKE_BUILD_TYPE="Release"
    $(MAKE) -C '$(PREFIX)/$(BUILD)/vtkCompileTools' -j '$(JOBS)' VERBOSE=1
endef
# to do make it via wine?
define $(PKG)_BUILD
    # DirectX is detected on Mac OSX but we use OpenGL
    $(SED) -i 's,d3d9,nod3d9,g' '$(1)/CMake/FindDirectX.cmake'
	
	
	FTLIBS:=$(shell "$(PREFIX)/$(TARGET)/bin/freetype-config --libs")
	FTDIR1:=$(PREFIX)/$(TARGET)/include/freetype2
	FTDIR2:=$(PREFIX)/$(TARGET)/include/
	FTDIRS:=$(FTDIR1)
	
	echo "$(FTLIBS)"
	echo "$(FTDIR1)"
	echo "$(FTDIR2)"
	echo "$(FTDIRS)"
	
	# -DVTK_USE_EXTERNAL=ON \
    # now the cross compilation
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)' \
        -DVTKCompileTools_DIR='$(PREFIX)/$(BUILD)/vtkCompileTools' \
        -DBUILD_SHARED_LIBS=$(CMAKE_SHARED_BOOL) \
        -DVTK_GROUP_ENABLE_Qt=YES \
        -DVTK_GROUP_ENABLE_Imaging=YES \
        -DVTK_QT_VERSION=$($(PKG)_QT_VERSION) \
		-DVTK_MODULE_ENABLE_VTK_GUISupportQtQuick=NO \
        -DVTK_USE_CXX11_FEATURES=ON \
        -DVTK_FORBID_DOWNLOADS=ON \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTING=OFF \
		-DFREETYPE_LIBRARIES="$(FTLIBS)" \
		-DFREETYPE_INCLUDE_DIR_ft2build="$(PREFIX)/$(TARGET)/include/freetype2" \
		-DFREETYPE_INCLUDE_DIR_freetype2="$(PREFIX)/$(TARGET)/include" \
		-DFREETYPE_INCLUDE_DIRS="$(PREFIX)/$(TARGET)/include/freetype2;$(PREFIX)/$(TARGET)/include" \
		-DVTK_MODULE_ENABLE_VTK_libproj=NO \
		-DVTK_MODULE_USE_EXTERNAL_VTK_freetype=ON \
		-DVTK_REQUIRE_LARGE_FILE_SUPPORT_EXITCODE=0 \
		-DH5_PRINTF_LL_TEST_RUN=0 -DH5_PRINTF_LL_TEST_RUN__TRYRUN_OUTPUT="" \
		-DH5_LDOUBLE_TO_LONG_SPECIAL_RUN=0 -DH5_LDOUBLE_TO_LONG_SPECIAL_RUN__TRYRUN_OUTPUT="" \
		-DH5_LONG_TO_LDOUBLE_SPECIAL_RUN=0 -DH5_LONG_TO_LDOUBLE_SPECIAL_RUN__TRYRUN_OUTPUT="" \
		-DH5_DISABLE_SOME_LDOUBLE_CONV_RUN=0 -DH5_DISABLE_SOME_LDOUBLE_CONV_RUN__TRYRUN_OUTPUT="" \
        $(PKG_CONFIGURE_OPTS)
    #$(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' VERBOSE=1
    #$(MAKE) -C '$(BUILD_DIR)' -j 1 install VERBOSE=1
	
	#echo 'target_link_libraries(Freetype::Freetype INTERFACE $(PREFIX)/$(TARGET)/lib/libbrotlidec.a $(PREFIX)/$(TARGET)/lib/libbrotlienc.a $(PREFIX)/$(TARGET)/lib/libbrotlicommon.a $(PREFIX)/$(TARGET)/lib/libbz2.a)' >> $(PREFIX)/$(TARGET)/lib/cmake/vtk-$(call SHORT_PKG_VERSION,$(PKG))/vtk-config.cmake
	echo 'target_link_libraries(Freetype::Freetype INTERFACE $(FTLIBS))' >> $(PREFIX)/$(TARGET)/lib/cmake/vtk-$(PKG)_VERSION/vtk-config.cmake
    #now build the GUI -> Qt -> SimpleView Example
    mkdir '$(BUILD_DIR).test'
	# echo 'target_link_libraries(SimpleView PRIVATE $(PREFIX)/$(TARGET)/lib/libbrotlidec.a)' >> $(SOURCE_DIR)/Examples/GUI/Qt/SimpleView/CMakeLists.txt
	# echo 'target_link_libraries(SimpleView PRIVATE $(PREFIX)/$(TARGET)/lib/libbrotlienc.a)' >> $(SOURCE_DIR)/Examples/GUI/Qt/SimpleView/CMakeLists.txt
	# echo 'target_link_libraries(SimpleView PRIVATE $(PREFIX)/$(TARGET)/lib/libbz2.a)' >> $(SOURCE_DIR)/Examples/GUI/Qt/SimpleView/CMakeLists.txt
    cd '$(BUILD_DIR).test' && '$(TARGET)-cmake' \
        '$(SOURCE_DIR)/Examples/GUI/Qt/SimpleView'
    $(MAKE) -C '$(BUILD_DIR).test' -j '$(JOBS)' VERBOSE=1
    $(INSTALL) '$(BUILD_DIR).test/SimpleView.exe' $(PREFIX)/$(TARGET)/bin/test-$(PKG).exe
endef
