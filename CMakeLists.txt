cmake_minimum_required(VERSION 3.18)

project(quickui
    LANGUAGES CXX
    VERSION 0.0.1
    DESCRIPTION "Qt Quick UI component library"
)


# 如果用户没指定安装前缀
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}" CACHE PATH "where ${PROJECT_NAME} will be installed" FORCE)
endif()

option(QUICKUI_BUILD_TESTS "Enable testsuite" OFF)
option(QUICKUI_BUILD_DOCS "Build docs" OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(ConfigBuildTree)
include(ConfigCompiler)
include(ConfigQT)
include(AddPlugin)

add_subdirectory(src)

if(QUICKUI_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

message(STATUS "")
include(PrintConfig)
