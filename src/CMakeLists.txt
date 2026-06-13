quickui_add_qml_plugin(
    TARGET quickui
    URI quickui
    VERSION 1.0
    PLUGIN_TARGET quickuiplugin
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
