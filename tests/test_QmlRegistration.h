#pragma once

#include "test_runner.h"

#include <QObject>

class QmlRegistrationTest : public QObject
{
    Q_OBJECT

private slots:
    void singletonFactoryUsesCppOwnership();
    void enumMetaObjectsAreExported();
};

REGISTER_TEST(QmlRegistrationTest);

