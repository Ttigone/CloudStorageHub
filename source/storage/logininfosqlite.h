#ifndef DAOLOGININFO_H
#define DAOLOGININFO_H

#include "source/helper/dbsqlite.h"
#include "source/middle/models/dbmodels.h"

class LoginInfoSqlite {
public:
  LoginInfoSqlite();

  ///
  /// @brief exists 判断密钥 id 是否存在
  /// @param secretId 用户 id
  /// @return
  ///
  bool exists(const QString &secretId);

  ///
  /// @brief insert 插入一条记录
  /// @param info
  ///
  void insert(const LoginInfo &info);

  ///
  /// @brief update 更新记录
  /// @param info
  ///
  void update(const LoginInfo &info);

  ///
  /// @brief remove 删除记录
  /// @param secretId
  ///
  void remove(const QString &secretId);

  QList<LoginInfo> select();

  void connect();

  void createTable();

private:
  DbSqlite m_db;
};

#endif // DAOLOGININFO_H
