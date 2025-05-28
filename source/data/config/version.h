#ifndef VERSION_H
#define VERSION_H

#include <QJsonObject>

class Version {
public:
  Version();
  virtual ~Version();
  virtual void setVersion() = 0;

  QString version();
  QString versionNum();
  QString major() const;

protected:
  std::string m_major;
  std::string m_env;

  int m_v1;
  int m_v2;
  int m_v3;
};

#endif // VERSION_H
