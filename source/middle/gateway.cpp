#include "gateway.h"
#include <QtConcurrent>
// #include "src/config/common.h"
#include "config/apis.h"
#include "config/common.h"
#include "config/errorcode.h"
#include "config/exceptions.h"
#include "config/loggerproxy.h"
#include "data/instance/instancecloud.h"
#include "middle/managerglobal.h"
#include "middle/models/cloudmodels.h"
#include "middle/signals/managersignals.h"

GateWay::GateWay(QObject *parent) : QObject{parent} {}

GateWay::~GateWay() {}

void GateWay::send(int api, const QJsonValue &params) {
  // QtConcurrent实际调用了线程池
  QtConcurrent::run([=]() {
    try {
      this->dispach(api, params);
    } catch (BaseException e) {
      mError(e.msg());
      emit MG->mSignal->error(api, e.msg().toStdString(), params);
    } catch (...) {
      BaseException e = BaseException(EC_100000, STR("未知错误"));
      mError(e.msg());
      emit MG->mSignal->error(api, e.msg().toStdString(), params);
    }
  });
}

void GateWay::dispach(int api, const QJsonValue &value) {
  switch (api) {
  case API::LOGIN::NORMAL: {
    // 登录申请
    apiLogin(value);
    break;
  }
  case API::BUCKETS::LIST: {
    // 获取桶列表
    apiGetBuckets(value);
    break;
  }
  case API::BUCKETS::PUT: {
    // 上传桶
    apiPutBucket(value);
    break;
  }
  case API::BUCKETS::DEL: {
    // 删除桶
    apiDeleteBucket(value);
    break;
  }
  case API::OBJECTS::LIST: {
    // 获取云对象
    apiGetObjects(value);
    break;
  }
  case API::OBJECTS::PUT: {
    // 上传云对象
    apiPutObject(value);
    break;
  }
  case API::OBJECTS::GET: {
    // 下载云对象
    apiDownLoadObject(value);
    break;
  }
  default:
    break;
  }
}

void GateWay::apiLogin(const QJsonValue &value) {
  QString secretId = value["secretId"].toString();
  QString secretKey = value["secretKey"].toString();
  MG->mCloud->login(secretId.toStdString(), secretKey.toStdString());
  mWarning(STR("Cloud Object Storage secretID: %1 logined.").arg(secretId));
}

void GateWay::apiGetBuckets(const QJsonValue &params) {
  Q_UNUSED(params);
  // 根据当前插件, 获取对应的云对象桶
  MG->mCloud->getBuckets();
}

void GateWay::apiPutBucket(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  QString location = params["location"].toString();
  mWarning(STR("The User Create a Bucket named: %1").arg(bucketName));
  MG->mCloud->putBucket(
      bucketName.toStdString(),
      location.toStdString()); // 如果失败会报错，后面无需记录成功的日志
}

void GateWay::apiDeleteBucket(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  mError(STR("The User Delete a Bucket named: %1").arg(bucketName));
  MG->mCloud->deleteBucket(bucketName.toStdString());
}

void GateWay::apiGetObjects(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  QString dir = params["dir"].toString();
  MG->mCloud->getObjects(bucketName.toStdString(), dir.toStdString());
}

void GateWay::apiPutObject(const QJsonValue &params) {
  QString jobId = params["jobId"].toString(); // 用于更新下载进度的任务id
  QString bucketName = params["bucketName"].toString();
  QString key = params["key"].toString();
  QString localPath = params["localPath"].toString();
  mWarning(STR("The User Upload a Object named: %1").arg(key));
  MG->mCloud->putObject(jobId.toStdString(), bucketName.toStdString(),
                        key.toStdString(), localPath.toStdString());
}

void GateWay::apiDownLoadObject(const QJsonValue &params) {
  QString jobId = params["jobId"].toString(); // 用于更新上传进度的任务id
  QString bucketName = params["bucketName"].toString();
  QString key = params["key"].toString();
  QString localPath = params["localPath"].toString();
  mInfo(STR("The User Download a Object named: %1").arg(key));
  MG->mCloud->getObject(jobId.toStdString(), bucketName.toStdString(),
                        key.toStdString(), localPath.toStdString());
}
