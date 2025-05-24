#include "storage/TtDb.h"
#include <QDateTime>

Q_GLOBAL_STATIC(TtDB, ins)

TtDB::TtDB(QObject *parent) : QObject{parent} {}

TtDB *TtDB::instance() { return ins(); }

void TtDB::init() {
  m_loginInfo.connect();
  m_loginInfo.createTable();
  // 初始时查询数据库数据
  m_loginInfoList = m_loginInfo.select();
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

  if (m_loginInfo.exists(info.secret_id)) {
    m_loginInfo.update(info);
    m_loginInfoList[indexOfLoginInfo(info.secret_id)] = info;
  } else {
    m_loginInfo.insert(info);
    m_loginInfoList.append(info);
  }
  qDebug() << "保存数据成功";
}

void TtDB::removeLoginInfo(const QString &id) {
  if (m_loginInfo.exists(id)) {
    m_loginInfo.remove(id);
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

QVariantMap TtDB::loginInfoAsMap(const QString &name) {
  QVariantMap result;
  try {
    LoginInfo info = loginInfoByName(name);
    result["name"] = info.name;
    result["secret_id"] = info.secret_id;
    result["secret_key"] = info.secret_key;
    result["remark"] = info.remark;
  } catch (const QString &error) {
    qDebug() << "Error getting login info:" << error;
  }
  return result;
}