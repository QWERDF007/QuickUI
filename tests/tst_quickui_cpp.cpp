#include "test_runner.h"

#include <QGuiApplication>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    return runAllCppTests(argc, argv);
}

