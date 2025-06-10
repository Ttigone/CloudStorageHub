#include "managermodel.h"
#include "config/global.h"
#include "data/clouds/baseclouds.h"
#include "helper/bytehelper.h"
#include "middle/managerglobal.h"
#include "middle/models/cloudmodels.h"
#include "middle/signals/managersignals.h"
#include "plugin/TtPlugin.h"

ManagerModels::ManagerModels(QObject* parent) : QObject{parent}
{
    m_modelBuckets = new QStandardItemModel(this);
    m_modelObjects = new QStandardItemModel(this);
    initBucketsTable();
    initObjectsTable();
}

ManagerModels::~ManagerModels() { qDebug() << __FUNCTION__; }

QStandardItemModel* ManagerModels::modelBuckets() const
{
    return m_modelBuckets;
}

QStandardItemModel* ManagerModels::modelObjects() const
{
    return m_modelObjects;
}

void ManagerModels::setBuckets(const QList<TtBucket>& buckets)
{
    qDebug() << "reces bucket";
    // 设置行数
    m_modelBuckets->setRowCount(buckets.size());

    // 桶模型
    for (int i = 0; i < buckets.size(); i++) {
        const TtBucket& bucket = buckets[i];
        QModelIndex index0 = m_modelBuckets->index(i, 0);
        m_modelBuckets->setData(index0, bucket.name);
        // 可以使鼠标放到该数据上显示提示信息
        m_modelBuckets->setData(
            index0, QString::fromLocal8Bit("存储桶名称： %1").arg(bucket.name),
            Qt::ToolTipRole);
        // 设置图标
        // m_modelBuckets->setData(index0, QIcon(GLOBAL::PATH::BUCKET),
        //                         Qt::DecorationRole);
        // m_modelBuckets->setData(index0, QIcon(), Qt::DecorationRole);

        QModelIndex index1 = m_modelBuckets->index(i, 1); // 设置行列数
        m_modelBuckets->setData(index1,
                                bucket.location); // 行列数和数据内容

        QModelIndex index2 = m_modelBuckets->index(i, 2);
        m_modelBuckets->setData(index2, bucket.createDate);
    }
    // 默认按时间倒序排序
    m_modelBuckets->sort(2, Qt::DescendingOrder);
}

void ManagerModels::setObjects(const QList<TtObject>& objects)
{
    // BUG 设置对象 模型数据
    m_modelObjects->setRowCount(objects.size());
    for (int i = 0; i < objects.size(); ++i) {
        const TtObject& obj = objects[i];
        QModelIndex index0 = m_modelObjects->index(i, 0);
        // qDebug() << "set name" << obj.name;
        m_modelObjects->setData(index0, obj.name);

        // 路径使用, 每个都是一个自桶名后的完整路径, 如何根据之前的路径进行拼接呢?
        // 使用 UserRole 保存额外信息
        QVariantMap userData;
        userData["isFolder"] = obj.isDir();          // 标记是否为文件夹(bool 值)
        userData["key"] = obj.key;                   // 路径
        userData["size"] = obj.size;                 // 大小
        userData["lastModified"] = obj.lastmodified; // 最后修改的时间
        // 将整个 userData 作为 UserRole 数据附加到模型项
        m_modelObjects->setData(index0, QVariant::fromValue(userData),
                                Qt::UserRole);

        // 第一列
        // 大小
        QModelIndex index1 = m_modelObjects->index(i, 1);
        QString sizeStr = ByteHelper::toBeautifulStr(obj.size);
        // qDebug() << "size: " << sizeStr;
        m_modelObjects->setData(index1, sizeStr);
        // 第二列
        // 修改时间
        QModelIndex index2 = m_modelObjects->index(i, 2);
        // qDebug() << "modified: " << obj.lastmodified;
        m_modelObjects->setData(index2, obj.lastmodified);

        QModelIndex index3 = m_modelObjects->index(i, 3);
        if (obj.isDir()) {
            m_modelObjects->setData(index3, "");
        } else {
            // 给出的下载名
            // qDebug() << "set download name" << obj.name;
            m_modelObjects->setData(index3, obj.name);
        }
    }
}

void ManagerModels::initBucketsTable()
{
    QStringList labels;
    labels << QString::fromLocal8Bit("桶名称") << QString::fromLocal8Bit("地区")
           << QString::fromLocal8Bit("创建时间");
    m_modelBuckets->setColumnCount(labels.size());
    m_modelBuckets->setHorizontalHeaderLabels(labels);
}

void ManagerModels::initObjectsTable()
{
    QStringList labels;
    labels << QString::fromLocal8Bit("对象名称") << QString::fromLocal8Bit("大小")
           << QString::fromLocal8Bit("更新时间")
           << QString::fromLocal8Bit("操作");
    m_modelObjects->setColumnCount(labels.size());
    m_modelObjects->setHorizontalHeaderLabels(labels);
}
