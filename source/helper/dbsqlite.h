#ifndef DBSQLITE_H
#define DBSQLITE_H

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QString>
#include <QVariant>

typedef QMap<QString, QVariant> RECORD;

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

private:
  QSqlDatabase m_db;
};

#endif // DBSQLITE_H
