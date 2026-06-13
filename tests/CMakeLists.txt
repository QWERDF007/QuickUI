set(QUICKUI_TEST_RUNTIME_DIR "${QUICKUI_QML_BUILD_IMPORT_DIR}/quickui")

function(quickui_add_test target)
    if(TARGET quickuiplugin)
        add_dependencies(${target} quickuiplugin)
    endif()

    set_target_properties(${target} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${QUICKUI_TEST_RUNTIME_DIR}"
    )

    foreach(config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
        set_target_properties(${target} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY_${config} "${QUICKUI_TEST_RUNTIME_DIR}"
        )
    endforeach()

    add_test(NAME ${target} COMMAND ${target})

    set(_test_env
        "QML2_IMPORT_PATH=${QUICKUI_QML_BUILD_IMPORT_DIR}"
        "QT_QUICK_CONTROLS_STYLE=Basic"
        "QSG_RHI_BACKEND=software"
    )
    set_tests_properties(${target} PROPERTIES ENVIRONMENT "${_test_env}")

    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.22)
        set(_env_mod "PATH=path_list_prepend:${QUICKUI_TEST_RUNTIME_DIR}")
        if(Qt6_ROOT)
            list(APPEND _env_mod "PATH=path_list_prepend:${Qt6_ROOT}/bin")
        endif()
        set_tests_properties(${target} PROPERTIES ENVIRONMENT_MODIFICATION "${_env_mod}")
    endif()
endfunction()

file(GLOB_RECURSE QUICKUI_TEST_HEADERS CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.hpp"
)

file(GLOB QUICKUI_CPP_TEST_CASE_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/test_*.cpp"
)

file(GLOB_RECURSE QUICKUI_QML_TEST_FILES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/qml/*.qml"
)
source_group("QML Tests" FILES ${QUICKUI_QML_TEST_FILES})

add_executable(tst_quickui_cpp
    tst_quickui_cpp.cpp
    ${QUICKUI_CPP_TEST_CASE_SOURCES}
    ${QUICKUI_TEST_HEADERS}
)
target_link_libraries(tst_quickui_cpp
    PRIVATE
        quickui::quickui
        Qt6::Test
        Qt6::Qml
)
quickui_add_test(tst_quickui_cpp)

add_executable(tst_quickui_qml
    tst_quickui_qml.cpp
    ${QUICKUI_QML_TEST_FILES}
)
target_compile_definitions(tst_quickui_qml
    PRIVATE QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml"
)
target_link_libraries(tst_quickui_qml
    PRIVATE
        quickui::quickui
        Qt6::QuickTest
        Qt6::Quick
)
quickui_add_test(tst_quickui_qml)
