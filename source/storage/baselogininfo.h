#ifndef DAOLOGININFO_H
#define DAOLOGININFO_H

class BaseLoginInfo {
public:
  BaseLoginInfo();

  ///
  /// @brief exists
  /// @param secretId
  /// @return
  /// 检查是否存在某个 id 记录
  virtual bool exists(const QString &secretId) = 0;

  ///
  /// @brief insert
  /// @param info
  /// 插入一条记录
  void insert(const LoginInfo &info) = 0;

  ///
  /// @brief update
  /// @param info
  /// 更新一条记录
  void update(const LoginInfo &info) = 0;

  ///
  /// @brief remove
  /// @param secretId
  /// 删除一条记录
  void remove(const QString &secretId) = 0;

  ///
  /// @brief select
  /// @return
  /// 获取所有记录
  QList<LoginInfo> select() = 0;

  ///
  /// @brief connect
  /// 链接数据库
  void connect() = 0;

  ///
  /// @brief createTable
  /// 创建表
  void createTable() = 0;
};

#endif // DAOLOGININFO_H
