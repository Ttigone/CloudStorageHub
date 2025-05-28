#ifndef DAOLOGININFO_H
#define DAOLOGININFO_H

#include "source/helper/dbsqlite.h"
#include "source/middle/models/dbmodels.h"

class LoginInfoSqlite {
public:
  LoginInfoSqlite();

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
