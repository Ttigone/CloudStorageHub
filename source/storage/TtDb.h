#ifndef MANDB_H
#define MANDB_H

#include <QObject>

#include "helper/dbsqlite.h"
#include "storage/Logininfo.h"

#define TDB TtDB::instance()

class TtDB : public QObject {
  Q_OBJECT
public:
  explicit TtDB(QObject *parent = nullptr);

  static TtDB *instance();

  void init();

  void saveLoginInfo(const QString &name, const QString &id, const QString &key,
                     const QString &remark);
  void removeLoginInfo(const QString &id);
  int indexOfLoginInfo(const QString &secretId);
  QStringList loginNameList();
  LoginInfo loginInfoByName(const QString &name);

signals:

private:
  DaoLoginInfo m_daoLoginInfo;
  QList<LoginInfo> m_loginInfoList;
};

#endif // MANDB_H
