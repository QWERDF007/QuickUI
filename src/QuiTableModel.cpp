#include "quickui/QuiTableModel.h"

#include <algorithm>

namespace quickui {

QuiTableModel::QuiTableModel(QObject *parent)
    : QAbstractTableModel{parent}
{
}

int QuiTableModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return rows_.count();
}

int QuiTableModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return column_source_.count();
}

QVariant QuiTableModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rows_.count()) {
        return {};
    }
    switch (role) {
    case RowModelRole:
        return QVariant::fromValue(rows_.at(index.row()));
    case ColumnModelRole:
        if (index.column() >= 0 && index.column() < column_source_.count()) {
            return QVariant::fromValue(column_source_.at(index.column()));
        }
        return {};
    default:
        break;
    }
    return {};
}

QHash<int, QByteArray> QuiTableModel::roleNames() const
{
    return {
        {RowModelRole,    "rowModel"   },
        {ColumnModelRole, "columnModel"},
    };
}

QList<QVariantMap> QuiTableModel::columnSource() const
{
    return column_source_;
}

void QuiTableModel::setColumnSource(const QList<QVariantMap> &in_column_source)
{
    if (column_source_ == in_column_source) {
        return;
    }
    beginResetModel();
    column_source_ = in_column_source;
    endResetModel();
    Q_EMIT columnSourceChanged();
}

QList<QVariantMap> QuiTableModel::rows() const
{
    return rows_;
}

void QuiTableModel::setRows(const QList<QVariantMap> &in_rows)
{
    if (rows_ == in_rows) {
        return;
    }
    beginResetModel();
    rows_ = in_rows;
    endResetModel();
    Q_EMIT rowsChanged();
}

void QuiTableModel::clear()
{
    setRows({});
}

QVariant QuiTableModel::getRow(int rowIndex) const
{
    if (rowIndex < 0 || rowIndex >= rows_.count()) {
        return {};
    }
    return QVariant::fromValue(rows_.at(rowIndex));
}

void QuiTableModel::setRow(int rowIndex, const QVariant &row)
{
    if (rowIndex < 0 || rowIndex >= rows_.count()) {
        return;
    }
    rows_[rowIndex] = row.toMap();
    Q_EMIT dataChanged(index(rowIndex, 0), index(rowIndex, std::max(0, columnCount() - 1)));
}

void QuiTableModel::insertRow(int rowIndex, const QVariant &row)
{
    if (rowIndex < 0 || rowIndex > rows_.count()) {
        return;
    }
    beginInsertRows({}, rowIndex, rowIndex);
    rows_.insert(rowIndex, row.toMap());
    endInsertRows();
    Q_EMIT rowsChanged();
}

void QuiTableModel::removeRow(int rowIndex, int rows)
{
    if (rowIndex < 0 || rowIndex >= rows_.count() || rows <= 0) {
        return;
    }
    const int count = static_cast<int>(rows_.count());
    const int last  = std::min(rowIndex + rows - 1, count - 1);
    beginRemoveRows({}, rowIndex, last);
    rows_.erase(rows_.begin() + rowIndex, rows_.begin() + last + 1);
    endRemoveRows();
    Q_EMIT rowsChanged();
}

void QuiTableModel::appendRow(const QVariant &row)
{
    insertRow(rows_.count(), row);
}

} // namespace quickui
