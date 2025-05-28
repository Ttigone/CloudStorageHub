#ifndef BASICLOGGER_H
#define BASICLOGGER_H

#include <QDate>
#include <QDebug>
#include <QObject>
#include <QString>
#include <QThread>
#include <QVariant>

/**
 * @brief 基础日志类，派生出该类来实现具体的日志记录
 */
class BaseLogger : public QObject {
  Q_OBJECT
public:
  explicit BaseLogger(QObject *parent = nullptr);
  virtual ~BaseLogger();

public slots:
  ///
  /// @brief onLog 处理日志信息槽
  /// @param file 错误文件
  /// @param line 行号
  /// @param func 函数
  /// @param tid 线程号
  /// @param level 日志级别
  /// @param var 日志内容
  /// @param up 是否上传服务器
  ///
  void onLog(const QString &file, int line, const QString &func, void *tid,
             int level, const QVariant &var, bool up);

protected:
  ///
  /// @brief print  子类插件时实现 print
  /// @param file 错误文件
  /// @param line 行号
  /// @param func 函数
  /// @param tid 线程号
  /// @param level 日志级别
  /// @param var 日志内容
  /// @param up 是否上传服务器
  ///
  virtual void print(const QString &file, int line, const QString &func,
                     void *tid, int level, const QVariant &var, bool up) = 0;

  ///
  /// @brief filePath
  /// @return  日志路径
  ///
  static QString filePath();

private:
  // QThread *m_td = nullptr;
  QThread *m_workThread{nullptr};
};

#endif // BASICLOGGER_H
