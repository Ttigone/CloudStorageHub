#include "TtPlugin.h"

#include "config/global.h"
#include "data/clouds/CloudsTC.h"
#include "data/clouds/cloudsmock.h"
#include "data/config/versioncmd.h"
#include "data/config/versionjson.h"

#include "config/loggerproxy.h"
#include "data/logs/loggerqdebug.h"
#include "middle/managerglobal.h"

Q_GLOBAL_STATIC(TtPlugin, ins)

TtPlugin::TtPlugin(QObject* parent) : QObject{parent} {}

TtPlugin::~TtPlugin()
{
    qDebug() << __FUNCTION__;
    if (m_clouds != nullptr) {
        delete m_clouds;
    }
    if (m_version != nullptr) {
        delete m_version;
    }
}

TtPlugin* TtPlugin::instance() { return ins(); }

BaseClouds* TtPlugin::clouds() const { return m_clouds; }

void TtPlugin::installPlugins(int argc, char* argv[])
{
    // 日志插件
    mLogIns->setLogger(new LoggerQDebug());

    VersionCmd version(argc, argv);
    if (version.isValid()) {
        m_version = new VersionCmd(argc, argv);
    } else {
        m_version = new VersionJson(GLOBAL::VERSION::JSON_PATH);
    }
    m_version->setVersion();
    if (m_version->major() == GLOBAL::VERSION::MAJOR_CUSTOM) {
        // 默认会进入这里
        // qDebug() << "测试版本1";
        m_clouds = new CloudsTC();
    } else {
        // qDebug() << "测试版本2";
        m_clouds = new CloudsMock(":/testing/custom.json");
    }

    m_version = new VersionJson(GLOBAL::VERSION::JSON_PATH);
}
