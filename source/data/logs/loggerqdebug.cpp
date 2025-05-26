#include "loggerqdebug.h"
#include "config/common.h"
#include "config/global.h"
#include <QIODevice>
#include <QString>
#include <QTextStream>
#include <QThread>
#include <iostream>

LoggerQDebug::LoggerQDebug(QObject *parent) : BaseLogger(parent) {
  // 回调函数
  // 由qDebug、qWarnng、qCritical、qFatal函数进行触发，
  // qDebug、qWarnng、qCritical、qFatal函数处理的消息文本
  // 会被qInstallMsgHandler所指向的回调函数截获，允许用户自己来处理输出的消息文本。
  qInstallMessageHandler(handle);
}

LoggerQDebug::~LoggerQDebug() {}

void LoggerQDebug::print(const QString &file, int line, const QString &func,
                         void *tid, int level, const QVariant &var, bool up) {
  Q_UNUSED(up);
  Q_UNUSED(tid);
  QDateTime dt;
  QString dtStr = dt.currentDateTime().toString(Qt::ISODate); // 时间
  QString front = STR("%1[%2] %3 %4 : %5 - ")
                      .arg(dtStr, GLOBAL::LOG_NAMES[level], file, func)
                      .arg(line); // 日志打印时包含时间、级别、文件、行号
  front = front.replace("..\\", "");

  // 如果日志级别超过了告警
  if (level > GLOBAL::LOG_LEVEL::WARNING) {
    // 获取线程 id
    QString threadInfo =
        STR(" Current Thread ID is %1.").arg(QString::asprintf("%p", tid));
    // BUG 但是后续没有需用
  }

  // 日志消息
  QString logMessage;
  if (var.canConvert<QString>()) {
    logMessage = var.toString();
  } else {
    // 尝试转换 string 类型
    logMessage = var.toString();
  }

  // 去除日志输出中的类型和括号等
  if (logMessage.startsWith("QString, ")) {
    // Remove "QString, " prefix
    logMessage = logMessage.mid(9);
  }
  if (logMessage.startsWith("(") && logMessage.endsWith(")")) {
    logMessage = logMessage.mid(1, logMessage.length() - 2);
  }

  if (level > GLOBAL::LOG_LEVEL::WARNING) // 如果日志级别超过了告警
  {
    QString threadInfo =
        STR(" Current Thread ID is %1.").arg(QString::asprintf("%p", tid));
    qDebug() << front.toLocal8Bit().data() << threadInfo << logMessage;
    // 都没有加到日志中
  } else {
    // 使用qDebug而不是直接存文件，是为了打印QVariant类型 日志打印
    qDebug() << front.toLocal8Bit().data() << logMessage;
  }
  // BUG 后面似乎都没有输入到日志文件中
}

void LoggerQDebug::handle(QtMsgType type, const QMessageLogContext &context,
                          const QString &msg) {
  Q_UNUSED(type);
  Q_UNUSED(context);
  // 调用父类静态函数提供的路径
  QFile file(filePath());
  QString key("QVariant(");
  QString message = msg;
  message.replace(msg.indexOf(key), key.size(), ""); // chop(1) 去掉末尾字符

  // 输入到文件流中
  if (file.open(QIODevice::WriteOnly | QIODevice::Append)) {
    QTextStream stream(&file);
    stream << message << "\n";
    file.close();
  }

  // 也打印一份到控制台
  std::cout << message.toLocal8Bit().data() << std::endl;
}
