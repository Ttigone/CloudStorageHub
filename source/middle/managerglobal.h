#ifndef MANGLOBAL_H
#define MANGLOBAL_H

#include <QOBJECT>

#include "storage/TtDb.h"

// 写入日志宏
#define MG ManGlobal::instance()

#define mLogIns MG->mLog

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
class ManGlobal : public QObject {
  Q_OBJECT
public:
  explicit ManGlobal(QObject *parent = nullptr);
  ~ManGlobal();
  static ManGlobal *instance();

  /**
   * @brief 全局配置初始化
   * @param argc
   * @param argv
   */
  void init(int argc, char *argv[]);

public:
  // LoggerProxy* mLog = nullptr;
  // ManCloud *mCloud = nullptr;
  // TtDB *mDb = nullptr;
  // TtPlugin *mPlugin = nullptr;
  // GateWay *mGate = nullptr;
  // ManSignals *mSignal = nullptr;
  // ManModels* mModels = nullptr;

  LoggerProxy *mLog = nullptr;
  ManagerCloud *mCloud = nullptr;
  TtDB *mDb = nullptr;
  TtPlugin *mPlugin = nullptr;
  GateWay *mGate = nullptr;
  ManagerSignals *mSignal = nullptr;
  ManagerModels *mModels = nullptr;
};

#endif // MANGLOBAL_H
