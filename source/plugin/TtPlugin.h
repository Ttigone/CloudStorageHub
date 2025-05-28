#ifndef TTPLUGIN_H
#define TTPLUGIN_H

#include <QObject>

class BaseClouds;
class Version;

#define TP TtPlugin::instance()

class TtPlugin : public QObject {
  Q_OBJECT
public:
  explicit TtPlugin(QObject *parent = nullptr);
  ~TtPlugin();

  static TtPlugin *instance();

  BaseClouds *clouds() const;

  void installPlugins(int argc, char *argv[]);

signals:

private:
  BaseClouds *m_clouds{nullptr};
  Version *m_version{nullptr};
};

#endif // TTPLUGIN_H
