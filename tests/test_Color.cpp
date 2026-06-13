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

