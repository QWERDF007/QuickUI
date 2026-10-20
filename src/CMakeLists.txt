quickui_add_qml_plugin(
    TARGET quickui
    URI quickui
    VERSION 1.0
    PLUGIN_TARGET quickui
    CLASS_NAME QuickUiPlugin
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include"
    QML_DIR "${CMAKE_CURRENT_SOURCE_DIR}/controls"
    BUILD_IMPORT_DIR "${CMAKE_BINARY_DIR}/qml"
    QML_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/qml/quickui"
    INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/quickui"
    EXPORT_SET quickuiTargets
    CONFIG_TEMPLATE "${PROJECT_SOURCE_DIR}/cmake/quickuiConfig.cmake.in"
)

# The QML plugin loader resolves the shared plugin beside its qmldir. Keep the
# build-tree module self-contained instead of relying on an external copy.
if(WIN32 AND TARGET quickui AND QUICKUI_QML_OUTPUT_DIRECTORY)
    add_custom_command(TARGET quickui POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "$<TARGET_FILE:quickui>"
                "${QUICKUI_QML_OUTPUT_DIRECTORY}/quickui.dll"
        COMMENT "Copying quickui.dll beside its QML module")
endif()
