#pragma once

#include "test_runner.h"

#include <QObject>

class TableModelsTest : public QObject
{
    Q_OBJECT

private slots:
    void rowColumnCounts();
    void roles();
    void rowOperations();
    void sortAndFilter();
};

REGISTER_TEST(TableModelsTest);
