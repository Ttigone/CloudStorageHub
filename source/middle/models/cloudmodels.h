// #ifndef MYBUCKET_H
// #define MYBUCKET_H

#ifndef CLOUDMODELS_H
#define CLOUDMODELS_H

#include <QObject>
#include <QString>

struct BaseObject {
  bool isValid() const { return !isInvalid(); }
  bool isInvalid() const { return name.isNull() || name.isEmpty(); }
  QString name;
};
Q_DECLARE_METATYPE(BaseObject); // 可以被QVairant使用

/**
 * @brief 自定义桶结构
 *
 * @var QString location
 * @var QString createDate
 * @var QString name
 */
struct TtBucket : public BaseObject {
  TtBucket() = default;
  QString location;
  QString createDate;
  QString name;
};
Q_DECLARE_METATYPE(TtBucket);

/**
 * @brief 自定义对象结构
 *
 * @var QString name
 * @var QString lastmodified 最后一次操作方式
 * @var QString dir 目录 eg:books/
 * @var QString key 对象key，eg：books/aaa.txt
 * @var qulonglong size
 */
struct TtObject : public BaseObject {
  bool isDir() const { return isValid() && name.endsWith("/"); }
  bool isFile() const { return isValid() && !name.endsWith("/"); }
  QString lastmodified;
  // qulonglong  == unsigned __int64 on Windows
  qulonglong size = 0;
  QString dir;
  QString key;
};
Q_DECLARE_METATYPE(TtObject);

#endif // CLOUDMODELS_H
