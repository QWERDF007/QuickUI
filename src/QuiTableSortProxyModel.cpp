#include "quickui/QuiTableSortProxyModel.h"

#include <QJSValueList>

namespace quickui {

QuiTableSortProxyModel::QuiTableSortProxyModel(QObject *parent)
    : QSortFilterProxyModel{parent}
{
    connect(this, &QuiTableSortProxyModel::modelChanged, this,
            [this] { setSourceModel(model_.value<QAbstractItemModel *>()); });
}

bool QuiTableSortProxyModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    Q_UNUSED(source_parent)
    const QJSValue filter = filter_;
    if (filter.isUndefined()) {
        return true;
    }
    QJSValueList data;
    data << source_row;
    return filter.call(data).toBool();
}

bool QuiTableSortProxyModel::filterAcceptsColumn(int source_column, const QModelIndex &source_parent) const
{
    Q_UNUSED(source_column)
    Q_UNUSED(source_parent)
    return true;
}

bool QuiTableSortProxyModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    const QJSValue comparator = comparator_;
    if (comparator.isUndefined()) {
        return true;
    }
    QJSValueList data;
    data << source_left.row();
    data << source_right.row();
    const bool flag = comparator.call(data).toBool();
    if (sortOrder() == Qt::AscendingOrder) {
        return !flag;
    }
    return flag;
}

QVariant QuiTableSortProxyModel::model() const
{
    return model_;
}

void QuiTableSortProxyModel::setModel(const QVariant &in_model)
{
    if (model_ == in_model) {
        return;
    }
    model_ = in_model;
    Q_EMIT modelChanged();
}

QVariant QuiTableSortProxyModel::getRow(int rowIndex) const
{
    if (rowIndex < 0 || rowIndex >= rowCount()) {
        return {};
    }
    const QModelIndex proxy_index = index(rowIndex, 0);
    if (!proxy_index.isValid()) {
        return {};
    }
    const QModelIndex source_index = mapToSource(proxy_index);
    if (!source_index.isValid()) {
        return {};
    }
    if (const auto *table_model = qobject_cast<const QuiTableModel *>(sourceModel())) {
        return table_model->getRow(source_index.row());
    }
    return QVariant();
}

void QuiTableSortProxyModel::setRow(int rowIndex, const QVariant &val)
{
    if (rowIndex < 0 || rowIndex >= rowCount()) {
        return;
    }
    const QModelIndex source_index = mapToSource(index(rowIndex, 0));
    if (!source_index.isValid()) {
        return;
    }
    if (auto *table_model = qobject_cast<QuiTableModel *>(sourceModel())) {
        table_model->setRow(source_index.row(), val);
    }
}

void QuiTableSortProxyModel::insertRow(int rowIndex, const QVariant &val)
{
    if (auto *table_model = qobject_cast<QuiTableModel *>(sourceModel())) {
        table_model->insertRow(rowIndex, val);
    }
}

void QuiTableSortProxyModel::removeRow(int rowIndex, int rows)
{
    if (rowIndex < 0 || rowIndex >= rowCount()) {
        return;
    }
    const QModelIndex source_index = mapToSource(index(rowIndex, 0));
    if (!source_index.isValid()) {
        return;
    }
    if (auto *table_model = qobject_cast<QuiTableModel *>(sourceModel())) {
        table_model->removeRow(source_index.row(), rows);
    }
}

void QuiTableSortProxyModel::setComparator(const QJSValue &comparator)
{
    comparator_ = comparator;
    const int column = comparator.isCallable() ? 0 : -1;
    if (sortOrder() == Qt::AscendingOrder) {
        sort(column, Qt::DescendingOrder);
    } else {
        sort(column, Qt::AscendingOrder);
    }
}

void QuiTableSortProxyModel::setFilter(const QJSValue &filter)
{
    filter_ = filter;
    invalidateFilter();
}

} // namespace quickui
