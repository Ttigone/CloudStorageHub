#ifndef BASECLOUDS_H
#define BASECLOUDS_H

#include "middle/models/cloudmodels.h"
#include <QList>

///
/// @brief The BaseClouds class
/// 操作云存储对象的接口
class BaseClouds {
public:
  BaseClouds() = default;

  ///
  /// @brief buckets 返回存储桶列表
  /// @return
  ///
  virtual QList<TtBucket> buckets() = 0;

  ///
  /// @brief login 登录云存储帐号
  /// @param secretId 帐号
  /// @param secretKey 密码
  /// @return 桶列表数据
  ///
  virtual QList<TtBucket> login(const QString secretId,
                                const QString secretKey) = 0;

  ///
  /// @brief isBucketExists 判断桶是否存在于云端
  /// @param bucketName 桶名
  /// @return 真假结果
  ///
  virtual bool isBucketExists(const QString &bucketName) = 0;

  ///
  /// @brief getBucketLocation 获取桶地区
  /// @param bucketName 桶名
  /// @return 地区名
  ///
  virtual QString getBucketLocation(const QString &bucketName) = 0;

  ///
  /// @brief putBucket 添加桶
  /// @param bucketName 桶名
  /// @param location 地区名
  ///
  virtual void putBucket(const QString &bucketName,
                         const QString &location) = 0;

  ///
  /// @brief deleteBucket 删除桶
  /// @param bucketName 桶名
  ///
  virtual void deleteBucket(const QString &bucketName) = 0;

  ///
  /// @brief getObjects 获取桶内对象
  /// @param bucketName 桶名
  /// @param dir 桶内层级目录
  /// @return 对象列表
  ///
  virtual QList<TtObject> getObjects(const QString &bucketName,
                                     const QString &dir) = 0;

  ///
  /// @brief putObject 上传对象
  /// @param bucket 桶名
  /// @param key 更变后桶内的路径
  /// @param localPath 本地路径
  /// @param callback 回调函数
  ///
  virtual void putObject(const QString &bucket, const QString &key,
                         const QString &localPath,
                         const TransProgressCallback &callback) = 0;

  ///
  /// @brief getObject 下载对象
  /// @param bucket 桶命
  /// @param key 对象在桶内的路径
  /// @param localPath 本地路径
  /// @param callback 回调函数
  ///
  virtual void getObject(const QString &bucket, const QString &key,
                         const QString &localPath,
                         const TransProgressCallback &callback) = 0;
};

#endif // BASECLOUDS_H
