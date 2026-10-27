#pragma once

#include "test_runner.h"

#include <QObject>

class QuiNativeFileDialogTest : public QObject
{
    Q_OBJECT

private slots:
    void instantiationAndAvailability();
    void safeExecutionUnderDontUseNativeDialogs();
};

REGISTER_TEST(QuiNativeFileDialogTest);
