////filepath: f:\MyProject\CloudStorageHub\source\middle\models\PaginationProxyModel.h
#ifndef PAGINATIONPROXYMODEL_H
#define PAGINATIONPROXYMODEL_H

#include <QAbstractProxyModel>
// #include <QQmlEngine>

class PaginationProxyModel : public QAbstractProxyModel
{
    Q_OBJECT
    // QML_ELEMENT

    // 暴露给QML的属性
    Q_PROPERTY(int currentPage READ currentPage WRITE setCurrentPage NOTIFY currentPageChanged)
    Q_PROPERTY(int rowsPerPage READ rowsPerPage WRITE setRowsPerPage NOTIFY rowsPerPageChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int pageCount READ pageCount NOTIFY pageCountChanged)
    Q_PROPERTY(int currentPageRowCount READ currentPageRowCount NOTIFY currentPageRowCountChanged)


public:
    explicit PaginationProxyModel(QObject* parent = nullptr);

    // 设置源模型
    void setSourceModel(QAbstractItemModel* sourceModel) override;

    // 索引映射方法 (必须实现)
    QModelIndex mapToSource(const QModelIndex& proxyIndex) const override;
    QModelIndex mapFromSource(const QModelIndex& sourceIndex) const override;

    // 数据访问方法 (必须实现)
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex& child) const override;

    // 获取属性值
    int currentPage() const;
    int rowsPerPage() const;
    int totalCount() const;
    int pageCount() const;

    // 在 public 部分添加方法
  int currentPageRowCount() const { return rowCount(); }

    // QML方法
    Q_INVOKABLE bool goToPage(int page);
    Q_INVOKABLE QVariantMap getRow(int row) const;
    Q_INVOKABLE void updateTotalCount();

public slots:
    Q_INVOKABLE void setCurrentPage(int page);
    Q_INVOKABLE void setRowsPerPage(int count);

signals:
    void currentPageChanged();
    void rowsPerPageChanged();
    void totalCountChanged();
    void pageCountChanged();
    // void dataChanged();
    void paginationDataChanged();
    void currentPageRowCountChanged();

private:
    void handleSourceModelDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight, const QVector<int>& roles);
    void handleSourceModelReset();
    void handleSourceModelRowsInserted(const QModelIndex& parent, int first, int last);
    void handleSourceModelRowsRemoved(const QModelIndex& parent, int first, int last);

    // 计算源模型行索引
    int proxyRowToSourceRow(int proxyRow) const;

    int m_currentPage = 1;
    int m_rowsPerPage = 20;
    int m_totalCount = 0;
};

#endif // PAGINATIONPROXYMODEL_H
