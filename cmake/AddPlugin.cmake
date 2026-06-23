include(CMakePackageConfigHelpers)

function(_quickui_set_output_directories target runtime_dir library_dir archive_dir)
    set_target_properties(${target} PROPERTIES
        DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}"
        RUNTIME_OUTPUT_DIRECTORY "${runtime_dir}"
        LIBRARY_OUTPUT_DIRECTORY "${library_dir}"
        ARCHIVE_OUTPUT_DIRECTORY "${archive_dir}"
    )

    foreach(config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
        set_target_properties(${target} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY_${config} "${runtime_dir}"
            LIBRARY_OUTPUT_DIRECTORY_${config} "${library_dir}"
            ARCHIVE_OUTPUT_DIRECTORY_${config} "${archive_dir}"
        )
    endforeach()
endfunction()

function(quickui_add_qml_plugin)
    set(options STATIC)
    set(oneValueArgs
        TARGET
        URI
        VERSION
        PLUGIN_TARGET
        CLASS_NAME
        SOURCE_DIR
        INCLUDE_DIR
        QML_DIR
        BUILD_IMPORT_DIR
        QML_INSTALL_DIR
        INSTALL_CMAKEDIR
        EXPORT_SET
        CONFIG_TEMPLATE
    )
    set(multiValueArgs PUBLIC_LIBS PRIVATE_LIBS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_TARGET)
        message(FATAL_ERROR "quickui_add_qml_plugin requires TARGET")
    endif()
    if(NOT ARG_URI)
        set(ARG_URI "${ARG_TARGET}")
    endif()
    if(NOT ARG_VERSION)
        set(ARG_VERSION 1.0)
    endif()
    if(NOT ARG_PLUGIN_TARGET)
        set(ARG_PLUGIN_TARGET "${ARG_TARGET}plugin")
    endif()
    if(NOT ARG_SOURCE_DIR)
        set(ARG_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    if(NOT ARG_INCLUDE_DIR)
        set(ARG_INCLUDE_DIR "${ARG_SOURCE_DIR}/include")
    endif()
    if(NOT ARG_QML_DIR)
        set(ARG_QML_DIR "${ARG_SOURCE_DIR}/controls")
    endif()
    if(NOT ARG_BUILD_IMPORT_DIR)
        set(ARG_BUILD_IMPORT_DIR "${CMAKE_BINARY_DIR}/qml")
    endif()
    if(NOT ARG_EXPORT_SET)
        set(ARG_EXPORT_SET "${ARG_TARGET}Targets")
    endif()
    if(NOT ARG_INSTALL_CMAKEDIR)
        set(ARG_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${ARG_TARGET}")
    endif()
    if(NOT ARG_CONFIG_TEMPLATE)
        set(ARG_CONFIG_TEMPLATE "${PROJECT_SOURCE_DIR}/cmake/${ARG_TARGET}Config.cmake.in")
    endif()

    string(REPLACE "." "/" _qml_uri_path "${ARG_URI}")
    set(_qml_output_dir "${ARG_BUILD_IMPORT_DIR}/${_qml_uri_path}")

    if(NOT ARG_QML_INSTALL_DIR)
        set(ARG_QML_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/qml/${_qml_uri_path}")
    endif()

    set(QUICKUI_QML_BUILD_IMPORT_DIR "${ARG_BUILD_IMPORT_DIR}" CACHE INTERNAL "QuickUI build-tree QML import root")
    set(QUICKUI_QML_OUTPUT_DIRECTORY "${_qml_output_dir}" CACHE INTERNAL "QuickUI build-tree QML module directory")
    set(QUICKUI_QML_INSTALL_DIR "${ARG_QML_INSTALL_DIR}" CACHE STRING "QuickUI QML install directory")
    set(QUICKUI_INSTALL_CMAKEDIR "${ARG_INSTALL_CMAKEDIR}" CACHE STRING "QuickUI CMake package install directory")

    file(GLOB_RECURSE _public_headers CONFIGURE_DEPENDS
        "${ARG_INCLUDE_DIR}/*.h"
        "${ARG_INCLUDE_DIR}/*.hpp"
    )

    file(GLOB_RECURSE _sources CONFIGURE_DEPENDS
        "${ARG_SOURCE_DIR}/*.cpp"
        "${ARG_SOURCE_DIR}/*.cxx"
        "${ARG_SOURCE_DIR}/*.cc"
    )

    file(GLOB_RECURSE _qml_files CONFIGURE_DEPENDS
        "${ARG_QML_DIR}/*.qml"
    )

    foreach(_qml_file IN LISTS _qml_files)
        get_filename_component(_qml_alias "${_qml_file}" NAME)
        set_source_files_properties("${_qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${_qml_alias}")

        file(READ "${_qml_file}" _qml_contents)
        if(_qml_contents MATCHES "(^|[\r\n])[ \t]*pragma[ \t]+Singleton")
            set_source_files_properties("${_qml_file}" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
        endif()
    endforeach()

    if(_sources OR _public_headers OR _qml_files)
        source_group(TREE "${ARG_SOURCE_DIR}" FILES ${_sources} ${_public_headers} ${_qml_files})
    endif()

    if(ARG_STATIC)
        qt_add_library(${ARG_TARGET} STATIC)
    else()
        qt_add_library(${ARG_TARGET} SHARED)
    endif()

    qt_add_qml_module(${ARG_TARGET}
        URI ${ARG_URI}
        VERSION ${ARG_VERSION}
        PLUGIN_TARGET ${ARG_PLUGIN_TARGET}
        CLASS_NAME ${ARG_CLASS_NAME}
        OUTPUT_DIRECTORY "${_qml_output_dir}"
        RESOURCE_PREFIX /qt/qml
        QML_FILES ${_qml_files}
        SOURCES ${_sources} ${_public_headers}
    )

    if(NOT TARGET ${PROJECT_NAME}::${ARG_TARGET})
        add_library(${PROJECT_NAME}::${ARG_TARGET} ALIAS ${ARG_TARGET})
    endif()

    if(ARG_STATIC)
        target_compile_definitions(${ARG_TARGET} PUBLIC QUICKUI_STATIC_LIBRARY)
    else()
        target_compile_definitions(${ARG_TARGET} PRIVATE QUICKUI_BUILD_LIBRARY)
    endif()

    target_include_directories(${ARG_TARGET}
        PUBLIC
            $<BUILD_INTERFACE:${ARG_INCLUDE_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    target_link_libraries(${ARG_TARGET}
        PUBLIC
            Qt6::Core
            Qt6::Gui
            Qt6::Qml
            Qt6::Quick
            ${ARG_PUBLIC_LIBS}
        PRIVATE
            Qt6::QuickControls2
            ${ARG_PRIVATE_LIBS}
    )

    set(_runtime_output_dir "${CMAKE_BINARY_DIR}/bin")
    set(_plugin_library_output_dir "${_qml_output_dir}")
    if(WIN32)
        set(_plugin_library_output_dir "${_runtime_output_dir}")
    endif()

    _quickui_set_output_directories(${ARG_TARGET} "${_runtime_output_dir}" "${_qml_output_dir}" "${CMAKE_BINARY_DIR}/lib")
    if(TARGET ${ARG_PLUGIN_TARGET})
        _quickui_set_output_directories(${ARG_PLUGIN_TARGET} "${_runtime_output_dir}" "${_plugin_library_output_dir}" "${CMAKE_BINARY_DIR}/lib")
    endif()

    if(COMMAND setup_dso)
        setup_dso(${ARG_TARGET} "${PROJECT_VERSION}")
    endif()

    set(_install_targets ${ARG_TARGET})
    if(TARGET ${ARG_PLUGIN_TARGET} AND NOT ARG_PLUGIN_TARGET STREQUAL ARG_TARGET)
        list(APPEND _install_targets ${ARG_PLUGIN_TARGET})
    endif()

    install(TARGETS ${_install_targets}
        EXPORT ${ARG_EXPORT_SET}
        RUNTIME DESTINATION "${ARG_QML_INSTALL_DIR}"
        LIBRARY DESTINATION "${ARG_QML_INSTALL_DIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    )

    install(DIRECTORY "${ARG_INCLUDE_DIR}/${ARG_TARGET}"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )

    install(DIRECTORY "${_qml_output_dir}/"
        DESTINATION "${ARG_QML_INSTALL_DIR}"
        FILES_MATCHING
            PATTERN "qmldir"
            PATTERN "*.qml"
            PATTERN "*.js"
            PATTERN "*.qmltypes"
            PATTERN "*.metatypes"
    )

    install(EXPORT ${ARG_EXPORT_SET}
        FILE "${ARG_TARGET}Targets.cmake"
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION "${ARG_INSTALL_CMAKEDIR}"
    )

    configure_package_config_file(
        "${ARG_CONFIG_TEMPLATE}"
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}Config.cmake"
        INSTALL_DESTINATION "${ARG_INSTALL_CMAKEDIR}"
    )

    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}ConfigVersion.cmake"
        VERSION "${PROJECT_VERSION}"
        COMPATIBILITY SameMajorVersion
    )

    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}ConfigVersion.cmake"
        DESTINATION "${ARG_INSTALL_CMAKEDIR}"
    )
endfunction()
