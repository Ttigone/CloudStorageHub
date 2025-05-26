#ifndef VERSIONCMD_H
#define VERSIONCMD_H

#include "version.h"

class VersionCmd : public Version
{
public:
    VersionCmd(int argc, char *argv[]);
    ~VersionCmd();

    void setVersion() override;
    bool isValid();

private:
    QStringList m_argv;

};

#endif // VERSIONCMD_H
