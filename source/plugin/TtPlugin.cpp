#include "TtPlugin.h"

#include "config/global.h"
#include "data/clouds/cloudsmock.h"
#include "data/config/versioncmd.h"
#include "data/config/versionjson.h"
#include "data/logs/baselogger.h"

Q_GLOBAL_STATIC(TtPlugin, ins)

TtPlugin::TtPlugin(QObject *parent) : QObject{parent} {}

TtPlugin::~TtPlugin() {
  delete m_clouds;
  delete m_version;
}

TtPlugin *TtPlugin::instance() { return ins(); }

BaseClouds *TtPlugin::clouds() const { return m_clouds; }

void TtPlugin::installPlugins(int argc, char *argv[]) {

  VersionCmd version(argc, argv);
  if (version.isValid()) {
    m_version = new VersionCmd(argc, argv);
  } else {
    m_version = new VersionJson(GLOBAL::VERSION::JSON_PATH);
  }
  m_version->setVersion();
  if (m_version->major() == GLOBAL::VERSION::MAJOR_BUSINESS) {
    m_clouds = new CloudsMock(":/testing/bussiness.json");
  } else {
    m_clouds = new CloudsMock(":/testing/custom.json");
  }

  m_version = new VersionJson(GLOBAL::VERSION::JSON_PATH);
}
