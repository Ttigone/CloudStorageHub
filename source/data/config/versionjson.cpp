#include "versionjson.h"
#include "helper/filehelper.h"

VersionJson::VersionJson(const std::string &path) { m_path = path; }

void VersionJson::setVersion() {
  QJsonObject obj =
      FileHelper::readAllJson(QString::fromStdString(m_path)).toJsonObject();
  obj = obj["version"].toObject();
  m_major = obj["major"].toString().toStdString();
  m_env = obj["env"].toString().toStdString();
  m_v1 = obj["v1"].toInt();
  m_v2 = obj["v2"].toInt();
  m_v3 = obj["v3"].toInt();
  qDebug() << obj << m_v1;
}
