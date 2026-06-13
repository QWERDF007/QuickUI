#pragma once

#include "test_runner.h"

#include <QObject>

class ColorTest : public QObject
{
    Q_OBJECT

private slots:
    void defaults();
    void changeSignalsAreValueSensitive();
};

REGISTER_TEST(ColorTest);

