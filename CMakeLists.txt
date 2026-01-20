# Version 3.24 needed for FetchContent OVERRIDE_FIND_PACKAGE
cmake_minimum_required(VERSION 3.24)

# Suppress Qt policy warnings
cmake_policy(SET CMP0071 NEW)
set(CMAKE_SUPPRESS_DEVELOPER_WARNINGS ON CACHE INTERNAL "")

project(ps4pkgunpacker LANGUAGES CXX)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Configuration-specific flags
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-g -O0)
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-O3)
    # Note: Stripping is usually handled by the linker or a separate step, 
    # but we can try to add linker flags for it if supported.
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        add_link_options(-s)
    endif()
else()
    # For other types like RelWithDebInfo, ensure -g is there if that's what's intended
    # But user asked for Release to be stripped and Debug to have -g -O0.
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(BUILD_SHARED_LIBS OFF)
set(BUILD_TESTING OFF)

find_package(Qt6 REQUIRED COMPONENTS Gui Qml Quick QuickControls2 Widgets Concurrent Core5Compat)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

# ZLIB
if (NOT TARGET ZLIB::ZLIB)
    set(ZLIB_ENABLE_TESTS OFF)
    set(WITH_GTEST OFF)
    set(WITH_NEW_STRATEGIES ON)
    set(WITH_NATIVE_INSTRUCTIONS ON)
    set(ZLIB_COMPAT ON CACHE BOOL "" FORCE)
    include(FetchContent)
    FetchContent_Declare(
        ZLIB
        SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/externals/zlib-ng"
        OVERRIDE_FIND_PACKAGE
    )
    FetchContent_MakeAvailable(ZLIB)
    add_library(ZLIB::ZLIB ALIAS zlib)
endif()

# CryptoPP
if (NOT TARGET cryptopp::cryptopp)
    set(CRYPTOPP_INSTALL OFF)
    set(CRYPTOPP_BUILD_TESTING OFF)
    set(CRYPTOPP_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/externals/cryptopp")
    # cryptopp instruction set checks do not account for added compile options,
    # so disable extensions in the library config to match our chosen target CPU.
    set(CRYPTOPP_DISABLE_AESNI ON)
    set(CRYPTOPP_DISABLE_AVX2 ON)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/externals/cryptopp-cmake" "${CMAKE_CURRENT_BINARY_DIR}/externals/cryptopp-cmake" EXCLUDE_FROM_ALL)
    
    # remove externals/cryptopp from include directories because it contains a conflicting zlib.h file
    set_target_properties(cryptopp PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_BINARY_DIR}/externals")
    
    # Provide includes for cryptopp
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/externals/cryptopp" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/externals" FILES_MATCHING PATTERN "*.h")
endif()

qt_standard_project_setup()

# Suppress QTP0004 warning by acknowledging we have a qmldir
set(QT_QML_GENERATE_QMLDIR ON)

set(SOURCES
    src/main.cpp
    src/ui/pkg_unpacker.h
    src/ui/pkg_unpacker.cpp
    src/core/file_format/pkg.h
    src/core/file_format/pkg.cpp
    src/core/file_format/pkg_type.h
    src/core/file_format/pkg_type.cpp
    src/core/file_format/psf.h
    src/core/file_format/psf.cpp
    src/core/file_format/pfs.h
    src/core/file_format/trp.h
    src/core/file_format/trp.cpp
    src/core/crypto/crypto.h
    src/core/crypto/crypto.cpp
    src/core/crypto/keys.h
    src/common/io_file.h
    src/common/io_file.cpp
    src/common/path_util.h
    src/common/path_util.cpp
    src/common/error.h
    src/common/error.cpp
)

qt_add_executable(ps4pkgunpacker_bin ${SOURCES})

set_target_properties(ps4pkgunpacker_bin PROPERTIES OUTPUT_NAME "ps4pkgunpacker-tool")

qt_add_qml_module(ps4pkgunpacker_bin
    URI ps4pkgunpacker
    RESOURCE_PREFIX "/"
    QML_FILES src/ui/Main.qml
    NO_PLUGIN
    NO_GENERATE_PLUGIN_SOURCE
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/ps4pkgunpacker"
)

target_include_directories(ps4pkgunpacker_bin PRIVATE 
    src
)

target_link_libraries(ps4pkgunpacker_bin PRIVATE
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::Concurrent
    Qt6::Core5Compat
    ZLIB::ZLIB
    cryptopp
)

install(TARGETS ps4pkgunpacker_bin DESTINATION bin)
