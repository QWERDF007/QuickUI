#include "test_TableModels.h"

#include "quickui/QuiTableModel.h"
#include "quickui/QuiTableSortProxyModel.h"

#include <QJSEngine>
#include <QVariantMap>
#include <QtTest/QtTest>

static QVariantMap row(const QString &name, int age)
{
    return {{"name", name}, {"age", age}};
}

void TableModelsTest::rowColumnCounts()
{
    quickui::QuiTableModel model;
    model.setColumnSource({{{"dataIndex", "name"}}, {{"dataIndex", "age"}}});
    model.setRows({row("a", 1), row("b", 2)});

    QCOMPARE(model.rowCount(), 2);
    QCOMPARE(model.columnCount(), 2);
    QCOMPARE(model.rows().count(), 2);
    QCOMPARE(model.columnSource().count(), 2);

    model.clear();
    QCOMPARE(model.rowCount(), 0);
}

void TableModelsTest::roles()
{
    quickui::QuiTableModel model;
    model.setColumnSource({{{"dataIndex", "name"}}});
    model.setRows({row("a", 1), row("b", 2)});

    QHash<int, QByteArray> names = model.roleNames();
    QCOMPARE(names.value(quickui::QuiTableModel::RowModelRole), QByteArray("rowModel"));
    QCOMPARE(names.value(quickui::QuiTableModel::ColumnModelRole), QByteArray("columnModel"));

    const QVariant rowModel = model.data(model.index(0, 0), quickui::QuiTableModel::RowModelRole);
    QCOMPARE(rowModel.toMap().value("name").toString(), QString("a"));

    const QVariant columnModel = model.data(model.index(0, 0), quickui::QuiTableModel::ColumnModelRole);
    QCOMPARE(columnModel.toMap().value("dataIndex").toString(), QString("name"));

}

void TableModelsTest::rowOperations()
{
    quickui::QuiTableModel model;
    model.setRows({row("a", 1), row("b", 2)});

    model.setRow(0, row("c", 3));
    QCOMPARE(model.getRow(0).toMap().value("name").toString(), QString("c"));
    QCOMPARE(model.rowCount(), 2);

    model.insertRow(1, row("d", 4));
    QCOMPARE(model.rowCount(), 3);
    QCOMPARE(model.getRow(1).toMap().value("name").toString(), QString("d"));

    model.removeRow(1);
    QCOMPARE(model.rowCount(), 2);
    QCOMPARE(model.getRow(1).toMap().value("name").toString(), QString("b"));

    model.appendRow(row("e", 5));
    QCOMPARE(model.rowCount(), 3);

    // Out of bounds must not crash or modify data.
    model.getRow(-1);
    model.getRow(99);
    model.setRow(99, row("x", 0));
    model.removeRow(99);
    QCOMPARE(model.rowCount(), 3);
}

void TableModelsTest::sortAndFilter()
{
    quickui::QuiTableModel table;
    table.setColumnSource({{{"dataIndex", "name"}}, {{"dataIndex", "age"}}});
    table.setRows({row("a", 3), row("b", 1), row("c", 2)});

    quickui::QuiTableSortProxyModel proxy;
    proxy.setModel(QVariant::fromValue(static_cast<QObject *>(&table)));
    QCOMPARE(proxy.rowCount(), 3);

    QJSEngine engine;

    // Filter callback receives the source row index: keep rows 0 and 2.
    proxy.setFilter(engine.evaluate("(index) => index !== 1"));
    QCOMPARE(proxy.rowCount(), 2);
    QCOMPARE(proxy.getRow(0).toMap().value("name").toString(), QString("a"));
    QCOMPARE(proxy.getRow(1).toMap().value("name").toString(), QString("c"));
    proxy.setFilter(engine.evaluate("undefined"));
    QCOMPARE(proxy.rowCount(), 3);

    // Sort callback receives the source row indices.  The first comparator
    // call toggles the sort order, so (l, r) => l < r yields descending rows.
    proxy.setComparator(engine.evaluate("(l, r) => l < r"));
    QCOMPARE(proxy.rowCount(), 3);
    QCOMPARE(proxy.getRow(0).toMap().value("name").toString(), QString("c"));
    QCOMPARE(proxy.getRow(1).toMap().value("name").toString(), QString("b"));
    QCOMPARE(proxy.getRow(2).toMap().value("name").toString(), QString("a"));

    // Update and remove rows through the proxy.
    proxy.setRow(1, row("b", 9));
    QCOMPARE(proxy.getRow(1).toMap().value("age").toInt(), 9);
    proxy.removeRow(0);
    QCOMPARE(proxy.rowCount(), 2);

    proxy.setComparator(engine.evaluate("undefined"));
    proxy.setFilter(engine.evaluate("undefined"));
    QCOMPARE(proxy.rowCount(), 2);
}
