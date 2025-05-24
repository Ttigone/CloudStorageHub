#ifndef MANBUCKETS_H
#define MANBUCKETS_H

#include <QObject>
#include <QStandardItemModel>

#define IB InstanceBuckets::instance()

class InstanceBuckets : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStandardItemModel* model READ model NOTIFY modelChanged)
public:
    // 不要使用ManBuckets构造函数创建对象，直接使用instance来使用对象即可
    explicit InstanceBuckets(QObject* parent = nullptr);

    ///
    /// @brief instance
    /// @return
    /// 全局单例
    static InstanceBuckets* instance();

    QStandardItemModel* model() const;

    // 将 setBuckets 标记为 Q_INVOKABLE，使其可从 QML 调用
    Q_INVOKABLE void setBuckets();
    Q_INVOKABLE QVariant getBucketData(int row, int column) const;
    Q_INVOKABLE int bucketCount() const;
    Q_INVOKABLE QStringList getBucketNames() const;
    // 添加一个专门用于刷新的方法
    Q_INVOKABLE void refreshBuckets();

    // 在类声明中添加
    Q_INVOKABLE QString getToolTip(int row, int column) const;

signals:
    void modelChanged();

private:
    // 存储模型
    QStandardItemModel* m_model = nullptr;
};

#endif // MANBUCKETS_H
