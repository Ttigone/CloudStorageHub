#include "managerglobal.h"
#include "config/apis.h"
#include "config/global.h"
#include "config/loggerproxy.h"
#include "data/instance/instancecloud.h"
#include "middle/gateway.h"
#include "middle/managermodel.h"
#include "middle/signals/managersignals.h"
#include "plugin/TtPlugin.h"
#include "storage/TtDb.h"

// #include <QFileDialog>
#include <QCoreApplication>
#include <QJsonObject>
#include <QSettings>
#include <QStandardPaths>

Q_GLOBAL_STATIC(ManagerGlobal, ins)

ManagerGlobal::ManagerGlobal(QObject *parent) : QObject{parent} {
  mLog = new LoggerProxy(this);
  mCloud = new ManagerCloud(this);
  mSignal = new ManagerSignals(this);
  mPlugin = new TtPlugin(this);
  mGate = new GateWay(this);
  mDb = new TtDB(this);
}

ManagerGlobal::~ManagerGlobal() {
  qDebug() << __FUNCTION__;
  delete mLog;
  delete mCloud;
  delete mSignal;
  delete mPlugin;
  delete mGate;
  delete mDb;
}

ManagerGlobal *ManagerGlobal::instance() { return ins(); }

void ManagerGlobal::init(int argc, char *argv[]) {
  mModels = new ManagerModels(this);

  // 创建分页代理模型并连接到桶模型
  m_bucketsPaginationModel = new PaginationProxyModel(this);
  m_bucketsPaginationModel->setSourceModel(getBucketsModel());

  // 创建分页代理模型并连接到对象模型
  m_objectsPaginationModel = new PaginationProxyModel(this);
  m_objectsPaginationModel->setSourceModel(getObjectsModel());

  // 创建临时目录和日志目录 C:/Users/xxxx/AppData/Local/Temp/qos/logs
  FileHelper::mkPath(GLOBAL::PATH::LOG_DIR);
  FileHelper::mkPath(GLOBAL::PATH::TMP);

  // 安装插件
  mPlugin->installPlugins(argc, argv);

  // // QApplication读取文件中的qss
  // QString qssStr = FileHelper::readAllTxt(":/static/qss/default.qss");

  // 配置前端美化内容
  // qApp->setStyleSheet(qssStr);

  // 初始化数据库
  // 链接信号 ???

  mDb->init();
}

void ManagerGlobal::login(const QString &secretId, const QString &secretKey,
                          const QString &name, const QString &remark) {
  qDebug() << "login : " << secretId << secretKey;
  // 创建参数
  QJsonObject params;
  params["secretId"] = secretId.trimmed();
  params["secretKey"] = secretKey.trimmed();
  // 后面两个参数不重要, 可以不填入
  params["name"] = name.trimmed();
  params["remark"] = remark.trimmed();
  // 请求登录
  // 调用网关
  mGate->send(API::LOGIN::NORMAL, params);
  // 调用失败的情况??
  // 那边是异步调用
  // qDebug() << "网关登录执行操作完成";
}

