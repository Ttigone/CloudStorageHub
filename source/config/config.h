#ifndef CONFIG_H
#define CONFIG_H
#include "helper/filehelper.h"
#include <QDir>
#include <QString>

namespace CONF {
namespace PATH {
static const QString WORK = QDir::currentPath();
static const QString TMP = FileHelper::joinPath(WORK, "temp");
}; // namespace PATH

namespace SQLITE {
static const QString NAME = FileHelper::joinPath(PATH::TMP, "cos.db");
};

namespace SQL {
static const QString LOGIN_INFO_TABLE = ":/static/sql/login_info.sql";
};

namespace TABLES {
static const QString LOGIN_INFO = "login_info";
};

static bool init() { return FileHelper::mkPath(PATH::TMP); }
static bool OK = init();
} // namespace CONF

#endif // CONFIG_H
