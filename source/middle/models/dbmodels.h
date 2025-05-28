#ifndef DBMODELS_H
#define DBMODELS_H

#include <QString>

struct LoginInfo {
  QString name;       // 名称
  QString secret_id;  // id
  QString secret_key; // key
  QString remark;     // 备注
  uint timestamp;     // 时间戳
};

#endif // DBMODELS_H
