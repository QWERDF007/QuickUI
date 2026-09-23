#pragma once

#include "test_runner.h"

#include <QObject>

class ColorTest : public QObject
{
    Q_OBJECT

private slots:
    void defaults();
    void changeSignalsAreValueSensitive();
    void lightThemeColors();
    void themeModeSwitching();
};

REGISTER_TEST(ColorTest);

