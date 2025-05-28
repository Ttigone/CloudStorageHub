#include "instancecloud.h"
#include "data/clouds/baseclouds.h"
#include "middle/managerglobal.h"
#include "middle/signals/managersignals.h"
#include "plugin/TtPlugin.h"

// ManagerCloud::ManagerCloud(QObject *parent) : QObject(parent) {}

// ManagerCloud::~ManagerCloud() {}

// void ManagerCloud::login(std::string secretId, std::string secretKey) {
//   QList<TtBucket> buckets = MG->mPlugin->clouds()->login(
//       secretId.toStdString(), secretKey.toStdString());

//   // 发送登录信号
//   emit MG->mSignal->loginSuccess();
//   bucketsAlready(buckets);
// }

// void ManagerCloud::getBuckets() {
//   QList<TtBucket> buckets = MG->mPlugin->clouds()->buckets();
//   bucketsAlready(buckets);
// }

// void ManagerCloud::putBucket(const std::string &bucketName,
//                              const std::string &location) {
//   MG->mPlugin->clouds()->putBucket(bucketName, location);
//   getBuckets(); // 更新本地存储桶展示
// }

// void ManagerCloud::deleteBucket(const std::string &bucketName) {
//   MG->mPlugin->clouds()->deleteBucket(bucketName);
//   emit MG->mSignal->deleteBucketSuccess(bucketName); // 成功删除桶
//   getBuckets();                                      // 刷新桶页面
// }

// void ManagerCloud::getObjects(const std::string &bucketName, const
// std::string &dir)
// {
//   QList<TtObject> objs = MG->mPlugin->clouds()->getObjects(bucketName, dir);
//   m_currentBucketName = bucketName;
//   m_currentDir = dir;
//   emit MG->mSignal->objectsSuccess(objs);
// }

// void ManagerCloud::getObject(const std::string &jobId, const std::string
// &bucketName,
//                              const std::string &key, const std::string
//                              &localPath) {
//   // transferred_size 已经传送的大小，total_size 需要传输的总大小
//   auto callback = [=](qulonglong transferred_size, qulonglong total_size,
//                       void *) {
//     assert(transferred_size <= total_size);
//     if (0 == transferred_size % (1024 * 512)) {
//       emit MG->mSignal->downloadProcess(jobId, transferred_size, total_size);
//     }
//   };
//   MG->mPlugin->clouds()->getObject(bucketName, key, localPath, callback);
//   emit MG->mSignal->downloadSuccess(jobId);
// }

// void ManagerCloud::putObject(const std::string &jobId, const std::string
// &bucketName,
//                              const std::string &key, const std::string
//                              &localPath) {
//   auto callback = [=](qulonglong transferred_size, qulonglong total_size,
//                       void *) {
//     assert(transferred_size <= total_size);
//     if (0 == transferred_size % (1024 * 512)) {
//       emit MG->mSignal->uploadProcess(jobId, transferred_size, total_size);
//     }
//   };
//   MG->mPlugin->clouds()->putObject(bucketName, key, localPath, callback);
//   emit MG->mSignal->uploadSuccess(jobId);
// }

// std::string ManagerCloud::currentBucketName() const { return
// m_currentBucketName;
// }

// std::string ManagerCloud::currentDir() const { return m_currentDir; }

// void ManagerCloud::bucketsAlready(const QList<TtBucket> &buckets) {
//   m_currentBucketName.clear();
//   m_currentDir.clear();
//   emit MG->mSignal->bucketsSuccess(buckets);
// }

ManagerCloud::ManagerCloud(QObject *parent) : QObject(parent) {}

ManagerCloud::~ManagerCloud() {}

void ManagerCloud::login(const std::string &secretId,
                         const std::string &secretKey) {
  // QList<TtBucket> buckets = MG->mPlugin->clouds()->login(
  //     secretId.toStdString(), secretKey.toStdString());
  QList<TtBucket> buckets = MG->mPlugin->clouds()->login(secretId, secretKey);

  // 发送登录信号
  emit MG->mSignal->loginSuccess();
  bucketsAlready(buckets);
}

void ManagerCloud::getBuckets() {
  QList<TtBucket> buckets = MG->mPlugin->clouds()->buckets();
  bucketsAlready(buckets);
}

void ManagerCloud::putBucket(const std::string &bucketName,
                             const std::string &location) {
  MG->mPlugin->clouds()->putBucket(bucketName, location);
  getBuckets(); // 更新本地存储桶展示
}

void ManagerCloud::deleteBucket(const std::string &bucketName) {
  MG->mPlugin->clouds()->deleteBucket(bucketName);
  // 成功删除桶
  emit MG->mSignal->deleteBucketSuccess(bucketName);
  // 刷新桶页面
  getBuckets();
}

void ManagerCloud::getObjects(const std::string &bucketName,
                              const std::string &dir) {
  QList<TtObject> objs = MG->mPlugin->clouds()->getObjects(bucketName, dir);
  m_currentBucketName = bucketName;
  m_currentDir = dir;
  emit MG->mSignal->objectsSuccess(objs);
}

void ManagerCloud::getObject(const std::string &jobId,
                             const std::string &bucketName,
                             const std::string &key,
                             const std::string &localPath) {
  // transferred_size 已经传送的大小，total_size 需要传输的总大小
  // 回调函数
  auto callback = [=](qulonglong transferred_size, qulonglong total_size,
                      void *) {
    // 断言, 确保没有传输未知字节数
    assert(transferred_size <= total_size);
    if (0 == transferred_size % (1024 * 512)) {
      // 512KB 为一个分块
      emit MG->mSignal->downloadProcess(jobId, transferred_size, total_size);
    }
  };
  // 获取云对象
  MG->mPlugin->clouds()->getObject(bucketName, key, localPath, callback);
  // 发出成功下载的信号
  emit MG->mSignal->downloadSuccess(jobId);
}

void ManagerCloud::putObject(const std::string &jobId,
                             const std::string &bucketName,
                             const std::string &key,
                             const std::string &localPath) {
  auto callback = [=](qulonglong transferred_size, qulonglong total_size,
                      void *) {
    assert(transferred_size <= total_size);
    if (0 == transferred_size % (1024 * 512)) {
      emit MG->mSignal->uploadProcess(jobId, transferred_size, total_size);
    }
  };
  MG->mPlugin->clouds()->putObject(bucketName, key, localPath, callback);
  emit MG->mSignal->uploadSuccess(jobId);
}

std::string ManagerCloud::currentBucketName() const {
  return m_currentBucketName;
}

std::string ManagerCloud::currentDir() const { return m_currentDir; }

void ManagerCloud::bucketsAlready(const QList<TtBucket> &buckets) {
  m_currentBucketName.clear();
  m_currentDir.clear();
  emit MG->mSignal->bucketsSuccess(buckets);
}
