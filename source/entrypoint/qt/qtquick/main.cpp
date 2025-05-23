#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuick/QQuickWindow>

#include <QWKQuick/qwkquickglobal.h>

#include "source/ConfigManager.hpp"

int main(int argc, char *argv[]) {
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
  // 创建配置管理器实例
  ConfigManager configManager;
  QQmlApplicationEngine engine;

#if QT_VERSION >= QT_VERSION_CHECK(6, 7, 0)
  const bool curveRenderingAvailable = true;
#else
  const bool curveRenderingAvailable = false;
#endif
  engine.rootContext()->setContextProperty(
      QStringLiteral("$curveRenderingAvailable"),
      QVariant(curveRenderingAvailable));

  QWK::registerTypes(&engine);

  qmlRegisterType<ConfigManager>("CloudStorageHub", 1, 0, "ConfigManager");
  engine.rootContext()->setContextProperty("configManager", &configManager);

  const QUrl url(QStringLiteral("qrc:/ui/main.qml"));
  //    const QUrl url(u"qrc:/ui/main.qml"_qs);
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
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
