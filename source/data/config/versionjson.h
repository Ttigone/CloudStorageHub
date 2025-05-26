#ifndef VERSIONJSON_H
#define VERSIONJSON_H

#include "version.h"

class VersionJson : public Version
{
public:
    VersionJson(const QString &path);

    void setVersion() override;

private:
    QString m_path;
};

#endif // VERSIONJSON_H
