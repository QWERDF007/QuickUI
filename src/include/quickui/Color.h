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

public:
    enum ThemeMode
    {
        Dark  = 0,
        Light = 1
    };
    Q_ENUM(ThemeMode)

    Q_PROPERTY(ThemeMode themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)

    ThemeMode themeMode() const { return _themeMode; }
    Q_INVOKABLE void setThemeMode(ThemeMode mode);
    Q_INVOKABLE void toggleTheme();

signals:
    void themeModeChanged();

public:
    Q_PROPERTY_AUTO(QColor, Transparent)
    Q_PROPERTY_AUTO(QColor, Black)
    Q_PROPERTY_AUTO(QColor, White)
    Q_PROPERTY_AUTO(QColor, Background)
    Q_PROPERTY_AUTO(QColor, WindowBackground)
    Q_PROPERTY_AUTO(QColor, WindowActiveBackground)
    Q_PROPERTY_AUTO(QColor, Primary)
    Q_PROPERTY_AUTO(QColor, Border)
    Q_PROPERTY_AUTO(QColor, ScrollBar)
    Q_PROPERTY_AUTO(QColor, ScrollBarBackground)
    Q_PROPERTY_AUTO(QColor, ToolTip)
    Q_PROPERTY_AUTO(QColor, Hovered)
    Q_PROPERTY_AUTO(QColor, Highlight)
    Q_PROPERTY_AUTO(QColor, FontPrimary)
    Q_PROPERTY_AUTO(QColor, FontDark)
    Q_PROPERTY_AUTO(QColor, FontCaption)
    Q_PROPERTY_AUTO(QColor, TabButton)
    Q_PROPERTY_AUTO(QColor, Button)
    Q_PROPERTY_AUTO(QColor, ButtonShadow)
    Q_PROPERTY_AUTO(QColor, Gray110)
    Q_PROPERTY_AUTO(QColor, Divider)
    Q_PROPERTY_AUTO(QColor, ItemNormal)
    Q_PROPERTY_AUTO(QColor, ItemHover)
    Q_PROPERTY_AUTO(QColor, ItemPress)
    Q_PROPERTY_AUTO(QColor, ItemCheck)
    Q_PROPERTY_AUTO(QColor, ItemDisabled)
    Q_PROPERTY_AUTO(QColor, CardBackground)
    Q_PROPERTY_AUTO(QColor, CardBorder)
    Q_PROPERTY_AUTO(QColor, BadgeBackground)
    Q_PROPERTY_AUTO(QColor, BadgeText)

private:
    explicit QuiColor(QObject *parent = nullptr);
    ~QuiColor();

    void applyDarkPalette();
    void applyLightPalette();

    ThemeMode _themeMode { Dark };
};

} // namespace quickui
