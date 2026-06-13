#pragma once

#include <QtCore/QtGlobal>

#if defined(QUICKUI_STATIC_LIBRARY)
#    define QUICKUI_EXPORT
#elif defined(QUICKUI_BUILD_LIBRARY)
#    define QUICKUI_EXPORT Q_DECL_EXPORT
#else
#    define QUICKUI_EXPORT Q_DECL_IMPORT
#endif