void ManagerGlobal::connectLoginSignals() {
  // qDebug() << "connect Singlas";
  connect(mSignal, &ManagerSignals::loginSuccess, this, [this] {
    // qDebug() << "reces loginSuccess";
    // 成功登录的信号, 发送给 qml 端
    // qDebug() << 发射信号;
    qDebug() << "reces loginSuccess";
    emit loginSuccess();
  });
  connect(mSignal, &ManagerSignals::loginFailed, this, [this](QString msg) {
    // 这里没有接受到信号
    // 这里还没执行，就退出程序
    qDebug() << "登录失败信号发出, 信号是乱码";
    emit loginFailed(msg);
  });
  connect(mSignal, &ManagerSignals::bucketsSuccess, this,
          [this](QList<TtBucket> buckets) {
            // qDebug() << "get buckets";
            QStringList words;
            for (const auto &bucket : qAsConst(buckets)) {
              words.append(bucket.name);
            }
            mModels->setBuckets(buckets);
            // 加载桶时就会触发
            // CPP 端只会触发第一次
            qDebug() << "加载桶列表成功, 桶个数: " << buckets.size();
            // if (!m_isFirstLoadBucketModel) {
            // qDebug() << "发射信号";
            // 能够发射信号
            emit bucketListLoaded();
            // m_isFirstLoadBucketModel = true;
            // }
          });
  connect(mSignal, &ManagerSignals::objectsSuccess, this,
          [this](QList<TtObject> objects) {
            // 获取对象后, 设置到对象模型中
            // 初始化之后, 就会发出对象请求成功
            // qDebug() << "get objects";
            mModels->setObjects(objects);
          });
  connect(mSignal, &ManagerSignals::downloadProcess, this,
          [this](const std::string &jobId, qulonglong transferred,
                 qulonglong total) {
            if (total > 0) {
              double progress = static_cast<double>(transferred) / total;
              qDebug() << "传输进度: " << jobId << transferred;
              emit downloadProgressUpdated(QString(jobId.c_str()), progress);
            }
          });

  connect(mSignal, &ManagerSignals::downloadSuccess, this,
          [this](const std::string &jobId) {
            emit downloadProgressUpdated(QString(jobId.c_str()), 1.0);
            qDebug() << "任务下载完成: " << jobId;
          });
  connect(mSignal, &ManagerSignals::uploadProcess, this,
          [this](const std::string &jobId, qulonglong transferred,
                 qulonglong total) {
            double progress = total > 0 ? (double)transferred / total : 0.0;
            emit uploadProgressUpdated(QString::fromStdString(jobId), progress);
          });
  connect(mSignal, &ManagerSignals::uploadSuccess, this,
          [this](const std::string &jobId) {
            emit uploadProgressUpdated(QString::fromStdString(jobId), 1.0);
            qDebug() << "任务上传完成: " << QString::fromStdString(jobId);
            // emit uploadSuccess(QString::fromStdString(jobId));
            // if (mCloud) {
            //   auto bucketName = mCloud->currentBucketName();
            //   auto currentDir = mCloud->currentDir();
            //   if (!bucketName.empty()) {
            //     refreshObjects(QString::fromStdString(bucketName),
            //                    QString::fromStdString(currentDir));
            //   }
            // }
          });
  connect(mSignal, &ManagerSignals::deleteObjectSuccess, this,
          [this](const std::string bucket, const std::string &key) {

          });
}

QStandardItemModel *ManagerGlobal::getBucketsModel() const {
  return mModels ? mModels->modelBuckets() : nullptr;
}

QStandardItemModel *ManagerGlobal::getObjectsModel() const {
  return mModels ? mModels->modelObjects() : nullptr;
}

void ManagerGlobal::refreshBuckets() {
  if (!mModels) {
    return;
  }
  try {
    mCloud->getBuckets();
  } catch (const std::exception &e) {
    // 捕获到异常 Invalid region configuration in CosConfig
    qWarning() << "refrsh bucket lose:" << e.what();
  }
}

void ManagerGlobal::deleteBucket(const QString &bucketName) {
  if (bucketName.isEmpty()) {
    qDebug() << "删除桶时, 获取的桶名是空的";
  }
  mCloud->deleteBucket(bucketName.toStdString());
}

void ManagerGlobal::refreshObjects(const QString &bucketName,
                                   const QString &path) {
  // 在点击左侧按钮时, 记录当前选择的桶名, 切换桶名时, 使用 current 记录
  if (!mModels) {
    return;
  }
  try {
    // 请求刷新
    // 获取最新的对象列表
    // 当前显示的 path 是 当前点击的  文件夹名字加上 "/"
    // 桶名加上第一层的文件夹, 是完整的路径
    // 获取的 path 是当前文件夹点击的路径, 是排除了 桶名之外的完整路径请求名
    // qDebug() << "path " << path;
    // QList<TtObject> objects =
    //     mCloud->getObjects(bucketName.toStdString(), path.toStdString());
    // 通过信号值获取
    mCloud->getObjects(bucketName.toStdString(), path.toStdString());
    // 通过返回值获取
    // 与使用信号槽获取, 那个更好, 信号槽获取是异步的, 这里是同步的
    // mModels->setObjects(objects);
    // 当前桶中对象的个数为 3
    // qDebug() << "refresh " << objects.size() << "count";
  } catch (const std::exception &e) {
    // BUG 点击左侧桶列表出现
    qWarning() << "refresh lose:" << e.what();
  }
}

void ManagerGlobal::downloadFile(const QString &jobId,
                                 const QString &bucketName, const QString &key,
                                 //  const QString& fileName)
                                 const QString &localPath) {
  QFileInfo fileInfo(localPath);
  QDir dir = fileInfo.dir();
  if (!dir.exists()) {
    // 如果目录不存在, 则创建目录
    dir.mkpath(".");
  }
  // // 完整文件路径
  // QString localPath = downloadDir + fileName;

  // 创建下载参数
  QJsonObject params;
  params["jobId"] = jobId;
  params["bucketName"] = bucketName;
  params["key"] = key; // QString 格式
  params["localPath"] = localPath;
  // 启动下载
  mGate->send(API::OBJECTS::GET, params);
}

