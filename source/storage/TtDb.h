#ifndef MANDB_H
#define MANDB_H

#include <QObject>

#include "helper/dbsqlite.h"
#include "storage/TtLogininfo.h"

#define TDB TtDB::instance()

class TtDB : public QObject {
  Q_OBJECT
  // BUG 返回 sql 数据库的结果
  Q_PROPERTY(
      QStringList loginNameList READ loginNameList NOTIFY loginNameListChanged)
public:
  explicit TtDB(QObject *parent = nullptr);

  static TtDB *instance();

  void init();

  ///
  /// @brief saveLoginInfo
  /// @param name
  /// @param id
  /// @param key
  /// @param remark
  /// 保存某条记录到数据库中
  Q_INVOKABLE void saveLoginInfo(const QString &name, const QString &id,
                                 const QString &key, const QString &remark);

  ///
  /// @brief removeLoginInfo
  /// @param id
  /// 在数据库中删除某条记录
  void removeLoginInfo(const QString &id);

  ///
  /// @brief indexOfLoginInfo
  /// @param secretId
  /// @return
  /// 索引某条记录
  int indexOfLoginInfo(const QString &secretId);

  ///
  /// @brief loginNameList
  /// @return
  /// 获取登录名
  QStringList loginNameList();

  ///
  /// @brief loginInfoByName
  /// @param name
  /// @return
  /// 根据登录名索取登录信息
  LoginInfo loginInfoByName(const QString &name);
  ///
  /// @brief loginInfoAsMap
  /// @param name
  /// @return 
  /// 根据登录名返回登录信息的Map (专供QML使用)
  Q_INVOKABLE QVariantMap loginInfoAsMap(const QString &name);

signals:
  void loginNameListChanged();

private:
  TtLoginInfo m_loginInfo;

  ///
  /// @brief m_loginInfoList
  /// 缓存数据库对象
  QList<LoginInfo> m_loginInfoList;
};

#endif // MANDB_H
