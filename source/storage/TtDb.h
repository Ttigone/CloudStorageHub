#ifndef MANDB_H
#define MANDB_H

#include <QObject>

#include "source/helper/dbsqlite.h"
#include "source/storage/logininfosqlite.h"

// #define TDB TtDB::instance()

class TtDB : public QObject {
  Q_OBJECT
  Q_PROPERTY(
      QStringList loginNameList READ loginNameList NOTIFY loginNameListChanged)
public:
  explicit TtDB(QObject *parent = nullptr);
  ~TtDB();
  // static TtDB *instance();

  void init();

  ///
  /// @brief saveLoginInfo
  /// @param name
  /// @param id
  /// @param key
  /// @param remark
  /// 保存某条记录到数据库中
  void saveLoginInfo(const QString &name, const QString &id, const QString &key,
                     const QString &remark);

  ///
  /// @brief removeLoginInfo
  /// @param id
  /// 在数据库中删除某条记录
  void removeLoginInfo(const QString &id);

  ///
  /// @brief indexOfLoginInfo 索引某条记录
  /// @param secretId
  /// @return
  ///
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
  QVariantMap loginInfoAsMap(const QString &name);

signals:
  void loginNameListChanged();

private:
  // TtLoginInfo m_loginInfo;
  LoginInfoSqlite m_loginInfo;

  ///
  /// @brief m_loginInfoList
  /// 缓存数据库对象
  QList<LoginInfo> m_loginInfoList;
};

#endif // MANDB_H
