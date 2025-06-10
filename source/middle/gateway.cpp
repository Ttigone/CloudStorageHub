#include "gateway.h"
#include <QMetaObject>
#include <QPointer>
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

GateWay::~GateWay() { qDebug() << __FUNCTION__; }

void GateWay::send(int api, const QJsonValue &params) {
  // 解析 json 数据
  // QtConcurrent实际调用了线程池
  QtConcurrent::run([=]() {
    try {
      this->dispach(api, params);
    } catch (BaseException e) {
      // 这里捕获异常失败
      if (e.code() == EC_211000) {
        // 内部处理的 e.msg
        qDebug() << "发了送登录失败信号" << e.msg();
        // 这里发出的信号值, 捕获时
        // emit ManGLOBAL->mSignal->loginFailed(e.msg());
        emit ManGLOBAL->mSignal->loginFailed(
            QString("登录失败, 请检查 Id 或者 Key"));
      }
      // 这里获取的信号乱码
      // qDebug() << "GateWay::send error:" << e.msg();
      // if ()
      // 这里捕获成功了
      // 但是后面还是没有事件句柄支持
      // 如果是登录失败, 发出登录失败的信号
      mError(e.msg());
      emit ManGLOBAL->mSignal->error(api, e.msg().toStdString(), params);
    } catch (...) {
      BaseException e = BaseException(EC_100000, STR("未知错误"));
      mError(e.msg());
      emit ManGLOBAL->mSignal->error(api, e.msg().toStdString(), params);
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
  case API::BUCKETS::DELBUCKET: {
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
  case API::OBJECTS::DELOBJECT: {
    // 删除云对象
    apiDeleteObject(value);
  }
  default:
    break;
  }
}

void GateWay::apiLogin(const QJsonValue &value) {
  QString secretId = value["secretId"].toString();
  QString secretKey = value["secretKey"].toString();
  qDebug() << "网关登录执行操作";
  ManGLOBAL->mCloud->login(secretId.toStdString(), secretKey.toStdString());
  // 这些信息都输出到哪里了???
  // 登录成功后, 执行下面的操作
  qDebug() << "网关登录执行操作完成";
  mWarning(STR("Cloud Object Storage secretID: %1 logined.").arg(secretId));
}

void GateWay::apiGetBuckets(const QJsonValue &params) {
  Q_UNUSED(params);
  // 根据当前插件, 获取对应的云对象桶
  ManGLOBAL->mCloud->getBuckets();
}

void GateWay::apiPutBucket(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  QString location = params["location"].toString();
  mWarning(STR("The User Create a Bucket named: %1").arg(bucketName));
  ManGLOBAL->mCloud->putBucket(
      bucketName.toStdString(),
      location.toStdString()); // 如果失败会报错，后面无需记录成功的日志
}

void GateWay::apiDeleteBucket(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  mError(STR("The User Delete a Bucket named: %1").arg(bucketName));
  ManGLOBAL->mCloud->deleteBucket(bucketName.toStdString());
}

void GateWay::apiGetObjects(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  QString dir = params["dir"].toString();
  ManGLOBAL->mCloud->getObjects(bucketName.toStdString(), dir.toStdString());
}

void GateWay::apiPutObject(const QJsonValue &params) {
  QString jobId = params["jobId"].toString(); // 用于更新下载进度的任务id
  QString bucketName = params["bucketName"].toString();
  QString key = params["key"].toString();
  QString localPath = params["localPath"].toString();
  // 执行了这里的语句, 上传的语句文件名是正确的
  // 否面执行无法打开文件
  mWarning(STR("The User Upload a Object named: %1").arg(key));
  ManGLOBAL->mCloud->putObject(jobId.toStdString(), bucketName.toStdString(),
                               key.toStdString(), localPath.toStdString());
}

void GateWay::apiDownLoadObject(const QJsonValue &params) {
  QString jobId = params["jobId"].toString(); // 用于更新上传进度的任务id
  QString bucketName = params["bucketName"].toString();
  QString key = params["key"].toString();
  QString localPath = params["localPath"].toString();
  mInfo(STR("The User Download a Object named: %1").arg(key));
  ManGLOBAL->mCloud->getObject(jobId.toStdString(), bucketName.toStdString(),
                               key.toStdString(), localPath.toStdString());
}

void GateWay::apiDeleteObject(const QJsonValue &params) {
  QString bucketName = params["bucketName"].toString();
  QString key = params["key"].toString();
  mInfo(STR("The User Delete a Object named: %1").arg(key));
  ManGLOBAL->mCloud->deleteObject(bucketName.toStdString(), key.toStdString());
}
