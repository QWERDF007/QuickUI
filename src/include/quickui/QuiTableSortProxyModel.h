#pragma once

#include "Export.h"
#include "quickui/QuiTableModel.h"

#include <QJSValue>
#include <QSortFilterProxyModel>
#include <QtQml>

namespace quickui {

/**
 * @brief 基于 JS 回调的表格排序/过滤代理模型。
 *
 * 包装 QuiTableModel。sort() 的 JS 比较器接收左右两个源模型行号，
 * filter() 的 JS 回调接收一个源模型行号，与 FluTableSortProxyModel 保持一致。
 */
class QUICKUI_EXPORT QuiTableSortProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QVariant model READ model WRITE setModel NOTIFY modelChanged FINAL)
    QML_NAMED_ELEMENT(QuiTableSortProxyModel)
public:
    explicit QuiTableSortProxyModel(QObject *parent = nullptr);

    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool filterAcceptsColumn(int source_column, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

    QVariant model() const;
    void setModel(const QVariant &model);

    Q_INVOKABLE QVariant getRow(int rowIndex) const;
    Q_INVOKABLE void setRow(int rowIndex, const QVariant &val);
    Q_INVOKABLE void insertRow(int rowIndex, const QVariant &val);
    Q_INVOKABLE void removeRow(int rowIndex, int rows = 1);
    Q_INVOKABLE void setComparator(const QJSValue &comparator);
    Q_INVOKABLE void setFilter(const QJSValue &filter);

signals:
    void modelChanged();

private:
    QJSValue filter_;
    QJSValue comparator_;
    QVariant model_;
};

} // namespace quickui
