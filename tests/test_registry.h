#pragma once

#include <QObject>

#include <functional>
#include <vector>

class TestRegistry
{
public:
    using Factory = std::function<QObject *()>;

    static TestRegistry &instance()
    {
        static TestRegistry registry;
        return registry;
    }

    void registerTest(const Factory &factory)
    {
        factories_.push_back(factory);
    }

    const std::vector<Factory> &tests() const
    {
        return factories_;
    }

private:
    std::vector<Factory> factories_;
};

