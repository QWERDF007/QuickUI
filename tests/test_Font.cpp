#include "test_Font.h"

#include "quickui/Font.h"

#include <QtTest/QtTest>

void FontTest::defaults()
{
    auto *font = quickui::QuiFont::getInstance();
    QVERIFY(font != nullptr);

    QCOMPARE(font->Caption().pixelSize(), 12);
    QCOMPARE(font->Body().pixelSize(), 16);
    QCOMPARE(font->BodyStrong().pixelSize(), 16);
    QCOMPARE(font->BodyStrong().weight(), QFont::DemiBold);
    QCOMPARE(font->Subtitle().pixelSize(), 20);
    QCOMPARE(font->Title().pixelSize(), 28);
    QCOMPARE(font->TitleLarge().pixelSize(), 40);
    QCOMPARE(font->Display().pixelSize(), 68);
}

