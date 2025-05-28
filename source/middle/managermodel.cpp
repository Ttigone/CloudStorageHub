#include "managermodel.h"
#include "config/global.h"
#include "data/clouds/baseclouds.h"
#include "helper/bytehelper.h"
#include "middle/managerglobal.h"
#include "middle/models/cloudmodels.h"
#include "middle/signals/managersignals.h"
#include "plugin/TtPlugin.h"

ManagerModels::ManagerModels(QObject *parent) : QObject{parent} {
  m_modelBuckets = new QStandardItemModel(this);
  m_modelObjects = new QStandardItemModel(this);
  initBucketsTable();
  initObjectsTable();

  // 设置存储桶
  connect(MG->mSignal, &ManagerSignals::bucketsSuccess, this,
          &ManagerModels::setBuckets);
  connect(MG->mSignal, &ManagerSignals::objectsSuccess, this,
          &ManagerModels::setObjects);
}

ManagerModels::~ManagerModels() {}

QStandardItemModel *ManagerModels::modelBuckets() const {
  return m_modelBuckets;
}

QStandardItemModel *ManagerModels::modelObjects() const {
  return m_modelObjects;
}

void ManagerModels::setBuckets(const QList<TtBucket> &buckets) {
  m_modelBuckets->setRowCount(buckets.size()); // 设置行数

  for (int i = 0; i < buckets.size(); i++) {
    const TtBucket &bucket = buckets[i];
    QModelIndex index0 = m_modelBuckets->index(i, 0);
    m_modelBuckets->setData(index0, bucket.name);
    // 可以使鼠标放到该数据上显示提示信息
    m_modelBuckets->setData(
        index0, QString::fromLocal8Bit("存储桶名称： %1").arg(bucket.name),
        Qt::ToolTipRole);
    // 设置图标
    // m_modelBuckets->setData(index0, QIcon(GLOBAL::PATH::BUCKET),
    //                         Qt::DecorationRole);
    m_modelBuckets->setData(index0, QIcon(), Qt::DecorationRole);

    QModelIndex index1 = m_modelBuckets->index(i, 1); // 设置行列数
    m_modelBuckets->setData(index1,
                            bucket.location); // 行列数和数据内容

    QModelIndex index2 = m_modelBuckets->index(i, 2);
    m_modelBuckets->setData(index2, bucket.createDate);
  }
  // 默认按时间倒序排序
  m_modelBuckets->sort(2, Qt::DescendingOrder);
}

void ManagerModels::setObjects(const QList<TtObject> &objects) {
  m_modelObjects->setRowCount(objects.size());
  for (int i = 0; i < objects.size(); ++i) {
    const TtObject &obj = objects[i];

    // 可将 index_x视为一个格子，有行列值，然后对其进行set
    QModelIndex index0 = m_modelObjects->index(i, 0);
    // 对象(文件)名称
    m_modelObjects->setData(index0, obj.name);
    QVariant var;
    var.setValue(obj);

    // Qt::UserRole，将特定的自定义数据与某个模型项关联
    // 这些数据不会被 Qt 的内置视图组件直接使用
    m_modelObjects->setData(index0, var, Qt::UserRole);

    // 设置图标，文件夹是文件夹，文件是文件
    if (obj.isDir()) {
      // m_modelObjects->setData(index0, QIcon(GLOBAL::PATH::DIR),
      //                         Qt::DecorationRole);
      m_modelObjects->setData(index0, QIcon(), Qt::DecorationRole);
    } else {
      // m_modelObjects->setData(index0, QIcon(GLOBAL::PATH::FILE),
      //                         Qt::DecorationRole);
      m_modelObjects->setData(index0, QIcon(), Qt::DecorationRole);
    }

    // 大小
    QModelIndex index1 = m_modelObjects->index(i, 1);
    QString sizeStr = ByteHelper::toBeautifulStr(obj.size);
    m_modelObjects->setData(index1, sizeStr);
    // 修改时间
    QModelIndex index2 = m_modelObjects->index(i, 2);
    m_modelObjects->setData(index2, obj.lastmodified);
  }
}

/**
 * @brief 初始化表格的title和列数
 */
void ManagerModels::initBucketsTable() {
  // QStringList labels;
  // labels
  //   << QString::fromLocal8Bit("桶名称") << QString::fromLocal8Bit("地区")
  //        << QString::fromLocal8Bit("创建时间");
  // QStringList labels;
  // labels << QString::fromLocal8Bit("桶名称");
  // m_modelBuckets->setColumnCount(labels.size());
  // m_modelBuckets->setHorizontalHeaderLabels(labels);
}

void ManagerModels::initObjectsTable() {
  // 设置标题内容
  QStringList labels;
  labels << QString::fromLocal8Bit("对象名称") << QString::fromLocal8Bit("大小")
         << QString::fromLocal8Bit("更新时间");
  m_modelObjects->setColumnCount(labels.size());
  m_modelObjects->setHorizontalHeaderLabels(labels);
}
