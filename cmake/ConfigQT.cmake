set(_quickui_default_qt_root "E:/Softwares/Qt/6.11.0/msvc2022_64")
if(EXISTS "${_quickui_default_qt_root}" AND NOT DEFINED QUICKUI_QT_ROOT)
    set(QUICKUI_QT_ROOT "${_quickui_default_qt_root}" CACHE PATH "Optional Qt installation prefix")
else()
    set(QUICKUI_QT_ROOT "" CACHE PATH "Optional Qt installation prefix")
endif()
unset(_quickui_default_qt_root)

if(QUICKUI_QT_ROOT)
    list(PREPEND CMAKE_PREFIX_PATH "${QUICKUI_QT_ROOT}")
    set(Qt6_ROOT "${QUICKUI_QT_ROOT}")
    set(QT_QML_IMPORT_DIR "${QUICKUI_QT_ROOT}/qml")
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

if(QUICKUI_BUILD_TESTS)
    find_package(Qt6 REQUIRED COMPONENTS Test QuickTest)
endif()

qt_standard_project_setup(REQUIRES 6.5)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

qt_policy(SET QTP0001 NEW)
if(Qt6_VERSION VERSION_GREATER_EQUAL 6.8.0)
    qt_policy(SET QTP0004 NEW)
    qt_policy(SET QTP0005 NEW)
endif()

list(APPEND QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/qml")
if(QT_QML_IMPORT_DIR)
    list(APPEND QML_IMPORT_PATH "${QT_QML_IMPORT_DIR}")
endif()
list(REMOVE_DUPLICATES QML_IMPORT_PATH)
set(QML_IMPORT_PATH "${QML_IMPORT_PATH}" CACHE STRING "QML import paths" FORCE)
