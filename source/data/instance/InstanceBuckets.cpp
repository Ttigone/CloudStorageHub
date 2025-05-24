#include "InstanceBuckets.h"
#include "data/import/buckets.h"

Q_GLOBAL_STATIC(InstanceBuckets, ins)

InstanceBuckets::InstanceBuckets(QObject* parent) : QObject{parent}
{
    m_model = new QStandardItemModel(this);
}

InstanceBuckets* InstanceBuckets::instance() { return ins(); }

void InstanceBuckets::setBuckets()
{
    ImportBuckets dao;
    QList<TtBucket> buckets = dao.bucketsFromMock(":/testing/buckets1.json");
    // 行数对应个数
    m_model->setRowCount(buckets.size());
    // 3 列
    m_model->setColumnCount(3);
    for (int i = 0; i < buckets.size(); ++i) {
        const TtBucket& bucket = buckets[i];
        QModelIndex index0 = m_model->index(i, 0);
        m_model->setData(index0, bucket.name);
        m_model->setData(index0, QString("存储桶名称：%1").arg(bucket.name),
                         Qt::ToolTipRole);

        QModelIndex index1 = m_model->index(i, 1);
        m_model->setData(index1, bucket.location);

        QModelIndex index2 = m_model->index(i, 2);
        m_model->setData(index2, bucket.createDate);
    }

    qDebug() << "setBuckets";
}

QStandardItemModel* InstanceBuckets::model() const { return m_model; }


// 添加新的辅助方法实现

QVariant InstanceBuckets::getBucketData(int row, int column) const
{
    if (!m_model || row < 0 || row >= m_model->rowCount() || column < 0 || column >= m_model->columnCount()) {
        return QVariant();
    }

    return m_model->data(m_model->index(row, column));
}

int InstanceBuckets::bucketCount() const
{
    return m_model ? m_model->rowCount() : 0;
}

QStringList InstanceBuckets::getBucketNames() const
{
    QStringList names;
    if (!m_model) {
        return names;
    }

    for (int i = 0; i < m_model->rowCount(); ++i) {
        names << m_model->data(m_model->index(i, 0)).toString();
    }

    return names;
}


// 添加一个新的刷新方法实现
void InstanceBuckets::refreshBuckets()
{
    // 清除当前模型数据
    if (m_model) {
        m_model->clear();

        // 重新设置列标题
        QStringList headers;
        headers << "Name"
                << "Location"
                << "CreationDate";
        m_model->setHorizontalHeaderLabels(headers);
    }

    // 重新加载数据
    setBuckets();

    // 确保发送信号
    emit modelChanged();

    qDebug() << "Buckets refreshed, total:" << (m_model ? m_model->rowCount() : 0);
}

// 实现方法
QString InstanceBuckets::getToolTip(int row, int column) const
{
    if (!m_model || row < 0 || row >= m_model->rowCount() || column < 0 || column >= m_model->columnCount()) {
        return QString();
    }

    return m_model->data(m_model->index(row, column), Qt::ToolTipRole).toString();
}

bool InstanceBuckets::updateBucketName(int row, const QString& newName)
{
    if (!m_model || row < 0 || row >= m_model->rowCount()) {
        return false;
    }

    // 更新模型中的名称
    QModelIndex index = m_model->index(row, 0);
    // 这里更新了数据, 但是没有写到本地
    bool success = m_model->setData(index, newName);

    // 如果成功，同时更新工具提示
    if (success) {
        m_model->setData(index, QString("存储桶名称：%1").arg(newName), Qt::ToolTipRole);
        emit modelChanged();
    }

    return success;
}