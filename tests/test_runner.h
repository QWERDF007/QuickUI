#pragma once

#include "test_registry.h"

#include <QTest>

#define REGISTER_TEST(TestClass)                                                      \
    namespace {                                                                       \
    struct TestClass##Registrator                                                     \
    {                                                                                 \
        TestClass##Registrator()                                                      \
        {                                                                             \
            TestRegistry::instance().registerTest([]() { return new TestClass; });    \
        }                                                                             \
    };                                                                                \
    static TestClass##Registrator _##TestClass##Registrator;                          \
    }

inline int runAllCppTests(int argc, char **argv)
{
    int result = 0;
    for (const auto &factory : TestRegistry::instance().tests()) {
        QObject *test = factory();
        result |= QTest::qExec(test, argc, argv);
        delete test;
    }
    return result;
}

