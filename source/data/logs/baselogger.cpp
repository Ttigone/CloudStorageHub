#include "baselogger.h"

// #include <src/config/globals.h>
// #include <src/helper/filehelper.h>
#include "config/global.h"
#include "helper/filehelper.h"

BaseLogger::BaseLogger(QObject *parent) : QObject(parent) {
  // 写日志记录使用单个线程操作, 避免了读写竞争
  // 基类 BaseLogger 构造函数就自动创建一个线程进行操作
  // 后续子类继承时调用基类的构造函数, 都会创建一个线程 ???
  m_workThread = new QThread();
  moveToThread(m_workThread);
  m_workThread->start();
}

BaseLogger::~BaseLogger() {
  // 等待线程运行结束后停止
  if (m_workThread->isRunning()) {
    m_workThread->quit();         // 让线程退出事件循环
    if (m_workThread->wait(1000)) // 等待1000毫秒
    {
      m_workThread->terminate(); // 强行关闭
      m_workThread->wait(1000);
    }
  }
  delete m_workThread;
}

void BaseLogger::onLog(const QString &file, int line, const QString &func,
                       void *tid, int level, const QVariant &var, bool up) {
  // 调用派生类打印
  print(file, line, func, tid, level, var, up);
}

QString BaseLogger::filePath() {
  // 获取当前时间
  QString name = QDate::currentDate().toString(Qt::ISODate);

  // 拼接路径 返回日志文件的路径
  // 基于时间创建
  return FileHelper::joinPath(GLOBAL::PATH::LOG_DIR,
                              QString::fromLocal8Bit("%1.log").arg(name));
}
