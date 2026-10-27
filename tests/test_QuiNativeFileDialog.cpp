#include "test_QuiNativeFileDialog.h"

#include "quickui/QuiNativeFileDialog.h"

#include <QCoreApplication>
#include <QScopeGuard>
#include <QtTest/QtTest>

void QuiNativeFileDialogTest::instantiationAndAvailability()
{
    quickui::QuiNativeFileDialog picker;
    const bool wasDontUse = QCoreApplication::testAttribute(Qt::AA_DontUseNativeDialogs);

    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
    QCOMPARE(picker.isAvailable(), false);

#ifdef Q_OS_WIN
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs, false);
    QCOMPARE(picker.isAvailable(), true);
#else
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs, false);
    QCOMPARE(picker.isAvailable(), false);
#endif

    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs, wasDontUse);
}

void QuiNativeFileDialogTest::safeExecutionUnderDontUseNativeDialogs()
{
    const bool wasDontUse = QCoreApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
    const auto restore = qScopeGuard([&] {
        QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs, wasDontUse);
    });

    QCoreApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
    quickui::QuiNativeFileDialog picker;

    // In automated/headless environments with DontUseNativeDialogs set,
    // calls should return empty immediately instead of blocking the thread.
    QCOMPARE(picker.chooseFileOrFolder(QStringLiteral("测试"), QStringLiteral("C:/")), QString{});
    QCOMPARE(picker.chooseFile(QStringLiteral("测试"), QStringLiteral("C:/")), QString{});
    QCOMPARE(picker.chooseFolder(QStringLiteral("测试"), QStringLiteral("C:/")), QString{});
}
