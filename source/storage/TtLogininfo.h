#ifndef DAOLOGININFO_H
#define DAOLOGININFO_H

#include "data/models/dbmodels.h"
#include "helper/dbsqlite.h"

class TtLoginInfo {
public:
  TtLoginInfo();

  ///
  /// @brief exists
  /// @param secretId
  /// @return
  /// 检查是否存在某个 id 记录
  bool exists(const QString &secretId);

  ///
  /// @brief insert
  /// @param info
  /// 插入一条记录
  void insert(const LoginInfo &info);

  ///
  /// @brief update
  /// @param info
  /// 更新一条记录
  void update(const LoginInfo &info);

  ///
  /// @brief remove
  /// @param secretId
  /// 删除一条记录
  void remove(const QString &secretId);

  ///
  /// @brief select
  /// @return
  /// 获取所有记录
  QList<LoginInfo> select();

  ///
  /// @brief connect
  /// 链接数据库
  void connect();

  ///
  /// @brief createTable
  /// 创建表
  void createTable();

private:
  DbSqlite m_db;
};

#endif // DAOLOGININFO_H
