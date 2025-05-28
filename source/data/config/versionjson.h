#ifndef VERSIONJSON_H
#define VERSIONJSON_H

#include "version.h"

class VersionJson : public Version {
public:
  VersionJson(const std::string &path);

  void setVersion() override;

private:
  std::string m_path;
};

#endif // VERSIONJSON_H
