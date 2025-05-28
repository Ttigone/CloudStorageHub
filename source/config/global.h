#ifndef CONFIG_H
#define CONFIG_H
#include "helper/filehelper.h"
#include <QDir>
#include <QString>
#include <string>

namespace GLOBAL {

namespace SQL {
static const QString LOGIN_INFO_TABLE = ":/sql/login_info.sql";
}

namespace TABLES {
static const QString LOGIN_INFO = "login_info";
}

namespace VERSION {
static const QString MAJOR_CUSTOM = "custom";
static const QString MAJOR_BUSINESS = "business";
// static const QString JSON_PATH = ":/version/config_default.json";
static const std::string JSON_PATH = ":/version/config_default.json";
} // namespace VERSION

namespace ENV {
static const QString ENV_DEV = "dev";
static const QString ENV_ALPHA = "alpha";
static const QString ENV_BETA = "beta";
static const QString ENV_PRE = "pre";
static const QString ENV_PROD = "prod";
} // namespace ENV

namespace PATH {
static const QString WORK = QDir::currentPath();
static const QString TMP = FileHelper::joinPath(WORK, "temp");
static const QString LOG_DIR = FileHelper::joinPath(TMP, "logs");

static const QString ERROR_CODE_PATH = ":/docs/errorcode.csv";
} // namespace PATH

static const QStringList LOG_NAMES = QStringList() << "TOTAL"
                                                   << "DEBUG"
                                                   << "INFO"
                                                   << "WARNING"
                                                   << "ERROR"
                                                   << "FATAL";

namespace SQLITE {
static const QString NAME = FileHelper::joinPath(PATH::TMP, "cos.db");
}

static bool init() { return FileHelper::mkPath(PATH::TMP); }
static bool OK = init();

enum LOG_LEVEL {
  TOTAL = 0,
  DEBUG = 1,
  INFO = 2,
  WARNING = 3,
  ERROR_L = 4,
  FATAL = 5
};

} // namespace GLOBAL

#endif // CONFIG_H
