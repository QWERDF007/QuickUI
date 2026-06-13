#include "test_QmlRegistration.h"

#include "quickui/Color.h"
#include "quickui/Def.h"
#include "quickui/Font.h"
#include "quickui/IconsFont.h"

#include <QJSEngine>
#include <QMetaEnum>
#include <QQmlEngine>
#include <QtTest/QtTest>

void QmlRegistrationTest::singletonFactoryUsesCppOwnership()
{
    QQmlEngine engine;

    auto *color = quickui::QuiColor::create(&engine, &engine);
    QCOMPARE(color, quickui::QuiColor::getInstance());
    QCOMPARE(QJSEngine::objectOwnership(color), QJSEngine::CppOwnership);

    auto *font = quickui::QuiFont::create(&engine, &engine);
    QCOMPARE(font, quickui::QuiFont::getInstance());
    QCOMPARE(QJSEngine::objectOwnership(font), QJSEngine::CppOwnership);
}

void QmlRegistrationTest::enumMetaObjectsAreExported()
{
    const int buttonIndex = quickui::button::staticMetaObject.indexOfEnumerator("ButtonFlag");
    QVERIFY(buttonIndex >= 0);
    const QMetaEnum buttonEnum = quickui::button::staticMetaObject.enumerator(buttonIndex);
    QCOMPARE(buttonEnum.keyToValue("NeutralButton"), 0x0001);
    QCOMPARE(buttonEnum.keyToValue("NegativeButton"), 0x0002);
    QCOMPARE(buttonEnum.keyToValue("PositiveButton"), 0x0004);

    const int iconIndex = quickui::icon::staticMetaObject.indexOfEnumerator("FontIconType");
    QVERIFY(iconIndex >= 0);
    const QMetaEnum iconEnum = quickui::icon::staticMetaObject.enumerator(iconIndex);
    QCOMPARE(iconEnum.keyToValue("ChevronDown"), 0xe70d);
    QCOMPARE(iconEnum.keyToValue("Accept"), 0xe8fb);
}

