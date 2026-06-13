#pragma once

#include "Def.h"
#include "Export.h"
#include "Singleton.h"

#include <QColor>

namespace quickui {

class QUICKUI_EXPORT QuiColor : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(QuiColor)
    QT_QML_SINGLETON(QuiColor)
    Q_PROPERTY_AUTO(QColor, Transparent)
    Q_PROPERTY_AUTO(QColor, Black)
    Q_PROPERTY_AUTO(QColor, Background)
    Q_PROPERTY_AUTO(QColor, Primary)
    Q_PROPERTY_AUTO(QColor, Border)
    Q_PROPERTY_AUTO(QColor, ScrollBar)
    Q_PROPERTY_AUTO(QColor, ScrollBarBackground)
    Q_PROPERTY_AUTO(QColor, ToolTip)
    Q_PROPERTY_AUTO(QColor, Hovered)
    Q_PROPERTY_AUTO(QColor, Highlight)
    Q_PROPERTY_AUTO(QColor, FontPrimary)
    Q_PROPERTY_AUTO(QColor, FontDark)
    Q_PROPERTY_AUTO(QColor, TabButton)
    Q_PROPERTY_AUTO(QColor, Button)
    Q_PROPERTY_AUTO(QColor, ButtonShadow)
    Q_PROPERTY_AUTO(QColor, Gray110)
private:
    explicit QuiColor(QObject *parent = nullptr);
    ~QuiColor();
};

} // namespace quickui
