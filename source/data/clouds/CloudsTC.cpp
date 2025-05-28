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
  // 本地配置文件没有问题
  // 需要的 密钥和 id
  m_config = new qcloud_cos::CosConfig("./cosconfig.json");
  QJsonObject config =
      FileHelper::readAllJson("./cosconfig.json").toJsonValue().toObject();

  uint64_t appid = 1324219408;
  std::string tmp_secret_id = config.value("SecretId").toString().toStdString();
  std::string tmp_secret_key =
      config.value("SecretKey").toString().toStdString();
  // 获取失败
  qDebug() << tmp_secret_id << tmp_secret_key;
  std::string region = "ap-guangzhou";

  this->login(tmp_secret_id, tmp_secret_key);
  this->buckets();
}

CloudsTC::~CloudsTC() {
  delete m_config;
  m_config = nullptr;
}

QList<TtBucket> CloudsTC::buckets() {
  qcloud_cos::GetServiceReq req;
  qcloud_cos::GetServiceResp resp;
  qcloud_cos::CosAPI cos = qcloud_cos::CosAPI(*m_config);

  // 请求登录云存储账户，返回结果
  qcloud_cos::CosResult result = cos.GetService(req, &resp);
  if (!result.IsSucc()) {
    // 用户登录用户密码有误
    throwError(EC_211000, result);
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
  return res;
}

QList<TtBucket> CloudsTC::login(const std::string secretId,
                                const std::string secretKey) {
  // 设置登录密钥
  m_config->SetAccessKey(secretId);
  m_config->SetSecretKey(secretKey);

  // 设置默认的地区为成都
  m_config->SetRegion("ap-guangzhou");

  // 调用 buckets 函数
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
    qDebug() << "bucketName exit";
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
  qDebug() << "test";
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
  if (dir != "")
    req.SetPrefix(dir);
  req.SetDelimiter("/");

  qcloud_cos::GetBucketResp resp;
  std::string location = getBucketLocation(bucketName); // 设置地址
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);

  qcloud_cos::CosResult result = cos.GetBucket(req, &resp); // 获取结果
  if (!result.IsSucc()) {
    throwError(EC_331200, result);
  }
  // 获取该桶层级下的所有文件夹和文件对象
  return getDirList(resp, dir) + getFileList(resp, dir);
}

bool CloudsTC::isObjectExists(const std::string &bucketname,
                              const std::string &key) {
  std::string location = getBucketLocation(bucketname);
  // m_config->SetRegion(location.toStdString());
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);
  // 判断文件对象是否存在
  // return cos.IsObjectExist(bucketname.toStdString(),
  // key.toLocal8Bit().data());
  return cos.IsObjectExist(bucketname, key);
}

void CloudsTC::throwError(const std::string &code,
                          qcloud_cos::CosResult &result) {
  QString msg =
      QString::fromUtf8("腾讯云错误码【%1】：%2")
          .arg(result.GetErrorCode().c_str(), result.GetErrorMsg().c_str());
  qDebug() << msg; // 这里会被捕获在控制台输出
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
  // std::string bucket_name = bucketName;
  // std::string local_file = localPath;
  // std::string object_name = key;
  std::setlocale(LC_ALL, ".UTF-8"); // 这一步会处理路径中的中文符号，必不可少

  // 异步上传
  // qcloud_cos::AsyncPutObjectReq put_req(bucket_name, object_name,
  // local_file);
  qcloud_cos::AsyncPutObjectReq put_req(bucketName, key, localPath);

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
    throwError(EC_332400, result);
  }
}

void CloudsTC::getObject(const std::string &bucketName, const std::string &key,
                         const std::string &localPath,
                         const TransProgressCallback &callback) {
  // 下载初始化
  qcloud_cos::SharedAsyncContext context;
  // 异步下载
  qcloud_cos::AsyncGetObjectReq get_req(bucketName, key, localPath);

  if (callback) {
    get_req.SetTransferProgressCallback(callback);
  }

  std::string location = getBucketLocation(bucketName);
  m_config->SetRegion(location);
  qcloud_cos::CosAPI cos(*m_config);

  // 开始下载
  context = cos.AsyncGetObject(get_req);
  context->WaitUntilFinish();
  qcloud_cos::CosResult result = context->GetResult();
  if (!result.IsSucc()) {
    throwError(EC_332500, result);
  }
}

QList<TtObject> CloudsTC::getDirList(qcloud_cos::GetBucketResp &resp,
                                     const std::string &dir) {

  QList<TtObject> res;
  // 获取目录列表
  std::vector<std::string> cs = resp.GetCommonPrefixes();
  for (int i = 0; i < cs.size(); i++) {
    // 这里是在桶中完整的路径，如：books/aaa.txt
    QString key(cs[i].c_str());

    TtObject object;
    object.dir = QString(dir.c_str());
    object.name =
        key.mid(dir.size()); // 将末位目录进行截取，dir.size是截取起始位置
    object.lastmodified = "-";
    object.key = key;
    qDebug() << object.dir << object.name << object.lastmodified << object.key;
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
    QString key(content.m_key.c_str());

    QString name = key.mid(dir.size()); // 目录尾节选出文件名
    // std::string name = key; // 目录尾节选出文件名
    if (key != QString(dir.c_str())) // 只有非目录，会加入res
    {
      TtObject object;
      object.name = name;
      object.lastmodified = QString(content.m_last_modified.c_str());
      object.size = QString(content.m_size.c_str()).toULongLong();
      object.dir = QString(dir.c_str());
      object.key = key;
      res.append(object);
    }
  }
  return res;
}
