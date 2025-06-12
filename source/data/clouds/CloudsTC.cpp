#include "CloudsTC.h"
#include "helper/filehelper.h"
#include "source/config/common.h"
#include "source/config/errorcode.h"
#include "source/config/exceptions.h"
#include "source/config/global.h"
#include "source/config/loggerproxy.h"
#include "source/middle/managerglobal.h"
#include "source/middle/models/cloudmodels.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <cos_config.h>

CloudsTC::CloudsTC() {
  // 这里需要放到执行文件(.exe)所在目录的上一个目录
  // m_config = new qcloud_cos::CosConfig(":/configs/cosconfig.json");
  // 默认配置本地, 需要根据 login 确认
  // 构造函数执行有问题
  m_config = new qcloud_cos::CosConfig("./cosconfig.json");
  // m_config = new qcloud_cos::CosConfig();

  // // 配置登录就没有问题
  // QJsonObject config =
  //     FileHelper::readAllJson("./cosconfig.json").toJsonValue().toObject();

  // uint64_t appid = 1324219408;
  // std::string tmp_secret_id =
  // config.value("SecretId").toString().toStdString(); std::string
  // tmp_secret_key =
  //     config.value("SecretKey").toString().toStdString();
  // // // 获取失败
  // qDebug() << tmp_secret_id << tmp_secret_key;
  // std::string region = "ap-guangzhou";

  // qDebug() << "start login";
  // this->login(tmp_secret_id, tmp_secret_key);
  // qDebug() << "sussces login";
  // this->buckets();
  // qDebug() << "sussces get bucket";

  // 队列请求
  // 连接下载管理器信号
  // connect(&DownloadManager::instance(), &DownloadManager::downloadRequested,
  //         this, &CloudsTC::executeDownloadInternal, Qt::QueuedConnection);
  // // 设置进度检查定时器
  // m_downloadProgressTimer->setInterval(500); // 500ms检查一次
  // connect(m_downloadProgressTimer, &QTimer::timeout, this,
  // &CloudsTc::checkDownloadProgress);
}

CloudsTC::~CloudsTC() {
  delete m_config;
  m_config = nullptr;
}

QList<TtBucket> CloudsTC::buckets() {
  qcloud_cos::GetServiceReq req;
  qcloud_cos::GetServiceResp resp;
  qcloud_cos::CosAPI cos = qcloud_cos::CosAPI(*m_config);

  // 请求登录云存储账户，返回结果, 是否之前没有调用 login
  qcloud_cos::CosResult result = cos.GetService(req, &resp);
  if (!result.IsSucc()) {
    // 用户登录用户密码有误
    // qDebug() << "登录失败";
    // 抛出了异常
    throwError(EC_211000, result);
    // qDebug() << "登录失败2";
  }
  QList<TtBucket> res;
  // 这里的Bucket是cos API中的类
  std::vector<qcloud_cos::Bucket> bs = resp.GetBuckets();
  for (std::vector<qcloud_cos::Bucket>::const_iterator it = bs.begin();
       it != bs.end(); ++it) {
    const qcloud_cos::Bucket &v = *it;

    TtBucket b;
    b.name = QString(v.m_name.c_str());
    b.location = QString(v.m_location.c_str());
    b.createDate = QString(v.m_create_date.c_str());
    // qDebug() << b.name << b.location << b.createDate;
    res.append(b);
  }
  // 有别的地方调用
  qDebug() << "1+ success";
  return res;
}

QList<TtBucket> CloudsTC::login(const std::string secretId,
                                const std::string secretKey) {
  // 设置登录密钥
  m_config->SetAccessKey(secretId);
  m_config->SetSecretKey(secretKey);
  // 设置默认的地区为成都
  // qDebug() << "test region1";
  // m_config->SetRegion("ap-guangzhou");
  // qDebug() << "test region2";
  // 后面执行失败
  // 上面成功了
  // TODO 不能使用 mDebug() 函数, 否则会造成无法执行
  // 这里确调用成功了 ???
  // 调用 buckets 函数
  // qDebug() << "登录成功, 获取腾讯云桶列表";
  // mDebug("登录成功, 获取列表");
  return buckets();
}

bool CloudsTC::isBucketExists(const std::string &bucketName) {
  // 根据桶名获取桶
  TtBucket bucket = getBucketByName(bucketName);
  return bucket.isValid();
}

std::string CloudsTC::getBucketLocation(const std::string &bucketName) {
  qcloud_cos::CosAPI cos = qcloud_cos::CosAPI(*m_config);
  // std::string
  // location(cos.GetBucketLocation(bucketName.toStdString()).c_str());
  std::string location(cos.GetBucketLocation(bucketName));
  if (location != "") {
    return location;
  }

  // 根据桶名获取桶信息
  TtBucket bucket = getBucketByName(bucketName);
  if (bucket.isValid()) {
    return bucket.location.toStdString();
  }
  // 抛出异常
  throw BaseException(EC_332000,
                      STR("获取桶位置失败 %1").arg(bucketName.c_str()));
}

