#pragma once

#include "test_runner.h"

#include <QObject>

class FontTest : public QObject
{
    Q_OBJECT

private slots:
    void defaults();
};

REGISTER_TEST(FontTest);

