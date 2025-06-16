#include "instancecloud.h"
#include "data/clouds/baseclouds.h"
#include "middle/managerglobal.h"
#include "middle/signals/managersignals.h"
#include "plugin/TtPlugin.h"

#include <data/clouds/CloudsTC.h>

ManagerCloud::ManagerCloud(QObject *parent) : QObject(parent) {

  m_bucketsWatcher = new QFutureWatcher<QList<TtBucket>>(this);
  m_objectsWatcher = new QFutureWatcher<QList<TtObject>>(this);

  // 缺失槽函数
  connect(m_bucketsWatcher, &QFutureWatcher<QList<TtBucket>>::finished, this,
          &ManagerCloud::handleBucketsLoaded);
  connect(m_objectsWatcher, &QFutureWatcher<QList<TtObject>>::finished, this,
          &ManagerCloud::handleObjectsLoaded);
}

ManagerCloud::~ManagerCloud() {
  qDebug() << __FUNCTION__;
  if (m_bucketsWatcher->isRunning()) {
    m_bucketsWatcher->cancel();
    m_bucketsWatcher->waitForFinished();
  }
  if (m_objectsWatcher->isRunning()) {
    m_objectsWatcher->cancel();
    m_objectsWatcher->waitForFinished();
  }
}

void ManagerCloud::login(const std::string &secretId,
                         const std::string &secretKey) {
  // 对应插件去执行登录操作
  QList<TtBucket> buckets =
      ManGLOBAL->mPlugin->clouds()->login(secretId, secretKey);
  // 上面登录失败将会抛出异常, 下面的语句
  // qDebug() << "发射成功登录信号";
  emit ManGLOBAL->mSignal->loginSuccess();
  // 将桶数据传递给信号
  bucketsAlready(buckets);
}

void ManagerCloud::getBuckets() {
  // QList<TtBucket> buckets = ManGLOBAL->mPlugin->clouds()->buckets();
  // bucketsAlready(buckets);
  getBucketsAsync();
}

void ManagerCloud::putBucket(const std::string &bucketName,
                             const std::string &location) {
  ManGLOBAL->mPlugin->clouds()->putBucket(bucketName, location);
  getBuckets(); // 更新本地存储桶展示
}

void ManagerCloud::deleteBucket(const std::string &bucketName) {
  ManGLOBAL->mPlugin->clouds()->deleteBucket(bucketName);
  // 成功删除桶
  emit ManGLOBAL->mSignal->deleteBucketSuccess(bucketName);
  // 刷新桶页面
  getBuckets();
}

void ManagerCloud::getObjects(const std::string &bucketName,
                              const std::string &dir) {
  // QList<TtObject> objs =
  //     ManGLOBAL->mPlugin->clouds()->getObjects(bucketName, dir);
  // // 保存桶名
  // m_currentBucketName = bucketName;
  // // 当前文件夹的名字, 带有 "/" 结尾
  // m_currentDir = dir;
  // // 发射信号
  // emit ManGLOBAL->mSignal->objectsSuccess(objs);
  getObjectsAsync(bucketName, dir);
}

void ManagerCloud::getObject(const std::string &jobId,
                             const std::string &bucketName,
                             const std::string &key,
                             const std::string &localPath) {
  // 执行的是这个
  qDebug() << "获取对象名";
  // 没有 key 值
  // qDebug() << jobId << bucketName << key << localPath;
  // transferred_size 已经传送的大小，total_size 需要传输的总大小
  // 回调函数
  auto callback = [=](qulonglong transferred_size, qulonglong total_size,
                      void *) {
    // 断言, 确保没有传输未知字节数
    assert(transferred_size <= total_size);
    if (0 == transferred_size % (1024 * 512)) {
      // 大于 512KB 为一个分块
      emit ManGLOBAL->mSignal->downloadProcess(jobId, transferred_size,
                                               total_size);
    }
  };
  // 这里会丢失一些传输对象
  // 获取云对象
  ManGLOBAL->mPlugin->clouds()->getObject(bucketName, key, localPath, callback);
  // // 成功下载, 为什么会先发出信号
  emit ManGLOBAL->mSignal->downloadSuccess(jobId);
}