void CloudsTC::putBucket(const std::string &bucketName,
                         const std::string &location) {
  if (isBucketExists(bucketName)) {
    // qDebug() << "bucketName exit";
    return;
  }
  // 创建推送桶请求
  qcloud_cos::PutBucketReq req(bucketName);
  // 响应结果
  qcloud_cos::PutBucketResp resp;
  // 配置项时刻只有一个地区
  m_config->SetRegion(location); // 重新设置地区
  qcloud_cos::CosAPI cos(*m_config);
  // 使用 config 配置
  // qcloud_cos::CosConfig config(appid, tmp_secret_id, tmp_secret_key, region);
  // qcloud_cos::CosAPI cos(config);
  // 发送推送桶请求
  qcloud_cos::CosResult result = cos.PutBucket(req, &resp);
  // qDebug() << "test";
  // 推送成功, 但是返回值有问题
  if (!result.IsSucc()) {
    throwError(EC_331100, result);
  }
}

void CloudsTC::deleteBucket(const std::string &bucketName) {
  // 删除存储桶，只能删除空的存储桶
  if (!isBucketExists(bucketName)) {
    return;
  }
  // qcloud_cos::DeleteBucketReq req(bucketName.toLocal8Bit().data());
  qcloud_cos::DeleteBucketReq req(bucketName);
  qcloud_cos::DeleteBucketResp resp;
  // 存储对应的地区
  std::string location = getBucketLocation(bucketName);
  // m_config->SetRegion(location.toStdString());
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);

  // 响应对象提供了获取和处理服务器返回结果的机制，
  // 确保了 API 调用能够正确地处理和反馈操作的结果
  qcloud_cos::CosResult result = cos.DeleteBucket(req, &resp);
  if (!result.IsSucc()) {
    throwError(EC_331300, result);
  }
}

QList<TtObject> CloudsTC::getObjects(const std::string &bucketName,
                                     const std::string &dir) {
  qcloud_cos::GetBucketReq req(bucketName);
  if (dir != "") {
    // 设置前缀, dir 当前的目录
    req.SetPrefix(dir);
  }
  // 设置分隔符号
  req.SetDelimiter("/");

  qcloud_cos::GetBucketResp resp;
  // 设置地址
  std::string location = getBucketLocation(bucketName);
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);
  // 获取结果
  qcloud_cos::CosResult result = cos.GetBucket(req, &resp);
  if (!result.IsSucc()) {
    throwError(EC_331200, result);
  }
  // 获取该桶层级下的所有文件夹和文件对象
  // dir 是 测试文件/
  // 执行第一次
  qDebug() << "dir" << dir;
  return getDirList(resp, dir) + getFileList(resp, dir);
}

bool CloudsTC::isObjectExists(const std::string &bucketname,
                              const std::string &key) {
  std::string location = getBucketLocation(bucketname);
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);
  // 判断文件对象是否存在
  return cos.IsObjectExist(bucketname, key);
}

void CloudsTC::throwError(const std::string &code,
                          qcloud_cos::CosResult &result) {
  // QString msg =
  //     QString::fromUtf8("腾讯云错误码[%1]: %2")
  //         .arg(result.GetErrorCode().c_str(), result.GetErrorMsg().c_str());
  QString msg =
      QString("腾讯云错误码[%1]: %2")
          .arg(result.GetErrorCode().c_str(), result.GetErrorMsg().c_str());
  // 构错误码, 但是乱码
  qDebug() << msg;
  qDebug() << QString(code.c_str());
  // 正确
  qDebug() << QString(msg.toUtf8());
  // 抛出异常, 但是没有捕获啊
  throw BaseException(QString(code.c_str()), msg); // 输出到日志里
}

TtBucket CloudsTC::getBucketByName(const std::string &bucketName) {
  QList<TtBucket> bs = buckets();
  for (const auto &b : qAsConst(bs)) {
    // if (b.name.toStdString() == bucketName) {
    //   return b;
    // }
    if (b.name.toStdString() == bucketName) {
      return b;
    }
  }
  return TtBucket();
}

