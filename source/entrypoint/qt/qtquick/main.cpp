#include "data/clouds/CloudsTC.h"
#include "data/instance/InstanceBuckets.h"
#include "logger.h"
#include "middle/managerglobal.h"
#include "middle/models/paginationproxymodel.h"
#include "plugin/TtPlugin.h"
#include "source/ConfigManager.hpp"
#include "storage/TtDb.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QWKQuick/qwkquickglobal.h>
#include <QtQuick/QQuickWindow>
#include <middle/managerglobal.h>


int main(int argc, char* argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
#else
    qputenv("QT_QUICK_CONTROLS_STYLE", "Default");
#endif

#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
#endif

    QGuiApplication app(argc, argv);
    QQuickWindow::setDefaultAlphaBuffer(true);
    QQmlApplicationEngine engine;

    qInstallMessageHandler(h::Logger::messageHandler);

#if QT_VERSION >= QT_VERSION_CHECK(6, 7, 0)
    const bool curveRenderingAvailable = true;
#else
    const bool curveRenderingAvailable = false;
#endif
    engine.rootContext()->setContextProperty(
        QStringLiteral("$curveRenderingAvailable"),
        QVariant(curveRenderingAvailable));

    QWK::registerTypes(&engine);
    qmlRegisterType<PaginationProxyModel>("com.cloudstorageapp", 1, 0, "PaginationProxyModel");

    // CloudsTC test;

    // // 创建配置管理器实例
    // ConfigManager configManager;
    // qmlRegisterType<ConfigManager>("CloudStorageHub", 1, 0, "ConfigManager");
    // // 注册 ConfigManager 到 QML
    // engine.rootContext()->setContextProperty("configManager", &configManager);

    // 获取 InstanceBuckets 单例实例并注册到 QML
    // auto buckets = InstanceBuckets::instance();
    // buckets->setBuckets(); // 加载数据
    // engine.rootContext()->setContextProperty("instanceBuckets", buckets);

    // BUG 数据库会重复链接
    // 初始化了数据库
    ManGLOBAL->init(argc, argv);
    engine.rootContext()->setContextProperty("ManagerGlobal", ManGLOBAL);

    // engine.rootContext()->setContextProperty("SignalManager",
    // ManGLOBAL->mSignal); engine.rootContext()->setContextProperty("DbManager",
    // ManGLOBAL->mDb); auto = InstanceBuckets::instance(); buckets->setBuckets();
    // // 加载数据 engine.rootContext()->setContextProperty("instanceBuckets",
    // buckets); 数据库 TDB->init(); 注册上下文
    // engine.rootContext()->setContextProperty("TtDB", TDB);

    // 点击 login 按钮后, 需要调用外部的登录验证

    // TP->installPlugins(argc, argv);

    // mWarning();

    const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
    //    const QUrl url(u"qrc:/ui/main.qml"_qs);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

// #include <QGuiApplication>
// #include <QQmlApplicationEngine>

// int main(int argc, char *argv[])
// {
//     QGuiApplication app(argc, argv);

//     QQmlApplicationEngine engine;
//     QObject::connect(
//         &engine,
//         &QQmlApplicationEngine::objectCreationFailed,
//         &app,
//         []() { QCoreApplication::exit(-1); },
//         Qt::QueuedConnection);
//     engine.loadFromModule("Rare", "Main");

//     return app.exec();
// }
