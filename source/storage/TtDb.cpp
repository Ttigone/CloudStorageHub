#include "storage/TtDb.h"
#include <QDateTime>

Q_GLOBAL_STATIC(TtDB, ins)

TtDB::TtDB(QObject *parent) : QObject{parent} {}

TtDB *TtDB::instance() { return ins(); }

void TtDB::init() {
  m_daoLoginInfo.connect();
  m_daoLoginInfo.createTable();
  m_loginInfoList = m_daoLoginInfo.select();
}

void TtDB::saveLoginInfo(const QString &name, const QString &id,
                         const QString &key, const QString &remark) {
  LoginInfo info;
  info.name = (name == "" ? id : name);
  info.secret_id = id.trimmed();
  info.secret_key = key.trimmed();
  info.remark = remark.trimmed();
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  info.timestamp = QDateTime::currentDateTimeUtc().toSecsSinceEpoch();
#else
  info.timestamp = QDateTime::currentDateTimeUtc().toTime_t();
#endif

  if (m_daoLoginInfo.exists(info.secret_id)) {
    m_daoLoginInfo.update(info);
    m_loginInfoList[indexOfLoginInfo(info.secret_id)] = info;
  } else {
    m_daoLoginInfo.insert(info);
    m_loginInfoList.append(info);
  }
}

void TtDB::removeLoginInfo(const QString &id) {
  if (m_daoLoginInfo.exists(id)) {
    m_daoLoginInfo.remove(id);
    m_loginInfoList.removeAt(indexOfLoginInfo(id));
  }
}

int TtDB::indexOfLoginInfo(const QString &secretId) {
  for (int i = 0; i < m_loginInfoList.size(); ++i) {
    if (m_loginInfoList[i].secret_id == secretId) {
      return i;
    }
  }
  throw QString::fromLocal8Bit("获取登录信息索引失败 %1").arg(secretId);
}

QStringList TtDB::loginNameList() {
  QStringList words;
  for (int i = 0; i < m_loginInfoList.size(); ++i) {
    words.append(m_loginInfoList[i].name);
  }
  return words;
}

LoginInfo TtDB::loginInfoByName(const QString &name) {
  for (int i = 0; i < m_loginInfoList.size(); ++i) {
    if (m_loginInfoList[i].name == name) {
      return m_loginInfoList[i];
    }
  }
  throw QString::fromLocal8Bit("通过名称查找登录信息失败 %1").arg(name);
}
