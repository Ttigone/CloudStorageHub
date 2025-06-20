#ifndef DBSQLITE_H
#define DBSQLITE_H

#include <QMap>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QString>
#include <QVariant>

typedef QMap<QString, QVariant> RECORD;
// using RECORD = QMap<QString, QVariant>;

class DbSqlite {
public:
  DbSqlite();
  ~DbSqlite();

  ///
  /// @brief connect
  /// @param dbPath
  /// 链接数据库
  void connect(const QString &dbPath);

  ///
  /// @brief exec
  /// @param sql
  /// @return
  /// 执行 sql 语句
  QSqlQuery exec(const QString &sql);

  ///
  /// @brief exec
  /// @param sql
  /// @param variantList
  /// @return
  /// 查询多条数据
  QSqlQuery exec(const QString &sql, const QVariantList &variantList);

  bool exists(const QString &sql);
  QList<RECORD> select(const QString &sql);

  ///
  /// @brief isConnected 检查数据库是否链接
  /// @return
  ///
  bool isConnected() const;

  ///
  /// @brief databasePath 获取数据库路径
  /// @return
  ///
  QString databasePath() const;

private:
  QSqlDatabase m_db;
  QString m_connectionName;
  QString m_dbPath;

  // 链接计数
  static int s_connectionCounter;
};

#endif // DBSQLITE_H
