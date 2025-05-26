#include "cloudsmock.h"
#include "helper/filehelper.h"

#include <QJsonArray>

CloudsMock::CloudsMock(const QString &path) {
  // QList<TtBucket> res;

  QVariant var = FileHelper::readAllJson(path);
  // QJsonArray arr = var.toJsonArray();
  QJsonObject obj = var.toJsonObject();
  QJsonArray arr = obj["buckets"].toArray();

  m_mock = QJsonValue(arr);

  // for (int i = 0; i < arr.count(); ++i) {
  //   QJsonValue v = arr[i];
  //   TtBucket bucket;
  //   bucket.name = v["name"].toString();
  //   bucket.location = v["location"].toString();
  //   bucket.createDate = v["create_date"].toString();

  //   // res.append(bucket);
  //   qDebug() << bucket.name << bucket.location << bucket.createDate;
  // }

  // return res;
  // m_mock =
  // m_mock =
}

QList<TtBucket> CloudsMock::buckets() {}
