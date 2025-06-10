#ifndef MANGLOBAL_H
#define MANGLOBAL_H

#include <QOBJECT>
#include <QStandardItemModel>

#include "middle/models/paginationproxymodel.h"
#include "storage/TtDb.h"

// 写入日志宏
#define ManGLOBAL ManagerGlobal::instance()

#define mLogIns ManGLOBAL->mLog

#define mTotal mLogIns->reset(__FILE__, __LINE__, __FUNCTION__).total
#define mDebug mLogIns->reset(__FILE__, __LINE__, __FUNCTION__).debug
#define mInfo mLogIns->reset(__FILE__, __LINE__, __FUNCTION__).info
#define mWarning mLogIns->reset(__FILE__, __LINE__, __FUNCTION__).warning
#define mError mLogIns->reset(__FILE__, __LINE__, __FUNCTION__).error
#define mFatal mLogIns->reset(__FILE__, __LINE__, __FUNCTION__).fatal

// 前置声明
class LoggerProxy;
class ManagerCloud;
class TtPlugin;
class GateWay;
class TtDB;
class ManagerSignals;
class ManagerModels;

/**
 * @brief 管理全局单例类
 *
 * 含 数据库、网关、日志、数据模型、信号中心、插件、云对象
 *
 */
class ManagerGlobal : public QObject {
  Q_OBJECT
public:
  explicit ManagerGlobal(QObject *parent = nullptr);
  ~ManagerGlobal();
  static ManagerGlobal *instance();

  void init(int argc, char *argv[]);
  ///
  /// @brief connectLoginSignals 初始化链接信号槽
  ///
  Q_INVOKABLE void connectLoginSignals();

  ///
  /// @brief login 执行登录指令操作
  /// @param secretId 用户id
  /// @param secretKey 用户密钥
  /// @param name 用户名
  /// @param remark 用户备注
  ///
  Q_INVOKABLE void login(const QString &secretId, const QString &secretKey,
                         const QString &name, const QString &remark);

  ///
  /// @brief getLoginNameList 获取登录用户名
  /// @return
  ///
  Q_INVOKABLE QStringList getLoginNameList() const {
    qDebug() << "getLoginNameList";
    return mDb->loginNameList();
  }

  Q_INVOKABLE QVariantMap getLoginInfoByName(const QString &name) const {
    return mDb->loginInfoAsMap(name);
  }

  Q_INVOKABLE void removeLoginInfo(const QString &name) {
    qDebug() << "删除登录信息:" << name;
    if (mDb) {
      // 需要先通过名称获取对应的 secret_id
      try {
        LoginInfo info = mDb->loginInfoByName(name);
        mDb->removeLoginInfo(info.secret_id);
        qDebug() << "成功删除登录信息:" << name;
      } catch (const QString &error) {
        qDebug() << "删除登录信息失败:" << error;
      }
    }
  }

  ///
  /// @brief saveLoginInfo 保存登录信息至数据库
  /// @param name   用户名
  /// @param id 用户id
  /// @param key 用户密钥
  /// @param remark 用户备注
  ///
  Q_INVOKABLE void saveLoginInfo(const QString &name, const QString &id,
                                 const QString &key, const QString &remark) {
    qDebug() << name << id << key << remark;
    mDb->saveLoginInfo(name, id, key, remark);
  }

  ///
  /// @brief getBucketsModel 获取存储桶列表模型 - 用于 ListView
  /// @return
  ///
  Q_INVOKABLE QStandardItemModel *getBucketsModel() const;

  ///
  /// @brief getObjectsModel 获取对象模型, 在这之后调用 refreshObjects
  /// 显示到表格之上
  /// @return  某个请求后产生的文件
  ///
  Q_INVOKABLE QStandardItemModel *getObjectsModel() const;

  // 刷新存储桶列表
  Q_INVOKABLE void refreshBuckets();

  ///
  /// @brief deleteBucket 删除桶
  ///
  Q_INVOKABLE void deleteBucket(const QString &bucketName);

  ///
  /// @brief refreshObjects 刷新
  /// @param bucketName
  /// @param path
  ///
  Q_INVOKABLE void refreshObjects(const QString &bucketName,
                                  const QString &path = "");

  ///
  /// @brief downloadFile 下载任务
  /// @param jobId 任务 id
  /// @param bucketName 桶名
  /// @param key 路径
  /// @param fileName 文件名
  ///
  Q_INVOKABLE void downloadFile(const QString &jobId, const QString &bucketName,
                                const QString &key, const QString &fileName);

  Q_INVOKABLE QString getDownloadDirectory() const;
  Q_INVOKABLE void setDownloadDirectory(const QString &path);

  ///
  /// @brief pauseDownload 暂停下载任务
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void pauseDownload(const QString &jobId);

  ///
  /// @brief resumeDownload 恢复任务下载
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void resumeDownload(const QString &jobId);

  ///
  /// @brief cancelDownload 取消任务下载
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void cancelDownload(const QString &jobId);

  ///
  /// @brief retryDownload 尝试重新下载任务
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void retryDownload(const QString &jobId);

  // 上传相关方法
  Q_INVOKABLE void uploadFile(const QString &jobId, const QString &bucketName,
                              const QString &key, const QString &localPath);

  ///
  /// @brief pauseUpload 暂停上传
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void pauseUpload(const QString &jobId);

  ///
  /// @brief resumeUpload 恢复上传
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void resumeUpload(const QString &jobId);

  ///
  /// @brief cancelUpload 取消上传
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void cancelUpload(const QString &jobId);

  ///
  /// @brief retryUpload 重新尝试上传
  /// @param jobId 任务 id
  ///
  Q_INVOKABLE void retryUpload(const QString &jobId);

  // 在 managerglobal.h 中添加
  Q_INVOKABLE QStringList getBucketNames() const;

  Q_INVOKABLE void deleteFile(const QString &bucketName, const QString &key);

signals:
  // 提供给 QML 使用
  void loginSuccess();
  void loginFailed(QString msg);
  void downloadProgressUpdated(const QString &jobId, double progress);
  void bucketListLoaded();
  // 上传相关信号
  void uploadProgressUpdated(const QString &jobId, double progress);
  void deleteObjectSuccess(const QString &bucketName, const QString &key);

public:
  LoggerProxy *mLog{nullptr};
  ManagerCloud *mCloud{nullptr};
  TtDB *mDb{nullptr};
  TtPlugin *mPlugin{nullptr};
  GateWay *mGate{nullptr};
  ManagerSignals *mSignal{nullptr};
  ManagerModels *mModels{nullptr};

private:
  PaginationProxyModel *m_bucketsPaginationModel{nullptr};
  PaginationProxyModel *m_objectsPaginationModel{nullptr};
  bool m_isFirstLoadBucketModel{false};
};

#endif // MANGLOBAL_H
