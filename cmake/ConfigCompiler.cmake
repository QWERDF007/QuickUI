set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(MSVC)
    add_compile_options(
        "$<$<COMPILE_LANGUAGE:CXX>:/utf-8>"
        "$<$<COMPILE_LANGUAGE:CXX>:/W4>"
        "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<BOOL:${WARNINGS_AS_ERRORS}>>:/WX>"
    )
    add_compile_definitions(NOMINMAX)
else()
    add_compile_options(
        "$<$<COMPILE_LANGUAGE:CXX>:-Wall>"
        "$<$<COMPILE_LANGUAGE:CXX>:-Wextra>"
        "$<$<COMPILE_LANGUAGE:CXX>:-Wpedantic>"
        "$<$<COMPILE_LANGUAGE:CXX>:-Wsuggest-override>"
        "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<BOOL:${WARNINGS_AS_ERRORS}>>:-Werror>"
    )
endif()

include(CheckIPOSupported)
check_ipo_supported(RESULT LTO_SUPPORTED OUTPUT LTO_ERROR)
set(LTO_ENABLED ON CACHE BOOL "Enable interprocedural optimization when supported")

if(ENABLE_SANITIZER AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(
        -fsanitize=address
        -fsanitize=undefined
        -fno-sanitize-recover=all
    )
    add_link_options(
        -fsanitize=address
        -fsanitize=undefined
        -fno-sanitize-recover=all
    )
endif()
