#ifndef MANSIGNALS_H
#define MANSIGNALS_H

// #include "src/middle/models/cloudmodels.h"
#include "middle/models/cloudmodels.h"
#include <QObject>

/**
 * @brief 信号中心
 *
 */
class ManagerSignals : public QObject {
  Q_OBJECT
public:
  explicit ManagerSignals(QObject *parent = nullptr);
  ~ManagerSignals();

signals:
  // 登录成功
  void loginSuccess();

  /**
   * @brief 报错
   * @param api 接口
   * @param msg 信息
   * @param req 请求信息
   */
  void error(int api, const std::string &msg, const QJsonValue &req);

  // 退出登录
  void unLogin();

  // 返回用户对应存储桶列表
  void bucketsSuccess(QList<TtBucket>);
  // 成功获取对象列表
  void objectsSuccess(const QList<TtObject> &objects);

  // 成功删除存储桶
  void deleteBucketSuccess(const std::string &bucketname);

  // 开始下载
  void startDownload(const std::string &jobId, const std::string &key,
                     const std::string &localPath, qulonglong total);
  // 下载对象进度
  void downloadProcess(const std::string &jobid, qulonglong transferred,
                       qulonglong total);
  // 下载对象成功
  void downloadSuccess(const std::string &jobId);

  // 开始上传
  void startUpload(const std::string &jobId, const std::string &key,
                   const std::string &localPath);
  // 上传对象进度
  void uploadProcess(const std::string &jobId, qulonglong transferred,
                     qulonglong total);
  // 上传对象成功
  void uploadSuccess(const std::string &jobId);
};

#endif // MANSIGNALS_H
