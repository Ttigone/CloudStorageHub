#include "dbsqlite.h"
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlRecord>

int DbSqlite::s_connectionCounter = 0;

DbSqlite::DbSqlite() {
  if (!QSqlDatabase::drivers().contains("QSQLITE")) {
    qCritical() << "❌ SQLite 驱动不可用！可用驱动:" << QSqlDatabase::drivers();
    throw QString("SQLite 驱动不可用");
  }
  // 每个实例不同的链接名
  m_connectionName =
      QString("DbSqlite_Connection_%1").arg(++s_connectionCounter);
  m_db = QSqlDatabase::addDatabase("QSQLITE", m_connectionName);
}

DbSqlite::~DbSqlite() {
  qDebug() << __FUNCTION__ << "Connection:" << m_connectionName;
  if (m_db.isOpen()) {
    m_db.close();
  }
  // 移除数据库连接
  if (QSqlDatabase::contains(m_connectionName)) {
    QSqlDatabase::removeDatabase(m_connectionName);
  }
}

// void DbSqlite::connect(const QString &dbPath) {
//   if (m_db.isOpen() && m_dbPath == dbPath) {
//     qWarning() << "重复链接数据库";
//     return;
//   }

//   if (m_db.isOpen()) {
//     // Qt 内部会自己断开链接
//     m_db.close();
//   }
//   m_dbPath = dbPath;
//   m_db.setDatabaseName(dbPath);
//   if (!m_db.open()) {
//     throw QString::fromLocal8Bit("打开数据库失败：%1 %2")
//         .arg(dbPath, m_db.lastError().text());
//   }
// }
void DbSqlite::connect(const QString &dbPath) {
  qDebug() << "🔗 尝试连接数据库:" << dbPath;

  // 检查数据库文件路径
  QFileInfo fileInfo(dbPath);
  QDir dir = fileInfo.dir();
  if (!dir.exists()) {
    qDebug() << "📁 创建数据库目录:" << dir.absolutePath();
    if (!dir.mkpath(".")) {
      throw QString("无法创建数据库目录: %1").arg(dir.absolutePath());
    }
  }

  if (m_db.isOpen() && m_dbPath == dbPath) {
    qDebug() << "⚠️ 数据库已连接到相同路径，跳过";
    return;
  }

  if (m_db.isOpen()) {
    qDebug() << "🔄 关闭现有连接";
    m_db.close();
  }

  m_dbPath = dbPath;
  m_db.setDatabaseName(dbPath);

  // 尝试打开数据库
  if (!m_db.open()) {
    QSqlError error = m_db.lastError();
    QString errorMsg =
        QString(
            "❌ 打开数据库失败: %1\n数据库路径: %2\n错误类型: %3\n驱动文本: %4")
            .arg(error.text())
            .arg(dbPath)
            .arg(error.type())
            .arg(error.driverText());

    qCritical() << errorMsg;
    throw errorMsg;
  }

  qDebug() << "✅ 数据库连接成功:" << dbPath;
  qDebug() << "📊 数据库信息:"
           << "isOpen:" << m_db.isOpen() << "isValid:" << m_db.isValid()
           << "driver:" << m_db.driverName();
}

QSqlQuery DbSqlite::exec(const QString &sql) {
  if (!isConnected()) {
    throw QString("数据库未链接");
  }
  QSqlQuery query(m_db);
  if (!query.exec(sql)) {
    throw QString::fromLocal8Bit("执行sql失败：%1 %2")
        .arg(sql, query.lastError().text());
  }
  return query;
}

QSqlQuery DbSqlite::exec(const QString &sql, const QVariantList &variantList) {
  // QSqlQuery query;
  if (!isConnected()) {
    throw QString("数据库未链接");
  }
  QSqlQuery query(m_db);
  if (!query.prepare(sql)) {
    throw QString::fromLocal8Bit("预编译sql失败：%1 %2")
        .arg(sql, query.lastError().text());
  }

  for (const auto &var : variantList) {
    query.addBindValue(var);
  }

  if (!query.exec()) {
    throw QString::fromLocal8Bit("执行sql bindvalue失败：%1 %2")
        .arg(sql, query.lastError().text());
  }
  return query;
}

bool DbSqlite::exists(const QString &sql) {
  QSqlQuery query = exec(sql);
  return query.next();
}

QList<RECORD> DbSqlite::select(const QString &sql) {
  QList<RECORD> retList;
  QSqlQuery query = exec(sql);

  while (query.next()) {
    RECORD ret;

    QSqlRecord record = query.record(); // 数据库中的一行记录
    for (int i = 0; i < record.count(); ++i) {
      QString name = record.fieldName(i);
      QVariant value = record.value(i);
      ret[name] = value;
    }
    qDebug() << QString::fromLocal8Bit("查询出结果 ") << ret;
    retList.append(ret);
  }

  return retList;
}

bool DbSqlite::isConnected() const { return m_db.isOpen(); }

QString DbSqlite::databasePath() const { return m_dbPath; }
