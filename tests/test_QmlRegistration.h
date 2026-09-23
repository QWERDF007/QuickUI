#pragma once

#include "test_runner.h"

#include <QObject>

class QmlRegistrationTest : public QObject
{
    Q_OBJECT

private slots:
    void singletonFactoryUsesCppOwnership();
    void enumMetaObjectsAreExported();
    void componentsCanBeInstantiated();
};

REGISTER_TEST(QmlRegistrationTest);