QString ManagerGlobal::getDownloadDirectory() const {
  // 从设置中读取下载目录，如果没有则返回默认目录
  // 设置
  // QSettings settings;
  QString appDir = QCoreApplication::applicationDirPath();
  // 创建 settings 子目录
  QDir settingsDir(appDir + "/settings");
  if (!settingsDir.exists()) {
    settingsDir.mkpath(".");
  }
  // 设置 INI 文件的完整路径
  QString iniFilePath = settingsDir.absolutePath() + "/setting.ini";
  // qDebug() << "Using settings file:" << iniFilePath;
  QSettings settings(iniFilePath, QSettings::IniFormat);

  QString defaultPath =
      QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
  return settings.value("downloadDirectory", defaultPath).toString();
}

void ManagerGlobal::setDownloadDirectory(const QString &path) {
  QString appDir = QCoreApplication::applicationDirPath();
  // 创建 settings 子目录
  QDir settingsDir(appDir + "/settings");
  if (!settingsDir.exists()) {
    settingsDir.mkpath(".");
  }
  // 设置 INI 文件的完整路径
  QString iniFilePath = settingsDir.absolutePath() + "/setting.ini";
  // qDebug() << "Using settings file:" << iniFilePath;
  QSettings settings(iniFilePath, QSettings::IniFormat);

  settings.setValue("downloadDirectory", path);
}

void ManagerGlobal::pauseDownload(const QString &jobId) {
  // 实现暂停下载逻辑
  // 这里需要与您的下载管理器交互
  qDebug() << "暂停下载:" << jobId;
}

void ManagerGlobal::resumeDownload(const QString &jobId) {
  // 实现继续下载逻辑
  qDebug() << "继续下载:" << jobId;
}

void ManagerGlobal::cancelDownload(const QString &jobId) {
  // 实现取消下载逻辑
  qDebug() << "取消下载:" << jobId;
}

void ManagerGlobal::retryDownload(const QString &jobId) {
  // 实现重试下载逻辑
  qDebug() << "重试下载:" << jobId;
}

void ManagerGlobal::uploadFile(const QString &jobId, const QString &bucketName,
                               const QString &key, const QString &localPath) {
  if (!mModels) {
    // emit uploadFailed(jobId, "模型管理器未初始化");
    return;
  }
  try {
    // 发出开始上传信号
    emit mSignal->startUpload(jobId.toStdString(), key.toStdString(),
                              localPath.toStdString());

    // 创建上传参数
    QJsonObject params;
    params["jobId"] = jobId;
    params["bucketName"] = bucketName;
    params["key"] = key;
    params["localPath"] = localPath;

    // 通过网关调用上传API
    mGate->send(API::OBJECTS::PUT, params);

  } catch (const std::exception &e) {
    mError(QString("上传文件失败: %1").arg(e.what()));
    // emit uploadFailed(jobId, e.what());
  }
}

void ManagerGlobal::pauseUpload(const QString &jobId) {
  // TODO: 实现暂停上传逻辑
  mInfo(QString("暂停上传: %1").arg(jobId));
}

void ManagerGlobal::resumeUpload(const QString &jobId) {
  // TODO: 实现恢复上传逻辑
  mInfo(QString("恢复上传: %1").arg(jobId));
}

void ManagerGlobal::cancelUpload(const QString &jobId) {
  // TODO: 实现取消上传逻辑
  mInfo(QString("取消上传: %1").arg(jobId));
}

void ManagerGlobal::retryUpload(const QString &jobId) {
  // TODO: 实现重试上传逻辑
  mInfo(QString("重试上传: %1").arg(jobId));
}

// 在 managerglobal.cpp 中实现
QStringList ManagerGlobal::getBucketNames() const {
  QStringList bucketNames;

  if (!mModels || !mModels->modelBuckets()) {
    qDebug() << "桶模型未初始化";
    return bucketNames;
  }

  QStandardItemModel *model = mModels->modelBuckets();
  qDebug() << "桶模型行数:" << model->rowCount();

  for (int i = 0; i < model->rowCount(); ++i) {
    QModelIndex index = model->index(i, 0);
    QString bucketName = model->data(index, Qt::DisplayRole).toString();
    if (!bucketName.isEmpty()) {
      bucketNames.append(bucketName);
      qDebug() << "添加桶名称到历史记录:" << bucketName;
    }
  }
  return bucketNames;
}

void ManagerGlobal::deleteFile(const QString &bucketName, const QString &key) {
  if (!mModels) {
    return;
  }
  try {
    QJsonObject params;
    params["bucketName"] = bucketName;
    params["key"] = key;
    // params["bucketName"] = QString("test-1324219408");
    // params["key"] = QString("test-1324219408qrc_qml.cpp");
    mGate->send(API::OBJECTS::DELOBJECT, params);
  } catch (const std::exception &e) {
    mError(QString("删除文件失败: %1").arg(e.what()));
  }
}
