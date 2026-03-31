cmake_minimum_required(VERSION 3.20)
project(MediaHelper LANGUAGES C OBJC)

set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")

# Framework
add_library(MediaHelper SHARED
    src/MediaHelper.m
)

target_include_directories(MediaHelper PUBLIC include)

target_link_libraries(MediaHelper
    "-framework Foundation"
    "-framework CoreFoundation"
)

set_target_properties(MediaHelper PROPERTIES
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER art.yukosugita.mediahelper
    PUBLIC_HEADER "include/MediaHelper.h"
    INSTALL_RPATH "@loader_path/../Frameworks"
)
