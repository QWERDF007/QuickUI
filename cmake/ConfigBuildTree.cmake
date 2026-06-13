set(CMAKE_DEBUG_POSTFIX "d")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

include(GNUInstallDirs)

if(EXISTS "${CMAKE_SOURCE_DIR}/.git" AND EXISTS "${CMAKE_SOURCE_DIR}/.gitmodules")
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.git/modules")
        message(FATAL_ERROR "git submodules are not initialized. Run: git submodule update --init")
    endif()
endif()

function(setup_dso target version)
    string(REGEX MATCHALL "[0-9]+" version_list "${version}")
    list(GET version_list 0 VERSION_MAJOR)

    set_target_properties(${target} PROPERTIES
        VERSION "${version}"
        SOVERSION "${VERSION_MAJOR}"
    )

    if(NOT MSVC)
        target_link_options(${target} PRIVATE
            -Wl,--exclude-libs,ALL
            -Wl,--no-undefined
            -Wl,--gc-sections
            -Wl,--as-needed
        )
        target_compile_options(${target} PRIVATE -ffunction-sections -fdata-sections)
        target_link_libraries(${target} PRIVATE -static-libstdc++ -static-libgcc)
        set_target_properties(${target} PROPERTIES
            VISIBILITY_INLINES_HIDDEN ON
            C_VISIBILITY_PRESET hidden
            CXX_VISIBILITY_PRESET hidden
        )
    endif()
endfunction()
