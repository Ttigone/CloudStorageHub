#ifndef CLOUDSMOCK_H
#define CLOUDSMOCK_H

#include "baseclouds.h"
#include <QJsonObject>
#include <QJsonValue>

///
/// @brief The CloudsMock class 模拟云存储操作
///
class CloudsMock : public BaseClouds {
public:
  CloudsMock(const std::string &path);

  QList<TtBucket> buckets() override;

  QList<TtBucket> login(const std::string secretId,
                        const std::string secretKey) override;

  bool isBucketExists(const std::string &bucketName) override;

  std::string getBucketLocation(const std::string &bucketName) override;

  void putBucket(const std::string &bucketName,
                 const std::string &location) override;

  void deleteBucket(const std::string &bucketName) override;

  QList<TtObject> getObjects(const std::string &bucketName,
                             const std::string &dir) override;

  void putObject(const std::string &bucket, const std::string &key,
                 const std::string &localPath,
                 const TransProgressCallback &callback) override;

  void getObject(const std::string &bucket, const std::string &key,
                 const std::string &localPath,
                 const TransProgressCallback &callback) override;

  void deleteObject(const std::string &bucket, const std::string &key) override;

private:
  QJsonValue m_mock;
};

#endif // CLOUDSMOCK_H
