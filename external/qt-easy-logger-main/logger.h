#ifndef LOGGER_H
#define LOGGER_H

#include "logview.h"
#include <QObject>

namespace h {
class Logger : public QObject {
  Q_OBJECT
public:
  static void messageHandler(QtMsgType type, const QMessageLogContext &context,
                             const QString &msg);

  static Logger *instance();
  static void openLogView();

signals:

private:
  static LogView *s_logView;
};

} // namespace h
#endif // LOGGER_H
