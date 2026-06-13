#pragma once

#include "Export.h"

#include <QObject>
#include <QtQml>

#define Q_PROPERTY_AUTO(TYPE, M)                              \
    Q_PROPERTY(TYPE M READ M WRITE set##M NOTIFY M##Changed)  \
public:                                                       \
    Q_SIGNAL void M##Changed();                               \
                                                              \
    void set##M(const TYPE &in_##M)                           \
    {                                                         \
        if (_##M == in_##M) {                                 \
            return;                                           \
        }                                                     \
        _##M = in_##M;                                        \
        Q_EMIT M##Changed();                                  \
    }                                                         \
                                                              \
    void M(const TYPE &in_##M)                                \
    {                                                         \
        set##M(in_##M);                                       \
    }                                                         \
                                                              \
    TYPE M() const                                            \
    {                                                         \
        return _##M;                                          \
    }                                                         \
                                                              \
private:                                                      \
    TYPE _##M {};

namespace quickui { namespace button {
Q_NAMESPACE_EXPORT(QUICKUI_EXPORT)

enum ButtonFlag
{
    NeutralButton  = 0x0001,
    NegativeButton = 0x0002,
    PositiveButton = 0x0004
};
Q_ENUM_NS(ButtonFlag)
QML_NAMED_ELEMENT(QuiDialogButtonFlag)
}} // namespace quickui::button
