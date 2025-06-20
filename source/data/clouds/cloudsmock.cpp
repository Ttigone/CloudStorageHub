#include "cloudsmock.h"
#include "config/common.h"
#include "config/errorcode.h"
#include "config/exceptions.h"
#include "config/loggerproxy.h"
#include "helper/filehelper.h"
#include "middle/managerglobal.h"
#include "middle/models/cloudmodels.h"

#include <QJsonArray>

CloudsMock::CloudsMock(const std::string &path) {
  // // QList<TtBucket> res;

  // QVariant var = FileHelper::readAllJson(path);
  // // QJsonArray arr = var.toJsonArray();
  // QJsonObject obj = var.toJsonObject();
  // QJsonArray arr = obj["buckets"].toArray();
  // m_mock = QJsonValue(arr);

  // 将QVariant的内容转换为Json格式
  m_mock = FileHelper::readAllJson(QString(path.c_str())).toJsonValue();
}

QList<TtBucket> CloudsMock::buckets() {
  // 把json文件里的数据数组化，每个元素也是一个jsonmap
  QList<TtBucket> res;
  QJsonArray arr = m_mock["buckets"].toArray(); // 这里是把json里的数据数组化
  for (int i = 0; i < arr.count(); ++i) {
    QJsonValue v = arr[i];
    TtBucket bucket;
    bucket.name = v["name"].toString();
    bucket.location = v["location"].toString();
    bucket.createDate = v["create_date"].toString();

    res.append(bucket);
    mInfo(STR("name[%1], location[%2], date[%3]")
              .arg(bucket.name, bucket.location, bucket.createDate));
  }
  return res;
}

QList<TtBucket> CloudsMock::login(const std::string secretId,
                                  const std::string secretKey) {
  QJsonArray arr = m_mock["users"].toArray();

  for (int i = 0; i < arr.size(); i++) {
    QJsonValue v = arr[i];
    // 这里应该是在模拟数据库里的登录信息
    // if (secretId == v["secretId"].toString() &&
    //     secretKey == v["secretKey"].toString()) {
    //   return buckets(); //
    //   因为是mock数据，这里没有对应的存储桶，所有用户用的同一个存储桶
    // }
    if (secretId == v["secretId"].toString().toStdString() &&
        secretKey == v["secretKey"].toString().toStdString()) {
      return buckets(); // 因为是mock数据，这里没有对应的存储桶，所有用户用的同一个存储桶
    }
  }
  throw BaseException(
      EC_211000, QString::fromUtf8("请检查您的SecretId或SecretKey是否正确"));
}

bool CloudsMock::isBucketExists(const std::string &bucketName) {
  Q_UNUSED(bucketName);
  return false;
}

std::string CloudsMock::getBucketLocation(const std::string &bucketName) {
  Q_UNUSED(bucketName);
  return std::string();
}

void CloudsMock::putBucket(const std::string &bucketName,
                           const std::string &location) {
  Q_UNUSED(bucketName);
  Q_UNUSED(location);
}

void CloudsMock::deleteBucket(const std::string &bucketName) {
  Q_UNUSED(bucketName);
}

QList<TtObject> CloudsMock::getObjects(const std::string &bucketName,
                                       const std::string &dir) {
  Q_UNUSED(bucketName);
  Q_UNUSED(dir);
  return QList<TtObject>();
}

void CloudsMock::putObject(const std::string &bucket, const std::string &key,
                           const std::string &localPath,
                           const TransProgressCallback &callback) {
  Q_UNUSED(bucket);
  Q_UNUSED(key);
  Q_UNUSED(localPath);
  Q_UNUSED(callback);
}

void CloudsMock::getObject(const std::string &bucket, const std::string &key,
                           const std::string &localPath,
                           const TransProgressCallback &callback) {
  Q_UNUSED(bucket);
  Q_UNUSED(key);
  Q_UNUSED(localPath);
  Q_UNUSED(callback);
}

void CloudsMock::deleteObject(const std::string &bucket,
                              const std::string &key) {
  Q_UNUSED(bucket);
  Q_UNUSED(key);
}
