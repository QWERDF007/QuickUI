#include "quickui/Color.h"

namespace quickui {

QuiColor::QuiColor(QObject *parent)
    : QObject(parent)
{
    applyDarkPalette();
}

QuiColor::~QuiColor() {}

void QuiColor::setThemeMode(ThemeMode mode)
{
    if (_themeMode == mode) {
        return;
    }
    _themeMode = mode;
    if (_themeMode == Light) {
        applyLightPalette();
    } else {
        applyDarkPalette();
    }
    emit themeModeChanged();
}

void QuiColor::toggleTheme()
{
    setThemeMode(_themeMode == Dark ? Light : Dark);
}

void QuiColor::applyDarkPalette()
{
    Transparent(QColor(0, 0, 0, 0));              // #000000
    Black(QColor(0, 0, 0, 255));                  // #000000
    White(QColor(255, 255, 255, 255));
    Background(QColor(48, 48, 48, 255));          // #303030
    WindowBackground(QColor(42, 42, 42, 255));
    WindowActiveBackground(QColor(48, 48, 48, 255));
    Primary(QColor(61, 61, 61, 255));             // #3D3D3D
    Border(QColor(62, 62, 62, 255));              // #3E3E3E
    ScrollBar(QColor(98, 98, 98, 255));           // #626262
    ScrollBarBackground(QColor(45, 45, 45, 255)); // #2D2D2D
    ToolTip(QColor(93, 93, 93, 255));             // #5D5D5D
    Hovered(QColor(95, 95, 95, 255));             // #5F5F5F
    Highlight(QColor("#009688"));
    FontPrimary(QColor(245, 245, 245, 255));
    FontDark(QColor(144, 144, 144, 255));         // #909090
    FontCaption(QColor(160, 160, 160, 255));
    TabButton(QColor(80, 80, 80, 255));           // #505050
    Button(QColor(80, 80, 80, 255));              // #505050
    ButtonShadow(QColor(72, 72, 72, 255));        // #484848
    Gray110(QColor(110, 110, 110, 255));          // #6E6E6E
    Divider(QColor(62, 62, 62, 255));
    ItemNormal(QColor(0, 0, 0, 0));
    ItemHover(QColor(255, 255, 255, 15));
    ItemPress(QColor(255, 255, 255, 25));
    ItemCheck(QColor(255, 255, 255, 35));
    ItemDisabled(QColor(80, 80, 80, 255));
    CardBackground(QColor(56, 56, 56, 255));       // #383838
    CardBorder(QColor(72, 72, 72, 255));           // #484848
    BadgeBackground(QColor(232, 17, 35, 255));     // #E81123
    BadgeText(QColor(255, 255, 255, 255));
}

void QuiColor::applyLightPalette()
{
    Transparent(QColor(0, 0, 0, 0));
    Black(QColor(0, 0, 0, 255));
    White(QColor(255, 255, 255, 255));
    Background(QColor(243, 243, 243, 255));       // #F3F3F3
    WindowBackground(QColor(237, 237, 237, 255)); // #EDEDED
    WindowActiveBackground(QColor(243, 243, 243, 255));
    Primary(QColor(0, 102, 180, 255));            // #0066B4
    Border(QColor(220, 220, 220, 255));           // #DCDCDC
    ScrollBar(QColor(176, 176, 176, 255));
    ScrollBarBackground(QColor(234, 234, 234, 255));
    ToolTip(QColor(255, 255, 255, 255));
    Hovered(QColor(0, 0, 0, 7));                  // 255 * 0.03
    Highlight(QColor(0, 102, 180, 255));          // #0066B4
    FontPrimary(QColor(7, 7, 7, 255));            // #070707
    FontDark(QColor(118, 118, 118, 255));         // #767676
    FontCaption(QColor(118, 118, 118, 255));
    TabButton(QColor(255, 255, 255, 255));
    Button(QColor(255, 255, 255, 255));           // #FFFFFF
    ButtonShadow(QColor(224, 224, 224, 255));     // #E0E0E0
    Gray110(QColor(138, 136, 134, 255));
    Divider(QColor(229, 229, 229, 255));
    ItemNormal(QColor(0, 0, 0, 0));
    ItemHover(QColor(0, 0, 0, 7));                // 255 * 0.03
    ItemPress(QColor(0, 0, 0, 15));               // 255 * 0.06
    ItemCheck(QColor(0, 0, 0, 22));               // 255 * 0.09
    ItemDisabled(QColor(225, 223, 221, 255));
    CardBackground(QColor(255, 255, 255, 255));   // #FFFFFF
    CardBorder(QColor(229, 229, 229, 255));       // #E5E5E5
    BadgeBackground(QColor(232, 17, 35, 255));     // #E81123
    BadgeText(QColor(255, 255, 255, 255));
}

} // namespace quickui
