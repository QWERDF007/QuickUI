#include "test_Color.h"

#include "quickui/Color.h"

#include <QSignalSpy>
#include <QtTest/QtTest>

void ColorTest::defaults()
{
    auto *color = quickui::QuiColor::getInstance();
    QVERIFY(color != nullptr);

    QCOMPARE(color->Transparent(), QColor(0, 0, 0, 0));
    QCOMPARE(color->Black(), QColor(0, 0, 0, 255));
    QCOMPARE(color->Background(), QColor(48, 48, 48, 255));
    QCOMPARE(color->Primary(), QColor(61, 61, 61, 255));
    QCOMPARE(color->Border(), QColor(62, 62, 62, 255));
    QCOMPARE(color->Highlight(), QColor("#009688"));
    QCOMPARE(color->FontPrimary(), QColor(245, 245, 245, 255));
    QCOMPARE(color->Gray110(), QColor(110, 110, 110, 255));
}

void ColorTest::changeSignalsAreValueSensitive()
{
    auto *color = quickui::QuiColor::getInstance();
    const QColor original = color->Highlight();
    const QColor changed = original == QColor("#123456") ? QColor("#654321") : QColor("#123456");

    QSignalSpy spy(color, &quickui::QuiColor::HighlightChanged);
    color->setHighlight(original);
    QCOMPARE(spy.count(), 0);

    color->setHighlight(changed);
    QCOMPARE(spy.count(), 1);
    QCOMPARE(color->Highlight(), changed);

    color->setHighlight(changed);
    QCOMPARE(spy.count(), 1);

    color->setHighlight(original);
    QCOMPARE(color->Highlight(), original);
}

void ColorTest::lightThemeColors()
{
    auto *color = quickui::QuiColor::getInstance();
    color->setThemeMode(quickui::QuiColor::Light);
    QCOMPARE(color->themeMode(), quickui::QuiColor::Light);
    QCOMPARE(color->Background(), QColor(243, 243, 243, 255));
    QCOMPARE(color->Primary(), QColor(0, 102, 180, 255));
    QCOMPARE(color->Highlight(), QColor(0, 102, 180, 255));
    QCOMPARE(color->FontPrimary(), QColor(7, 7, 7, 255));
    QCOMPARE(color->FontDark(), QColor(118, 118, 118, 255));
    QCOMPARE(color->Border(), QColor(220, 220, 220, 255));
    QCOMPARE(color->Button(), QColor(255, 255, 255, 255));
    QCOMPARE(color->CardBackground(), QColor(255, 255, 255, 255));
    QCOMPARE(color->CardBorder(), QColor(229, 229, 229, 255));
    QCOMPARE(color->BadgeBackground(), QColor(232, 17, 35, 255));
    QCOMPARE(color->BadgeText(), QColor(255, 255, 255, 255));
    QCOMPARE(color->ToolTip(), QColor(255, 255, 255, 255));

    // Reset back to Dark for subsequent tests
    color->setThemeMode(quickui::QuiColor::Dark);
    QCOMPARE(color->themeMode(), quickui::QuiColor::Dark);
    QCOMPARE(color->Background(), QColor(48, 48, 48, 255));
    QCOMPARE(color->CardBackground(), QColor(56, 56, 56, 255));
}

void ColorTest::themeModeSwitching()
{
    auto *color = quickui::QuiColor::getInstance();
    color->setThemeMode(quickui::QuiColor::Dark);

    QSignalSpy themeSpy(color, &quickui::QuiColor::themeModeChanged);
    QSignalSpy bgSpy(color, &quickui::QuiColor::BackgroundChanged);

    color->toggleTheme();
    QCOMPARE(color->themeMode(), quickui::QuiColor::Light);
    QCOMPARE(themeSpy.count(), 1);
    QCOMPARE(bgSpy.count(), 1);

    color->toggleTheme();
    QCOMPARE(color->themeMode(), quickui::QuiColor::Dark);
    QCOMPARE(themeSpy.count(), 2);
    QCOMPARE(bgSpy.count(), 2);
}

