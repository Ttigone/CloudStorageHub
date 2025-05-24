#ifndef DAOLOGININFO_H
#define DAOLOGININFO_H

#include "data/models/dbmodels.h"
#include "helper/dbsqlite.h"

class DaoLoginInfo {
public:
  DaoLoginInfo();

  bool exists(const QString &secretId);
  void insert(const LoginInfo &info);
  void update(const LoginInfo &info);
  void remove(const QString &secretId);
  QList<LoginInfo> select();

  void connect();
  void createTable();

private:
  DbSqlite m_db;
};

#endif // DAOLOGININFO_H
