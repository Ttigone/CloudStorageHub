#ifndef CLOUDSTC_H
#define CLOUDSTC_H

#include "baseclouds.h"
#include <QFuture>
#include <cos_api.h>
#include <op/cos_result.h>
#include <response/bucket_resp.h>

///
/// @brief The CloudsTC class 腾讯云接口, 进行存储桶的增删改查
///
class CloudsTC : public BaseClouds {
public:
  CloudsTC();
  ~CloudsTC();

  QFuture<QList<TtObject>> getObjectsAsync(
    const std::string &bucketName,
    const std::string &dir
  );
  QFuture<QList<TtBucket>> bucketsAsync();


  QList<TtBucket> buckets() override;

  QList<TtBucket> login(const std::string secretId,
                        const std::string secretKey) override;

  bool isBucketExists(const std::string &bucketName) override;

  std::string getBucketLocation(const std::string &bucketName) override;

  void putBucket(const std::string &bucketName,
                 const std::string &location) override; // 增加存储桶

  void deleteBucket(const std::string &bucketName) override; // 删除存储桶

  QList<TtObject>
  getObjects(const std::string &bucketName,
             const std::string &dir) override; // 获取存储桶目录下的对象（文件）

  bool isObjectExists(const std::string &bucketname, const std::string &key);

  void putObject(const std::string &bucketName, const std::string &key,
                 const std::string &localPath,
                 const TransProgressCallback &callback) override;

  void getObject(const std::string &bucketName, const std::string &key,
                 const std::string &localPath,
                 const TransProgressCallback &callback) override;

  void deleteObject(const std::string &bucket, const std::string &key) override;

private:
  ///
  /// @brief getDirList 获取当前层级文件夹
  /// @param resp 响应头
  /// @param    dir 目录
  /// @return  文件夹列表
  ///
  QList<TtObject> getDirList(qcloud_cos::GetBucketResp &resp,
                             const std::string &dir);

  ///
  /// @brief getFileList 获取当前目录喜下的文件对象
  /// @param resp 响应头
  /// @param dir 层级目录
  /// @return  文件对象列表
  ///
  QList<TtObject> getFileList(qcloud_cos::GetBucketResp &resp,
                              const std::string &dir);

  /**
   * @brief 根据桶名获取桶
   * @param bucketName  桶名
   * @return 桶对象
   */
  TtBucket getBucketByName(const std::string &bucketName);

  /**
   * @brief 异常处理
   * @param code 错误码
   * @param result 响应结果
   */
  void throwError(const std::string &code, qcloud_cos::CosResult &result);

private:
  QList<TtObject> getObjectsInternal(const std::string&bucketName, const std::string &dir);
  QList<TtBucket> bucketsInternal();

  qcloud_cos::CosConfig *m_config = nullptr;
  QMutex m_configMutex; // 保护配置访问的互斥锁

};

#endif // CLOUDSTC_H
