#pragma once

#include "Export.h"

#include <QAbstractTableModel>
#include <QVariantMap>
#include <QtQml>

namespace quickui {

/**
 * @brief QML 可用的表格式行-列数据模型。
 *
 * 以 QVariantMap 行列表的形式存储数据，并通过 rowModel/columnModel 两个角色
 * 向 QML 委托暴露整行与整列信息。columnSource 提供列描述（宽度、标题、
 * dataIndex、冻结、编辑委托等），dataIndex 用于把行数据字段映射到列。
 */
class QUICKUI_EXPORT QuiTableModel : public QAbstractTableModel
{
    Q_OBJECT
    Q_PROPERTY(QList<QVariantMap> columnSource READ columnSource WRITE setColumnSource NOTIFY columnSourceChanged FINAL)
    Q_PROPERTY(QList<QVariantMap> rows READ rows WRITE setRows NOTIFY rowsChanged FINAL)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowsChanged FINAL)
    QML_NAMED_ELEMENT(QuiTableModel)
public:
    enum TableModelRoles
    {
        RowModelRole    = 0x0101,
        ColumnModelRole = 0x0102,
    };
    Q_ENUM(TableModelRoles)

    explicit QuiTableModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QList<QVariantMap> columnSource() const;
    void setColumnSource(const QList<QVariantMap> &in_column_source);

    QList<QVariantMap> rows() const;
    void setRows(const QList<QVariantMap> &in_rows);

    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariant getRow(int rowIndex) const;
    Q_INVOKABLE void setRow(int rowIndex, const QVariant &row);
    Q_INVOKABLE void insertRow(int rowIndex, const QVariant &row);
    Q_INVOKABLE void removeRow(int rowIndex, int rows = 1);
    Q_INVOKABLE void appendRow(const QVariant &row);

signals:
    void columnSourceChanged();
    void rowsChanged();

private:
    QList<QVariantMap> column_source_;
    QList<QVariantMap> rows_;
};

} // namespace quickui