void CloudsTC::putObject(const std::string &bucketName, const std::string &key,
                         const std::string &localPath,
                         const TransProgressCallback &callback) {
  // 初始化上传
  qcloud_cos::SharedAsyncContext context;
  std::setlocale(LC_ALL, ".UTF-8"); // 这一步会处理路径中的中文符号，必不可少
  // 异步上传
  qcloud_cos::AsyncPutObjectReq put_req(bucketName, key, localPath);
  // 桶名正确, 文件名正确, 路径不正确
  // 本地路径问题
  // 替换成 /
  // localPath =
  //     QString("F:/MyProject/CloudStorageHub/"
  //             "build-CloudStorageHub-Desktop_Qt_6_6_3_MSVC2019_64bit-Release/"
  //             "CMakeCache.txt.prev")
  // .toStdString();
  qDebug() << bucketName << key << localPath;

  // 设置上传进度回调
  if (callback) {
    put_req.SetTransferProgressCallback(callback);
  }

  // 根据桶名，获取远端的地域设置
  std::string location = getBucketLocation(bucketName);
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);

  // 获取预期上下文结果
  context = cos.AsyncPutObject(put_req);
  // 等待上传结束
  context->WaitUntilFinish();

  qcloud_cos::CosResult result = context->GetResult();
  if (!result.IsSucc()) {
    // 错误码
    throwError(EC_332400, result);
  }
}

void CloudsTC::getObject(const std::string &bucketName, const std::string &key,
                         const std::string &localPath,
                         const TransProgressCallback &callback) {
  // 下载初始化
  qcloud_cos::SharedAsyncContext context;
  // 异步下载
  // 有时候任务会丢失
  // qDebug() << QThread::currentThread();
  // 处于不同的线程中执行
  qDebug() << "异步下载任务" << bucketName << key << localPath;
  qcloud_cos::AsyncGetObjectReq get_req(bucketName, key, localPath);

  if (callback) {
    // 进度回调
    get_req.SetTransferProgressCallback(callback);
  }
  std::string location = getBucketLocation(bucketName);
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);
  // 开始下载, 单线程, 本生又是运行在多线程任务中
  context = cos.AsyncGetObject(get_req);
  // 等待下载结束
  context->WaitUntilFinish();
  qcloud_cos::CosResult result = context->GetResult();
  if (!result.IsSucc()) {
    throwError(EC_332500, result);
  }
}

void CloudsTC::deleteObject(const std::string &bucket, const std::string &key) {
  qDebug() << "delete Key: " << key;

  qcloud_cos::CosAPI cos(*m_config);
  // key 是除了桶名之外的完整路径名
  qcloud_cos::DeleteObjectReq req(bucket, key);                // 删除请求
  qcloud_cos::DeleteObjectResp resp;                           // 删除恢复
  qcloud_cos::CosResult result = cos.DeleteObject(req, &resp); // 获取结果
  if (!result.IsSucc()) {
    throwError(EC_332600, result);
  }
}

QList<TtObject> CloudsTC::getDirList(qcloud_cos::GetBucketResp &resp,
                                     const std::string &dir) {
  QList<TtObject> res;
  // 获取目录列表
  std::vector<std::string> cs = resp.GetCommonPrefixes();
  // qDebug() << "文件夹";
  for (int i = 0; i < cs.size(); i++) {
    // 这里是在桶中完整的路径，如：books/aaa.txt
    QString key(cs[i].c_str());

    TtObject object;
    object.dir = QString(dir.c_str());
    // 获取目录名带(/)
    // 将末位目录进行截取，dir.size是截取起始位置
    object.name = key.mid(QString(dir.c_str()).size());
    // 文件夹没有修改时间
    object.lastmodified = "-";
    object.key = key;
    // qDebug() << "dir: " << object.dir << object.name << object.lastmodified
    //          << object.key;
    // 添加了 name 是空的
    res.append(object);
  }
  return res;
}

QList<TtObject> CloudsTC::getFileList(qcloud_cos::GetBucketResp &resp,
                                      const std::string &dir) {
  QList<TtObject> res;
  // 获取文件列表
  const std::vector<qcloud_cos::Content> &contents = resp.GetContents();
  for (std::vector<qcloud_cos::Content>::const_iterator it = contents.begin();
       it != contents.end(); ++it) {
    const qcloud_cos::Content &content = *it;
    //  附带文件的完整路径名
    QString key(content.m_key.c_str());
    // 获取 char * 指针后需要转换为 QString, 调用 size 截取文件名
    QString name = key.mid(QString(dir.c_str()).size());
    // dir 是在哪一个文件夹之下, 从桶名之后的路径
    // qDebug() << "file: "
    //          << "key" << key << "file name: " << name << "dir" << dir;
    if (key != QString(dir.c_str())) {
      // 只有非目录，会加入res
      TtObject object;
      object.name = name;
      // 修改时间
      object.lastmodified = QString(content.m_last_modified.c_str());
      // 大小
      object.size = QString(content.m_size.c_str()).toULongLong();
      //
      object.dir = QString(dir.c_str());
      // key 是除了桶名之外的路径
      object.key = key;
      // qDebug() << object.name << object.lastmodified << object.size
      //          << object.dir << object.key;
      res.append(object);
    }
  }
  return res;
}