void ManagerCloud::putObject(const std::string &jobId,
                             const std::string &bucketName,
                             const std::string &key,
                             const std::string &localPath) {
  auto callback = [=](qulonglong transferred_size, qulonglong total_size,
                      void *) {
    assert(transferred_size <= total_size);
    if (0 == transferred_size % (1024 * 512)) {
      emit ManGLOBAL->mSignal->uploadProcess(jobId, transferred_size,
                                             total_size);
    }
  };

  // 路径的问题
  // std::string localPathtest = "F:/MyProject/CloudStorageHub/"
  //                             "build-CloudStorageHub-Desktop_Qt_6_6_3_MSVC2019_"
  //                             "64bit-Release/CMakeCache.txt.prev";
  // ManGLOBAL->mPlugin->clouds()->putObject(bucketName, key, localPathtest,
  //                                         callback);
  ManGLOBAL->mPlugin->clouds()->putObject(bucketName, key, localPath, callback);
  emit ManGLOBAL->mSignal->uploadSuccess(jobId);
}

void ManagerCloud::deleteObject(const std::string &bucketName,
                                const std::string &key) {
  ManGLOBAL->mPlugin->clouds()->deleteObject(bucketName, key);
  qDebug() << "发出删除对象的信号";
  // 但是这里执行了
  emit ManGLOBAL->mSignal->deleteObjectSuccess(bucketName, key);
}

std::string ManagerCloud::currentBucketName() const {
  return m_currentBucketName;
}

std::string ManagerCloud::currentDir() const { return m_currentDir; }

void ManagerCloud::bucketsAlready(const QList<TtBucket> &buckets) {
  m_currentBucketName.clear();
  m_currentDir.clear();
  emit ManGLOBAL->mSignal->bucketsSuccess(buckets);
}

void ManagerCloud::getBucketsAsync() {
  if (m_bucketsWatcher->isRunning()) {
    m_bucketsWatcher->cancel();
    m_bucketsWatcher->waitForFinished();
  }
  // 缺少信号
  emit ManGLOBAL->mSignal->bucketsLoadingStarted();

  CloudsTC *clouds = dynamic_cast<CloudsTC *>(ManGLOBAL->mPlugin->clouds());
  if (clouds) {
    QFuture<QList<TtBucket>> future = clouds->bucketsAsync();
    m_bucketsWatcher->setFuture(future);
  }
}

void ManagerCloud::getObjectsAsync(const std::string &bucketName,
                                   const std::string &dir) {
  if (m_objectsWatcher->isRunning()) {
    m_objectsWatcher->cancel();
    m_objectsWatcher->waitForFinished();
  }
  m_currentBucketName = bucketName;
  m_currentDir = dir;

  emit ManGLOBAL->mSignal->objectsLoadingStarted();

  // 特定化方法了, 需求重写根类
  CloudsTC *clouds = dynamic_cast<CloudsTC *>(ManGLOBAL->mPlugin->clouds());
  if (clouds) {
    QFuture<QList<TtObject>> future = clouds->getObjectsAsync(bucketName, dir);
    m_objectsWatcher->setFuture(future);
  }
}

void ManagerCloud::handleBucketsLoaded() {
  QList<TtBucket> buckets = m_bucketsWatcher->result();
  bucketsAlready(buckets);
  emit ManGLOBAL->mSignal->bucketsLoadingFinished();
}

void ManagerCloud::handleObjectsLoaded() {
  QList<TtObject> objects = m_objectsWatcher->result();
  emit ManGLOBAL->mSignal->objectsSuccess(objects);
  emit ManGLOBAL->mSignal->objectsLoadingFinished();
}
