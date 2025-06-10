#ifndef CLOUDMODELS_H
#define CLOUDMODELS_H

#include <QDebug>
#include <QObject>
#include <string>

class BaseObject {
public:
  BaseObject() {}
  virtual ~BaseObject() {}

  QString name;

public:
  bool isValid() const { return !isInvalid(); }
  bool isInvalid() const { return name.isNull() || name.isEmpty(); }
};
Q_DECLARE_METATYPE(BaseObject) // 可以被QVairant使用

class TtBucket : public BaseObject {
public:
  TtBucket() = default;
  QString location;
  QString createDate;
};
Q_DECLARE_METATYPE(TtBucket)

class TtObject : public BaseObject {
public:
  bool isDir() const {
    qDebug() << name << isValid() << name.endsWith("/");
    return isValid() && name.endsWith("/");
  }
  bool isFile() const { return isValid() && !name.endsWith("/"); }
  QString lastmodified; // 修改时间
  // qulonglong  == unsigned __int64 on Windows
  qulonglong size = 0; // 文件大小
  QString dir;         // 文件目录 books/
  QString key;         // 对象key ， eg：books/aaa.txt
};
Q_DECLARE_METATYPE(TtObject)

#endif // CLOUDMODELS_H
